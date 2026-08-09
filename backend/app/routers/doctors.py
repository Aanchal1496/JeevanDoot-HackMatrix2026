from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Doctor, TriageRecord, User, UserRole
from app.routers.auth import get_current_user, require_roles
from app.schemas import DoctorOut

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