from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import Consultation, Doctor, User, UserProfile, UserRole
from app.routers.auth import get_current_user
from app.schemas import ConsultationCreate, ConsultationOut, ConsultationQueueItem

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
        risk_level=payload.risk_level,
        symptoms=", ".join(payload.symptoms) if payload.symptoms else None,
    )
    db.add(consultation)
    db.commit()
    db.refresh(consultation)
    if user.role.value == "doctor":
        record_audit(db, user.id, "consultation.create", "consultation", consultation.id)
    patient = db.query(User).get(consultation.user_id)
    patient_name = patient.name if patient else "Patient"
    return ConsultationOut(
        id=consultation.id,
        user_id=consultation.user_id,
        doctor_id=consultation.doctor_id,
        doctor_name=consultation.doctor_name,
        consultation_type=consultation.consultation_type,
        status=consultation.status,
        scheduled_at=consultation.scheduled_at,
        patient_name=patient_name,
        risk_level=consultation.risk_level,
        symptoms=consultation.symptoms,
    )


def _queue_items(db: Session, doctor: Doctor) -> list[dict]:
    rows = (
        db.query(Consultation)
        .filter(Consultation.doctor_id == doctor.id, Consultation.status == "WAITING")
        .all()
    )
    patients = {
        u.id: u
        for u in db.query(User).filter(User.id.in_([r.user_id for r in rows])).all()
    }
    profiles = {
        p.user_id: p
        for p in db.query(UserProfile)
        .filter(UserProfile.user_id.in_(list(patients.keys())))
        .all()
    }
    risk_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    rows.sort(
        key=lambda r: (
            risk_order.get((r.risk_level or "").upper(), 3),
            r.created_at or r.id,
        )
    )
    items = []
    for r in rows:
        u = patients.get(r.user_id)
        p = profiles.get(r.user_id)
        symptoms = [s.strip() for s in (r.symptoms or "").split(",") if s.strip()]
        items.append(
            {
                "id": r.id,
                "patient_id": r.user_id,
                "patient_name": u.name if u else "Patient",
                "age": p.age if p else None,
                "gender": p.gender if p else None,
                "risk_level": (r.risk_level or "LOW").upper(),
                "symptoms": symptoms,
                "status": r.status,
                "consultation_type": r.consultation_type,
                "scheduled_at": r.scheduled_at,
                "created_at": r.created_at,
            }
        )
    return items


@router.get("/queue", response_model=list[ConsultationQueueItem])
def consultation_queue(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role.value != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors access the queue.")
    doctor = db.query(Doctor).filter(Doctor.user_id == user.id).first()
    if not doctor:
        raise HTTPException(status_code=403, detail="No doctor profile linked.")
    return _queue_items(db, doctor)


@router.post("/{consultation_id}/start", response_model=ConsultationOut)
def start_consultation(
    consultation_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if user.role.value != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can start a consultation.")
    consultation = db.query(Consultation).get(consultation_id)
    if not consultation:
        raise HTTPException(status_code=404, detail="Consultation not found.")
    doctor = db.query(Doctor).filter(Doctor.user_id == user.id).first()
    if not doctor or consultation.doctor_id != doctor.id:
        raise HTTPException(status_code=403, detail="Not your consultation.")
    if consultation.status == "IN_PROGRESS":
        return consultation
    import datetime

    consultation.status = "IN_PROGRESS"
    consultation.started_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(consultation)
    record_audit(db, user.id, "consultation.start", "consultation", consultation.id)
    patient = db.query(User).get(consultation.user_id)
    return ConsultationOut(
        id=consultation.id,
        user_id=consultation.user_id,
        doctor_id=consultation.doctor_id,
        doctor_name=consultation.doctor_name,
        consultation_type=consultation.consultation_type,
        status=consultation.status,
        scheduled_at=consultation.scheduled_at,
        patient_name=patient.name if patient else "Patient",
        risk_level=consultation.risk_level,
        symptoms=consultation.symptoms,
    )