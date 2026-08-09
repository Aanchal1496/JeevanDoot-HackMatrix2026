"""Patient profile, records, and reminders endpoints."""
from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import ProfileUpdate, ReminderDone

router = APIRouter(prefix="/api", tags=["patient"])

_BOOL_COLS = [
    "sms_alerts", "app_alerts", "email_updates", "reminder_alerts",
    "appointment_alerts", "data_sharing", "app_lock", "biometric_lock",
    "share_health_reports", "marketing_updates",
]

_STRING_COLS = [
    "name", "age", "gender", "blood_group", "email", "address", "dob",
    "id_number", "phone", "language", "allergies", "chronic_conditions",
    "height", "weight", "medications",
]


def _profile_dict(conn, patient_id: str) -> dict:
    row = conn.execute(
        "SELECT * FROM patients WHERE id = ?", (patient_id,)
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Patient not found.")
    d = dict(row)
    out = {
        "id": d["id"],
        "name": d["name"],
        "phone": d["phone"],
        "age": d["age"],
        "gender": d["gender"],
        "blood_group": d["blood_group"],
        "email": d["email"],
        "address": d["address"],
        "dob": d["dob"],
        "id_number": d["id_number"],
        "language": d["language"],
        "photo_url": d["photo_url"],
        "allergies": d["allergies"],
        "chronic_conditions": d["chronic_conditions"],
        "height": d["height"],
        "weight": d["weight"],
        "medications": d["medications"],
    }
    for col in _BOOL_COLS:
        out[col] = bool(d[col])
    return out


@router.get("/profile")
def get_profile(patient_id: str):
    conn = get_connection()
    try:
        return {"profile": _profile_dict(conn, patient_id)}
    finally:
        conn.close()


@router.put("/profile")
def update_profile(patient_id: str, payload: ProfileUpdate):
    conn = get_connection()
    try:
        sets, values = [], []
        for col in _STRING_COLS:
            val = getattr(payload, col)
            if val is not None:
                sets.append(f"{col} = ?")
                values.append(val)
        for col in _BOOL_COLS:
            val = getattr(payload, col)
            if val is not None:
                sets.append(f"{col} = ?")
                values.append(int(val))
        if not sets:
            raise HTTPException(status_code=400, detail="Nothing to update.")
        values.append(patient_id)
        conn.execute(
            f"UPDATE patients SET {', '.join(sets)} WHERE id = ?", values
        )
        conn.commit()
        return {"profile": _profile_dict(conn, patient_id), "message": "Profile updated."}
    finally:
        conn.close()


@router.get("/records")
def get_records(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM records WHERE patient_id = ? ORDER BY id DESC",
            (patient_id,),
        ).fetchall()
        return {"records": [dict(r) for r in rows]}
    finally:
        conn.close()


@router.get("/reminders")
def get_reminders(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM reminders WHERE patient_id = ? ORDER BY time",
            (patient_id,),
        ).fetchall()
        return {"reminders": [dict(r) for r in rows]}
    finally:
        conn.close()


@router.post("/reminders/{reminder_id}/done")
def set_reminder_done(reminder_id: str, payload: ReminderDone):
    conn = get_connection()
    try:
        conn.execute(
            "UPDATE reminders SET done = ? WHERE id = ?",
            (int(payload.done), reminder_id),
        )
        conn.commit()
        return {"message": "Reminder updated."}
    finally:
        conn.close()
