"""Pre-consultation case file endpoints.

All endpoints require a valid doctor token (see ``auth.get_current_doctor``)
and record their actions in the ``case_file_audit_log`` table.
"""
import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from ..casefile import (
    add_audit_log,
    build_case_file_payload,
    upsert_case_file,
)
from ..db import get_connection
from ..routers.auth import get_current_doctor
from ..schemas import CaseFileSummaryUpdate

router = APIRouter(prefix="/api/doctor", tags=["doctor-case-file"])

_CASE_SELECT = """
    SELECT q.*, p.blood_group
      FROM queue_patients q
      LEFT JOIN patients p ON p.id = q.patient_id
"""


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _fetch_queue_row(conn, patient_id: str):
    return conn.execute(
        f"{_CASE_SELECT} WHERE q.patient_id = ? OR q.id = ?",
        (patient_id, patient_id),
    ).fetchone()


def _row_with_wait(row, now: datetime) -> dict:
    """Copy of the queue row with dynamic waiting time attached."""
    d = dict(row)
    from ..routers.doctor import _parse_arrival

    arrival = _parse_arrival(d.get("arrival_time"))
    if arrival is not None:
        wait_minutes = max(0, int((now - arrival).total_seconds() // 60))
    else:
        wait_minutes = int(d.get("wait_minutes") or 0)
    d["wait_minutes"] = wait_minutes
    d["wait_time"] = (
        f"{wait_minutes} min"
        if wait_minutes < 60
        else f"{wait_minutes // 60} hr {wait_minutes % 60} min"
    )
    return d


def _stored_case_file(conn, patient_id: str):
    row = conn.execute(
        "SELECT * FROM case_files WHERE patient_id = ?", (patient_id,)
    ).fetchone()
    return dict(row) if row else None


def _doctor_identity(auth: dict) -> tuple:
    """Return (doctor_id, display_name) for audit logging."""
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


def _log_changes(conn, stored: dict | None, payload: dict, patient_id: str,
                 doctor_id: str | None, now: datetime) -> None:
    """Log VITALS_UPDATED / RISK_UPDATED when the refresh detected changes."""
    if stored is None:
        return
    old_risk = stored.get("ai_risk_score")
    new_risk = payload["risk_assessment"].get("ai_risk_score")
    if old_risk != new_risk:
        add_audit_log(
            conn, patient_id, doctor_id, "RISK_UPDATED",
            {"from": old_risk, "to": new_risk}, now,
        )
    try:
        old_vitals = stored.get("current_vitals")
        old_vitals = json.loads(old_vitals) if old_vitals else []
    except (TypeError, ValueError):
        old_vitals = []
    new_vitals = payload["vitals"]["items"]
    if old_vitals != new_vitals:
        add_audit_log(
            conn, patient_id, doctor_id, "VITALS_UPDATED",
            {"count": len(new_vitals)}, now,
        )


@router.get("/patients/{patient_id}/case-file")
def get_case_file(
    patient_id: str,
    auth: dict = Depends(get_current_doctor),
):
    """Aggregated pre-consultation case file (single request, no N+1)."""
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        row = _fetch_queue_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        now = _now()
        data = _row_with_wait(row, now)
        stored = _stored_case_file(conn, data["patient_id"] or data["id"])

        pid = data["patient_id"] or data["id"]
        payload = build_case_file_payload(data, stored)
        if stored is None:
            # First open: generate + record the audit trail.
            payload = upsert_case_file(conn, pid, data, payload, now)
            add_audit_log(
                conn, pid, doctor_id,
                "AI_SUMMARY_GENERATED", {"mode": "auto"}, now,
            )
            add_audit_log(conn, pid, doctor_id, "CASE_FILE_VIEWED", {}, now)
        else:
            # Subsequent reads (including UI polling) stay read-only unless
            # vitals/risk actually changed, so the audit log isn't spammed.
            payload = upsert_case_file(conn, pid, data, payload, now)
            _log_changes(
                conn, stored, payload, pid, doctor_id, now,
            )
        conn.commit()
        return {"case_file": payload}
    finally:
        conn.close()


@router.post("/patients/{patient_id}/case-file/generate")
def generate_case_file(
    patient_id: str,
    auth: dict = Depends(get_current_doctor),
):
    """Regenerate the case file from the latest patient data.

    A doctor-edited summary is preserved; only unedited AI content is
    refreshed. Audit records when this ran and why.
    """
    doctor_id, _ = _doctor_identity(auth)
    conn = get_connection()
    try:
        row = _fetch_queue_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        now = _now()
        data = _row_with_wait(row, now)
        stored = _stored_case_file(conn, data["patient_id"] or data["id"])

        payload = build_case_file_payload(data, stored)
        payload = upsert_case_file(
            conn, data["patient_id"] or data["id"], data, payload, now
        )
        add_audit_log(
            conn, data["patient_id"] or data["id"], doctor_id,
            "AI_SUMMARY_GENERATED", {"mode": "manual"}, now,
        )
        _log_changes(
            conn, stored, payload, data["patient_id"] or data["id"],
            doctor_id, now,
        )
        conn.commit()
        return {"case_file": payload}
    finally:
        conn.close()


@router.patch("/patients/{patient_id}/case-file/summary")
def update_case_file_summary(
    patient_id: str,
    payload: CaseFileSummaryUpdate,
    auth: dict = Depends(get_current_doctor),
):
    """Apply the doctor's edited summary.

    The original AI summary is preserved untouched and both versions are
    returned so the UI can show them side by side.
    """
    doctor_id, doctor_name = _doctor_identity(auth)
    conn = get_connection()
    try:
        row = _fetch_queue_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        now = _now()
        data = _row_with_wait(row, now)
        pid = data["patient_id"] or data["id"]

        stored = _stored_case_file(conn, pid)
        if stored is None:
            # Ensure a case file exists before editing it.
            fresh = build_case_file_payload(data, None)
            upsert_case_file(conn, pid, data, fresh, now)
            stored = _stored_case_file(conn, pid)

        summary = payload.doctor_summary.strip()
        if not summary:
            raise HTTPException(status_code=400, detail="Summary cannot be empty.")

        conn.execute(
            """UPDATE case_files
                  SET ai_summary = ?, doctor_edited_summary = ?,
                      edited_by = ?, edited_at = ?, updated_at = ?
                WHERE id = ?""",
            (summary, summary, doctor_name, now.isoformat(), now.isoformat(),
             stored["id"]),
        )
        add_audit_log(
            conn, pid, doctor_id, "SUMMARY_EDITED",
            {"edited_by": doctor_name}, now,
        )
        conn.commit()

        stored = _stored_case_file(conn, pid)
        result = build_case_file_payload(data, stored)
        result["timestamps"]["updated_at"] = stored["updated_at"]
        result["timestamps"]["updated_label"] = _format_label(stored["updated_at"])
        return {"case_file": result}
    finally:
        conn.close()


def _format_label(iso_value: str | None) -> str:
    if not iso_value:
        return ""
    try:
        dt = datetime.fromisoformat(str(iso_value))
        if dt.tzinfo:
            dt = dt.astimezone()
    except ValueError:
        return str(iso_value)
    return dt.strftime("%d %b %Y • %I:%M %p")
