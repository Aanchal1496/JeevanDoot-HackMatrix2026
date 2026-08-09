"""Patient profile, records, and reminders endpoints."""
import re
from datetime import date, datetime

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import ProfileUpdate, ReminderDone
from .prescriptions import _prescription_dict

router = APIRouter(prefix="/api", tags=["patient"])

_MONTHS = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]

_MONTH_INDEX = {
    "January": 1, "February": 2, "March": 3, "April": 4, "May": 5,
    "June": 6, "July": 7, "August": 8, "September": 9, "October": 10,
    "November": 11, "December": 12,
}

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


def _iso_from_datetime(value: str) -> str:
    """'2026-08-09T12:34:56' (or '2026-08-09') -> '2026-08-09'."""
    if not value:
        return ""
    return value.split("T")[0]


def _iso_from_date_string(value: str) -> str:
    """'August 10, 2026' -> '2026-08-10'. Returns '' when unparseable."""
    if not value:
        return ""
    m = re.match(r"^\s*([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})\s*$", value)
    if not m:
        return ""
    month = _MONTH_INDEX.get(m.group(1).strip().capitalize())
    if not month:
        return ""
    day = int(m.group(2))
    year = int(m.group(3))
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return ""


def _display_date(iso: str) -> str:
    """'2026-08-09' -> '9 Aug 2026' (falls back to the input)."""
    try:
        d = date.fromisoformat(iso)
    except (ValueError, TypeError):
        return iso
    return f"{d.day} {_MONTHS[d.month - 1]} {d.year}"


@router.get("/timeline")
def get_timeline(patient_id: str):
    """Personal health records / visit timeline.

    Merges the patient's real data into one chronologically-ordered feed:
    consultation visits (with the AI summary + doctor notes), prescriptions,
    and generic health records. Newest first.
    """
    conn = get_connection()
    try:
        events = []

        # -- Consultation visits (doctor-documented outcomes) -----------------
        for row in conn.execute(
            "SELECT * FROM consultation_notes WHERE patient_id = ? "
            "ORDER BY created_at DESC",
            (patient_id,),
        ).fetchall():
            d = dict(row)
            date_iso = _iso_from_datetime(d["created_at"])
            symptoms = d["symptoms"].split("|") if d["symptoms"] else []
            vitals = {}
            if d["vitals"]:
                try:
                    import json

                    vitals = json.loads(d["vitals"])
                except ValueError:
                    vitals = {}
            diagnosis = (d["diagnosis"] or "").strip()
            events.append(
                {
                    "date": _display_date(date_iso) if date_iso else "",
                    "date_iso": date_iso,
                    "type": "consultation",
                    "title": "Consultation",
                    "subtitle": d["doctor_name"] or "Doctor",
                    "detail": diagnosis or "Consultation visit",
                    "data": {
                        "id": d["id"],
                        "doctor_name": d["doctor_name"] or "",
                        "diagnosis": diagnosis,
                        "notes": d["notes"] or "",
                        "ai_summary": d["ai_summary"] or "",
                        "symptoms": symptoms,
                        "vitals": vitals,
                        "consultation_id": d["consultation_id"] or "",
                    },
                }
            )

        # -- Prescriptions -----------------------------------------------------
        for row in conn.execute(
            "SELECT * FROM prescriptions WHERE patient_id = ?",
            (patient_id,),
        ).fetchall():
            d = _prescription_dict(conn, row)
            date_iso = d.get("date_iso") or _iso_from_date_string(d.get("date", ""))
            medicines = [
                {
                    "name": m["name"],
                    "dosage": m["dosage"],
                    "unit": m["unit"],
                    "instructions": m["instructions"] or "",
                    "days": m["days"],
                }
                for m in d.get("medicines") or []
            ]
            events.append(
                {
                    "date": _display_date(date_iso) if date_iso else d.get("date", ""),
                    "date_iso": date_iso,
                    "type": "prescription",
                    "title": "Prescription",
                    "subtitle": d["doctor_name"] or "Doctor",
                    "detail": ", ".join(m["name"] for m in medicines[:3])
                    or "Prescription",
                    "data": {
                        "id": d["id"],
                        "doctor_name": d["doctor_name"] or "",
                        "notes": d["notes"] or "",
                        "follow_up_date": d.get("follow_up_date") or "",
                        "follow_up_time": d.get("follow_up_time") or "",
                        "medicines": medicines,
                    },
                }
            )

        # -- Generic records ---------------------------------------------------
        for row in conn.execute(
            "SELECT * FROM records WHERE patient_id = ?",
            (patient_id,),
        ).fetchall():
            d = dict(row)
            date_iso = _iso_from_date_string(d.get("date", ""))
            events.append(
                {
                    "date": _display_date(date_iso) if date_iso else d.get("date", ""),
                    "date_iso": date_iso,
                    "type": "record",
                    "title": d.get("title") or "Health Record",
                    "subtitle": d.get("type") or "Record",
                    "detail": d.get("detail") or "",
                    "data": {"id": d.get("id"), "detail": d.get("detail") or ""},
                }
            )

        def _sort_key(e):
            try:
                return date.fromisoformat(e["date_iso"])
            except (ValueError, TypeError):
                return date.min

        events.sort(key=_sort_key, reverse=True)
        return {"timeline": events}
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
