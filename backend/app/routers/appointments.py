"""Appointment endpoints: slot availability + booking."""
import uuid
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import AppointmentCreate

router = APIRouter(prefix="/api/appointments", tags=["appointments"])

_DAY_IDS = ["today", "tomorrow", "mon", "tue"]
_SLOTS = [
    {"id": "17:00", "label": "5:00 PM"},
    {"id": "17:30", "label": "5:30 PM"},
    {"id": "18:00", "label": "6:00 PM"},
    {"id": "18:30", "label": "6:30 PM"},
]


@router.get("/slots")
def get_slots():
    today = date.today()
    months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]
    weekdays = [
        "Monday", "Tuesday", "Wednesday", "Thursday",
        "Friday", "Saturday", "Sunday",
    ]
    dates = []
    for i, day_id in enumerate(_DAY_IDS):
        d = today + timedelta(days=i)
        label = "Today" if i == 0 else ("Tom" if i == 1 else weekdays[d.weekday()][:3])
        dates.append(
            {
                "id": day_id,
                "label": label,
                "day": d.day,
                "month": months[d.month - 1],
                "full": f"{weekdays[d.weekday()]}, {months[d.month - 1]} {d.day}, {d.year}",
                "weekday": weekdays[d.weekday()],
            }
        )
    return {"dates": dates, "slots": _SLOTS}


@router.post("")
def create_appointment(payload: AppointmentCreate):
    conn = get_connection()
    try:
        patient = conn.execute(
            "SELECT * FROM patients WHERE id = ?", (payload.patient_id,)
        ).fetchone()
        if patient is None:
            raise HTTPException(status_code=404, detail="Patient not found.")

        slot = next((s for s in _SLOTS if s["id"] == payload.time), None)
        time_label = slot["label"] if slot else payload.time

        date_info = None
        date_rows = get_slots()["dates"]
        for d in date_rows:
            if d["id"] == payload.date_id:
                date_info = d
                break
        date_full = date_info["full"] if date_info else "Today"
        weekday = date_info["weekday"] if date_info else "Monday"

        appt_id = "APT-" + uuid.uuid4().hex[:6].upper()
        consult_type = "Video Consultation" if payload.consult_type == "video" else "Audio Consultation"
        name = payload.name or patient["name"]

        conn.execute(
            """INSERT INTO appointments
               (id, patient_id, name, time, date_label, status, risk,
                risk_label, consult_type)
               VALUES (?,?,?,?,?,?,?,?,?)""",
            (appt_id, payload.patient_id, name, time_label, date_full,
             "Upcoming", "low", "Low Risk", consult_type),
        )
        conn.commit()

        return {
            "appointment": {
                "id": appt_id,
                "name": name,
                "doctor_name": "Dr. Priya Sharma",
                "specialization": "General Physician",
                "time": time_label,
                "date": date_full,
                "weekday": weekday,
                "consult_type": consult_type,
            },
            "message": "Appointment confirmed.",
        }
    finally:
        conn.close()


@router.get("/mine")
def my_appointments(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM appointments WHERE patient_id = ? ORDER BY id", (patient_id,)
        ).fetchall()
        return {"appointments": [dict(r) for r in rows]}
    finally:
        conn.close()
