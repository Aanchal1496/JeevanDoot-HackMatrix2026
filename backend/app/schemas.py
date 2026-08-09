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


class ApiMessage(BaseModel):
    message: str = ""
    data: Any = None
