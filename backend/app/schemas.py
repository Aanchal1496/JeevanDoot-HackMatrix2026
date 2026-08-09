"""Pydantic request/response schemas for the JeevanDoot API."""
from typing import Any, List, Literal, Optional

from pydantic import BaseModel


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
