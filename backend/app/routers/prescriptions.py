"""Prescription endpoints: read-only for patients."""
from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import PrescriptionCreate

router = APIRouter(prefix="/api/prescriptions", tags=["prescriptions"])


def _prescription_dict(conn, row) -> dict:
    d = dict(row)
    items = conn.execute(
        "SELECT * FROM prescription_items WHERE prescription_id = ? ORDER BY id",
        (d["id"],),
    ).fetchall()
    d["medicines"] = [dict(i) for i in items]
    return d


@router.get("")
def list_prescriptions(patient_id: str):
    """Patient-facing list: only ISSUED prescriptions are visible.

    Drafts stay hidden from the patient portal - the server enforces this,
    never the client.
    """
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM prescriptions
               WHERE patient_id = ? AND status = 'ISSUED'
               ORDER BY issued_at DESC, id DESC""",
            (patient_id,),
        ).fetchall()
        return {"prescriptions": [_prescription_dict(conn, r) for r in rows]}
    finally:
        conn.close()


@router.get("/{prescription_id}")
def get_prescription(prescription_id: str):
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM prescriptions WHERE id = ?", (prescription_id,)
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Prescription not found.")
        return {"prescription": _prescription_dict(conn, row)}
    finally:
        conn.close()


@router.post("")
def create_prescription(payload: PrescriptionCreate):
    """Deprecated: prescriptions are created by doctors only.

    The legacy patient-facing create path bypassed the doctor-confirmation
    and safety checks of the prescription writer, so it is disabled. Use the
    authenticated doctor endpoints under `/api/doctor/prescriptions`.
    """
    raise HTTPException(
        status_code=403,
        detail="Prescriptions can only be created by an authorized doctor "
        "through the consultation workflow.",
    )
