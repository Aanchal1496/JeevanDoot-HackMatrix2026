from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Appointment,
    AppointmentStatus,
    Doctor,
    DoctorAvailability,
    TriageRecord,
    User,
    UserRole,
)
from app.routers.auth import get_current_user, require_roles
from app.schemas import (
    DoctorAvailabilityCreate,
    DoctorAvailabilityOut,
    DoctorOut,
    SlotOut,
)

router = APIRouter(prefix="/doctors", tags=["doctors"])


@router.get("", response_model=list[DoctorOut])
def list_doctors(db: Session = Depends(get_db)):
    return db.query(Doctor).order_by(Doctor.rating.desc()).all()


@router.get("/queue")
def risk_sorted_queue(db: Session = Depends(get_db)):
    """Risk-sorted patient queue: HIGH first, then MEDIUM, then LOW.

    Built from recent triage assessments so ordering reflects clinical urgency.
    """
    order = text("""
        CASE level
            WHEN 'HIGH' THEN 0
            WHEN 'MEDIUM' THEN 1
            ELSE 2
        END
    """)
    rows = (
        db.query(TriageRecord)
        .order_by(order, TriageRecord.created_at.desc())
        .limit(50)
        .all()
    )
    queue = []
    for r in rows:
        patient = db.query(User).get(r.user_id) if r.user_id else None
        queue.append(
            {
                "triage_id": r.id,
                "patient_id": r.user_id,
                "patient_name": patient.name if patient else "Unknown",
                "symptoms": r.symptoms,
                "risk_level": r.level,
                "risk_score": r.risk_score,
                "red_flags": (r.red_flags or ""),
                "assessed_at": r.created_at.isoformat() if r.created_at else None,
            }
        )
    return queue


@router.get("/patients")
def doctor_patients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Patients a doctor can schedule a follow-up appointment for."""
    if current_user.role != UserRole.doctor:
        raise HTTPException(status_code=403, detail="Doctors only.")
    rows = (
        db.query(User)
        .filter(User.role == UserRole.patient)
        .order_by(User.name)
        .all()
    )
    return [
        {"id": u.id, "name": u.name, "phone": u.phone, "email": u.email}
        for u in rows
    ]


@router.get("/me")
def doctor_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.doctor)),
):
    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="No doctor profile linked.")
    return {
        "id": doctor.id,
        "name": doctor.name,
        "specialization": doctor.specialization,
        "qualification": doctor.qualification,
        "registration_number": doctor.registration_number,
        "languages": doctor.languages,
        "experience_years": doctor.experience_years,
        "verification_status": current_user.verification_status,
    }


def _minutes(t: str) -> int:
    parts = t.split(":")
    return int(parts[0]) * 60 + (int(parts[1]) if len(parts) > 1 else 0)


def _hour_slots(start_time: str, end_time: int) -> list[dict]:
    """One-hour slots strictly inside [start_time, end_time), whole-hour aligned."""
    start = _minutes(start_time)
    if start % 60 != 0:
        start = (start // 60) * 60
    slots = []
    h = start
    while h + 60 <= end_time:
        hh_s, mm_s = divmod(h, 60)
        hh_e, mm_e = divmod(h + 60, 60)
        slots.append(
            {"start": f"{hh_s:02d}:{mm_s:02d}", "end": f"{hh_e:02d}:{mm_e:02d}"}
        )
        h += 60
    return slots


@router.get("/appointments")
def doctor_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.doctor)),
):
    """Booked appointments for the current doctor (with patient names included)."""
    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        return []
    rows = (
        db.query(Appointment)
        .filter(
            Appointment.doctor_id == doctor.id,
            Appointment.status != AppointmentStatus.cancelled,
        )
        .order_by(Appointment.scheduled_at.asc())
        .all()
    )
    return [
        {
            "id": a.id,
            "patient_user_id": a.patient_user_id,
            "patient_name": (
                db.query(User).get(a.patient_user_id).name
                if db.query(User).get(a.patient_user_id)
                else "Patient"
            ),
            "doctor_id": a.doctor_id,
            "scheduled_at": a.scheduled_at,
            "type": a.type,
            "status": a.status.value if a.status else None,
        }
        for a in rows
    ]


@router.post("/availability", response_model=DoctorAvailabilityOut)
def set_availability(
    payload: DoctorAvailabilityCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.doctor)),
):
    """Doctor declares a free window (e.g. 16:00-20:00) for a given date."""
    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="No doctor profile linked.")

    if _minutes(payload.start_time) >= _minutes(payload.end_time):
        raise HTTPException(
            status_code=422, detail="start_time must be before end_time."
        )
    existing = (
        db.query(DoctorAvailability)
        .filter(
            DoctorAvailability.doctor_id == doctor.id,
            DoctorAvailability.date == payload.date,
        )
        .all()
    )
    start = _minutes(payload.start_time)
    end = _minutes(payload.end_time)
    for w in existing:
        if start < _minutes(w.end_time) and end > _minutes(w.start_time):
            raise HTTPException(
                status_code=409,
                detail="This window overlaps an existing availability window.",
            )
    window = DoctorAvailability(
        doctor_id=doctor.id,
        date=payload.date,
        start_time=payload.start_time,
        end_time=payload.end_time,
    )
    db.add(window)
    db.commit()
    db.refresh(window)
    return window


@router.get("/availability", response_model=list[DoctorAvailabilityOut])
def my_availability(
    date: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.doctor)),
):
    """The current doctor's own availability windows."""
    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        return []
    q = db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor.id)
    if date:
        q = q.filter(DoctorAvailability.date == date)
    return q.order_by(DoctorAvailability.date, DoctorAvailability.start_time).all()


@router.get("/{doctor_id}/availability/slots", response_model=list[SlotOut])
def doctor_slots(
    doctor_id: int,
    date: str,
    db: Session = Depends(get_db),
):
    """Free 1-hour bookable slots for a doctor on a date."""
    windows = (
        db.query(DoctorAvailability)
        .filter(
            DoctorAvailability.doctor_id == doctor_id,
            DoctorAvailability.date == date,
        )
        .all()
    )
    booked = {
        a.scheduled_at.strftime("%H:%M")
        for a in (
            db.query(Appointment)
            .filter(
                Appointment.doctor_id == doctor_id,
                Appointment.status.in_(
                    [AppointmentStatus.pending, AppointmentStatus.confirmed]
                ),
            )
            .all()
        )
        if a.scheduled_at and a.scheduled_at.strftime("%Y-%m-%d") == date
    }
    slots = []
    for w in windows:
        for s in _hour_slots(w.start_time, _minutes(w.end_time)):
            if s["start"] not in booked:
                slots.append(s)
    return slots


@router.get("/{doctor_id}/availability", response_model=list[DoctorAvailabilityOut])
def doctor_availability(
    doctor_id: int,
    date: str | None = None,
    db: Session = Depends(get_db),
):
    """Availability windows set by a doctor (visible to patients)."""
    q = db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor_id)
    if date:
        q = q.filter(DoctorAvailability.date == date)
    return q.all()