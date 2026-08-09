"""Tests for the built-in prescription writer.

Covers the spec's verification cases 1-14:
  1 add medicine           6 draft recovery        11 unauthorized doctor
  2 quick select           7 review                12 PDF
  3 search                 8 issue                 13 (offline - client side)
  4 allergy warning        9 edit issued blocked   14 audit
  5 duplicate             10 patient sees ISSUED only

Run with:  python -m pytest tests/ -v
"""
import os
import tempfile

import pytest
from fastapi.testclient import TestClient

_tmp_db = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp_db.close()
os.environ["JEEVANDOOT_DB"] = _tmp_db.name

from app.db import get_connection, init_db  # noqa: E402
from app.seed import seed_if_empty  # noqa: E402

init_db()
seed_if_empty()

from app.main import app  # noqa: E402

client = TestClient(app)


@pytest.fixture(autouse=True)
def _clean_prescriptions():
    """Isolate each test: drafts must not leak across tests."""
    conn = get_connection()
    try:
        conn.execute("DELETE FROM prescription_items")
        conn.execute("DELETE FROM prescriptions")
        conn.execute("DELETE FROM prescription_audit_log")
        conn.commit()
    finally:
        conn.close()
    yield


def _doctor_token() -> str:
    r = client.post(
        "/api/auth/doctor-login",
        json={"medical_id": "DR-PRIYA", "password": "doctor123"},
    )
    assert r.status_code == 200, r.text
    return r.json()["token"]


def _patient_token() -> str:
    client.post("/api/auth/request-otp", json={"phone": "9822099421"})
    r = client.post(
        "/api/auth/verify-otp", json={"phone": "9822099421", "otp": "123456"}
    )
    assert r.status_code == 200, r.text
    return r.json()["token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _create_draft(token: str, patient_id: str = "PT-9942") -> dict:
    r = client.post(
        "/api/doctor/prescriptions",
        headers=_auth(token),
        json={"patient_id": patient_id},
    )
    assert r.status_code == 200, r.text
    return r.json()["prescription"]


def _add_paracetamol(token: str, rx_id: str, patient_id: str = "PT-9942") -> dict:
    r = client.post(
        f"/api/doctor/prescriptions/{rx_id}/items",
        headers=_auth(token),
        json={
            "medicine_id": "1",  # Paracetamol
            "dose": "1 tablet",
            "frequency": "Twice daily",
            "duration": "3",
            "duration_unit": "days",
            "route": "Oral",
            "timing": "After food",
            "instructions": "Take with water.",
        },
    )
    assert r.status_code == 200, r.text
    return r.json()


# ---------------------------------------------------------------------------
# Test 1 - add medicine with full configuration
# ---------------------------------------------------------------------------


def test_add_medicine_appears_in_prescription():
    token = _doctor_token()
    rx = _create_draft(token)
    res = _add_paracetamol(token, rx["id"])
    items = res["prescription"]["medicines"]
    assert len(items) == 1
    item = items[0]
    assert item["name"] == "Paracetamol"
    assert item["generic_name"] == "Paracetamol"
    assert item["strength"] == "500 mg"
    assert item["dose"] == "1 tablet"
    assert item["frequency"] == "Twice daily"
    assert item["duration"] == "3"
    assert item["duration_unit"] == "days"
    assert item["route"] == "Oral"
    assert item["timing"] == "After food"
    assert item["instructions"] == "Take with water."


def test_add_medicine_requires_dose_and_frequency():
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={"medicine_id": "1", "frequency": "Twice daily"},
    )
    assert r.status_code == 422  # missing dose


def test_duration_accepts_integer():
    """The API is lenient: duration may arrive as "3" or 3 (normalized)."""
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={
            "medicine_id": "1",
            "dose": "1 tablet",
            "frequency": "Twice daily",
            "duration": 3,  # int form
            "duration_unit": "days",
            "route": "Oral",
        },
    )
    assert r.status_code == 200, r.text
    item = r.json()["prescription"]["medicines"][0]
    assert item["duration"] == "3"


def test_legacy_patient_create_deprecated():
    """Patients cannot create prescriptions - only the doctor writer can."""
    r = client.post(
        "/api/prescriptions",
        json={
            "patient_id": "PT-9942",
            "medicines": [{"name": "Paracetamol"}],
        },
    )
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Test 2 - quick select is only a shortcut, never auto-prescribes
# ---------------------------------------------------------------------------


def test_common_medicines_returns_configured_set():
    token = _doctor_token()
    r = client.get(
        "/api/doctor/medicines/common", headers=_auth(token)
    )
    assert r.status_code == 200
    names = [m["name"] for m in r.json()["medicines"]]
    assert "Paracetamol" in names
    assert "Cetirizine" in names
    # Quick select alone must NOT create any prescription.
    conn = get_connection()
    try:
        count = conn.execute(
            "SELECT COUNT(*) FROM prescriptions WHERE patient_id = 'PT-9942'"
        ).fetchone()[0]
    finally:
        conn.close()
    assert count == 0


# ---------------------------------------------------------------------------
# Test 3 - search by generic name / category / strength
# ---------------------------------------------------------------------------


def test_medicine_search_para():
    token = _doctor_token()
    r = client.get(
        "/api/doctor/medicines", params={"q": "para"}, headers=_auth(token)
    )
    assert r.status_code == 200
    names = [m["name"] for m in r.json()["medicines"]]
    assert "Paracetamol" in names
    assert "Paracetamol 650 mg" in names


def test_medicine_search_by_strength_and_category():
    token = _doctor_token()
    r = client.get(
        "/api/doctor/medicines", params={"q": "650"}, headers=_auth(token)
    )
    assert any("650" in m["name"] for m in r.json()["medicines"])
    r = client.get(
        "/api/doctor/medicines", params={"q": "Antibiotic"}, headers=_auth(token)
    )
    assert any(m["category"] == "Antibiotic" for m in r.json()["medicines"])


# ---------------------------------------------------------------------------
# Test 4 - allergy warning (penicillin allergy + amoxicillin)
# ---------------------------------------------------------------------------


def test_allergy_warning_for_penicillin_allergy():
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={
            "medicine_id": "6",  # Amoxicillin (penicillin family)
            "dose": "1 capsule",
            "frequency": "Three times daily",
            "duration": "5",
            "duration_unit": "days",
            "route": "Oral",
        },
    )
    assert r.status_code == 200
    warnings = r.json()["safety"]["warnings"]
    types = [w["type"] for w in warnings]
    assert "ALLERGY_WARNING" in types
    allergy = next(w for w in warnings if w["type"] == "ALLERGY_WARNING")
    assert any("penicillin" in a.lower() for a in allergy["allergies"])
    # The warning must not block - the item was still added.
    assert len(r.json()["prescription"]["medicines"]) == 1


def test_no_allergy_warning_for_unrelated_medicine():
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={
            "medicine_id": "1",  # Paracetamol - no penicillin link
            "dose": "1 tablet",
            "frequency": "Twice daily",
            "route": "Oral",
        },
    )
    types = [w["type"] for w in r.json()["safety"]["warnings"]]
    assert "ALLERGY_WARNING" not in types


def test_interaction_check_never_invents():
    token = _doctor_token()
    rx = _create_draft(token)
    res = _add_paracetamol(token, rx["id"])
    interaction = res["safety"]["interaction_check"]
    assert interaction["available"] is False  # honest: no fabricated warnings


# ---------------------------------------------------------------------------
# Test 5 - duplicate medicine warning
# ---------------------------------------------------------------------------


def test_duplicate_medicine_warning():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={
            "medicine_id": "2",  # Paracetamol 650 mg (same generic)
            "dose": "1 tablet",
            "frequency": "Once daily",
            "route": "Oral",
        },
    )
    types = [w["type"] for w in r.json()["safety"]["warnings"]]
    assert "DUPLICATE_WARNING" in types
    # Not silently merged - both items kept.
    assert len(r.json()["prescription"]["medicines"]) == 2


# ---------------------------------------------------------------------------
# Test 6 - draft recovery (one draft per patient)
# ---------------------------------------------------------------------------


def test_draft_recovery_returns_same_draft():
    token = _doctor_token()
    first = _create_draft(token)
    second = _create_draft(token)
    assert second["id"] == first["id"]  # no duplicate drafts

    r = client.get(
        "/api/doctor/prescriptions/drafts",
        params={"patient_id": "PT-9942"},
        headers=_auth(token),
    )
    assert r.status_code == 200
    assert r.json()["prescription"]["id"] == first["id"]


# ---------------------------------------------------------------------------
# Test 7 - review shows complete read-only data
# ---------------------------------------------------------------------------


def test_review_prescription():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    r = client.get(
        f"/api/doctor/prescriptions/{rx['id']}", headers=_auth(token)
    )
    assert r.status_code == 200
    data = r.json()["prescription"]
    assert data["status"] == "DRAFT"
    assert len(data["medicines"]) == 1
    assert data["medicines"][0]["dose"] == "1 tablet"


# ---------------------------------------------------------------------------
# Test 8 - issue: DRAFT -> ISSUED
# ---------------------------------------------------------------------------


def test_issue_prescription():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    assert r.status_code == 200, r.text
    issued = r.json()["prescription"]
    assert issued["status"] == "ISSUED"
    assert issued["issued_at"]


def test_issue_rejects_empty_prescription():
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    assert r.status_code == 409  # no medicines


# ---------------------------------------------------------------------------
# Test 9 - editing an issued prescription is blocked
# ---------------------------------------------------------------------------


def test_edit_issued_prescription_blocked():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/items",
        headers=_auth(token),
        json={"medicine_id": "3", "dose": "1 tablet",
              "frequency": "Once daily", "route": "Oral"},
    )
    assert r.status_code == 409
    r = client.patch(
        f"/api/doctor/prescriptions/{rx['id']}/notes",
        headers=_auth(token),
        json={"additional_instructions": "edited"},
    )
    assert r.status_code == 409


# ---------------------------------------------------------------------------
# Test 10 - patient portal sees only ISSUED prescriptions
# ---------------------------------------------------------------------------


def test_patient_sees_only_issued():
    token = _doctor_token()
    rx = _create_draft(token, patient_id="PT-88231")
    _add_paracetamol(token, rx["id"], patient_id="PT-88231")

    # Draft exists but the patient must not see it.
    r = client.get(
        "/api/prescriptions", params={"patient_id": "PT-88231"}
    )
    assert r.status_code == 200
    assert all(p["status"] == "ISSUED" for p in r.json()["prescriptions"])

    # After issue it becomes visible.
    client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    r = client.get(
        "/api/prescriptions", params={"patient_id": "PT-88231"}
    )
    assert any(p["id"] == rx["id"] for p in r.json()["prescriptions"])


# ---------------------------------------------------------------------------
# Test 11 - authorization: patient token cannot use doctor endpoints
# ---------------------------------------------------------------------------


def test_unauthorized_doctor_endpoints():
    token = _patient_token()
    r = client.post(
        "/api/doctor/prescriptions",
        headers=_auth(token),
        json={"patient_id": "PT-9942"},
    )
    assert r.status_code == 403
    r = client.get(
        "/api/doctor/prescriptions/drafts",
        params={"patient_id": "PT-9942"},
        headers=_auth(token),
    )
    assert r.status_code == 403


def test_doctor_requires_authentication():
    r = client.post(
        "/api/doctor/prescriptions", json={"patient_id": "PT-9942"}
    )
    assert r.status_code == 401


# ---------------------------------------------------------------------------
# Test 12 - PDF generation
# ---------------------------------------------------------------------------


def test_issued_prescription_pdf():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    r = client.get(
        f"/api/doctor/prescriptions/{rx['id']}/pdf", headers=_auth(token)
    )
    assert r.status_code == 200
    assert r.headers["content-type"] == "application/pdf"
    assert rx["id"] in r.headers["content-disposition"]
    # PDF signature bytes + it is non-trivial in size.
    assert r.content.startswith(b"%PDF")
    assert len(r.content) > 1000


def test_pdf_blocked_for_draft():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    r = client.get(
        f"/api/doctor/prescriptions/{rx['id']}/pdf", headers=_auth(token)
    )
    assert r.status_code == 409  # only issued prescriptions render a PDF


# ---------------------------------------------------------------------------
# Test 14 - audit trail
# ---------------------------------------------------------------------------


def test_issue_records_audit_events():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    conn = get_connection()
    try:
        actions = [
            r["action"]
            for r in conn.execute(
                "SELECT action FROM prescription_audit_log"
                " WHERE prescription_id = ?",
                (rx["id"],),
            )
        ]
    finally:
        conn.close()
    assert "DRAFT_CREATED" in actions
    assert "MEDICINE_ADDED" in actions
    assert "PRESCRIPTION_REVIEWED" in actions
    assert "PRESCRIPTION_ISSUED" in actions


def test_cancel_prescription_recorded():
    token = _doctor_token()
    rx = _create_draft(token)
    r = client.post(
        f"/api/doctor/prescriptions/{rx['id']}/cancel",
        headers=_auth(token),
        json={"reason": "Duplicate of another prescription."},
    )
    assert r.status_code == 200
    assert r.json()["prescription"]["status"] == "CANCELLED"
    conn = get_connection()
    try:
        actions = [
            r["action"]
            for r in conn.execute(
                "SELECT action FROM prescription_audit_log"
                " WHERE prescription_id = ?",
                (rx["id"],),
            )
        ]
    finally:
        conn.close()
    assert "PRESCRIPTION_CANCELLED" in actions


# ---------------------------------------------------------------------------
# Prescription history (doctor view)
# ---------------------------------------------------------------------------


def test_doctor_prescription_history():
    token = _doctor_token()
    rx = _create_draft(token)
    _add_paracetamol(token, rx["id"])
    client.post(
        f"/api/doctor/prescriptions/{rx['id']}/issue", headers=_auth(token)
    )
    r = client.get(
        "/api/doctor/prescriptions/history",
        params={"patient_id": "PT-9942"},
        headers=_auth(token),
    )
    assert r.status_code == 200
    assert any(p["id"] == rx["id"] for p in r.json()["prescriptions"])
