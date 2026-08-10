"""Demo-mode router for the JeevanDoot hackathon showcase.

Kept behind no auth so the demo can be driven from a laptop/browser during the
pitch without swapping phone sessions. Everything is idempotent and scoped to
the seeded demo patient emails so ``reset`` always restores a clean, repeatable
queue. Signal-less on purpose: nothing here is clinically meaningful.
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    Consultation,
    Doctor,
    HealthRecord,
    Prescription,
    PrescriptionMedicine,
    User,
    UserProfile,
    UserRole,
    Vital,
)
from app.auth import get_user_by_email, hash_password
from app.schemas import DemoConsultationCreate, DemoStatusOut, DemoPatientOut

router = APIRouter(prefix="/demo", tags=["demo"])

# Stable identities for the demo patients. These doubles double as the seeded
# queue, and ``reset`` restores exactly these three cases.
DEMO_PATIENTS = [
    {
        "email": "priya@demo.jeevandoot.in",
        "name": "Priya Sharma",
        "age": 34,
        "gender": "F",
        "risk_level": "HIGH",
        "symptoms": ["Chest pain", "Shortness of breath", "Palpitations"],
    },
    {
        "email": "rahul@demo.jeevandoot.in",
        "name": "Rahul Patil",
        "age": 41,
        "gender": "M",
        "risk_level": "MEDIUM",
        "symptoms": ["Persistent cough", "Mild fever", "Fatigue"],
    },
    {
        "email": "sunita@demo.jeevandoot.in",
        "name": "Sunita Devi",
        "age": 52,
        "gender": "F",
        "risk_level": "LOW",
        "symptoms": ["Headache", "Dizziness"],
    },
]


def _demo_user(db: Session, data: dict) -> User:
    user = get_user_by_email(db, data["email"])
    if not user:
        user = User(
            email=data["email"],
            name=data["name"],
            role=UserRole.patient,
            password_hash=hash_password("demo123"),
            verification_status="VERIFIED",
        )
        db.add(user)
        db.flush()
        db.add(
            UserProfile(
                user_id=user.id, age=data["age"], gender=data["gender"], location="Demo"
            )
        )
        db.flush()
    else:
        prof = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
        if prof and prof.age is None:
            prof.age = data["age"]
            prof.gender = data["gender"]
            db.flush()
    return user


def _doctor(db: Session) -> Doctor:
    doc = (
        db.query(Doctor).filter(Doctor.name == "Dr. Priya Sharma").first()
        or db.query(Doctor).first()
    )
    return doc


def _create_consultation(
    db: Session, user: User, data: dict, doctor: Doctor, status_: str = "WAITING"
) -> Consultation:
    c = Consultation(
        user_id=user.id,
        doctor_id=doctor.id,
        doctor_name=doctor.name,
        consultation_type="Video Consultation",
        status=status_,
        scheduled_at="Demo",
        risk_level=data["risk_level"],
        symptoms=", ".join(data["symptoms"]),
    )
    db.add(c)
    db.flush()
    return c


_VITALS = {
    "HIGH": (158, 96, 104, 93, 38.4, 62.0, "158/96"),
    "MEDIUM": (138, 86, 88, 96, 37.8, 68.0, "138/86"),
    "LOW": (128, 80, 76, 98, 37.0, 55.0, "128/80"),
}
_REPORTS = {
    "HIGH": ("Full Blood Count Report", "Hb 11.2, WBC 13.4, shows mild infection markers."),
    "MEDIUM": ("Chest X-Ray", "Clear lung fields; no acute findings."),
    "LOW": ("Lipid Profile", "Cholesterol 198 mg/dL — borderline."),
}
_DIAGNOSIS = {
    "HIGH": "Hypertension with symptom cluster — follow-up required",
    "MEDIUM": "Upper respiratory infection — supportive care",
    "LOW": "General wellness — continue routine care",
}


def _seed_history(db: Session, user: User, data: dict, doctor: Doctor) -> None:
    """Seed patient-facing history (vital, report, prior prescription) so the
    patient's Records tab is populated. Idempotent per demo patient."""
    risk = data["risk_level"]
    # A recorded vital.
    has_vital = db.query(Vital).filter(Vital.patient_user_id == user.id).first()
    if not has_vital:
        sys, dia, pulse, spo2, temp, wt, bp = _VITALS.get(risk, _VITALS["LOW"])
        db.add(
            Vital(
                patient_user_id=user.id,
                recorded_by=doctor.user_id or user.id,
                blood_pressure=bp,
                temperature=temp,
                weight=wt,
                pulse=pulse,
                oxygen_saturation=spo2,
            )
        )
        db.flush()
    # A lab/report record.
    has_rec = (
        db.query(HealthRecord).filter(HealthRecord.patient_user_id == user.id).first()
    )
    if not has_rec:
        title, desc = _REPORTS.get(risk, _REPORTS["LOW"])
        db.add(
            HealthRecord(
                patient_user_id=user.id,
                record_type="Report",
                title=title,
                description=desc,
            )
        )
        db.flush()
    # A prior prescription attached to the demo consultation (if none yet).
    consultation = (
        db.query(Consultation)
        .filter(
            Consultation.user_id == user.id,
            Consultation.doctor_id == doctor.id,
        )
        .order_by(Consultation.id.asc())
        .first()
    )
    if consultation and not consultation.prescription:
        rx = Prescription(
            consultation_id=consultation.id,
            doctor_id=doctor.id,
            patient_user_id=user.id,
            patient_name=user.name,
            diagnosis=_DIAGNOSIS.get(risk, _DIAGNOSIS["LOW"]),
            instructions="Take medications as advised. Stay hydrated and rest well.",
        )
        db.add(rx)
        db.flush()
        for m in [
            ("Paracetamol", "500 mg", "M:1 A:1 N:1", "5 days", "After food"),
            ("Oral Rehydration Salts", "1 dose", "M:1 A:1 N:1", "3 days", "Mix in water"),
        ]:
            db.add(
                PrescriptionMedicine(
                    prescription_id=rx.id,
                    medicine_name=m[0],
                    dosage=m[1],
                    frequency=m[2],
                    duration=m[3],
                    timing="Morning/Afternoon/Night",
                    before_after_food=m[4],
                )
            )
        db.flush()


def ensure_demo(queue_limit: int = 50) -> bool:
    """Seed the base demo queue if missing. Returns True if anything was added."""
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        doc = _doctor(db)
        if not doc:
            return False
        added = False
        for data in DEMO_PATIENTS:
            user = _demo_user(db, data)
            has_case = (
                db.query(Consultation)
                .filter(
                    Consultation.user_id == user.id,
                    Consultation.doctor_id == doc.id,
                    Consultation.status == "WAITING",
                )
                .first()
            )
            if not has_case:
                _create_consultation(db, user, data, doc)
                added = True
            _seed_history(db, user, data, doc)
        db.commit()
        return added
    finally:
        db.close()


@router.get("", response_model=DemoStatusOut)
def demo_status(db: Session = Depends(get_db)):
    doc = _doctor(db)
    rows = []
    for data in DEMO_PATIENTS:
        user = get_user_by_email(db, data["email"])
        c = None
        if user and doc:
            c = (
                db.query(Consultation)
                .filter(
                    Consultation.user_id == user.id,
                    Consultation.doctor_id == doc.id,
                )
                .order_by(Consultation.id.desc())
                .first()
            )
        rows.append(
            DemoPatientOut(
                name=data["name"],
                age=data["age"],
                gender=data["gender"],
                risk_level=data["risk_level"],
                symptoms=data["symptoms"],
                status=(c.status if c else "NONE"),
            )
        )
    return DemoStatusOut(mode="ON", patients=rows)


@router.post("/consultations", response_model=DemoPatientOut, status_code=status.HTTP_201_CREATED)
def simulate_booking(payload: DemoConsultationCreate, db: Session = Depends(get_db)):
    """Simulate a patient booking a teleconsultation (used by 'Simulate new case')."""
    doc = _doctor(db)
    if not doc:
        raise RuntimeError("No doctor seeded.")
    data = {
        "email": None,
        "name": payload.patient_name,
        "age": payload.age,
        "gender": payload.gender,
        "risk_level": payload.risk_level.upper(),
        "symptoms": payload.symptoms or ["New symptom"],
    }
    if payload.doctor_id:
        target = db.query(Doctor).get(payload.doctor_id)
        if target:
            doc = target
    user = _demo_user(db, data) if data["email"] else None
    if not user:
        user = User(
            email="",
            name=data["name"],
            role=UserRole.patient,
            password_hash=hash_password("demo123"),
            verification_status="VERIFIED",
        )
        db.add(user)
        db.flush()
        # Give it a real-ish email so reset can find it later.
        user.email = f"demo.{user.id}@jeevandoot.in"
        db.add(
            UserProfile(
                user_id=user.id, age=data["age"], gender=data["gender"], location="Demo"
            )
        )
        db.flush()
    _create_consultation(db, user, data, doc)
    db.commit()
    return DemoPatientOut(
        name=user.name,
        age=data["age"],
        gender=data["gender"],
        risk_level=data["risk_level"],
        symptoms=data["symptoms"],
        status="WAITING",
    )


@router.post("/reset", response_model=DemoStatusOut)
def reset_demo(db: Session = Depends(get_db)):
    """Restore the clean initial demo queue."""
    demo_ids = {getattr(get_user_by_email(db, d["email"]), "id", None) for d in DEMO_PATIENTS}
    demo_ids |= {
        u.id
        for u in db.query(User)
        .filter(
            User.email.like("%@demo.jeevandoot.in")
            | User.email.like("demo.%@jeevandoot.in")
        )
        .all()
    }
    demo_ids = {u for u in demo_ids if u}
    cons_ids = [
        c.id
        for c in db.query(Consultation)
        .filter(Consultation.user_id.in_(demo_ids))
        .all()
    ]
    if cons_ids:
        db.query(Prescription).filter(
            Prescription.consultation_id.in_(cons_ids)
        ).delete(synchronize_session=False)
        db.query(Consultation).filter(Consultation.id.in_(cons_ids)).delete(
            synchronize_session=False
        )
        db.commit()
    ensure_demo()
    return demo_status(db)