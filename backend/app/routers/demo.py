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
    Prescription,
    User,
    UserProfile,
    UserRole,
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