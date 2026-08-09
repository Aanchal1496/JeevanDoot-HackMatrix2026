from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import Doctor, NotificationType, Prescription, PrescriptionMedicine, User
from app.notifications import create_notification
from app.routers.auth import get_current_user
from app.schemas import PrescriptionCreate, PrescriptionOut

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])


@router.get("", response_model=list[PrescriptionOut])
def list_my_prescriptions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = (
        db.query(Prescription)
        .filter(Prescription.patient_user_id == current_user.id)
        .order_by(Prescription.created_at.desc())
        .all()
    )
    return rows


@router.post("", response_model=PrescriptionOut, status_code=status.HTTP_201_CREATED)
def create_prescription(
    payload: PrescriptionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Only VERIFIED doctors can create prescriptions."""
    if current_user.role.value != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can prescribe.")
    if current_user.verification_status != "VERIFIED":
        raise HTTPException(status_code=403, detail="Doctor account is not verified yet.")

    if not payload.patient_user_id:
        raise HTTPException(status_code=422, detail="patient_user_id is required.")
    patient = db.query(User).get(payload.patient_user_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=403, detail="No doctor profile linked to this account.")
    doctor_id = doctor.id

    rx = Prescription(
        consultation_id=payload.consultation_id,
        doctor_id=doctor_id,
        patient_user_id=patient.id,
        patient_name=payload.patient_name or patient.name,
        diagnosis=payload.diagnosis,
        instructions=payload.instructions,
    )
    db.add(rx)
    db.flush()
    for m in payload.medicines:
        db.add(
            PrescriptionMedicine(
                prescription_id=rx.id,
                medicine_name=m.medicine_name,
                dosage=m.dosage,
                frequency=m.frequency,
                duration=m.duration,
                timing=m.timing,
                before_after_food=m.before_after_food,
                visual_instruction=m.visual_instruction,
            )
        )
    create_notification(
        db,
        patient.id,
        "New prescription",
        "Your doctor has issued a new prescription.",
        NotificationType.prescription,
        rx.id,
    )
    db.commit()
    db.refresh(rx)
    record_audit(db, current_user.id, "prescription.create", "prescription", rx.id)
    return rx


@router.get("/{prescription_id}", response_model=PrescriptionOut)
def get_prescription(
    prescription_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rx = db.query(Prescription).get(prescription_id)
    if not rx:
        raise HTTPException(status_code=404, detail="Prescription not found.")
    if rx.patient_user_id != current_user.id and current_user.role.value != "doctor":
        raise HTTPException(status_code=403, detail="Not allowed.")
    return rx