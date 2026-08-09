"""Tests for the pre-consultation case file feature.

Covers the spec's verification cases:
  Test 1 - complete patient -> complete case file
  Test 2 - no history      -> "Not available", nothing fabricated
  Test 3 - no vitals       -> empty vitals list
  Test 4 - new vitals      -> case file updated (VITALS_UPDATED audit)
  Test 5 - risk changes    -> case file risk assessment updates
  Test 6 - doctor edits    -> original AI summary preserved
  Test 7 - unauthorized    -> 401 / 403

Run with:  python -m pytest tests/ -v
"""
import os
import tempfile

import pytest
from fastapi.testclient import TestClient

# Point the DB at a throwaway file BEFORE importing the app modules.
_tmp_db = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp_db.close()
os.environ["JEEVANDOOT_DB"] = _tmp_db.name

from app.db import get_connection, init_db
from app.seed import seed_if_empty
from app.casefile import (
    build_ai_summary,
    build_case_file_payload,
    extract_structured_symptoms,
    generate_ai_insights,
    generate_important_flags,
    upsert_case_file,
)
from app.vitals import evaluate_all_vitals, evaluate_bp, evaluate_vital

init_db()
seed_if_empty()

from app.main import app  # noqa: E402

client = TestClient(app)


def _queue_row(patient_id: str) -> dict:
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM queue_patients WHERE id = ?", (patient_id,)
        ).fetchone()
        assert row is not None, f"seeded patient {patient_id} not found"
        data = dict(row)
        data["wait_minutes"] = data.get("wait_minutes") or 0
        return data
    finally:
        conn.close()


def _doctor_token() -> str:
    r = client.post(
        "/api/auth/doctor-login",
        json={"medical_id": "DR-PRIYA", "password": "doctor123"},
    )
    assert r.status_code == 200, r.text
    return r.json()["token"]


def _patient_token() -> str:
    r = client.post(
        "/api/auth/request-otp", json={"phone": "9822099421"}
    )
    assert r.status_code == 200
    r = client.post(
        "/api/auth/verify-otp", json={"phone": "9822099421", "otp": "123456"}
    )
    assert r.status_code == 200, r.text
    return r.json()["token"]


def _auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Vitals interpretation (spec section 10) - centralized, configurable
# ---------------------------------------------------------------------------


def test_evaluate_vital_normal():
    item = evaluate_vital("hr", 76)
    assert item["status"] == "normal"
    assert item["unit"] == "bpm"


def test_evaluate_vital_elevated_and_critical():
    assert evaluate_vital("hr", 104)["status"] == "elevated"
    assert evaluate_vital("hr", 122)["status"] == "high_critical"
    assert evaluate_vital("spo2", 92)["status"] == "low"
    assert evaluate_vital("spo2", 88)["status"] == "low_critical"
    assert evaluate_vital("temp", 38.7)["status"] == "elevated"
    assert evaluate_vital("rr", 26)["status"] == "high_critical"


def test_evaluate_vital_missing_returns_none():
    assert evaluate_vital("hr", None) is None
    assert evaluate_vital("hr", "") is None
    assert evaluate_vital("unknown_vital", 10) is None


def test_evaluate_bp_combines_systolic_and_diastolic():
    assert evaluate_bp("148/92")["status"] == "elevated"
    assert evaluate_bp("120/80")["status"] == "normal"
    assert evaluate_bp("180/110")["status"] == "high_critical"
    assert evaluate_bp("not a bp") is None


def test_evaluate_all_vitals_omits_missing():
    items = evaluate_all_vitals(
        {"temp": "37.4", "hr": "104", "spo2": "94", "bp": "148/92", "rr": "22"}
    )
    labels = [i["label"] for i in items]
    assert "Heart Rate" in labels and "Blood Pressure" in labels
    assert "Blood Glucose" not in labels  # not provided
    for item in items:
        assert item["status"] in (
            "low_critical", "low", "normal", "elevated", "high_critical",
        )


# ---------------------------------------------------------------------------
# Structured symptom extraction (spec section 6)
# ---------------------------------------------------------------------------


def test_extract_structured_symptoms_ranks_primary_complaint():
    structured = extract_structured_symptoms(
        ["Chest pain", "Shortness of breath", "Fatigue"],
        duration="2 hours", severity="Severe", onset="Sudden",
    )
    # "Shortness of breath" carries the highest risk weight (30) -> the
    # most concerning symptom becomes the primary complaint.
    assert structured["primary_complaint"] == "Shortness of breath"
    assert "Fatigue" in structured["associated_symptoms"]
    assert structured["progression"] == "Worsening"
    assert len(structured["symptoms"]) == 3


def test_extract_structured_symptoms_empty():
    structured = extract_structured_symptoms([], "", "", "")
    assert structured["primary_complaint"] is None
    assert structured["symptoms"] == []
    assert structured["duration"] == "Not reported"


# ---------------------------------------------------------------------------
# AI summary - never fabricates (spec sections 5 & 22)
# ---------------------------------------------------------------------------


def test_ai_summary_composes_only_reported_fields():
    summary = build_ai_summary(
        ["Chest pain", "Shortness of breath", "Fatigue"],
        duration="2 hours", severity="Severe",
    )
    assert "Patient reports Chest discomfort, Shortness of breath and Fatigue" in summary
    assert "2 hours" in summary
    assert "severe" in summary
    # Nothing about onset is claimed because it wasn't reported.
    assert "onset" not in summary.lower()


def test_ai_summary_empty_symptoms():
    assert build_ai_summary([], "", "", "") == (
        "Insufficient symptom information available."
    )


def test_summary_never_invents_clinical_history():
    summary = build_ai_summary(["Fever"], duration="", severity="")
    assert "fever" in summary.lower()
    assert "prescribe" not in summary.lower()
    assert "diagnos" not in summary.lower()


# ---------------------------------------------------------------------------
# Flags + insights (spec sections 12 & 13)
# ---------------------------------------------------------------------------


def test_flags_from_symptoms_vitals_history():
    flags = generate_important_flags(
        ["Difficulty breathing"],
        evaluate_all_vitals({"hr": "104"}),
        {"allergies": ["Penicillin"], "conditions": ["Hypertension"]},
    )
    texts = [f["text"] for f in flags]
    joined = " ".join(texts).lower()
    assert "difficulty breathing reported" in joined
    assert "elevated heart rate" in joined
    assert "known allergy: penicillin" in joined
    assert "hypertension history" in joined
    # Flags are observations, not diagnoses.
    for f in flags:
        assert f["category"] not in ("Diagnosis", "Confirmed condition")


def test_insights_never_diagnose():
    insights = generate_ai_insights(
        ["Chest pain", "Shortness of breath", "Fatigue"],
        extract_structured_symptoms(
            ["Chest pain", "Shortness of breath", "Fatigue"],
            duration="2 hours", severity="Severe",
        ),
        evaluate_all_vitals({"hr": "104"}),
        # Cardiovascular history + cardiovascular symptoms -> review line.
        {"allergies": [], "conditions": ["Hypertension"]},
    )
    assert any("cardiovascular" in c.lower() for c in insights["suggested_review"])
    assert insights["information_to_clarify"]  # e.g. dizziness/fainting
    assert any("dizziness" in c.lower() for c in insights["information_to_clarify"])
    for bucket in insights.values():
        for line in bucket:
            assert "diagnos" not in line.lower()


# ---------------------------------------------------------------------------
# Test 1 - complete patient: full case file assembled from stored data
# ---------------------------------------------------------------------------


def test_complete_case_file_payload():
    data = _queue_row("PT-9942")  # chest pain + SOB + fever, history, vitals
    payload = build_case_file_payload(data, None)
    assert payload["patient"]["name"] == "Rahul Kumar"
    assert payload["symptom_summary"]["ai_summary"]
    assert payload["symptom_summary"]["primary_complaint"]
    assert payload["history"]["conditions"]  # Hypertension / diabetes
    assert payload["history"]["allergies"] == ["Penicillin (Mild rash)", "Dust mites"]
    assert payload["vitals"]["items"]  # vitals present
    assert payload["risk_assessment"]["ai_risk_score"] is not None
    assert payload["risk_assessment"]["final_triage_level"] in (
        "RED", "YELLOW", "GREEN",
    )
    assert payload["flags"]
    assert payload["ai_insights"]["key_concerns"]
    # Every vital carries its interpreted status - UI never interprets.
    for item in payload["vitals"]["items"]:
        assert "status" in item and "status_label" in item


# ---------------------------------------------------------------------------
# Test 2 - no history: "Not available", nothing fabricated
# ---------------------------------------------------------------------------


def test_no_history_case_file():
    data = _queue_row("PT-8876")  # no history seeded
    payload = build_case_file_payload(data, None)
    assert payload["history"]["conditions"] == []
    assert payload["history"]["allergies"] == []
    assert payload["history"]["medications"] == []
    # The flag list must not fabricate allergies/conditions.
    assert not any("allergy" in f["text"].lower() for f in payload["flags"])


# ---------------------------------------------------------------------------
# Test 3 - no vitals: empty vitals list, graceful payload
# ---------------------------------------------------------------------------


def test_no_vitals_case_file():
    data = _queue_row("PT-9214")
    data["vitals_temp"] = data["vitals_hr"] = data["vitals_spo2"] = None
    data["vitals_bp"] = data["vitals_rr"] = None
    payload = build_case_file_payload(data, None)
    assert payload["vitals"]["items"] == []


# ---------------------------------------------------------------------------
# Risk propagation - the case file consumes, never recalculates (spec §11)
# ---------------------------------------------------------------------------


def test_case_file_uses_stored_risk_assessment():
    data = _queue_row("PT-9942")
    stored_score = data["ai_risk_score"]
    payload = build_case_file_payload(data, None)
    assert payload["risk_assessment"]["ai_risk_score"] == stored_score
    assert payload["risk_assessment"]["final_triage_level"] == data["final_triage_level"]
    assert payload["risk_assessment"]["triage_source"] == data["triage_source"]


# ---------------------------------------------------------------------------
# Test 6 - doctor edit preserves the original AI summary
# ---------------------------------------------------------------------------


def test_doctor_edit_preserves_original_ai_summary():
    data = _queue_row("PT-9942")
    conn = get_connection()
    try:
        payload = build_case_file_payload(data, None)
        upsert_case_file(conn, data["id"], data, payload,
                         __import__("datetime").datetime.now(
                             __import__("datetime").timezone.utc))
        stored = dict(conn.execute(
            "SELECT * FROM case_files WHERE patient_id = ?", (data["id"],)
        ).fetchone())

        original = stored["original_ai_summary"]
        # Simulate the PATCH: doctor summary replaces display content only.
        conn.execute(
            "UPDATE case_files SET doctor_edited_summary = ?, edited_by = ?,"
            " edited_at = ? WHERE id = ?",
            ("Patient condition appears stable now.", "Dr. Priya Sharma",
             "2026-08-09T10:47:00+00:00", stored["id"]),
        )
        conn.commit()
        stored = dict(conn.execute(
            "SELECT * FROM case_files WHERE patient_id = ?", (data["id"],)
        ).fetchone())

        rebuilt = build_case_file_payload(data, stored)
        # Doctor's version is displayed first...
        assert rebuilt["symptom_summary"]["doctor_edited_summary"] == (
            "Patient condition appears stable now."
        )
        # ...but the original AI content is preserved and returned.
        assert rebuilt["symptom_summary"]["original_ai_summary"] == original
        assert rebuilt["symptom_summary"]["edited_by"] == "Dr. Priya Sharma"
        assert original != "Patient condition appears stable now."
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Test 7 - authorization: 401 unauthenticated, 403 wrong role
# ---------------------------------------------------------------------------


def test_case_file_requires_authentication():
    r = client.get("/api/doctor/patients/PT-9942/case-file")
    assert r.status_code == 401


def test_case_file_rejects_patient_token():
    token = _patient_token()
    r = client.get(
        "/api/doctor/patients/PT-9942/case-file", headers=_auth(token)
    )
    assert r.status_code == 403


def test_case_file_unknown_patient_404():
    token = _doctor_token()
    r = client.get(
        "/api/doctor/patients/PT-NOPE/case-file", headers=_auth(token)
    )
    assert r.status_code == 404


# ---------------------------------------------------------------------------
# Endpoint tests: GET / generate / PATCH + audit trail
# ---------------------------------------------------------------------------


def test_get_case_file_endpoint():
    token = _doctor_token()
    r = client.get(
        "/api/doctor/patients/PT-9942/case-file", headers=_auth(token)
    )
    assert r.status_code == 200, r.text
    cf = r.json()["case_file"]
    assert cf["symptom_summary"]["ai_summary"]
    assert cf["patient"]["name"] == "Rahul Kumar"
    assert cf["timestamps"]["generated_label"]


def test_generate_case_file_endpoint_refreshes():
    token = _doctor_token()
    r = client.post(
        "/api/doctor/patients/PT-9103/case-file/generate", headers=_auth(token)
    )
    assert r.status_code == 200, r.text
    assert r.json()["case_file"]["id"]


def test_patch_summary_records_doctor_and_timestamp():
    token = _doctor_token()
    r = client.patch(
        "/api/doctor/patients/PT-9103/case-file/summary",
        headers=_auth(token),
        json={"doctor_summary": "Migraine pattern; advise rest and hydration."},
    )
    assert r.status_code == 200, r.text
    cf = r.json()["case_file"]["symptom_summary"]
    assert cf["doctor_edited_summary"] == (
        "Migraine pattern; advise rest and hydration."
    )
    assert cf["original_ai_summary"]  # AI content preserved
    assert cf["edited_by"]  # recorded
    assert cf["edited_at"]  # timestamped

    # The edit is written to the audit log.
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT * FROM case_file_audit_log WHERE patient_id = 'PT-9103'"
            " AND action = 'SUMMARY_EDITED'"
        ).fetchone()
        assert row is not None, "SUMMARY_EDITED audit row missing"
    finally:
        conn.close()


def test_patch_summary_rejects_empty():
    token = _doctor_token()
    r = client.patch(
        "/api/doctor/patients/PT-9103/case-file/summary",
        headers=_auth(token),
        json={"doctor_summary": "   "},
    )
    assert r.status_code == 400


# ---------------------------------------------------------------------------
# Test 4/5 - refresh detects vitals/risk changes and audits them
# ---------------------------------------------------------------------------


def test_generate_logs_vitals_and_risk_updates():
    token = _doctor_token()
    client.get(
        "/api/doctor/patients/PT-9214/case-file", headers=_auth(token)
    )
    # Simulate a new vital + risk change at the source.
    conn = get_connection()
    try:
        conn.execute(
            "UPDATE queue_patients SET vitals_hr = '118', ai_risk_score = 88,"
            " final_triage_level = 'RED', updated_at = ? WHERE id = 'PT-9214'",
            ("2026-08-09T11:00:00+00:00",),
        )
        conn.commit()
    finally:
        conn.close()

    client.post(
        "/api/doctor/patients/PT-9214/case-file/generate", headers=_auth(token)
    )
    conn = get_connection()
    try:
        actions = {
            r["action"]
            for r in conn.execute(
                "SELECT action FROM case_file_audit_log WHERE patient_id = 'PT-9214'"
            )
        }
        assert "VITALS_UPDATED" in actions
        assert "RISK_UPDATED" in actions
    finally:
        conn.close()
