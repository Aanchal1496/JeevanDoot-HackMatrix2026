from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import (
    Appointment,
    AppointmentStatus,
    Doctor,
    DoctorAvailability,
    NotificationType,
    User,
    UserRole,
)
from app.notifications import create_notification
from app.routers.auth import get_current_user
from app.schemas import AppointmentCreate, AppointmentOut

router = APIRouter(prefix="/appointments", tags=["appointments"])


def _parse_dt(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M"):
        try:
            return datetime.strptime(value, fmt)
        except (ValueError, TypeError):
            continue
    return None


def _minutes_hm(t):
    parts = t.split(":")
    return int(parts[0]) * 60 + (int(parts[1]) if len(parts) > 1 else 0)


def _notify_patient_and_doctor(db, appointment: Appointment, doctor: Doctor | None):
    patient = db.query(User).get(appointment.patient_user_id)
    if patient:
        create_notification(
            db,
            patient.id,
            "Appointment booked",
            f"Your appointment with {doctor.name if doctor else 'the doctor'} is confirmed.",
            NotificationType.appointment_booked,
            appointment.id,
        )
    if doctor and doctor.user_id:
        create_notification(
            db,
            doctor.user_id,
            "New appointment",
            f"A new appointment is scheduled for you.",
            NotificationType.appointment_booked,
            appointment.id,
        )


@router.get("", response_model=list[AppointmentOut])
def list_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.doctor:
        doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        if doctor:
            return (
                db.query(Appointment)
                .filter(Appointment.doctor_id == doctor.id)
                .order_by(Appointment.scheduled_at.desc())
                .all()
            )
        return []
    if current_user.role == UserRole.asha:
        return (
            db.query(Appointment)
            .filter(Appointment.asha_id == current_user.id)
            .order_by(Appointment.scheduled_at.desc())
            .all()
        )
    return (
        db.query(Appointment)
        .filter(Appointment.patient_user_id == current_user.id)
        .order_by(Appointment.scheduled_at.desc())
        .all()
    )


@router.post("", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
def create_appointment(
    payload: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    doctor = db.query(Doctor).get(payload.doctor_id)
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    # ASHA books on a patient's behalf (patient_user_id supplied by ASHA/admin);
    # a patient books for themself.
    target_user_id = current_user.id
    asha_id = None
    if current_user.role == UserRole.doctor:
        # A doctor can schedule their own follow-up appointment for a patient.
        doctor_profile = (
            db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        )
        if not doctor_profile or doctor_profile.id != doctor.id:
            raise HTTPException(
                status_code=403,
                detail="You can only schedule appointments for yourself.",
            )
        if not payload.patient_user_id:
            raise HTTPException(
                status_code=422,
                detail="patient_user_id is required for doctor-initiated booking.",
            )
        patient_user = db.query(User).get(payload.patient_user_id)
        if not patient_user or patient_user.role != UserRole.patient:
            raise HTTPException(status_code=404, detail="Patient not found.")
        target_user_id = patient_user.id
    elif current_user.role == UserRole.asha:
        if not payload.family_member_id:
            # for the supported scope, ASHA books for the primary patient account
            pass
        asha_id = current_user.id

    scheduled = _parse_dt(payload.scheduled_at)
    if not scheduled:
        raise HTTPException(status_code=422, detail="Invalid scheduled_at.")

    # Prevent double booking on the same doctor+slot.
    clash = (
        db.query(Appointment)
        .filter(
            Appointment.doctor_id == doctor.id,
            Appointment.scheduled_at == scheduled,
            Appointment.status.in_([AppointmentStatus.pending, AppointmentStatus.confirmed]),
        )
        .first()
    )
    if clash:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="That time slot is already booked. Please choose another time.",
        )

    # Patient-initiated bookings must fall inside a window the doctor declared.
    # Enforced only when the doctor has set windows for that date, so legacy
    # booking flows (and tests) without availability still work.
    if current_user.role == UserRole.patient:
        date_key = scheduled.strftime("%Y-%m-%d")
        slot_start = scheduled.hour * 60 + scheduled.minute
        slot_end = slot_start + 60  # 1-hour consultation
        windows = (
            db.query(DoctorAvailability)
            .filter(
                DoctorAvailability.doctor_id == doctor.id,
                DoctorAvailability.date == date_key,
            )
            .all()
        )
        if windows:
            allowed = False
            for w in windows:
                if (
                    _minutes_hm(w.start_time) <= slot_start
                    and slot_end <= _minutes_hm(w.end_time)
                    and scheduled.minute == 0
                ):
                    allowed = True
                    break
            if not allowed:
                raise HTTPException(
                    status_code=422,
                    detail="Please pick a free 1-hour slot within the doctor's availability.",
                )

    appointment = Appointment(
        patient_user_id=target_user_id,
        family_member_id=payload.family_member_id,
        doctor_id=doctor.id,
        asha_id=asha_id,
        scheduled_at=scheduled,
        type=payload.type,
    )
    db.add(appointment)
    db.flush()
    db.refresh(doctor)
    _notify_patient_and_doctor(db, appointment, doctor)
    db.commit()
    db.refresh(appointment)
    record_audit(db, current_user.id, "appointment.create", "appointment", appointment.id)
    return appointment


@router.put("/{appointment_id}/cancel", response_model=AppointmentOut)
def cancel_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    appointment = db.query(Appointment).get(appointment_id)
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    owner_ids = {appointment.patient_user_id, appointment.asha_id}
    doctor = db.query(Doctor).get(appointment.doctor_id) if appointment.doctor_id else None
    if doctor and doctor.user_id:
        owner_ids.add(doctor.user_id)
    if current_user.id not in owner_ids:
        raise HTTPException(status_code=403, detail="Not allowed.")
    appointment.status = AppointmentStatus.cancelled
    db.commit()
    db.refresh(appointment)
    create_notification(
        db,
        appointment.patient_user_id,
        "Appointment cancelled",
        "Your appointment has been cancelled.",
        NotificationType.appointment_cancelled,
        appointment.id,
    )
    db.commit()
    return appointment