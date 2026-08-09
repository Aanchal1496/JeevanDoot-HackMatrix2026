from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import (
    HealthRecord,
    PatientProfile,
    TriageRecord,
    User,
    UserProfile,
    Vital,
)
from app.routers.auth import get_current_user
from app.schemas import (
    HealthRecordCreate,
    HealthRecordOut,
    TriageRecordOut,
    VitalCreate,
    VitalOut,
)

router = APIRouter(prefix="/patients", tags=["patients"])


def _get_profile(db: Session, user: User) -> PatientProfile:
    profile = user.patient_profile
    if not profile:
        profile = PatientProfile(user_id=user.id)
        db.add(profile)
        db.flush()
    return profile


@router.get("/me")
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = _get_profile(db, current_user)
    up = current_user.profile
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "phone": current_user.phone,
        "role": current_user.role,
        "language": current_user.language,
        "age": up.age if up else None,
        "gender": up.gender if up else None,
        "blood_group": up.blood_group if up else None,
        "emergency_contact": profile.emergency_contact,
        "address": profile.address,
        "village": profile.village,
        "district": profile.district,
        "state": profile.state,
        "preferred_language": profile.preferred_language,
    }


@router.put("/me")
def update_me(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    allowed = {
        "phone", "language", "age", "gender", "blood_group", "emergency_contact",
        "address", "village", "district", "state", "preferred_language",
    }
    data = {k: v for k, v in payload.items() if k in allowed}
    if "phone" in data:
        current_user.phone = data.pop("phone")
    if "language" in data:
        current_user.language = data.pop("language")
    up = current_user.profile or UserProfile(user_id=current_user.id)
    if not current_user.profile:
        db.add(up)
    for prof_field in ("age", "gender", "blood_group"):
        if prof_field in data:
            setattr(up, prof_field, data.pop(prof_field))
    profile = _get_profile(db, current_user)
    for k, v in data.items():
        setattr(profile, k, v)
    db.commit()
    record_audit(db, current_user.id, "profile.update")
    return {"detail": "Profile updated."}


@router.get("/history", response_model=list[TriageRecordOut])
def list_triage_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(TriageRecord)
        .filter(TriageRecord.user_id == current_user.id)
        .order_by(TriageRecord.created_at.desc())
        .all()
    )


# --------------------------------------------------------------------------- #
# Vitals (patient views own, may record own)
# --------------------------------------------------------------------------- #
@router.get("/me/vitals", response_model=list[VitalOut])
def list_my_vitals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(Vital)
        .filter(Vital.patient_user_id == current_user.id)
        .order_by(Vital.recorded_at.desc())
        .all()
    )


@router.post("/me/vitals", response_model=VitalOut, status_code=status.HTTP_201_CREATED)
def create_my_vital(
    payload: VitalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    vital = Vital(patient_user_id=current_user.id, recorded_by=current_user.id, **payload.model_dump(exclude_unset=True, exclude={"patient_user_id"}))
    db.add(vital)
    db.commit()
    db.refresh(vital)
    record_audit(db, current_user.id, "vital.create")
    return vital


# --------------------------------------------------------------------------- #
# Health records (patient's own)
# --------------------------------------------------------------------------- #
@router.get("/me/health-records", response_model=list[HealthRecordOut])
def list_my_records(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(HealthRecord)
        .filter(HealthRecord.patient_user_id == current_user.id)
        .order_by(HealthRecord.created_at.desc())
        .all()
    )


@router.post(
    "/me/health-records",
    response_model=HealthRecordOut,
    status_code=status.HTTP_201_CREATED,
)
def create_my_record(
    payload: HealthRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rec = HealthRecord(
        patient_user_id=current_user.id,
        record_type=payload.record_type,
        title=payload.title,
        description=payload.description,
        file_url=payload.file_url,
        date=None,
    )
    db.add(rec)
    db.commit()
    db.refresh(rec)
    return rec