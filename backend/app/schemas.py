from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import UserRole


class SignUpRequest(BaseModel):
    name: str = Field(min_length=1)
    email: EmailStr
    password: str = Field(min_length=6)
    role: UserRole = UserRole.patient


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserPublic"


class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    name: str
    role: UserRole
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None


class DoctorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    specialization: str
    clinic: Optional[str] = None
    rating: float
    experience_years: Optional[int] = None
    available: bool
    fee: int
    image_url: Optional[str] = None
    location: Optional[str] = None


class TriageRequest(BaseModel):
    symptoms: list[str] = []


class TriageResponse(BaseModel):
    level: str
    advice: str


class SymptomItem(BaseModel):
    name: str
    severity: Optional[str] = None
    red_flag: bool = False


class SymptomCheckRequest(BaseModel):
    input_type: str = "icon"  # "icon" | "voice"
    text: str = ""
    symptoms: list[str] = []
    duration: Optional[str] = None
    severity: Optional[str] = None


class SymptomCheckResponse(BaseModel):
    symptoms: list[SymptomItem] = []
    risk_score: int
    risk_level: str
    explanation: str
    red_flags: list[str] = []
    self_care: list[str] = []


class ConsultationCreate(BaseModel):
    doctor_id: Optional[int] = None
    doctor_name: Optional[str] = None
    consultation_type: str = "Video Consultation"
    scheduled_at: Optional[str] = None
    status: str = "WAITING"
    patient_user_id: Optional[int] = None
    risk_level: Optional[str] = None
    symptoms: Optional[list[str]] = None


class ConsultationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    doctor_id: Optional[int] = None
    doctor_name: Optional[str] = None
    consultation_type: Optional[str] = None
    status: Optional[str] = None
    scheduled_at: Optional[str] = None
    patient_name: Optional[str] = None
    risk_level: Optional[str] = None
    symptoms: Optional[str] = None


class ConsultationQueueItem(BaseModel):
    id: int
    patient_id: int
    patient_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    risk_level: str
    symptoms: Optional[list[str]] = None
    status: str
    consultation_type: Optional[str] = None
    scheduled_at: Optional[str] = None
    created_at: Optional[object] = None


class DemoConsultationCreate(BaseModel):
    patient_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    risk_level: str = "HIGH"
    symptoms: Optional[list[str]] = None
    doctor_id: Optional[int] = None
    consultation_type: str = "Video Consultation"


class DemoPatientOut(BaseModel):
    name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    risk_level: str
    symptoms: list[str]
    status: str


class DemoStatusOut(BaseModel):
    mode: str = "ON"
    patients: list[DemoPatientOut]


class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    name: str
    role: UserRole
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    phone: Optional[str] = None
    language: Optional[str] = "en"
    verification_status: Optional[str] = None


# --------------------------------------------------------------------------- #
# Family members
# --------------------------------------------------------------------------- #
class FamilyMemberCreate(BaseModel):
    name: str = Field(min_length=1)
    relationship_type: Optional[str] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    medical_info: Optional[str] = None


class FamilyMemberUpdate(BaseModel):
    name: Optional[str] = None
    relationship_type: Optional[str] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    medical_info: Optional[str] = None


class FamilyMemberOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    owner_id: int
    name: str
    relationship_type: Optional[str] = None
    date_of_birth: Optional[object] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    medical_info: Optional[str] = None


# --------------------------------------------------------------------------- #
# Symptoms + triage assessments
# --------------------------------------------------------------------------- #
class SymptomEntryCreate(BaseModel):
    patient_user_id: Optional[int] = None
    family_member_id: Optional[int] = None
    symptom: str = Field(min_length=1)
    normalized_symptom: Optional[str] = None
    severity: Optional[str] = None
    duration: Optional[str] = None
    onset: Optional[str] = None
    associated_symptoms: Optional[str] = None


class SymptomEntryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    family_member_id: Optional[int] = None
    symptom: str
    normalized_symptom: Optional[str] = None
    severity: Optional[str] = None
    duration: Optional[str] = None
    onset: Optional[str] = None
    associated_symptoms: Optional[str] = None
    created_at: Optional[object] = None


class SymptomCheckRequestExtended(BaseModel):
    """Triage payload supporting optional patient/family scoping."""
    input_type: str = "icon"
    text: str = ""
    symptoms: list[str] = []
    duration: Optional[str] = None
    severity: Optional[str] = None
    patient_user_id: Optional[int] = None
    family_member_id: Optional[int] = None


class TriageRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: Optional[int] = None
    family_member_id: Optional[int] = None
    symptoms: str
    level: str
    advice: Optional[str] = None
    risk_score: Optional[int] = None
    red_flags: Optional[str] = None
    recommendations: Optional[str] = None
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Appointments
# --------------------------------------------------------------------------- #
class AppointmentCreate(BaseModel):
    doctor_id: int
    scheduled_at: Optional[str] = None
    type: str = "Video Consultation"
    family_member_id: Optional[int] = None
    # Doctor-initiated bookings: the patient this follow-up appointment is for.
    patient_user_id: Optional[int] = None


class AppointmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    family_member_id: Optional[int] = None
    doctor_id: Optional[int] = None
    asha_id: Optional[int] = None
    scheduled_at: Optional[object] = None
    type: Optional[str] = None
    status: Optional[str] = None


class DoctorAvailabilityCreate(BaseModel):
    date: str  # YYYY-MM-DD
    start_time: str  # "16:00"
    end_time: str  # "20:00"


class DoctorAvailabilityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    doctor_id: int
    date: str
    start_time: str
    end_time: str


class SlotOut(BaseModel):
    start: str  # "16:00"
    end: str  # "17:00"


# --------------------------------------------------------------------------- #
# Prescriptions
# --------------------------------------------------------------------------- #
class MedicineItem(BaseModel):
    medicine_name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    duration: Optional[str] = None
    timing: Optional[str] = None
    before_after_food: Optional[str] = None
    visual_instruction: Optional[str] = None


class PrescriptionCreate(BaseModel):
    consultation_id: int
    patient_user_id: Optional[int] = None
    patient_name: Optional[str] = None
    diagnosis: Optional[str] = None
    instructions: Optional[str] = None
    medicines: list[MedicineItem] = []


class MedicineOut(MedicineItem):
    id: int


class PrescriptionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    consultation_id: int
    doctor_id: int
    patient_user_id: int
    patient_name: Optional[str] = None
    diagnosis: Optional[str] = None
    instructions: Optional[str] = None
    medicines: list[MedicineOut] = []
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Referrals
# --------------------------------------------------------------------------- #
class ReferralCreate(BaseModel):
    patient_user_id: Optional[int] = None
    doctor_id: Optional[int] = None
    hospital: Optional[str] = None
    specialist: Optional[str] = None
    urgency: str = "ROUTINE"
    reason: Optional[str] = None


class ReferralOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    doctor_id: Optional[int] = None
    hospital: Optional[str] = None
    specialist: Optional[str] = None
    urgency: Optional[str] = None
    reason: Optional[str] = None
    status: Optional[str] = None
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Follow-ups
# --------------------------------------------------------------------------- #
class FollowUpCreate(BaseModel):
    patient_user_id: Optional[int] = None
    doctor_id: int
    consultation_id: Optional[int] = None
    scheduled_at: str
    reason: Optional[str] = None


class FollowUpOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    doctor_id: int
    consultation_id: Optional[int] = None
    scheduled_at: object
    reason: Optional[str] = None
    status: Optional[str] = None
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Patient notes
# --------------------------------------------------------------------------- #
class PatientNoteCreate(BaseModel):
    consultation_id: int
    patient_user_id: Optional[int] = None
    note: str = Field(min_length=1)
    ai_summary: Optional[str] = None


class PatientNoteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    doctor_id: int
    consultation_id: int
    note: str
    ai_summary: Optional[str] = None
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Vitals
# --------------------------------------------------------------------------- #
class VitalCreate(BaseModel):
    patient_user_id: Optional[int] = None
    blood_pressure: Optional[str] = None
    temperature: Optional[float] = None
    weight: Optional[float] = None
    pulse: Optional[int] = None
    oxygen_saturation: Optional[float] = None


class VitalOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    recorded_by: int
    blood_pressure: Optional[str] = None
    temperature: Optional[float] = None
    weight: Optional[float] = None
    pulse: Optional[int] = None
    oxygen_saturation: Optional[float] = None
    recorded_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# ASHA
# --------------------------------------------------------------------------- #
class AshaAssignmentCreate(BaseModel):
    patient_user_id: int
    village: Optional[str] = None


class AshaAssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    asha_id: int
    patient_user_id: int
    patient_name: Optional[str] = None
    village: Optional[str] = None
    status: Optional[str] = None


class AshaTaskCreate(BaseModel):
    patient_user_id: Optional[int] = None
    task_type: str
    due_date: Optional[str] = None


class AshaTaskUpdate(BaseModel):
    status: Optional[str] = None


class AshaTaskOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    asha_id: int
    patient_user_id: Optional[int] = None
    task_type: str
    due_date: Optional[object] = None
    status: Optional[str] = None
    created_at: Optional[object] = None


class EscalationCreate(BaseModel):
    patient_user_id: int
    reason: str
    symptoms: Optional[str] = None
    urgency: str = "URGENT"


# --------------------------------------------------------------------------- #
# Notifications
# --------------------------------------------------------------------------- #
class NotificationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    type: Optional[str] = None
    title: str
    message: str
    read: bool
    created_at: Optional[object] = None


# --------------------------------------------------------------------------- #
# Health records
# --------------------------------------------------------------------------- #
class HealthRecordCreate(BaseModel):
    record_type: str
    title: str
    description: Optional[str] = None
    file_url: Optional[str] = None
    date: Optional[str] = None


class HealthRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    patient_user_id: int
    record_type: str
    title: str
    description: Optional[str] = None
    file_url: Optional[str] = None
    date: Optional[object] = None
    created_at: Optional[object] = None


class Message(BaseModel):
    detail: str


TokenResponse.model_rebuild()
ConsultationOut.model_rebuild()
PrescriptionOut.model_rebuild()