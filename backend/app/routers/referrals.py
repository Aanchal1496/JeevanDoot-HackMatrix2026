from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import (
    Doctor,
    NotificationType,
    Referral,
    Urgency,
    User,
    UserRole,
)
from app.notifications import create_notification
from app.routers.auth import get_current_user
from app.schemas import ReferralCreate, ReferralOut

router = APIRouter(prefix="/referrals", tags=["referrals"])


@router.get("", response_model=list[ReferralOut])
def list_my_referrals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.doctor:
        doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        q = (
            db.query(Referral)
            .order_by(Referral.created_at.desc())
        )
        if doctor:
            q = q.filter(Referral.doctor_id == doctor.id)
        return q.all()
    return (
        db.query(Referral)
        .filter(Referral.patient_user_id == current_user.id)
        .order_by(Referral.created_at.desc())
        .all()
    )


@router.post("", response_model=ReferralOut, status_code=status.HTTP_201_CREATED)
def create_referral(
    payload: ReferralCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not payload.patient_user_id:
        raise HTTPException(status_code=422, detail="patient_user_id is required.")
    patient = db.query(User).get(payload.patient_user_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    # Doctors (verified) and ASHA workers (escalation) may create referrals.
    if current_user.role == UserRole.doctor:
        if current_user.verification_status != "VERIFIED":
            raise HTTPException(status_code=403, detail="Doctor not verified.")
        dx = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        referrer_doctor_id = dx.id if dx else payload.doctor_id
    elif current_user.role == UserRole.asha:
        referrer_doctor_id = payload.doctor_id
    else:
        raise HTTPException(status_code=403, detail="Not allowed.")

    urgency = payload.urgency
    if payload.urgency not in {u.value for u in Urgency}:
        raise HTTPException(status_code=422, detail="Invalid urgency.")

    referral = Referral(
        patient_user_id=patient.id,
        doctor_id=referrer_doctor_id,
        hospital=payload.hospital,
        specialist=payload.specialist,
        urgency=urgency,
        reason=payload.reason,
    )
    db.add(referral)
    db.flush()
    create_notification(
        db,
        patient.id,
        "Medical referral",
        f"A referral for {payload.specialist or 'specialist care'} has been created ({urgency}).",
        NotificationType.referral,
        referral.id,
    )
    db.commit()
    db.refresh(referral)
    record_audit(db, current_user.id, "referral.create", "referral", referral.id)
    return referral