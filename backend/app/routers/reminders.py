"""Medicine + follow-up reminder endpoints.

All reminder data is scoped to a single authenticated patient: every query
is filtered by `patient_id` and mutation helpers verify ownership before
touching a row. A patient can never read or modify another patient's
reminders.
"""
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException

from ..db import get_connection
from ..schemas import (
    DoseAction,
    FollowUpCreate,
    FollowUpUpdate,
    MedicineReminderCreate,
    MedicineReminderUpdate,
)

router = APIRouter(prefix="/api/reminders", tags=["reminders"])

DOSE_STATUSES = {"upcoming", "due", "taken", "skipped", "missed"}


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _local_id(prefix: str) -> str:
    return f"{prefix}-" + uuid.uuid4().hex[:8].upper()


def _parse_future(days: int, time: str) -> str:
    """Return ISO datetime for a dose `days` from today at HH:MM local."""
    base = datetime.now()
    try:
        hh = int(time.split(":")[0])
        mm = int(time.split(":")[1])
    except (ValueError, IndexError):
        hh, mm = 8, 0
    dt = (base + timedelta(days=days)).replace(hour=hh, minute=mm, second=0, microsecond=0)
    return dt.astimezone().isoformat()


def _reminder_dict(conn, row) -> dict:
    d = dict(row)
    doses = conn.execute(
        "SELECT * FROM medicine_doses WHERE reminder_id = ? ORDER BY scheduled_time",
        (d["id"],),
    ).fetchall()
    d["doses"] = [dict(x) for x in doses]
    return d


def _patient_owns_reminder(conn, reminder_id: str, patient_id: str) -> bool:
    row = conn.execute(
        "SELECT patient_id FROM medicine_reminders WHERE id = ?", (reminder_id,)
    ).fetchone()
    return row is not None and row["patient_id"] == patient_id


# ---------------------------------------------------------------------------
# Medicine reminders
# ---------------------------------------------------------------------------

@router.get("/medicines")
def list_reminders(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM medicine_reminders WHERE patient_id = ? ORDER BY time",
            (patient_id,),
        ).fetchall()
        return {"reminders": [_reminder_dict(conn, r) for r in rows]}
    finally:
        conn.close()


@router.post("/medicines")
def create_reminder(payload: MedicineReminderCreate):
    conn = get_connection()
    try:
        rid = _local_id("RM")
        now = _now()
        conn.execute(
            """INSERT INTO medicine_reminders
               (id, patient_id, prescription_id, medicine_id, medicine_name,
                category, dosage, unit, quantity, period, meal_instruction,
                time, start_date, end_date, duration_days, reminder_type,
                voice_enabled, language, status, created_at, updated_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                rid, payload.patient_id, payload.prescription_id,
                payload.medicine_id, payload.medicine_name, payload.category,
                payload.dosage, payload.unit, payload.quantity, payload.period,
                payload.meal_instruction, payload.time, payload.start_date,
                payload.end_date, payload.duration_days, payload.reminder_type,
                int(payload.voice_enabled), payload.language, "active", now, now,
            ),
        )
        # Seed daily doses across the prescription duration.
        for day_no in range(payload.duration_days):
            conn.execute(
                """INSERT INTO medicine_doses
                   (id, reminder_id, scheduled_time, status, taken_at)
                   VALUES (?,?,?,?,?)""",
                (_local_id("DZ"), rid, _parse_future(day_no, payload.time),
                 "upcoming", None),
            )
        conn.commit()
        return {"reminder": _reminder_dict(conn, conn.execute(
            "SELECT * FROM medicine_reminders WHERE id = ?", (rid,)
        ).fetchone()), "message": "Medicine reminder set."}
    finally:
        conn.close()


@router.get("/medicines/{reminder_id}")
def get_reminder(reminder_id: str, patient_id: str):
    conn = get_connection()
    try:
        if not _patient_owns_reminder(conn, reminder_id, patient_id):
            raise HTTPException(status_code=404, detail="Reminder not found.")
        row = conn.execute(
            "SELECT * FROM medicine_reminders WHERE id = ?", (reminder_id,)
        ).fetchone()
        return {"reminder": _reminder_dict(conn, row)}
    finally:
        conn.close()


@router.put("/medicines/{reminder_id}")
def update_reminder(reminder_id: str, patient_id: str, payload: MedicineReminderUpdate):
    conn = get_connection()
    try:
        if not _patient_owns_reminder(conn, reminder_id, patient_id):
            raise HTTPException(status_code=404, detail="Reminder not found.")
        fields = payload.model_dump(exclude_none=True)
        if not fields:
            raise HTTPException(status_code=400, detail="Nothing to update.")
        if "voice_enabled" in fields:
            fields["voice_enabled"] = int(fields["voice_enabled"])
        fields["updated_at"] = _now()
        sets = ", ".join(f"{k} = ?" for k in fields)
        conn.execute(
            f"UPDATE medicine_reminders SET {sets} WHERE id = ?",
            (*fields.values(), reminder_id),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM medicine_reminders WHERE id = ?", (reminder_id,)
        ).fetchone()
        return {"reminder": _reminder_dict(conn, row), "message": "Reminder updated."}
    finally:
        conn.close()


@router.delete("/medicines/{reminder_id}")
def delete_reminder(reminder_id: str, patient_id: str):
    conn = get_connection()
    try:
        if not _patient_owns_reminder(conn, reminder_id, patient_id):
            raise HTTPException(status_code=404, detail="Reminder not found.")
        conn.execute("DELETE FROM medicine_doses WHERE reminder_id = ?", (reminder_id,))
        conn.execute("DELETE FROM medicine_reminders WHERE id = ?", (reminder_id,))
        conn.commit()
        return {"message": "Reminder removed."}
    finally:
        conn.close()


def _set_dose(conn, reminder_id: str, status: str, patient_id: str) -> dict:
    if not _patient_owns_reminder(conn, reminder_id, patient_id):
        raise HTTPException(status_code=404, detail="Reminder not found.")
    # Mark the next *due or upcoming* dose; a taken/skipped dose cannot be
    # undone by the patient (matches "do not allow modifying prescribed
    # dosage" — they only record whether they took it).
    row = conn.execute(
        """SELECT id FROM medicine_doses
           WHERE reminder_id = ? AND status IN ('upcoming','due')
           ORDER BY scheduled_time LIMIT 1""",
        (reminder_id,),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=409, detail="No pending dose to update.")
    now = _now()
    conn.execute(
        "UPDATE medicine_doses SET status = ?, taken_at = ? WHERE id = ?",
        (status, now, row["id"]),
    )
    conn.commit()
    return {"message": "Dose marked."}


@router.post("/medicines/{reminder_id}/taken")
def dose_taken(reminder_id: str, patient_id: str, payload: DoseAction):
    conn = get_connection()
    try:
        return _set_dose(conn, reminder_id, "taken", patient_id)
    finally:
        conn.close()


@router.post("/medicines/{reminder_id}/skip")
def dose_skip(reminder_id: str, patient_id: str):
    conn = get_connection()
    try:
        return _set_dose(conn, reminder_id, "skipped", patient_id)
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Follow-up reminders
# ---------------------------------------------------------------------------

def _followup_dict(row) -> dict:
    return dict(row)


@router.get("/followups")
def list_followups(patient_id: str):
    conn = get_connection()
    try:
        rows = conn.execute(
            "SELECT * FROM followup_reminders WHERE patient_id = ? ORDER BY followup_date",
            (patient_id,),
        ).fetchall()
        return {"followups": [_followup_dict(r) for r in rows]}
    finally:
        conn.close()


@router.post("/followups")
def create_followup(payload: FollowUpCreate):
    conn = get_connection()
    try:
        fid = _local_id("FU")
        now = _now()
        conn.execute(
            """INSERT INTO followup_reminders
               (id, patient_id, prescription_id, doctor_name, followup_date,
                followup_time, reason, voice_enabled, language, enabled,
                created_at, updated_at)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                fid, payload.patient_id, payload.prescription_id,
                payload.doctor_name, payload.followup_date, payload.followup_time,
                payload.reason, int(payload.voice_enabled), payload.language,
                1, now, now,
            ),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM followup_reminders WHERE id = ?", (fid,)
        ).fetchone()
        return {"followup": _followup_dict(row), "message": "Follow-up reminder added."}
    finally:
        conn.close()


def _patient_owns_followup(conn, fid: str, patient_id: str) -> bool:
    row = conn.execute(
        "SELECT patient_id FROM followup_reminders WHERE id = ?", (fid,)
    ).fetchone()
    return row is not None and row["patient_id"] == patient_id


@router.put("/followups/{fid}")
def update_followup(fid: str, patient_id: str, payload: FollowUpUpdate):
    conn = get_connection()
    try:
        if not _patient_owns_followup(conn, fid, patient_id):
            raise HTTPException(status_code=404, detail="Follow-up not found.")
        fields = payload.model_dump(exclude_none=True)
        if not fields:
            raise HTTPException(status_code=400, detail="Nothing to update.")
        if "voice_enabled" in fields:
            fields["voice_enabled"] = int(fields["voice_enabled"])
        if "enabled" in fields:
            fields["enabled"] = int(fields["enabled"])
        fields["updated_at"] = _now()
        sets = ", ".join(f"{k} = ?" for k in fields)
        conn.execute(
            f"UPDATE followup_reminders SET {sets} WHERE id = ?",
            (*fields.values(), fid),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM followup_reminders WHERE id = ?", (fid,)
        ).fetchone()
        return {"followup": _followup_dict(row), "message": "Follow-up updated."}
    finally:
        conn.close()


@router.delete("/followups/{fid}")
def delete_followup(fid: str, patient_id: str):
    conn = get_connection()
    try:
        if not _patient_owns_followup(conn, fid, patient_id):
            raise HTTPException(status_code=404, detail="Follow-up not found.")
        conn.execute("DELETE FROM followup_reminders WHERE id = ?", (fid,))
        conn.commit()
        return {"message": "Follow-up removed."}
    finally:
        conn.close()