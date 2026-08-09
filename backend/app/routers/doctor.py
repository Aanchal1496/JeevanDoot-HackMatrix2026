"""Doctor-facing endpoints: risk-sorted queue, triage override, consultations.

The queue is sorted on the backend (never trusted to the frontend) using the
centralized triage engine in ``app/triage``:

    RED -> YELLOW -> GREEN, then highest risk score, then longest wait.
"""
import uuid
from datetime import datetime, timezone
from typing import Any, Dict

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import TriageOverride
from ..triage import PRIORITY, format_wait_time, queue_sort_key

router = APIRouter(prefix="/api/doctor", tags=["doctor"])

# Back-compat mapping so older doctor screens keep working with the new
# RED/YELLOW/GREEN levels.
_LEVEL_TO_LEGACY: Dict[str, tuple] = {
    "RED": ("high", "High Risk"),
    "YELLOW": ("medium", "Medium Risk"),
    "GREEN": ("low", "Low Risk"),
}

_QUEUE_SELECT = """
    SELECT q.*, p.blood_group
      FROM queue_patients q
      LEFT JOIN patients p ON p.id = q.patient_id
"""


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_arrival(raw: Any) -> datetime | None:
    if not raw:
        return None
    try:
        dt = datetime.fromisoformat(str(raw))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def _row_to_patient(row, now: datetime) -> Dict[str, Any]:
    """Serialize a queue_patients row into the full patient payload."""
    d = dict(row)
    d["symptoms"] = d["symptoms"].split("|") if d["symptoms"] else []
    d["critical_symptoms"] = (
        d["critical_symptoms"].split("|") if d["critical_symptoms"] else []
    )

    # Waiting time is computed dynamically from arrival_time, never stored.
    arrival = _parse_arrival(d.get("arrival_time"))
    if arrival is not None:
        wait_minutes = max(0, int((now - arrival).total_seconds() // 60))
    else:
        wait_minutes = int(d.get("wait_minutes") or 0)
    d["wait_minutes"] = wait_minutes

    final_level = str(d.get("final_triage_level") or "GREEN").upper()
    if final_level not in PRIORITY:
        final_level = "GREEN"
    legacy = _LEVEL_TO_LEGACY[final_level]

    vitals = {
        "temp": d.get("vitals_temp"),
        "hr": d.get("vitals_hr"),
        "spo2": d.get("vitals_spo2"),
        "bp": d.get("vitals_bp"),
        "rr": d.get("vitals_rr"),
    }

    return {
        "id": d["id"],
        "patient_id": d.get("patient_id") or d["id"],
        "name": d["name"],
        "age": d["age"],
        "gender": d["gender"],
        "blood_group": d.get("blood_group") or "",
        "symptoms": d["symptoms"],
        "symptom_duration": d.get("symptom_duration") or "",
        "symptom_severity": d.get("symptom_severity") or "",
        "symptom_onset": d.get("symptom_onset") or "",
        "vitals": vitals,
        "arrival_time": d.get("arrival_time"),
        "wait_minutes": wait_minutes,
        "wait_time": format_wait_time(wait_minutes),
        "status": d.get("status") or "WAITING",
        "consult_type": d.get("consult_type"),
        "ai_risk_score": d.get("ai_risk_score"),
        "ai_triage_level": d.get("ai_triage_level") or final_level,
        "ai_triage_reason": d.get("ai_triage_reason"),
        "final_triage_level": final_level,
        "triage_source": d.get("triage_source") or "AI",
        "triage_reason": d.get("triage_reason") or d.get("ai_triage_reason"),
        "doctor_override_reason": d.get("doctor_override_reason"),
        "safety_escalated": bool(d.get("safety_escalated")),
        "critical_symptoms": d["critical_symptoms"],
        "history": {
            "conditions": (
                d["history_conditions"].split("|") if d["history_conditions"] else []
            ),
            "allergies": (
                d["history_allergies"].split("|") if d["history_allergies"] else []
            ),
            "medications": (
                d["history_medications"].split("|") if d["history_medications"] else []
            ),
            "consultations": (
                d["history_consultations"].split("|")
                if d["history_consultations"]
                else []
            ),
        },
        "ai_summary": d.get("ai_summary"),
        # Back-compat fields consumed by pre-existing doctor screens.
        "risk": legacy[0],
        "risk_label": legacy[1],
    }


def _fetch_patient_row(conn, patient_id: str):
    row = conn.execute(
        f"{_QUEUE_SELECT} WHERE q.patient_id = ? OR q.id = ?",
        (patient_id, patient_id),
    ).fetchone()
    return row


def _triage_history(conn, patient_id: str) -> list:
    rows = conn.execute(
        """SELECT * FROM triage_history
           WHERE patient_id = ?
           ORDER BY created_at ASC""",
        (patient_id,),
    ).fetchall()
    return [dict(r) for r in rows]


def _add_triage_history(conn, patient_id: str, previous: str, new: str,
                        risk_score: int | None, source: str, reason: str,
                        changed_by: str, created_at: str) -> None:
    conn.execute(
        """INSERT INTO triage_history
           (id, patient_id, previous_level, new_level, risk_score, source,
            reason, changed_by, created_at)
           VALUES (?,?,?,?,?,?,?,?,?)""",
        (
            "TH-" + uuid.uuid4().hex[:10].upper(),
            patient_id,
            previous,
            new,
            risk_score,
            source,
            reason,
            changed_by,
            created_at,
        ),
    )


# ---------------------------------------------------------------------------
# Queue
# ---------------------------------------------------------------------------


@router.get("/queue")
def get_risk_sorted_queue():
    """The live, risk-sorted queue plus summary counts and consulting list."""
    conn = get_connection()
    try:
        now = _now()
        rows = conn.execute(_QUEUE_SELECT).fetchall()
        patients = [_row_to_patient(r, now) for r in rows]

        waiting = [p for p in patients if p["status"] == "WAITING"]
        consulting = [p for p in patients if p["status"] == "IN_CONSULTATION"]
        waiting.sort(key=queue_sort_key)
        consulting.sort(key=queue_sort_key)

        counts = {level: 0 for level in ("RED", "YELLOW", "GREEN")}
        for p in waiting:
            counts[p["final_triage_level"]] = (
                counts.get(p["final_triage_level"], 0) + 1
            )

        doctors = [
            {"id": r["id"], "name": r["name"]}
            for r in conn.execute("SELECT id, name FROM doctors").fetchall()
        ]

        return {
            "queue": waiting,
            "consulting": consulting,
            "summary": {
                "red": counts["RED"],
                "yellow": counts["YELLOW"],
                "green": counts["GREEN"],
                "total_waiting": len(waiting),
                "in_consultation": len(consulting),
            },
            "doctors": doctors,
        }
    finally:
        conn.close()


@router.get("/patients")
def get_queue():
    """Flat, risk-sorted list of active (waiting + consulting) patients.

    Kept for back-compatibility with older doctor screens.
    """
    conn = get_connection()
    try:
        now = _now()
        rows = conn.execute(
            _QUEUE_SELECT + " WHERE q.status != 'COMPLETED' AND q.status != 'CANCELLED'"
        ).fetchall()
        patients = [_row_to_patient(r, now) for r in rows]
        patients.sort(key=queue_sort_key)
        return {"patients": patients}
    finally:
        conn.close()


@router.get("/patients/{patient_id}")
def get_case(patient_id: str):
    """Full patient case: triage assessment, vitals, history, triage history."""
    conn = get_connection()
    try:
        row = _fetch_patient_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        patient = _row_to_patient(row, _now())
        patient["triage_history"] = _triage_history(conn, patient["patient_id"])
        return {"case": patient}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Triage override
# ---------------------------------------------------------------------------


@router.post("/patients/{patient_id}/triage/override")
def override_triage(patient_id: str, payload: TriageOverride):
    """Apply a doctor's manual triage override and record it in the audit log.

    The original AI assessment is never overwritten - only the final triage
    level and the source are updated, and a TriageHistory row is created.
    """
    reason = payload.reason.strip()
    if not reason:
        raise HTTPException(status_code=400, detail="A reason is required for the override.")

    conn = get_connection()
    try:
        row = _fetch_patient_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        current = dict(row)
        previous = str(current.get("final_triage_level") or "GREEN").upper()
        if previous not in PRIORITY:
            previous = "GREEN"
        if previous == payload.triage_level:
            raise HTTPException(
                status_code=400,
                detail=f"Patient is already triaged as {payload.triage_level}.",
            )

        now = _now()
        # The doctor's decision supersedes any prior safety escalation: clear
        # the escalation flags so the UI no longer claims "flagged for urgent
        # review" after the doctor has explicitly re-triaged the patient.
        conn.execute(
            """UPDATE queue_patients
                  SET final_triage_level = ?, triage_source = 'DOCTOR',
                      doctor_override_reason = ?, triage_reason = ?,
                      safety_escalated = 0, critical_symptoms = '',
                      updated_at = ?
                WHERE id = ?""",
            (payload.triage_level, reason, reason, now.isoformat(), current["id"]),
        )
        changed_by = (payload.changed_by or "Dr. Priya Sharma").strip() or "Doctor"
        _add_triage_history(
            conn,
            current.get("patient_id") or current["id"],
            previous,
            payload.triage_level,
            current.get("ai_risk_score"),
            "DOCTOR",
            reason,
            changed_by,
            now.isoformat(),
        )
        conn.commit()

        updated = _fetch_patient_row(conn, current["id"])
        patient = _row_to_patient(updated, _now())
        patient["triage_history"] = _triage_history(conn, patient["patient_id"])
        return {"patient": patient}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Consultation lifecycle
# ---------------------------------------------------------------------------


@router.post("/patients/{patient_id}/consultation/start")
def start_consultation(patient_id: str):
    """Move a patient from WAITING to IN_CONSULTATION."""
    conn = get_connection()
    try:
        row = _fetch_patient_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        current = dict(row)
        status = current.get("status") or "WAITING"
        if status == "COMPLETED":
            raise HTTPException(
                status_code=409, detail="This consultation has already been completed."
            )
        if status == "CANCELLED":
            raise HTTPException(
                status_code=409, detail="This patient was cancelled."
            )
        if status != "IN_CONSULTATION":
            conn.execute(
                """UPDATE queue_patients
                      SET status = 'IN_CONSULTATION', updated_at = ?
                    WHERE id = ?""",
                (_now().isoformat(), current["id"]),
            )
            conn.commit()
        updated = _fetch_patient_row(conn, current["id"])
        return {"patient": _row_to_patient(updated, _now())}
    finally:
        conn.close()


@router.post("/patients/{patient_id}/consultation/complete")
def complete_consultation(patient_id: str):
    """Move a patient from IN_CONSULTATION to COMPLETED."""
    conn = get_connection()
    try:
        row = _fetch_patient_row(conn, patient_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        current = dict(row)
        status = current.get("status") or "WAITING"
        if status != "IN_CONSULTATION":
            raise HTTPException(
                status_code=409,
                detail="Patient is not in an active consultation.",
            )
        conn.execute(
            """UPDATE queue_patients
                  SET status = 'COMPLETED', updated_at = ?
                WHERE id = ?""",
            (_now().isoformat(), current["id"]),
        )
        conn.commit()
        updated = _fetch_patient_row(conn, current["id"])
        return {"patient": _row_to_patient(updated, _now())}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Appointments / stats / medicines (unchanged behaviour)
# ---------------------------------------------------------------------------


@router.get("/appointments")
def get_appointments():
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM appointments ORDER BY time ASC"
        ).fetchall()
        return {"appointments": [dict(r) for r in rows]}
    finally:
        conn.close()


@router.get("/stats")
def get_stats():
    conn = get_connection()
    try:
        now = _now()
        rows = conn.execute(_QUEUE_SELECT).fetchall()
        patients = [_row_to_patient(r, now) for r in rows]
        waiting = [p for p in patients if p["status"] == "WAITING"]
        waiting.sort(key=queue_sort_key)

        total = len(patients)
        urgent = sum(
            1 for p in waiting if p["final_triage_level"] == "RED"
        )
        completed = conn.execute(
            "SELECT COUNT(*) AS c FROM appointments WHERE status = 'Completed'"
        ).fetchone()["c"]

        urgent_case = waiting[0] if waiting else None
        next_row = conn.execute(
            "SELECT * FROM appointments WHERE status != 'Completed' ORDER BY id LIMIT 1"
        ).fetchone()

        return {
            "stats": {
                "patients": str(total),
                "waiting": str(len(waiting)),
                "urgent": str(urgent),
                "completed": str(completed),
            },
            "urgent_case": urgent_case,
            "next_consultation": dict(next_row) if next_row else None,
        }
    finally:
        conn.close()


# Medicine search moved to routers/doctor_prescriptions.py which returns the
# structured catalog (generic name, brand, strength, form, route, category)
# and the configurable common-medicine quick-select list.
