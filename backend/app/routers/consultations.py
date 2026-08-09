"""Teleconsultation endpoints: specialties, doctors, slots, booking.

Slot availability is real (stored in `doctor_availability`), booking is
protected against double-booking both with a transaction + re-check and a
database-level partial unique index on (doctor_id, date, start_time).
"""
import json
import sqlite3
import uuid
from datetime import date, datetime, timedelta

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import (
    ConsultationBookRequest,
    ConsultationCancelRequest,
    ConsultationRescheduleRequest,
)

router = APIRouter(prefix="/api/consultations", tags=["consultations"])

# How many minutes before the appointment a patient may join the call.
JOIN_WINDOW_MINUTES = 10

_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

# Consult types allowed at booking time.
_CONSULT_TYPES = {"video": "Video Consultation", "audio": "Audio Consultation"}

# Slots grouped by period in the UI (matches SLOT_WINDOWS in seed.py).
_SLOT_PERIODS = [
    ("09:00", "12:30", "Morning"),
    ("13:30", "17:00", "Afternoon"),
    ("17:30", "20:30", "Evening"),
]

# Attachments accepted at booking (name, type, size validation).
_ALLOWED_ATTACHMENT_EXT = {"jpg", "jpeg", "png", "webp", "heic", "pdf"}
_MAX_ATTACHMENT_BYTES = 5 * 1024 * 1024


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _fmt_12h(hhmm: str) -> str:
    try:
        h, m = (int(x) for x in hhmm.split(":"))
    except (ValueError, AttributeError):
        return hhmm or ""
    ap = "AM" if h < 12 else "PM"
    h12 = h % 12 or 12
    return f"{h12}:{m:02d} {ap}"


def _parse_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")


def _fmt_full_date(d: date) -> str:
    return f"{d.day} {_MONTHS[d.month - 1]} {d.year}"


def _doctor_public(d) -> dict:
    languages = (d["languages"] or "Hindi • English").split("•")
    return {
        "id": d["id"],
        "name": d["name"],
        "qualification": d["qualification"] or "",
        "specialization": d["specialization"] or "General Physician",
        "experience": d["experience"] or "0 yrs",
        "languages": [l.strip() for l in languages if l.strip()],
        "photo_url": d["photo_url"] or "",
        "consultation_fee": round(float(d["consultation_fee"] or 0), 2),
        "rating": float(d["rating"] or 0),
        "is_active": bool(d["is_available"]),
    }


def _appointment_payload(conn, row) -> dict:
    d = dict(row)
    start_iso = None
    if d.get("date") and d.get("start_time"):
        start_iso = f"{d['date']}T{d['start_time']}:00"
    end_time = d.get("end_time") or d.get("start_time") or ""
    return {
        "id": d["id"],
        "patient_id": d["patient_id"],
        "doctor_id": d.get("doctor_id"),
        "doctor_name": d.get("doctor_name") or "",
        "specialization": d.get("specialization") or "",
        "qualification": d.get("qualification") or "",
        "photo_url": d.get("photo_url") or "",
        "consultation_fee": round(float(d.get("consultation_fee") or 0), 2),
        "date": d.get("date") or "",
        "date_label": d.get("date_label") or "",
        "start_time": d.get("start_time") or "",
        "end_time": end_time,
        "time": d.get("time") or _fmt_12h(d.get("start_time") or ""),
        "consult_type": d.get("consult_type") or "Video Consultation",
        "reason": d.get("reason") or "",
        "status": d.get("status") or "Confirmed",
        "booking_source": d.get("booking_source") or "SELF",
        "meeting_id": d.get("meeting_id") or "",
        "attachments": _decode_attachments(d.get("attachments")),
        "created_at": d.get("created_at") or "",
        "updated_at": d.get("updated_at") or "",
        "start_iso": start_iso,
        "join_window_minutes": JOIN_WINDOW_MINUTES,
        "can_join": _can_join(start_iso),
        "join_available_at": _join_available_at(start_iso),
    }


def _decode_attachments(raw) -> list:
    if not raw:
        return []
    try:
        parsed = json.loads(raw)
        return parsed if isinstance(parsed, list) else []
    except (ValueError, TypeError):
        return []


def _join_available_at(start_iso):
    if not start_iso:
        return None
    return (datetime.fromisoformat(start_iso) - timedelta(minutes=JOIN_WINDOW_MINUTES)).isoformat()


def _can_join(start_iso) -> bool:
    if not start_iso:
        return False
    start = datetime.fromisoformat(start_iso)
    now = datetime.now()
    return start - timedelta(minutes=JOIN_WINDOW_MINUTES) <= now <= start + timedelta(minutes=60)


def _notify(conn, patient_id: str, title: str, body: str, ntype: str = "system") -> None:
    conn.execute(
        """INSERT INTO notifications (id, patient_id, title, body, type, read, created_at)
           VALUES (?,?,?,?,?,0,?)""",
        (
            "NTF-" + uuid.uuid4().hex[:8].upper(),
            patient_id,
            title,
            body,
            ntype,
            datetime.now().isoformat(timespec="seconds"),
        ),
    )


def _audit(conn, appointment_id: str, action: str, from_value=None, to_value=None) -> None:
    conn.execute(
        """INSERT INTO appointment_audit (appointment_id, action, from_value, to_value, created_at)
           VALUES (?,?,?,?,?)""",
        (
            appointment_id,
            action,
            from_value,
            to_value,
            datetime.now().isoformat(timespec="seconds"),
        ),
    )


def _validate_attachments(attachments) -> None:
    for att in attachments or []:
        name = (att.get("name") or "").strip()
        size = int(att.get("size") or 0)
        ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
        if not name:
            raise HTTPException(status_code=400, detail="Attachment name is required.")
        if ext not in _ALLOWED_ATTACHMENT_EXT:
            raise HTTPException(
                status_code=400,
                detail=f"Attachment '{name}' has an unsupported type. Allowed: {', '.join(sorted(_ALLOWED_ATTACHMENT_EXT))}.",
            )
        if size <= 0 or size > _MAX_ATTACHMENT_BYTES:
            raise HTTPException(
                status_code=400,
                detail=f"Attachment '{name}' exceeds the 5 MB limit.",
            )


def _doctor_exists(conn, doctor_id: str):
    return conn.execute(
        "SELECT * FROM doctors WHERE id = ? AND is_available = 1", (doctor_id,)
    ).fetchone()


def _specialty_slug(name: str) -> str:
    return name.strip().lower().replace(" ", "-").replace("/", "-")


def _appointment_row_join(conn, appointment_id: str):
    """A single appointment row joined with doctor display fields."""
    return conn.execute(
        """SELECT a.*, d.name AS doctor_name, d.specialization, d.qualification,
                  d.photo_url, d.consultation_fee
           FROM appointments a
           LEFT JOIN doctors d ON d.id = a.doctor_id
           WHERE a.id = ?""",
        (appointment_id,),
    ).fetchone()


# ---------------------------------------------------------------------------
# Specialties
# ---------------------------------------------------------------------------

@router.get("/specialties")
def list_specialties():
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT specialization, COUNT(*) AS c
               FROM doctors WHERE is_available = 1 AND specialization IS NOT NULL
               GROUP BY specialization ORDER BY c DESC"""
        ).fetchall()
        specialties = [
            {
                "id": _specialty_slug(r["specialization"]),
                "name": r["specialization"],
                "doctor_count": r["c"],
            }
            for r in rows
        ]
        # Always include "Other" so the patient can browse everything.
        if not any(s["name"] == "Other" for s in specialties):
            total = sum(s["doctor_count"] for s in specialties)
            specialties.append({"id": "other", "name": "Other", "doctor_count": total})
        return {"specialties": specialties}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Doctors
# ---------------------------------------------------------------------------

@router.get("/doctors")
def list_doctors(specialty: str = "", q: str = ""):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM doctors WHERE is_available = 1 ORDER BY CAST(rating AS REAL) DESC"
        ).fetchall()
        if specialty and specialty not in ("", "other", "all"):
            rows = [r for r in rows if _specialty_slug(r["specialization"] or "") == specialty]
        if q:
            query = q.strip().lower()
            rows = [
                r
                for r in rows
                if query in f"{r['name']} {r['specialization']}".lower()
            ]
        today = date.today().isoformat()
        tomorrow = (date.today() + timedelta(days=1)).isoformat()
        doctors = []
        for r in rows:
            d = _doctor_public(r)
            has_today = conn.execute(
                "SELECT COUNT(*) AS c FROM doctor_availability WHERE doctor_id = ? AND date IN (?, ?)",
                (d["id"], today, tomorrow),
            ).fetchone()["c"]
            d["available_today"] = has_today > 0
            doctors.append(d)
        return {"doctors": doctors}
    finally:
        conn.close()


@router.get("/doctors/{doctor_id}/dates")
def doctor_dates(doctor_id: str):
    conn = get_connection()
    try:
        if _doctor_exists(conn, doctor_id) is None:
            raise HTTPException(status_code=404, detail="Doctor not found.")
        today = date.today()
        dates = []
        for i in range(14):
            d = today + timedelta(days=i)
            slot_count = conn.execute(
                """SELECT COUNT(*) AS c FROM doctor_availability
                   WHERE doctor_id = ? AND date = ? AND status = 'available'""",
                (doctor_id, d.isoformat()),
            ).fetchone()["c"]
            label = "Today" if i == 0 else ("Tom" if i == 1 else _DAY_NAMES[d.weekday()][:3])
            dates.append(
                {
                    "id": d.isoformat(),
                    "label": label,
                    "day": d.day,
                    "month": _MONTHS[d.month - 1],
                    "weekday": _DAY_NAMES[d.weekday()],
                    "full": f"{_DAY_NAMES[d.weekday()]}, {d.day} {_MONTHS[d.month - 1]} {d.year}",
                    "available": slot_count > 0,
                    "slot_count": slot_count,
                }
            )
        return {"dates": dates}
    finally:
        conn.close()


@router.get("/doctors/{doctor_id}/slots")
def doctor_slots(doctor_id: str, date: str):
    conn = get_connection()
    try:
        if _doctor_exists(conn, doctor_id) is None:
            raise HTTPException(status_code=404, detail="Doctor not found.")
        day = _parse_date(date)
        rows = conn.execute(
            """SELECT * FROM doctor_availability
               WHERE doctor_id = ? AND date = ? ORDER BY start_time""",
            (doctor_id, day.isoformat()),
        ).fetchall()
        booked = {
            r["start_time"]
            for r in conn.execute(
                """SELECT start_time FROM appointments
                   WHERE doctor_id = ? AND date = ? AND status NOT IN ('Cancelled', 'No Show')""",
                (doctor_id, day.isoformat()),
            ).fetchall()
        }
        now_hhmm = datetime.now().strftime("%H:%M")
        is_today = day == datetime.now().date()
        slots = []
        for r in rows:
            start = r["start_time"]
            if start in booked:
                status = "booked"
            elif r["status"] != "available":
                status = "unavailable"
            elif is_today and start <= now_hhmm:
                # A slot earlier today has already passed.
                status = "unavailable"
            else:
                status = "available"
            period = _period_of(start)
            slots.append(
                {
                    "id": start,
                    "start_time": start,
                    "end_time": r["end_time"],
                    "label": _fmt_12h(start),
                    "period": period,
                    "status": status,
                }
            )
        return {
            "date": day.isoformat(),
            "date_label": f"{_DAY_NAMES[day.weekday()]}, {day.day} {_MONTHS[day.month - 1]} {day.year}",
            "slots": slots,
        }
    finally:
        conn.close()


def _period_of(hhmm: str) -> str:
    mins = _hhmm_to_min(hhmm)
    for start, end, label in _SLOT_PERIODS:
        if _hhmm_to_min(start) <= mins < _hhmm_to_min(end):
            return label.lower()
    return "evening"


def _hhmm_to_min(hhmm: str) -> int:
    h, m = (int(x) for x in hhmm.split(":"))
    return h * 60 + m


# ---------------------------------------------------------------------------
# Booking (concurrency-safe)
# ---------------------------------------------------------------------------

@router.post("/book")
def book_consultation(payload: ConsultationBookRequest):
    attachments = [a.model_dump() for a in payload.attachments]
    _validate_attachments(attachments)
    if payload.consult_type not in _CONSULT_TYPES:
        raise HTTPException(status_code=400, detail="Consultation type must be 'video' or 'audio'.")

    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        patient = conn.execute(
            "SELECT * FROM patients WHERE id = ?", (payload.patient_id,)
        ).fetchone()
        if patient is None:
            # Device-local accounts carry a generated id that does not exist in
            # the backend yet. Auto-provision a minimal record (mirrors the
            # OTP login flow) so booking works for every signed-in patient.
            conn.execute(
                """INSERT INTO patients (id, phone, name, age, gender, language)
                   VALUES (?,?,?,?,?,?)""",
                (
                    payload.patient_id,
                    payload.patient_phone or "",
                    payload.patient_name or "Patient",
                    "30", "Male", "hi",
                ),
            )
            patient = conn.execute(
                "SELECT * FROM patients WHERE id = ?", (payload.patient_id,)
            ).fetchone()

        doctor = _doctor_exists(conn, payload.doctor_id)
        if doctor is None:
            conn.rollback()
            raise HTTPException(status_code=404, detail="Doctor not found.")

        day = _parse_date(payload.date)
        if day < date.today():
            conn.rollback()
            raise HTTPException(status_code=400, detail="Cannot book a date in the past.")
        if day == date.today() and payload.start_time <= datetime.now().strftime("%H:%M"):
            conn.rollback()
            raise HTTPException(status_code=400, detail="This time has already passed. Please select a later slot.")

        slot = conn.execute(
            """SELECT * FROM doctor_availability
               WHERE doctor_id = ? AND date = ? AND start_time = ? AND status = 'available'""",
            (payload.doctor_id, day.isoformat(), payload.start_time),
        ).fetchone()
        if slot is None:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="Sorry, this slot is no longer available. Please select another time.",
            )

        taken = conn.execute(
            """SELECT id FROM appointments
               WHERE doctor_id = ? AND date = ? AND start_time = ?
                 AND status NOT IN ('Cancelled', 'No Show')""",
            (payload.doctor_id, day.isoformat(), payload.start_time),
        ).fetchone()
        if taken is not None:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="Sorry, this slot was just booked. Please select another time.",
            )

        appt_id = "JD-" + uuid.uuid4().hex[:8].upper()
        meeting_id = "MEET-" + uuid.uuid4().hex[:6].upper()
        consult_type = _CONSULT_TYPES[payload.consult_type]
        start_label = _fmt_12h(payload.start_time)
        end_label = _fmt_12h(slot["end_time"])
        name = payload.patient_name or patient["name"]
        now = datetime.now().isoformat(timespec="seconds")
        atts_json = json.dumps(attachments or [])

        try:
            conn.execute(
                """INSERT INTO appointments
                   (id, patient_id, doctor_id, name, date, date_label, start_time,
                    end_time, time, status, risk, risk_label, consult_type, reason,
                    booking_source, meeting_id, attachments, created_at, updated_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    appt_id, payload.patient_id, payload.doctor_id, name,
                    day.isoformat(), _fmt_full_date(day), payload.start_time,
                    slot["end_time"], start_label, "Confirmed", "low", "Low Risk",
                    consult_type, payload.reason, payload.booking_source,
                    meeting_id, atts_json, now, now,
                ),
            )
        except sqlite3.IntegrityError:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="Sorry, this slot was just booked. Please select another time.",
            )

        _audit(conn, appt_id, "booked", to_value=f"{day.isoformat()} {payload.start_time}")
        _notify(
            conn,
            payload.patient_id,
            "Consultation confirmed",
            f"Your consultation with {doctor['name']} on {_fmt_full_date(day)} at {start_label} has been confirmed.",
            "booking",
        )

        if payload.booking_source == "ASHA" and payload.asha_request_id:
            conn.execute(
                """UPDATE asha_requests SET status = 'booking_confirmed', appointment_id = ?,
                   updated_at = ? WHERE id = ?""",
                (appt_id, now, payload.asha_request_id),
            )

        conn.commit()
    except HTTPException:
        raise
    except sqlite3.IntegrityError:
        conn.rollback()
        raise HTTPException(
            status_code=409,
            detail="Sorry, this slot was just booked. Please select another time.",
        )
    finally:
        conn.close()

    return {
        "appointment": _booked_response(appt_id),
        "message": "Consultation booked successfully.",
    }


def _booked_response(appt_id: str):
    """Build the response payload for a freshly booked appointment."""
    c = get_connection()
    try:
        return _appointment_payload(c, _appointment_row_join(c, appt_id))
    finally:
        c.close()


# ---------------------------------------------------------------------------
# Patient queries
# ---------------------------------------------------------------------------

@router.get("/upcoming")
def upcoming_appointments(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT a.*, d.name AS doctor_name, d.specialization, d.qualification,
                      d.photo_url, d.consultation_fee
               FROM appointments a
               LEFT JOIN doctors d ON d.id = a.doctor_id
               WHERE a.patient_id = ? AND a.doctor_id IS NOT NULL
                 AND a.status NOT IN ('Cancelled', 'No Show', 'Completed')
               ORDER BY a.date, a.start_time""",
            (patient_id,),
        ).fetchall()
        # Prune stale rows: keep today (including in-progress) and future
        # appointments only, so past uncompleted ones roll into history.
        now = datetime.now()
        today = date.today().isoformat()
        horizon = (now - timedelta(hours=1)).strftime("%H:%M")
        rows = [
            r
            for r in rows
            if (r["date"] or "") > today
            or (r["date"] or "") == today
            and (r["start_time"] or "") >= horizon
        ]
        return {"appointments": [_appointment_payload(conn, r) for r in rows]}
    finally:
        conn.close()


@router.get("/history")
def appointment_history(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT a.*, d.name AS doctor_name, d.specialization, d.qualification,
                      d.photo_url, d.consultation_fee
               FROM appointments a
               LEFT JOIN doctors d ON d.id = a.doctor_id
               WHERE a.patient_id = ? AND a.doctor_id IS NOT NULL
                 AND a.status IN ('Cancelled', 'No Show', 'Completed')
               ORDER BY a.date DESC, a.start_time DESC""",
            (patient_id,),
        ).fetchall()
        return {"appointments": [_appointment_payload(conn, r) for r in rows]}
    finally:
        conn.close()


@router.get("/{appointment_id}")
def appointment_detail(appointment_id: str, patient_id: str):
    conn = get_connection()
    try:
        row = _appointment_row_join(conn, appointment_id)
        if row is None or row["patient_id"] != patient_id:
            raise HTTPException(status_code=404, detail="Appointment not found.")
        return {"appointment": _appointment_payload(conn, row)}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Cancel / reschedule
# ---------------------------------------------------------------------------

@router.patch("/{appointment_id}/cancel")
def cancel_appointment(appointment_id: str, payload: ConsultationCancelRequest):
    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        row = _appointment_row_join(conn, appointment_id)
        if row is None or row["patient_id"] != payload.patient_id:
            conn.rollback()
            raise HTTPException(status_code=404, detail="Appointment not found.")
        if row["status"] in ("Cancelled", "No Show", "Completed"):
            conn.rollback()
            raise HTTPException(status_code=400, detail="This appointment can no longer be cancelled.")
        start_iso = f"{row['date']}T{row['start_time']}:00" if row["date"] and row["start_time"] else None
        if start_iso and datetime.fromisoformat(start_iso) < datetime.now():
            conn.rollback()
            raise HTTPException(status_code=400, detail="Past appointments cannot be cancelled.")
        now = datetime.now().isoformat(timespec="seconds")
        conn.execute(
            "UPDATE appointments SET status = 'Cancelled', updated_at = ? WHERE id = ?",
            (now, appointment_id),
        )
        _audit(conn, appointment_id, "cancelled", from_value=row["status"], to_value="Cancelled")
        _notify(
            conn,
            row["patient_id"],
            "Consultation cancelled",
            f"Your consultation with {row['doctor_name'] or 'your doctor'} on {row['date_label'] or row['date']} has been cancelled.",
            "cancellation",
        )
        conn.commit()
    finally:
        conn.close()
    return {"message": "Appointment cancelled. The time slot has been released."}


@router.patch("/{appointment_id}/reschedule")
def reschedule_appointment(appointment_id: str, payload: ConsultationRescheduleRequest):
    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        row = _appointment_row_join(conn, appointment_id)
        if row is None or row["patient_id"] != payload.patient_id:
            conn.rollback()
            raise HTTPException(status_code=404, detail="Appointment not found.")
        if row["status"] in ("Cancelled", "No Show", "Completed"):
            conn.rollback()
            raise HTTPException(status_code=400, detail="This appointment cannot be rescheduled.")

        day = _parse_date(payload.date)
        slot = conn.execute(
            """SELECT * FROM doctor_availability
               WHERE doctor_id = ? AND date = ? AND start_time = ? AND status = 'available'""",
            (row["doctor_id"], day.isoformat(), payload.start_time),
        ).fetchone()
        if slot is None:
            conn.rollback()
            raise HTTPException(status_code=409, detail="Sorry, this slot is no longer available. Please select another time.")

        taken = conn.execute(
            """SELECT id FROM appointments
               WHERE doctor_id = ? AND date = ? AND start_time = ? AND id != ?
                 AND status NOT IN ('Cancelled', 'No Show')""",
            (row["doctor_id"], day.isoformat(), payload.start_time, appointment_id),
        ).fetchone()
        if taken is not None:
            conn.rollback()
            raise HTTPException(status_code=409, detail="Sorry, this slot was just booked. Please select another time.")

        now = datetime.now().isoformat(timespec="seconds")
        from_value = f"{row['date']} {row['start_time']}"
        try:
            conn.execute(
                """UPDATE appointments SET date = ?, date_label = ?, start_time = ?,
                   end_time = ?, time = ?, status = 'Confirmed', updated_at = ?
                   WHERE id = ?""",
                (
                    day.isoformat(), _fmt_full_date(day), payload.start_time,
                    slot["end_time"], _fmt_12h(payload.start_time), now, appointment_id,
                ),
            )
        except sqlite3.IntegrityError:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="Sorry, this slot was just booked. Please select another time.",
            )
        _audit(conn, appointment_id, "rescheduled", from_value=from_value, to_value=f"{day.isoformat()} {payload.start_time}")
        _notify(
            conn,
            row["patient_id"],
            "Consultation rescheduled",
            f"Your consultation with {row['doctor_name'] or 'your doctor'} has been moved to {_fmt_full_date(day)} at {_fmt_12h(payload.start_time)}.",
            "reschedule",
        )
        conn.commit()
    finally:
        conn.close()
    return {"message": "Appointment rescheduled."}
