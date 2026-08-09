"""Doctor documentation endpoints: consultation notes, AI summary, follow-ups.

Notes and AI drafts are doctor-authored content that is stored so the patient
and the doctor can review the outcome of a consultation. The AI never decides
anything - it only drafts a summary the doctor edits and approves. If the AI
service is not configured or fails, a deterministic template summary is used.
"""
import json
import sqlite3
import uuid
from datetime import date, datetime, timedelta

from fastapi import APIRouter, HTTPException

from .. import ai_service
from ..db import get_connection
from ..schemas import AiSummaryRequest, ConsultationNotesCreate, FollowUpCreate

router = APIRouter(prefix="/api/doctor", tags=["doctor-docs"])

_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
_DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

CONSULT_TYPES = {"video": "Video Consultation", "audio": "Audio Consultation"}


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


def _fmt_full_date(d: date) -> str:
    return f"{d.day} {_MONTHS[d.month - 1]} {d.year}"


def _add_minutes(hhmm: str, mins: int) -> str:
    try:
        h, m = (int(x) for x in hhmm.split(":"))
    except (ValueError, AttributeError):
        return hhmm
    total = h * 60 + m + mins
    return f"{total // 60 % 24:02d}:{total % 60:02d}"


def _parse_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")


def _parse_time(value: str) -> str:
    try:
        h, m = (int(x) for x in value.split(":"))
        if not (0 <= h <= 23 and 0 <= m <= 59):
            raise ValueError
    except (ValueError, AttributeError):
        raise HTTPException(status_code=400, detail="Invalid time format. Use HH:MM.")
    return f"{h:02d}:{m:02d}"


def _patient_context(conn, patient_id: str) -> dict:
    """Best-effort snapshot of symptoms/vitals/consult type for a patient."""
    ctx = {
        "symptoms": [],
        "vitals": {},
        "risk_label": "",
        "consult_type": "",
        "reason": "",
    }
    q = conn.execute(
        "SELECT * FROM queue_patients WHERE id = ? OR patient_id = ? LIMIT 1",
        (patient_id, patient_id),
    ).fetchone()
    if q is not None:
        d = dict(q)
        ctx["symptoms"] = d["symptoms"].split("|") if d["symptoms"] else []
        ctx["vitals"] = {
            "temp": d["vitals_temp"] or "",
            "hr": d["vitals_hr"] or "",
            "spo2": d["vitals_spo2"] or "",
            "bp": d["vitals_bp"] or "",
        }
        ctx["risk_label"] = d["risk_label"] or d["risk"] or ""
        ctx["consult_type"] = d["consult_type"] or ""
    appt = conn.execute(
        """SELECT reason, consult_type FROM appointments
           WHERE patient_id = ? AND reason IS NOT NULL AND reason != ''
           ORDER BY created_at DESC LIMIT 1""",
        (patient_id,),
    ).fetchone()
    if appt is not None:
        ctx["reason"] = appt["reason"] or ""
        if appt["consult_type"]:
            ctx["consult_type"] = appt["consult_type"]
    return ctx


def _notes_payload(row) -> dict:
    d = dict(row)
    if d.get("vitals"):
        try:
            d["vitals"] = json.loads(d["vitals"])
        except (ValueError, TypeError):
            d["vitals"] = {}
    if d.get("symptoms"):
        d["symptoms"] = d["symptoms"].split("|")
    return d


def _notify(conn, patient_id: str, title: str, body: str, ntype: str = "follow_up") -> None:
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


# ---------------------------------------------------------------------------
# Consultation notes
# ---------------------------------------------------------------------------

@router.post("/consultation-notes")
def save_consultation_notes(payload: ConsultationNotesCreate):
    conn = get_connection()
    try:
        nid = "NOTE-" + uuid.uuid4().hex[:8].upper()
        now = datetime.now().isoformat(timespec="seconds")
        vitals_json = json.dumps(payload.vitals or {}, ensure_ascii=False)
        symptoms_str = "|".join(payload.symptoms or [])
        conn.execute(
            """INSERT INTO consultation_notes
               (id, patient_id, doctor_id, doctor_name, consultation_id, diagnosis,
                notes, vitals, symptoms, ai_summary, created_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
            (
                nid,
                payload.patient_id,
                payload.doctor_id,
                payload.doctor_name,
                payload.consultation_id,
                payload.diagnosis,
                payload.notes,
                vitals_json,
                symptoms_str,
                payload.ai_summary,
                now,
            ),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM consultation_notes WHERE id = ?", (nid,)
        ).fetchone()
        return {"note": _notes_payload(row), "message": "Consultation notes saved."}
    finally:
        conn.close()


@router.get("/consultation-notes/{patient_id}")
def list_consultation_notes(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM consultation_notes
               WHERE patient_id = ? ORDER BY created_at DESC""",
            (patient_id,),
        ).fetchall()
        return {"notes": [_notes_payload(r) for r in rows]}
    finally:
        conn.close()


@router.post("/consultation-notes/ai-summary")
def consultation_ai_summary(payload: AiSummaryRequest):
    """Draft a consultation summary + follow-up suggestion for a patient.

    The AI output is a DRAFT the doctor reviews and edits; the deterministic
    template is used whenever the AI is disabled or fails.
    """
    conn = get_connection()
    try:
        ctx = _patient_context(conn, payload.patient_id)
    finally:
        conn.close()

    ai = ai_service.generate_consultation_summary(
        symptoms=ctx["symptoms"],
        vitals=ctx["vitals"],
        diagnosis=payload.diagnosis,
        notes=payload.notes,
    )
    if ai:
        return {
            "summary": ai["summary"],
            "follow_up": ai.get("follow_up", ""),
            "source": "ai",
            "context": ctx,
        }

    symptom_text = ", ".join(ctx["symptoms"]) if ctx["symptoms"] else "reported symptoms"
    parts = [f"The patient presented with {symptom_text}."]
    vitals = {k: v for k, v in ctx["vitals"].items() if v}
    if vitals:
        parts.append(
            "Vitals recorded: " + "; ".join(f"{k} {v}" for k, v in vitals.items()) + "."
        )
    if payload.diagnosis:
        parts.append(f"Working diagnosis: {payload.diagnosis}.")
    if payload.notes:
        parts.append(f"Doctor notes: {payload.notes}")
    summary = " ".join(parts)
    follow_up = "Schedule a follow-up if symptoms do not improve within 7 days."
    return {
        "summary": summary,
        "follow_up": follow_up,
        "source": "template",
        "context": ctx,
    }


# ---------------------------------------------------------------------------
# Follow-up scheduling
# ---------------------------------------------------------------------------

@router.post("/follow-ups")
def schedule_follow_up(payload: FollowUpCreate):
    """Create a follow-up appointment (booking_source = FOLLOW_UP).

    The doctor picks any future date/time; the slot must not already be taken.
    """
    day = _parse_date(payload.date)
    start_time = _parse_time(payload.time)
    if day < date.today():
        raise HTTPException(status_code=400, detail="Follow-up date must be in the future.")
    if day == date.today() and start_time <= datetime.now().strftime("%H:%M"):
        raise HTTPException(status_code=400, detail="Please pick a time that has not passed yet.")
    if payload.consult_type not in CONSULT_TYPES.values():
        raise HTTPException(status_code=400, detail="Unsupported consultation type.")

    conn = get_connection()
    try:
        conn.execute("BEGIN IMMEDIATE")
        patient = conn.execute(
            "SELECT * FROM patients WHERE id = ?", (payload.patient_id,)
        ).fetchone()
        name = patient["name"] if patient is not None else "Patient"

        taken = conn.execute(
            """SELECT id FROM appointments
               WHERE doctor_id = ? AND date = ? AND start_time = ?
                 AND status NOT IN ('Cancelled', 'No Show', 'Completed')""",
            (payload.doctor_id, day.isoformat(), start_time),
        ).fetchone()
        if taken is not None:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="That time slot is already booked. Please pick another time.",
            )

        appt_id = "JD-" + uuid.uuid4().hex[:8].upper()
        meeting_id = "MEET-" + uuid.uuid4().hex[:6].upper()
        now = datetime.now().isoformat(timespec="seconds")
        try:
            conn.execute(
                """INSERT INTO appointments
                   (id, patient_id, doctor_id, name, date, date_label, start_time,
                    end_time, time, status, risk, risk_label, consult_type, reason,
                    booking_source, meeting_id, created_at, updated_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    appt_id,
                    payload.patient_id,
                    payload.doctor_id,
                    name,
                    day.isoformat(),
                    _fmt_full_date(day),
                    start_time,
                    _add_minutes(start_time, 30),
                    _fmt_12h(start_time),
                    "Confirmed",
                    "low",
                    "Low Risk",
                    payload.consult_type,
                    payload.reason or "Follow-up consultation",
                    "FOLLOW_UP",
                    meeting_id,
                    now,
                    now,
                ),
            )
        except sqlite3.IntegrityError:
            conn.rollback()
            raise HTTPException(
                status_code=409,
                detail="That time slot was just booked. Please pick another time.",
            )

        _audit(conn, appt_id, "follow_up_scheduled", to_value=f"{day.isoformat()} {start_time}")
        _notify(
            conn,
            payload.patient_id,
            "Follow-up scheduled",
            f"Your doctor scheduled a follow-up consultation for {_fmt_full_date(day)} at {_fmt_12h(start_time)}.",
        )
        conn.commit()

        row = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (appt_id,)
        ).fetchone()
        return {"appointment": dict(row), "message": "Follow-up scheduled."}
    finally:
        conn.close()


@router.get("/follow-ups/{patient_id}")
def list_follow_ups(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM appointments
               WHERE patient_id = ? AND booking_source = 'FOLLOW_UP'
               ORDER BY date DESC, start_time DESC""",
            (patient_id,),
        ).fetchall()
        return {"follow_ups": [dict(r) for r in rows]}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Patient-facing (read-only) mirror of the doctor documentation
# ---------------------------------------------------------------------------

patient_router = APIRouter(prefix="/api/patient", tags=["patient-docs"])


@patient_router.get("/consultation-notes/{patient_id}")
def list_patient_notes(patient_id: str):
    """The patient reads the notes + AI summary their doctor saved."""
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM consultation_notes
               WHERE patient_id = ? ORDER BY created_at DESC""",
            (patient_id,),
        ).fetchall()
        return {"notes": [_notes_payload(r) for r in rows]}
    finally:
        conn.close()


@patient_router.get("/follow-ups/{patient_id}")
def list_patient_follow_ups(patient_id: str):
    """The patient reads follow-ups their doctor scheduled."""
    conn = get_connection()
    try:
        rows = conn.execute(
            """SELECT * FROM appointments
               WHERE patient_id = ? AND booking_source = 'FOLLOW_UP'
               ORDER BY date DESC, start_time DESC""",
            (patient_id,),
        ).fetchall()
        return {"follow_ups": [dict(r) for r in rows]}
    finally:
        conn.close()
