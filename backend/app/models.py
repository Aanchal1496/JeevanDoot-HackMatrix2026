import enum
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from app.database import Base


class UserRole(str, enum.Enum):
    patient = "patient"
    doctor = "doctor"
    asha = "asha"
    admin = "admin"


class RiskLevel(str, enum.Enum):
    low = "LOW"
    medium = "MEDIUM"
    high = "HIGH"


class Urgency(str, enum.Enum):
    routine = "ROUTINE"
    urgent = "URGENT"
    emergency = "EMERGENCY"


class AppointmentStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    cancelled = "cancelled"
    completed = "completed"


class AshaTaskStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"


class NotificationType(str, enum.Enum):
    appointment_booked = "appointment_booked"
    appointment_reminder = "appointment_reminder"
    appointment_cancelled = "appointment_cancelled"
    prescription = "prescription"
    referral = "referral"
    followup = "followup"
    high_risk = "high_risk"
    emergency = "emergency"
    escalation = "escalation"
    sync = "sync"
    generic = "generic"


class TimestampMixin:
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.patient, nullable=False)
    password_hash = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    language = Column(String, default="en", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    # Doctor verification state (only meaningful for role=doctor).
    verification_status = Column(
        String, default="PENDING", nullable=False
    )  # PENDING | VERIFIED | REJECTED

    profile = relationship("UserProfile", back_populates="user", uselist=False)
    family_members = relationship("FamilyMember", back_populates="owner")
    patient_profile = relationship(
        "PatientProfile", back_populates="user", uselist=False
    )
    notifications = relationship(
        "Notification",
        back_populates="user",
        foreign_keys="Notification.user_id",
    )


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    location = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    emergency_contact = Column(String, nullable=True)

    user = relationship("User", back_populates="profile")


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    emergency_contact = Column(String, nullable=True)
    address = Column(String, nullable=True)
    village = Column(String, nullable=True)
    district = Column(String, nullable=True)
    state = Column(String, nullable=True)
    preferred_language = Column(String, default="en")

    user = relationship("User", back_populates="patient_profile")


class FamilyMember(Base, TimestampMixin):
    __tablename__ = "family_members"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    name = Column(String, nullable=False)
    relationship_type = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    medical_info = Column(Text, nullable=True)

    owner = relationship("User", back_populates="family_members")


class SymptomEntry(Base, TimestampMixin):
    """A raw/normalized symptom capture from a patient or an ASHA on a patient's behalf."""

    __tablename__ = "symptoms"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    family_member_id = Column(Integer, ForeignKey("family_members.id"), index=True, nullable=True)
    recorded_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    symptom = Column(Text, nullable=False)
    normalized_symptom = Column(String, nullable=True)
    severity = Column(String, nullable=True)
    duration = Column(String, nullable=True)
    onset = Column(String, nullable=True)
    associated_symptoms = Column(Text, nullable=True)


class TriageRecord(Base, TimestampMixin):
    __tablename__ = "triage_records"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=True)
    family_member_id = Column(Integer, ForeignKey("family_members.id"), nullable=True)
    symptoms = Column(Text, nullable=False)
    level = Column(String, nullable=False)
    advice = Column(Text, nullable=True)
    risk_score = Column(Integer, nullable=True)
    red_flags = Column(Text, nullable=True)
    recommendations = Column(Text, nullable=True)


class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    specialization = Column(String, nullable=False)
    clinic = Column(String, nullable=True)
    rating = Column(Float, default=4.5, nullable=False)
    experience_years = Column(Integer, default=0, nullable=False)
    available = Column(Boolean, default=True, nullable=False)
    fee = Column(Integer, default=0, nullable=False)
    image_url = Column(String, nullable=True)
    location = Column(String, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    qualification = Column(String, nullable=True)
    registration_number = Column(String, nullable=True)
    languages = Column(String, nullable=True)


class Consultation(Base, TimestampMixin):
    __tablename__ = "consultations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False)
    doctor_id = Column(Integer, index=True, nullable=True)
    doctor_name = Column(String, nullable=True)
    consultation_type = Column(String, nullable=True)
    status = Column(String, default="upcoming", nullable=False)
    scheduled_at = Column(String, nullable=True)
    started_at = Column(DateTime, nullable=True)
    ended_at = Column(DateTime, nullable=True)
    connection_quality = Column(String, nullable=True)
    risk_level = Column(String, nullable=True)  # LOW | MEDIUM | HIGH
    symptoms = Column(Text, nullable=True)  # comma-joined symptom names

    prescription = relationship("Prescription", back_populates="consultation", uselist=False)
    notes = relationship("PatientNote", back_populates="consultation")


class Appointment(Base, TimestampMixin):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    family_member_id = Column(Integer, ForeignKey("family_members.id"), nullable=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    asha_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    scheduled_at = Column(DateTime, nullable=False)
    type = Column(String, default="Video Consultation", nullable=False)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.confirmed, nullable=False)


class DoctorAvailability(Base, TimestampMixin):
    """A time window (e.g. 16:00-20:00) during which a doctor is free for
    scheduled 1-hour slots. Patients book an hour-aligned slot inside a window.
    """

    __tablename__ = "doctor_availability"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False, index=True)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    start_time = Column(String, nullable=False)  # "16:00"
    end_time = Column(String, nullable=False)  # "20:00"


class Prescription(Base, TimestampMixin):
    __tablename__ = "prescriptions"

    id = Column(Integer, primary_key=True, index=True)
    consultation_id = Column(Integer, ForeignKey("consultations.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), index=True, nullable=False)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    patient_name = Column(String, nullable=True)
    diagnosis = Column(Text, nullable=True)
    instructions = Column(Text, nullable=True)

    consultation = relationship("Consultation", back_populates="prescription")
    medicines = relationship("PrescriptionMedicine", back_populates="prescription")


class PrescriptionMedicine(Base):
    __tablename__ = "prescription_medicines"

    id = Column(Integer, primary_key=True, index=True)
    prescription_id = Column(Integer, ForeignKey("prescriptions.id"), index=True, nullable=False)
    medicine_name = Column(String, nullable=False)
    dosage = Column(String, nullable=True)
    frequency = Column(String, nullable=True)
    duration = Column(String, nullable=True)
    timing = Column(String, nullable=True)
    before_after_food = Column(String, nullable=True)
    visual_instruction = Column(String, nullable=True)

    prescription = relationship("Prescription", back_populates="medicines")


class Referral(Base, TimestampMixin):
    __tablename__ = "referrals"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=True)
    hospital = Column(String, nullable=True)
    specialist = Column(String, nullable=True)
    urgency = Column(Enum(Urgency), default=Urgency.routine, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(String, default="open", nullable=False)


class FollowUp(Base, TimestampMixin):
    __tablename__ = "followups"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    consultation_id = Column(Integer, ForeignKey("consultations.id"), nullable=True)
    scheduled_at = Column(DateTime, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(String, default="scheduled", nullable=False)


class PatientNote(Base, TimestampMixin):
    __tablename__ = "patient_notes"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    consultation_id = Column(Integer, ForeignKey("consultations.id"), nullable=False)
    note = Column(Text, nullable=False)
    ai_summary = Column(Text, nullable=True)

    consultation = relationship("Consultation", back_populates="notes")


class Vital(Base, TimestampMixin):
    __tablename__ = "vitals"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    recorded_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    blood_pressure = Column(String, nullable=True)
    temperature = Column(Float, nullable=True)
    weight = Column(Float, nullable=True)
    pulse = Column(Integer, nullable=True)
    oxygen_saturation = Column(Float, nullable=True)
    recorded_at = Column(DateTime, default=datetime.utcnow, nullable=False)


class AshaAssignment(Base, TimestampMixin):
    __tablename__ = "asha_assignments"

    id = Column(Integer, primary_key=True, index=True)
    asha_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    village = Column(String, nullable=True)
    status = Column(String, default="active", nullable=False)


class AshaTask(Base, TimestampMixin):
    __tablename__ = "asha_tasks"

    id = Column(Integer, primary_key=True, index=True)
    asha_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    patient_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    task_type = Column(String, nullable=False)
    due_date = Column(Date, nullable=True)
    status = Column(Enum(AshaTaskStatus), default=AshaTaskStatus.pending, nullable=False)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)


class Notification(Base, TimestampMixin):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    type = Column(Enum(NotificationType), default=NotificationType.generic, nullable=False)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    read = Column(Boolean, default=False, nullable=False)
    related_id = Column(Integer, nullable=True)

    user = relationship(
        "User", back_populates="notifications", foreign_keys=[user_id]
    )


class EmergencyEvent(Base, TimestampMixin):
    __tablename__ = "emergency_events"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    location = Column(String, nullable=True)
    hospital = Column(String, nullable=True)
    ambulance_status = Column(String, default="requested", nullable=False)


class HealthRecord(Base, TimestampMixin):
    __tablename__ = "health_records"

    id = Column(Integer, primary_key=True, index=True)
    patient_user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    record_type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    file_url = Column(String, nullable=True)
    date = Column(Date, nullable=True)


class AuditLog(Base, TimestampMixin):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=True)
    action = Column(String, nullable=False)
    entity = Column(String, nullable=True)
    entity_id = Column(Integer, nullable=True)
    meta = Column(Text, nullable=True)