"""Pydantic request/response schemas for the JeevanDoot API."""
from typing import Any, List, Literal, Optional, Union

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
class OtpRequest(BaseModel):
    phone: str


class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str


class DoctorLoginRequest(BaseModel):
    medical_id: str
    password: str


# ---------------------------------------------------------------------------
# Triage
# ---------------------------------------------------------------------------
class TriageRequest(BaseModel):
    symptoms: List[str]


# ---------------------------------------------------------------------------
# Doctor: triage override
# ---------------------------------------------------------------------------
class TriageOverride(BaseModel):
    triage_level: Literal["RED", "YELLOW", "GREEN"]
    reason: str = Field(..., min_length=1, max_length=500)
    changed_by: Optional[str] = None


# ---------------------------------------------------------------------------
# Doctor: case file
# ---------------------------------------------------------------------------
class CaseFileSummaryUpdate(BaseModel):
    doctor_summary: str = Field(..., min_length=1, max_length=2000)


# ---------------------------------------------------------------------------
# Appointments
# ---------------------------------------------------------------------------
class AppointmentCreate(BaseModel):
    patient_id: str
    doctor_id: str = "DR-PRIYA"
    consult_type: str = "video"
    date_id: str = "today"
    time: str = "17:30"
    name: Optional[str] = None


# ---------------------------------------------------------------------------
# Teleconsultations
# ---------------------------------------------------------------------------
class AttachmentMeta(BaseModel):
    name: str
    size: int = 0
    type: str = ""


class ConsultationBookRequest(BaseModel):
    patient_id: str
    doctor_id: str
    date: str  # YYYY-MM-DD
    start_time: str  # HH:MM
    consult_type: str = "video"
    reason: str = ""
    attachments: List[AttachmentMeta] = []
    booking_source: str = "SELF"  # SELF | ASHA
    asha_request_id: Optional[str] = None
    patient_name: Optional[str] = None
    patient_phone: Optional[str] = None


class ConsultationCancelRequest(BaseModel):
    patient_id: str


class ConsultationRescheduleRequest(BaseModel):
    patient_id: str
    date: str
    start_time: str


# ---------------------------------------------------------------------------
# ASHA assistance
# ---------------------------------------------------------------------------
class AshaRequestCreate(BaseModel):
    patient_id: str
    patient_name: str = ""
    specialty: str = ""
    preferred_date: str = ""
    preferred_time: str = ""
    preferred_language: str = ""
    reason: str = ""
    notes: str = ""


class AshaRequestUpdate(BaseModel):
    status: Optional[str] = None
    asha_id: Optional[str] = None
    asha_name: Optional[str] = None


class AshaBookRequest(BaseModel):
    patient_id: str
    doctor_id: str
    date: str
    start_time: str
    consult_type: str = "video"
    reason: str = ""


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------
class NotificationRead(BaseModel):
    read: bool = True


# ---------------------------------------------------------------------------
# Prescriptions
# ---------------------------------------------------------------------------
class MedicineItem(BaseModel):
    name: str
    category: str = "Tablet"
    dosage: str = "1"
    unit: str = "mg"
    morning: int = 1
    afternoon: int = 0
    night: int = 1
    days: int = 5
    instructions: str = "After food"


class PrescriptionCreate(BaseModel):
    patient_id: str
    doctor_name: str = "Dr. Priya Sharma"
    notes: str = ""
    medicines: List[MedicineItem]


# ---------------------------------------------------------------------------
# Doctor: prescription writer
# ---------------------------------------------------------------------------
class PrescriptionDraftCreate(BaseModel):
    patient_id: str
    consultation_id: Optional[str] = None


class PrescriptionItemAdd(BaseModel):
    medicine_id: str
    generic_name: Optional[str] = None
    strength: Optional[str] = None
    dosage_form: Optional[str] = None
    dose: Optional[str] = None
    frequency: Optional[str] = None
    # Accept both "3" and 3 - normalized to a string by the service.
    duration: Optional[Union[int, str]] = None
    duration_unit: Optional[str] = None
    route: Optional[str] = None
    timing: Optional[str] = None
    instructions: Optional[str] = None


class PrescriptionItemUpdate(BaseModel):
    strength: Optional[str] = None
    dosage_form: Optional[str] = None
    dose: Optional[str] = None
    frequency: Optional[str] = None
    duration: Optional[Union[int, str]] = None
    duration_unit: Optional[str] = None
    route: Optional[str] = None
    timing: Optional[str] = None
    instructions: Optional[str] = None


class PrescriptionNotesUpdate(BaseModel):
    additional_instructions: str = Field("", max_length=2000)


class PrescriptionCancel(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


class PrescriptionSupersede(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------
class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[str] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    dob: Optional[str] = None
    id_number: Optional[str] = None
    phone: Optional[str] = None
    language: Optional[str] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    height: Optional[str] = None
    weight: Optional[str] = None
    medications: Optional[str] = None
    sms_alerts: Optional[bool] = None
    app_alerts: Optional[bool] = None
    email_updates: Optional[bool] = None
    reminder_alerts: Optional[bool] = None
    appointment_alerts: Optional[bool] = None
    data_sharing: Optional[bool] = None
    app_lock: Optional[bool] = None
    biometric_lock: Optional[bool] = None
    share_health_reports: Optional[bool] = None
    marketing_updates: Optional[bool] = None


class ReminderDone(BaseModel):
    done: bool = True


# ---------------------------------------------------------------------------
# Medicine / follow-up reminders
# ---------------------------------------------------------------------------
class MedicineReminderCreate(BaseModel):
    patient_id: str
    prescription_id: Optional[str] = None
    medicine_id: Optional[str] = None
    medicine_name: str
    category: str = "Tablet"
    dosage: str = ""
    unit: str = "mg"
    quantity: int = 1
    period: str = "morning"
    meal_instruction: str = "After food"
    time: str = "08:00"
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    duration_days: int = 5
    reminder_type: str = "medicine"
    voice_enabled: bool = False
    language: str = "hi"


class MedicineReminderUpdate(BaseModel):
    time: Optional[str] = None
    period: Optional[str] = None
    meal_instruction: Optional[str] = None
    voice_enabled: Optional[bool] = None
    language: Optional[str] = None
    status: Optional[str] = None
    end_date: Optional[str] = None
    duration_days: Optional[int] = None


class DoseAction(BaseModel):
    taken_at: Optional[str] = None


class FollowUpCreate(BaseModel):
    patient_id: str
    prescription_id: Optional[str] = None
    doctor_name: str = "Dr. Priya Sharma"
    followup_date: str
    followup_time: str = "10:00"
    reason: str = "Follow-up consultation"
    voice_enabled: bool = False
    language: str = "hi"


class FollowUpUpdate(BaseModel):
    followup_date: Optional[str] = None
    followup_time: Optional[str] = None
    reason: Optional[str] = None
    doctor_name: Optional[str] = None
    voice_enabled: Optional[bool] = None
    language: Optional[str] = None
    enabled: Optional[bool] = None


class ApiMessage(BaseModel):
    message: str = ""
    data: Any = None


# ---------------------------------------------------------------------------
# Symptom check (AI triage)
# ---------------------------------------------------------------------------
class SymptomCheckRequest(BaseModel):
    text: Optional[str] = None
    selected_symptoms: List[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Consultations (video/audio teleconsultation)
# ---------------------------------------------------------------------------
class ConsultationCreate(BaseModel):
    appointment_id: str
    requester_role: str


class ConsultationEnd(BaseModel):
    duration_seconds: Optional[int] = None
    connection_quality: Optional[str] = None


# ---------------------------------------------------------------------------
# Doctor documentation (consultation notes + AI summary + follow-ups)
# ---------------------------------------------------------------------------
class ConsultationNotesCreate(BaseModel):
    patient_id: str
    doctor_id: str = ""
    doctor_name: str = ""
    consultation_id: str = ""
    diagnosis: str = ""
    notes: str = ""
    vitals: dict = {}
    symptoms: list = []
    ai_summary: str = ""


class AiSummaryRequest(BaseModel):
    patient_id: str
    notes: str = ""
    diagnosis: str = ""


class FollowUpCreate(BaseModel):
    patient_id: str
    doctor_id: str = ""
    doctor_name: str = ""
    date: str
    time: str
    reason: str = ""
    consult_type: str = "Video Consultation"
