"""Doctor-facing prescription writer endpoints.

The server is the source of truth: nothing the client reports (status,
safety) is trusted. Issue revalidates medicine fields, the prescription
status and the doctor's authorization. Every lifecycle action is audited.
"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response

from ..db import get_connection
from ..prescription_pdf import build_prescription_pdf
from ..prescription_service import (
    add_audit,
    add_item,
    cancel_prescription,
    check_allergy,
    check_duplicate,
    common_medicines,
    create_draft,
    evaluate_safety,
    get_medicine,
    get_open_draft,
    get_prescription,
    issue_prescription,
    remove_item,
    search_medicines,
    update_item,
    update_notes,
)
from ..routers.auth import get_current_doctor
from ..schemas import (
    PrescriptionCancel,
    PrescriptionDraftCreate,
    PrescriptionItemAdd,
    PrescriptionItemUpdate,
    PrescriptionNotesUpdate,
)

router = APIRouter(prefix="/api/doctor", tags=["doctor-prescriptions"])


def _doctor_identity(auth: dict):
    """Return (doctor_id, display_name)."""
    user_id = auth.get("user_id")
    if user_id:
        conn = get_connection()
        try:
            row = conn.execute(
                "SELECT name FROM doctors WHERE id = ?", (user_id,)
            ).fetchone()
        finally:
            conn.close()
        if row is not None:
            return user_id, row["name"]
        return user_id, "Doctor"
    return None, auth.get("name") or "Dr. Priya Sharma"


def _require_draft(rx: dict) -> dict:
    if rx["status"] == "ISSUED":
        raise HTTPException(
            status_code=409,
            detail="This prescription has already been issued and cannot be edited.",
        )
    if rx["status"] == "CANCELLED":
        raise HTTPException(
            status_code=409, detail="This prescription is cancelled."
        )
    return rx


def _require_issued(rx: dict) -> dict:
    if rx["status"] != "ISSUED":
        raise HTTPException(
            status_code=409, detail="Only issued prescriptions can be viewed this way."
        )
    return rx


def _patient_block(conn, patient_id: str) -> dict:
    """Patient identity + allergies for the PDF / history view."""
    row = conn.execute(
        """SELECT q.name, q.age, q.gender, q.history_allergies, p.allergies
             FROM queue_patients q
             LEFT JOIN patients p ON p.id = q.patient_id
            WHERE q.patient_id = ? OR q.id = ?""",
        (patient_id, patient_id),
    ).fetchone()
    if row is None:
        row = conn.execute(
            "SELECT name, age, gender, allergies FROM patients WHERE id = ?",
            (patient_id,),
        ).fetchone()
    if row is None:
        return {"id": patient_id, "name": "Patient", "age": "", "gender": "",
                "allergies": []}
    allergies = []
    for col in ("history_allergies", "allergies"):
        value = row[col]
        if value:
            for piece in str(value).replace(",", "|").split("|"):
                piece = piece.strip()
                if piece and piece.lower() not in ("none", "no", "-", "nil"):
                    allergies.append(piece)
    return {
        "id": patient_id,
        "name": row["name"] or "Patient",
        "age": row["age"] or "",
        "gender": row["gender"] or "",
        "allergies": allergies,
    }


def _doctor_block(conn, doctor_id) -> dict:
    if doctor_id:
        row = conn.execute(
            "SELECT * FROM doctors WHERE id = ?", (doctor_id,)
        ).fetchone()
        if row is not None:
            d = dict(row)
            return {
                "id": d["id"],
                "name": d["name"],
                "specialization": d.get("specialization") or "",
                "registration_id": d.get("registration_id") or "",
                "clinic": d.get("clinic") or "",
            }
    return {
        "id": doctor_id,
        "name": "Dr. Priya Sharma",
        "specialization": "General Physician",
        "registration_id": "MCI-78945612",
        "clinic": "JeevanDoot Clinic",
    }


# ---------------------------------------------------------------------------
# Medicine catalog (search + configurable quick select)
# ---------------------------------------------------------------------------


@router.get("/medicines")
def list_medicines(q: str = ""):
    conn = get_connection()
    try:
        return {"medicines": search_medicines(conn, q)}
    finally:
        conn.close()


@router.get("/medicines/common")
def list_common_medicines():
    conn = get_connection()
    try:
        return {"medicines": common_medicines(conn)}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Draft lifecycle
# ---------------------------------------------------------------------------


@router.post("/prescriptions")
def create_prescription_draft(
    payload: PrescriptionDraftCreate,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, doctor_name = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = create_draft(
            conn, payload.patient_id, doctor_id, doctor_name,
            payload.consultation_id,
        )
        conn.commit()
        return {
            "prescription": rx,
            "message": "Draft created. Reopening the existing draft for this patient." if rx["status"] == "DRAFT" else "",
        }
    finally:
        conn.close()


@router.get("/prescriptions/drafts")
def get_draft(patient_id: str, auth: dict = Depends(get_current_doctor)):
    conn = get_connection()
    try:
        rx = get_open_draft(conn, patient_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="No draft found.")
        return {"prescription": rx}
    finally:
        conn.close()


@router.get("/prescriptions/history")
def prescription_history(patient_id: str, auth: dict = Depends(get_current_doctor)):
    """Issued prescription history for a patient (doctor view)."""
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM prescriptions
               WHERE patient_id = ? AND status = 'ISSUED'
               ORDER BY issued_at DESC, created_at DESC""",
            (patient_id,),
        ).fetchall()
        from ..prescription_service import prescription_dict

        return {"prescriptions": [prescription_dict(conn, r) for r in rows]}
    finally:
        conn.close()


@router.get("/prescriptions/{prescription_id}")
def get_rx(prescription_id: str, auth: dict = Depends(get_current_doctor)):
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        return {"prescription": rx}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Items
# ---------------------------------------------------------------------------


@router.post("/prescriptions/{prescription_id}/items")
def add_rx_item(
    prescription_id: str,
    payload: PrescriptionItemAdd,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        _require_draft(rx)

        medicine = get_medicine(conn, payload.medicine_id)
        if medicine is None:
            raise HTTPException(
                status_code=422,
                detail="Medicine could not be added. Please select a valid medicine.",
            )
        safety = evaluate_safety(
            conn, rx["patient_id"], medicine, rx["medicines"]
        )
        try:
            rx = add_item(conn, rx, payload, medicine, doctor_id)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc))
        conn.commit()
        return {"prescription": rx, "safety": safety}
    finally:
        conn.close()


@router.patch("/prescriptions/{prescription_id}/items/{item_id}")
def update_rx_item(
    prescription_id: str,
    item_id: int,
    payload: PrescriptionItemUpdate,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        _require_draft(rx)
        rx = update_item(conn, rx, item_id, payload, doctor_id)
        conn.commit()
        return {"prescription": rx}
    finally:
        conn.close()


@router.delete("/prescriptions/{prescription_id}/items/{item_id}")
def delete_rx_item(
    prescription_id: str,
    item_id: int,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        _require_draft(rx)
        rx = remove_item(conn, rx, item_id, doctor_id)
        conn.commit()
        return {"prescription": rx}
    finally:
        conn.close()


@router.patch("/prescriptions/{prescription_id}/notes")
def save_rx_notes(
    prescription_id: str,
    payload: PrescriptionNotesUpdate,
    auth: dict = Depends(get_current_doctor),
):
    """Autosave additional instructions (never issues anything)."""
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        _require_draft(rx)
        rx = update_notes(conn, rx, payload.additional_instructions, doctor_id)
        conn.commit()
        return {"prescription": rx}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Issue / cancel
# ---------------------------------------------------------------------------


@router.post("/prescriptions/{prescription_id}/issue")
def issue_rx(
    prescription_id: str,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, doctor_name = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        add_audit(conn, rx["id"], doctor_id, "PRESCRIPTION_REVIEWED", {})
        try:
            rx = issue_prescription(conn, rx, doctor_id, doctor_name)
        except ValueError as exc:
            raise HTTPException(status_code=409, detail=str(exc))
        conn.commit()
        return {
            "prescription": rx,
            "message": "Prescription issued.",
        }
    finally:
        conn.close()


@router.post("/prescriptions/{prescription_id}/cancel")
def cancel_rx(
    prescription_id: str,
    payload: PrescriptionCancel,
    auth: dict = Depends(get_current_doctor),
):
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        try:
            rx = cancel_prescription(conn, rx, payload.reason.strip(), doctor_id)
        except ValueError as exc:
            raise HTTPException(status_code=409, detail=str(exc))
        conn.commit()
        return {"prescription": rx, "message": "Prescription cancelled."}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# PDF (authenticated, issued only)
# ---------------------------------------------------------------------------


@router.get("/prescriptions/{prescription_id}/pdf")
def rx_pdf(prescription_id: str, auth: dict = Depends(get_current_doctor)):
    conn = get_connection()
    try:
        rx = get_prescription(conn, prescription_id)
        if rx is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        _require_issued(rx)
        doctor = _doctor_block(conn, rx.get("doctor_id"))
        patient = _patient_block(conn, rx["patient_id"])
        pdf = build_prescription_pdf(rx, doctor, patient)
    finally:
        conn.close()
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{rx["id"]}.pdf"',
        },
    )
