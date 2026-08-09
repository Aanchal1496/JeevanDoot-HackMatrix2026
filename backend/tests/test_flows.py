"""End-to-end API flow tests across patient, doctor, ASHA, and RBAC boundaries."""
import uuid

from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.main import app
from app.models import AshaAssignment, User

client = TestClient(app)

# Run startup (migrations + seed) once so seeded users/roles exist.
with TestClient(app) as _bootstrap:
    pass


def _email(prefix):
    return f"{prefix}+{uuid.uuid4().hex[:8]}@example.com"


def _signup(name, role, password="secret123"):
    res = client.post(
        "/api/auth/signup",
        json={"name": name, "email": _email(role), "password": password, "role": role},
    )
    assert res.status_code == 201, res.text
    return res.json()["access_token"]


def _auth(token=None):
    return {"Authorization": f"Bearer {token}"} if token else {}


def test_unauthenticated_access_rejected():
    res = client.get("/api/family-members")
    assert res.status_code == 401


def test_patient_can_manage_only_own_family_members():
    token = _signup("P", "patient")
    other = _signup("O", "patient")

    created = client.post(
        "/api/family-members",
        json={"name": "Mother", "relationship_type": "mother"},
        headers=_auth(token),
    )
    assert created.status_code == 201, created.text
    fid = created.json()["id"]

    upd = client.put(
        f"/api/family-members/{fid}",
        json={"name": "Mother2"},
        headers=_auth(other),
    )
    assert upd.status_code == 403


def test_patient_triage_and_double_booking_prevented():
    token = _signup("P", "patient")
    head = _auth(token)

    tri = client.post(
        "/api/symptom-check",
        json={"input_type": "voice", "text": "fever and severe headache", "symptoms": []},
        headers=head,
    )
    assert tri.status_code == 200, tri.text
    assert tri.json()["risk_level"] in {"LOW", "MEDIUM", "HIGH"}

    doctor = client.get("/api/doctors").json()[0]
    slot = "2026-08-10T10:%02d:00" % (int(uuid.uuid4().hex[:2], 16) % 59)

    payload = {"doctor_id": doctor["id"], "scheduled_at": slot, "type": "Video Consultation"}
    first = client.post("/api/appointments", json=payload, headers=head)
    assert first.status_code == 201, first.text

    second = client.post("/api/appointments", json=payload, headers=head)
    assert second.status_code == 409


def test_asha_can_record_vitals_and_escalate_assigned_patient():
    patient_token = _signup("Pat", "patient")
    patient_id = client.get("/api/patients/me", headers=_auth(patient_token)).json()["id"]

    asha_token = _signup("AshaW", "asha")
    asha_id = client.get("/api/auth/me", headers=_auth(asha_token)).json()["id"]
    db = SessionLocal()
    try:
        db.add(AshaAssignment(asha_id=asha_id, patient_user_id=patient_id))
        db.commit()
    finally:
        db.close()

    ash = _auth(asha_token)
    vit = client.post(
        f"/api/asha/patients/{patient_id}/vitals",
        json={"blood_pressure": "120/80", "temperature": 99.0, "oxygen_saturation": 98.0},
        headers=ash,
    )
    assert vit.status_code == 201, vit.text

    esc = client.post(
        f"/api/asha/patients/{patient_id}/escalate",
        json={"reason": "high fever", "urgency": "URGENT"},
        headers=ash,
    )
    assert esc.status_code == 201, esc.text
    assert esc.json()["urgency"] == "URGENT"


def test_only_verified_doctor_can_create_prescription():
    login = client.post(
        "/api/auth/login",
        json={"email": "doctor@jeevandoot.in", "password": "doctor123"},
    )
    assert login.status_code == 200, login.text
    doc_head = _auth(login.json()["access_token"])

    patient_token = _signup("PX", "patient")
    patient_id = client.get("/api/patients/me", headers=_auth(patient_token)).json()["id"]

    rx = client.post(
        "/api/prescriptions",
        json={
            "consultation_id": 1,
            "patient_user_id": patient_id,
            "diagnosis": "Viral fever",
            "medicines": [{"medicine_name": "Paracetamol", "dosage": "650 mg", "frequency": "1-1-1"}],
        },
        headers=doc_head,
    )
    assert rx.status_code == 201, rx.text
    assert rx.json()["medicines"][0]["medicine_name"] == "Paracetamol"


def test_unverified_doctor_cannot_prescribe():
    token = _signup("DocNew", "doctor", password="secret123")
    head = _auth(token)
    rx = client.post(
        "/api/prescriptions",
        json={"consultation_id": 1, "patient_user_id": 1, "diagnosis": "x"},
        headers=head,
    )
    assert rx.status_code == 403


def test_doctor_risk_queue_and_patient_history():
    login = client.post(
        "/api/auth/login",
        json={"email": "doctor@jeevandoot.in", "password": "doctor123"},
    )
    head = _auth(login.json()["access_token"])
    q = client.get("/api/doctors/queue", headers=head)
    assert q.status_code == 200

    patient_token = _signup("PP", "patient")
    hist = client.get("/api/patients/history", headers=_auth(patient_token))
    assert hist.status_code == 200