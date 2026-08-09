"""Auth endpoints: patient OTP login + doctor credentials login."""
import secrets
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException

from ..db import get_connection
from ..schemas import DoctorLoginRequest, OtpRequest, VerifyOtpRequest

router = APIRouter(prefix="/api/auth", tags=["auth"])

# Demo OTP: always 123456. Stored in memory only for this demo.
_PENDING_OTP: dict[str, str] = {}


@router.post("/request-otp")
def request_otp(payload: OtpRequest):
    phone = payload.phone.strip()
    _PENDING_OTP[phone] = "123456"
    return {"message": "OTP sent to your mobile number.", "otp": "123456"}


def _patient_payload(conn, phone: str) -> dict:
    row = conn.execute(
        "SELECT * FROM patients WHERE phone = ?", (phone,)
    ).fetchone()
    if row is None:
        # Auto-provision a patient so any valid number can sign in.
        import uuid

        pid = "PT-" + uuid.uuid4().hex[:8].upper()
        conn.execute(
            """INSERT INTO patients (id, phone, name, age, gender, blood_group, language)
               VALUES (?,?,?,?,?,?,?)""",
            (pid, phone, "Patient", "30", "Male", "O+", "hi"),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM patients WHERE phone = ?", (phone,)
        ).fetchone()
    data = dict(row)
    return {
        "id": data["id"],
        "phone": data["phone"],
        "name": data["name"],
        "age": data["age"],
        "gender": data["gender"],
        "blood_group": data["blood_group"],
        "email": data["email"],
        "address": data["address"],
        "dob": data["dob"],
        "id_number": data["id_number"],
        "language": data["language"],
        "allergies": data["allergies"],
        "chronic_conditions": data["chronic_conditions"],
        "height": data["height"],
        "weight": data["weight"],
        "medications": data["medications"],
    }


@router.post("/verify-otp")
def verify_otp(payload: VerifyOtpRequest):
    phone = payload.phone.strip()
    expected = _PENDING_OTP.get(phone, "123456")
    if payload.otp != expected:
        raise HTTPException(status_code=401, detail="Invalid OTP. Please try again.")

    conn = get_connection()
    try:
        user = _patient_payload(conn, phone)
        token = secrets.token_hex(16)
        conn.execute(
            "INSERT OR REPLACE INTO auth_tokens (token, role, user_id, created_at) VALUES (?,?,?,?)",
            (token, "patient", user["id"], datetime.now(timezone.utc).isoformat()),
        )
        conn.commit()
    finally:
        conn.close()

    return {"token": token, "role": "patient", "user": user}


@router.post("/doctor-login")
def doctor_login(payload: DoctorLoginRequest):
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM doctors WHERE medical_id = ?", (payload.medical_id.strip(),)
        ).fetchone()
        if row is None or dict(row)["password"] != payload.password:
            raise HTTPException(
                status_code=401, detail="Invalid Medical ID or password."
            )
        data = dict(row)
        token = secrets.token_hex(16)
        conn.execute(
            "INSERT OR REPLACE INTO auth_tokens (token, role, user_id, created_at) VALUES (?,?,?,?)",
            (token, "doctor", data["id"], datetime.now(timezone.utc).isoformat()),
        )
        conn.commit()
    finally:
        conn.close()

    return {
        "token": token,
        "role": "doctor",
        "user": {
            "id": data["id"],
            "name": data["name"],
            "medical_id": data["medical_id"],
            "specialization": data["specialization"],
            "registration_id": data["registration_id"],
            "clinic": data["clinic"],
            "working_hours": data["working_hours"],
            "working_days": data["working_days"],
            "is_available": bool(data["is_available"]),
            "photo_url": data["photo_url"],
        },
    }


# ---------------------------------------------------------------------------
# Authorization dependency for doctor-facing endpoints
# ---------------------------------------------------------------------------


def get_current_doctor(authorization: Optional[str] = Header(default=None)) -> dict:
    """Resolve the calling doctor from the Bearer token.

    Security model for this demo:
    - A real server-issued token must exist and belong to a ``doctor`` role;
      anything else is rejected (401 invalid / 403 wrong role).
    - Device-local demo sessions issue ``local-...`` tokens that never touch
      the server; those are accepted so the offline demo keeps working.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authentication required.")
    token = authorization.removeprefix("Bearer ").strip()
    if token.startswith("local-"):
        return {"role": "doctor", "user_id": None, "name": "Dr. Priya Sharma"}

    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM auth_tokens WHERE token = ?", (token,)
        ).fetchone()
    finally:
        conn.close()
    if row is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    data = dict(row)
    if data["role"] != "doctor":
        raise HTTPException(status_code=403, detail="Doctor access required.")
    return {"role": "doctor", "user_id": data["user_id"], "name": None}


@router.post("/logout")
def logout(token: str):
    conn = get_connection()
    try:
        conn.execute("DELETE FROM auth_tokens WHERE token = ?", (token,))
        conn.commit()
    finally:
        conn.close()
    return {"message": "Logged out."}
