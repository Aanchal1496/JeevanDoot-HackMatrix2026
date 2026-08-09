from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.analysis import analyze
from app.audit import record_audit
from app.database import get_db
from app.models import (
    AshaAssignment,
    AshaTask,
    AshaTaskStatus,
    Doctor,
    NotificationType,
    Referral,
    SymptomEntry,
    TriageRecord,
    Urgency,
    User,
    UserRole,
    Vital,
)
from app.normalizer import normalize_input
from app.notifications import create_notification
from app.routers.auth import get_current_user, require_roles
from app.schemas import (
    AshaAssignmentOut,
    AshaTaskOut,
    AshaTaskUpdate,
    SymptomEntryOut,
    VitalCreate,
    VitalOut,
)

router = APIRouter(prefix="/asha", tags=["asha"])

RequireAsha = require_roles(UserRole.asha, UserRole.admin)


@router.get("/assignments", response_model=list[AshaAssignmentOut])
def my_assignments(
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    rows = (
        db.query(AshaAssignment)
        .filter(AshaAssignment.asha_id == asha.id, AshaAssignment.status == "active")
        .all()
    )
    names = {
        u.id: u.name
        for u in db.query(User).filter(User.id.in_([r.patient_user_id for r in rows])).all()
    }
    return [
        {
            "id": r.id,
            "asha_id": r.asha_id,
            "patient_user_id": r.patient_user_id,
            "patient_name": names.get(r.patient_user_id, "Patient"),
            "village": r.village,
            "status": r.status,
        }
        for r in rows
    ]


@router.get("/tasks", response_model=list[AshaTaskOut])
def my_tasks(
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    return (
        db.query(AshaTask)
        .filter(AshaTask.asha_id == asha.id)
        .order_by(AshaTask.created_at.desc())
        .all()
    )


@router.post("/tasks", response_model=AshaTaskOut, status_code=status.HTTP_201_CREATED)
def create_task(
    payload: dict,
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    task = AshaTask(
        asha_id=asha.id,
        patient_user_id=payload.get("patient_user_id"),
        task_type=payload.get("task_type"),
        due_date=None,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.put("/tasks/{task_id}", response_model=AshaTaskOut)
def update_task(
    task_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    task = db.query(AshaTask).filter(AshaTask.id == task_id, AshaTask.asha_id == asha.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")
    new_status = payload.get("status")
    if new_status:
        try:
            task.status = AshaTaskStatus(new_status)
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid status.")
        now = datetime.utcnow()
        if task.status == AshaTaskStatus.in_progress and not task.started_at:
            task.started_at = now
        if task.status == AshaTaskStatus.completed:
            task.completed_at = now
    db.commit()
    db.refresh(task)
    return task


@router.post("/patients/{patient_id}/vitals", response_model=VitalOut, status_code=status.HTTP_201_CREATED)
def record_vitals(
    patient_id: int,
    payload: VitalCreate,
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    assignment = (
        db.query(AshaAssignment)
        .filter(
            AshaAssignment.asha_id == asha.id,
            AshaAssignment.patient_user_id == patient_id,
            AshaAssignment.status == "active",
        )
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=403, detail="Patient not assigned to you.")
    vital = Vital(
        patient_user_id=patient_id,
        recorded_by=asha.id,
        blood_pressure=payload.blood_pressure,
        temperature=payload.temperature,
        weight=payload.weight,
        pulse=payload.pulse,
        oxygen_saturation=payload.oxygen_saturation,
    )
    db.add(vital)
    db.commit()
    db.refresh(vital)
    record_audit(db, asha.id, "vital.create", "vital", vital.id)
    return vital


@router.post(
    "/patients/{patient_id}/assist", response_model=dict, status_code=status.HTTP_200_OK
)
def assisted_symptom_check(
    patient_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    assignment = (
        db.query(AshaAssignment)
        .filter(
            AshaAssignment.asha_id == asha.id,
            AshaAssignment.patient_user_id == patient_id,
            AshaAssignment.status == "active",
        )
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=403, detail="Patient not assigned to you.")

    patient = db.query(User).get(patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found.")

    text = payload.get("text") or ""
    raw_symptoms = payload.get("symptoms") or []
    if not text and not raw_symptoms:
        raise HTTPException(status_code=422, detail="No symptoms provided.")

    normalized = normalize_input(raw_symptoms, text)
    if not normalized["symptoms"]:
        raise HTTPException(status_code=422, detail="No recognized symptoms.")
    result = analyze(normalized["symptoms"], normalized["severity"], normalized["duration"])

    for sid in normalized["symptoms"]:
        db.add(
            SymptomEntry(
                patient_user_id=patient_id,
                recorded_by_user_id=asha.id,
                symptom=sid,
                normalized_symptom=sid,
            )
        )
    db.add(
        TriageRecord(
            user_id=patient_id,
            symptoms=", ".join(s["name"] for s in result["symptoms"]),
            level=result["risk_level"],
            advice=result["explanation"],
            risk_score=result["risk_score"],
            red_flags=", ".join(result["red_flags"]),
        )
    )
    if result["risk_level"].upper() == "HIGH":
        create_notification(
            db,
            patient_id,
            "Urgent review needed",
            "A high-risk assessment was entered by your ASHA worker.",
            NotificationType.high_risk,
        )
    db.commit()
    result["assisted_by"] = {"asha_id": asha.id, "note": "Assessment entered with assistance from ASHA worker."}
    record_audit(db, asha.id, "triage.assist", "triage", None, {"patient_id": patient_id})
    return result


@router.post("/patients/{patient_id}/escalate", status_code=status.HTTP_201_CREATED)
def escalate_patient(
    patient_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    asha: User = Depends(require_roles(UserRole.asha)),
):
    assignment = (
        db.query(AshaAssignment)
        .filter(
            AshaAssignment.asha_id == asha.id,
            AshaAssignment.patient_user_id == patient_id,
            AshaAssignment.status == "active",
        )
        .first()
    )
    if not assignment:
        raise HTTPException(status_code=403, detail="Patient not assigned to you.")
    urgency_value = payload.get("urgency", "URGENT")
    if urgency_value not in {u.value for u in Urgency}:
        raise HTTPException(status_code=422, detail="Invalid urgency.")

    referral = Referral(
        patient_user_id=patient_id,
        hospital=payload.get("hospital"),
        specialist=payload.get("specialist"),
        urgency=urgency_value,
        reason=payload.get("reason"),
    )
    db.add(referral)
    db.flush()
    create_notification(
        db,
        patient_id,
        "Escalation submitted",
        "Your case has been escalated to a doctor.",
        NotificationType.escalation,
        referral.id,
    )
    # Notify all verified doctors whose records exist.
    doctors = db.query(Doctor).filter(Doctor.available == True).all()  # noqa: E712
    for d in doctors:
        if d.user_id:
            create_notification(
                db,
                d.user_id,
                "Urgent case",
                "A patient has been escalated to you.",
                NotificationType.emergency,
                referral.id,
            )
    db.commit()
    record_audit(db, asha.id, "escalation.create", "referral", referral.id)
    return {"detail": "Escalation submitted.", "urgency": urgency_value}