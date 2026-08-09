from sqlalchemy.orm import Session

from app.models import AshaAssignment, Doctor, User, UserRole
from app.auth import get_user_by_email, hash_password


def seed(db: Session) -> None:
    if not db.query(Doctor).first():
        doctor_seed = [
            Doctor(
                name="Dr. Priya Sharma",
                specialization="General Physician",
                clinic="JeevanDoot Clinic",
                rating=4.9,
                experience_years=8,
                available=True,
                fee=300,
                location="Ramnagar, Maharashtra",
            ),
            Doctor(
                name="Dr. Rahul Verma",
                specialization="Cardiologist",
                clinic="Heartcare Center",
                rating=4.8,
                experience_years=12,
                available=True,
                fee=600,
                location="Pune, Maharashtra",
            ),
            Doctor(
                name="Dr. Sunita Iyer",
                specialization="Pediatrician",
                clinic="Little Stars Clinic",
                rating=4.7,
                experience_years=6,
                available=True,
                fee=350,
                location="Mumbai, Maharashtra",
            ),
        ]
        db.add_all(doctor_seed)
        db.flush()

    # Link the seeded doctor login to a doctor profile and mark VERIFIED.
    doctor_user = get_user_by_email(db, "doctor@jeevandoot.in")
    if not doctor_user:
        doctor_user = User(
            email="doctor@jeevandoot.in",
            name="Dr. Priya Sharma",
            role=UserRole.doctor,
            password_hash=hash_password("doctor123"),
            verification_status="VERIFIED",
        )
        db.add(doctor_user)
        db.flush()
    else:
        doctor_user.verification_status = "VERIFIED"

    dr_priya = db.query(Doctor).filter(Doctor.name == "Dr. Priya Sharma").first()
    if dr_priya and not dr_priya.user_id:
        dr_priya.user_id = doctor_user.id

    # Seed an ASHA worker account for testing the ASHA portal.
    if not get_user_by_email(db, "asha@jeevandoot.in"):
        db.add(
            User(
                email="asha@jeevandoot.in",
                name="Sunita Patil",
                role=UserRole.asha,
                password_hash=hash_password("asha@123"),
            )
        )
        db.flush()

    # Seed a demo patient and assign them to the ASHA worker so the portal
    # has realistic data to act on.
    patient_user = get_user_by_email(db, "rajesh@jeevandoot.in")
    if not patient_user:
        patient_user = User(
            email="rajesh@jeevandoot.in",
            name="Rajesh Kumar",
            role=UserRole.patient,
            password_hash=hash_password("rajesh@123"),
        )
        db.add(patient_user)
        db.flush()

    asha_user = get_user_by_email(db, "asha@jeevandoot.in")
    if asha_user and patient_user:
        existing = (
            db.query(AshaAssignment)
            .filter(
                AshaAssignment.asha_id == asha_user.id,
                AshaAssignment.patient_user_id == patient_user.id,
            )
            .first()
        )
        if not existing:
            db.add(
                AshaAssignment(
                    asha_id=asha_user.id,
                    patient_user_id=patient_user.id,
                    village="Ramnagar",
                    status="active",
                )
            )

    db.commit()