from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Doctor, FollowUp, NotificationType, User, UserRole
from app.notifications import create_notification
from app.routers.auth import get_current_user
from app.schemas import FollowUpCreate, FollowUpOut

router = APIRouter(prefix="/followups", tags=["followups"])


def _parse_dt(value):
    if not value:
        return None
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M"):
        try:
            return datetime.strptime(value, fmt)
        except (ValueError, TypeError):
            continue
    return None


@router.get("", response_model=list[FollowUpOut])
def list_my_followups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.doctor:
        return (
            db.query(FollowUp)
            .filter(FollowUp.doctor_id != None)  # noqa: E711
            .order_by(FollowUp.scheduled_at.desc())
            .all()
        )
    return (
        db.query(FollowUp)
        .filter(FollowUp.patient_user_id == current_user.id)
        .order_by(FollowUp.scheduled_at.desc())
        .all()
    )


@router.post("", response_model=FollowUpOut, status_code=status.HTTP_201_CREATED)
def create_followup(
    payload: FollowUpCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not payload.patient_user_id:
        raise HTTPException(status_code=422, detail="patient_user_id is required.")
    scheduled = _parse_dt(payload.scheduled_at)
    if not scheduled:
        raise HTTPException(status_code=422, detail="Invalid scheduled_at.")

    dx = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    doctor_id = dx.id if dx else payload.doctor_id

    fu = FollowUp(
        patient_user_id=payload.patient_user_id,
        doctor_id=doctor_id,
        consultation_id=payload.consultation_id,
        scheduled_at=scheduled,
        reason=payload.reason,
    )
    db.add(fu)
    db.flush()
    create_notification(
        db,
        payload.patient_user_id,
        "Follow-up scheduled",
        "Your doctor has scheduled a follow-up.",
        NotificationType.followup,
        fu.id,
    )
    db.commit()
    db.refresh(fu)
    return fu