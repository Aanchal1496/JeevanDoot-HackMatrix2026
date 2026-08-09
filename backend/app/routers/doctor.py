"""Doctor-facing endpoints: queue, appointments, cases, stats, medicines."""
from fastapi import APIRouter, HTTPException

from ..db import get_connection

router = APIRouter(prefix="/api/doctor", tags=["doctor"])


def _queue_row_to_dict(r) -> dict:
    d = dict(r)
    d["symptoms"] = d["symptoms"].split("|") if d["symptoms"] else []
    d["wait_time"] = f"{d['wait_minutes']:02d} MIN WAIT"
    return d


@router.get("/patients")
def get_queue():
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM queue_patients ORDER BY wait_minutes ASC"
        ).fetchall()
        return {"patients": [_queue_row_to_dict(r) for r in rows]}
    finally:
        conn.close()


@router.get("/patients/{patient_id}")
def get_case(patient_id: str):
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM queue_patients WHERE id = ?", (patient_id,)
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Patient not found.")
        d = _queue_row_to_dict(row)
        return {
            "case": {
                "id": d["id"],
                "name": d["name"],
                "age": d["age"],
                "gender": d["gender"],
                "risk": d["risk"],
                "risk_label": d["risk_label"],
                "symptoms": d["symptoms"],
                "wait_time": d["wait_time"],
                "consult_type": d["consult_type"],
                "vitals": {
                    "temp": d["vitals_temp"],
                    "hr": d["vitals_hr"],
                    "spo2": d["vitals_spo2"],
                    "bp": d["vitals_bp"],
                },
                "history": {
                    "conditions": d["history_conditions"].split("|") if d["history_conditions"] else [],
                    "allergies": d["history_allergies"].split("|") if d["history_allergies"] else [],
                    "medications": d["history_medications"].split("|") if d["history_medications"] else [],
                    "consultations": d["history_consultations"].split("|") if d["history_consultations"] else [],
                },
                "ai_summary": d["ai_summary"],
            }
        }
    finally:
        conn.close()


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
        total = conn.execute("SELECT COUNT(*) AS c FROM queue_patients").fetchone()["c"]
        urgent = conn.execute(
            "SELECT COUNT(*) AS c FROM queue_patients WHERE risk IN ('high','urgent')"
        ).fetchone()["c"]
        completed = conn.execute(
            "SELECT COUNT(*) AS c FROM appointments WHERE status = 'Completed'"
        ).fetchone()["c"]
        return {
            "stats": {
                "patients": str(total),
                "waiting": str(total),
                "urgent": str(urgent),
                "completed": str(completed),
            },
            "urgent_case": _queue_row_to_dict(
                conn.execute(
                    "SELECT * FROM queue_patients WHERE risk IN ('high','urgent') ORDER BY wait_minutes ASC LIMIT 1"
                ).fetchone()
            ),
            "next_consultation": dict(
                conn.execute(
                    "SELECT * FROM appointments WHERE status != 'Completed' ORDER BY id LIMIT 1"
                ).fetchone()
            ),
        }
    finally:
        conn.close()


@router.get("/medicines")
def search_medicines(q: str = ""):
    conn = get_connection()
    try:
        if q:
            rows = conn.execute(
                "SELECT name FROM medicines WHERE name LIKE ? ORDER BY name LIMIT 20",
                (f"%{q}%",),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT name FROM medicines ORDER BY name LIMIT 20"
            ).fetchall()
        return {"medicines": [dict(r)["name"] for r in rows]}
    finally:
        conn.close()
