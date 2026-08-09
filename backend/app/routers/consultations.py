from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import Consultation, Doctor, User, UserRole
from app.routers.auth import get_current_user
from app.schemas import ConsultationCreate, ConsultationOut

router = APIRouter(prefix="/consultations", tags=["consultations"])


@router.get("", response_model=list[ConsultationOut])
def list_consultations(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role.value == "doctor":
        doctor = db.query(Doctor).filter(Doctor.user_id == user.id).first()
        if doctor:
            rows = (
                db.query(Consultation)
                .filter(Consultation.doctor_id == doctor.id)
                .order_by(Consultation.created_at.desc())
                .all()
            )
            names = {
                u.id: u.name
                for u in db.query(User)
                .filter(User.id.in_([r.user_id for r in rows]))
                .all()
            }
            return [
                {
                    "id": r.id,
                    "user_id": r.user_id,
                    "doctor_id": r.doctor_id,
                    "doctor_name": r.doctor_name,
                    "consultation_type": r.consultation_type,
                    "status": r.status,
                    "scheduled_at": r.scheduled_at,
                    "patient_name": names.get(r.user_id, "Patient"),
                }
                for r in rows
            ]
        return []
    return db.query(Consultation).filter(Consultation.user_id == user.id).all()


@router.post("", response_model=ConsultationOut, status_code=status.HTTP_201_CREATED)
def create_consultation(
    payload: ConsultationCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    doctor_name = payload.doctor_name
    patient_user_id = payload.patient_user_id
    doctor_id = payload.doctor_id

    if payload.doctor_id:
        doctor = db.query(Doctor).get(payload.doctor_id)
        if not doctor:
            raise HTTPException(status_code=404, detail="Doctor not found.")
        doctor_name = doctor.name

    # A doctor may open a consultation record for a patient (e.g. from the
    # triage queue). Otherwise the consultation belongs to the caller.
    if user.role.value == "doctor":
        doctor = db.query(Doctor).filter(Doctor.user_id == user.id).first()
        if not doctor:
            raise HTTPException(status_code=403, detail="No doctor profile linked.")
        doctor_id = doctor.id
        doctor_name = doctor.name
        if not patient_user_id:
            raise HTTPException(
                status_code=422, detail="patient_user_id is required for a doctor."
            )
        patient = db.query(User).get(patient_user_id)
        if not patient:
            raise HTTPException(status_code=404, detail="Patient not found.")

    consultation = Consultation(
        user_id=patient_user_id or user.id,
        doctor_id=doctor_id,
        doctor_name=doctor_name,
        consultation_type=payload.consultation_type,
        scheduled_at=payload.scheduled_at,
        status=payload.status,
    )
    db.add(consultation)
    db.commit()
    db.refresh(consultation)
    if user.role.value == "doctor":
        record_audit(db, user.id, "consultation.create", "consultation", consultation.id)
    return consultation