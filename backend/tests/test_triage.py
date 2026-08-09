"""Tests for the risk-sorted patient queue triage engine.

Run with:  python -m pytest tests/ -v
"""
import pytest

from app.triage import (
    calculate_triage_level,
    calculate_risk_score,
    compute_triage,
    detect_critical_symptoms,
    format_wait_time,
    queue_sort_key,
    sort_queue,
)


# ---------------------------------------------------------------------------
# Test 1-3: triage level boundaries
# ---------------------------------------------------------------------------


def test_risk_85_is_red():
    assert calculate_triage_level(85) == "RED"


def test_risk_55_is_yellow():
    assert calculate_triage_level(55) == "YELLOW"


def test_risk_25_is_green():
    assert calculate_triage_level(25) == "GREEN"


def test_risk_boundaries():
    assert calculate_triage_level(70) == "RED"
    assert calculate_triage_level(69) == "YELLOW"
    assert calculate_triage_level(40) == "YELLOW"
    assert calculate_triage_level(39) == "GREEN"


# ---------------------------------------------------------------------------
# Test 4: safety escalation overrides a low numerical score
# ---------------------------------------------------------------------------


def test_low_score_with_critical_symptom_escalates_to_red():
    # Spec Test 4: a moderate numerical score (YELLOW band) plus a critical
    # symptom must escalate to RED. "Difficulty breathing" (30) + "Mild
    # cough" (10) + multi-symptom bonus (4) = 44 -> YELLOW by score, well
    # below the 70 needed for RED, yet the safety layer escalates.
    triage = compute_triage(["Difficulty breathing", "Mild cough"])
    assert 40 <= triage["ai_risk_score"] < 70
    assert triage["ai_triage_level"] == "YELLOW"
    assert triage["final_triage_level"] == "RED"
    assert triage["triage_source"] == "SAFETY_ESCALATION"
    assert triage["safety_escalated"] is True
    assert "difficulty breathing" in triage["critical_symptoms"]
    # The AI's original assessment must never be overwritten.
    assert triage["ai_triage_level"] == "YELLOW"


def test_critical_symptom_detection_case_insensitive():
    assert detect_critical_symptoms(["SHORTNESS OF BREATH since morning"]) == [
        "shortness of breath"
    ]
    assert detect_critical_symptoms(["Mild rash", "Cold"]) == []


# ---------------------------------------------------------------------------
# Test 5: queue ordered RED -> YELLOW -> GREEN regardless of wait time
# ---------------------------------------------------------------------------


def test_queue_orders_by_level_then_score_then_wait():
    patients = [
        {"id": "g", "name": "Green long wait", "final_triage_level": "GREEN",
         "ai_risk_score": 20, "arrival_time": "2026-08-09T08:00:00"},
        {"id": "r", "name": "Red new", "final_triage_level": "RED",
         "ai_risk_score": 70, "arrival_time": "2026-08-09T09:55:00"},
        {"id": "y", "name": "Yellow", "final_triage_level": "YELLOW",
         "ai_risk_score": 50, "arrival_time": "2026-08-09T09:30:00"},
    ]
    ordered = sort_queue(patients)
    assert [p["id"] for p in ordered] == ["r", "y", "g"]


# ---------------------------------------------------------------------------
# Test 6: within a level, highest risk score first
# ---------------------------------------------------------------------------


def test_same_level_sorted_by_risk_score_desc():
    patients = [
        {"id": "a", "final_triage_level": "RED", "ai_risk_score": 75,
         "arrival_time": "2026-08-09T09:40:00"},  # waiting 20 min
        {"id": "b", "final_triage_level": "RED", "ai_risk_score": 80,
         "arrival_time": "2026-08-09T09:55:00"},  # waiting 5 min
    ]
    ordered = sort_queue(patients)
    assert [p["id"] for p in ordered] == ["b", "a"]


def test_same_score_sorted_by_longest_wait_first():
    patients = [
        {"id": "early", "final_triage_level": "YELLOW", "ai_risk_score": 55,
         "arrival_time": "2026-08-09T09:00:00"},
        {"id": "late", "final_triage_level": "YELLOW", "ai_risk_score": 55,
         "arrival_time": "2026-08-09T09:45:00"},
    ]
    ordered = sort_queue(patients)
    assert [p["id"] for p in ordered] == ["early", "late"]


def test_queue_sort_is_deterministic():
    patients = [
        {"id": "a", "final_triage_level": "GREEN", "ai_risk_score": 20,
         "arrival_time": "2026-08-09T08:00:00"},
        {"id": "b", "final_triage_level": "RED", "ai_risk_score": 90,
         "arrival_time": "2026-08-09T09:55:00"},
        {"id": "c", "final_triage_level": "RED", "ai_risk_score": 90,
         "arrival_time": "2026-08-09T09:50:00"},
    ]
    assert sort_queue(patients) == sort_queue(patients)
    assert sort_queue(patients) == sort_queue(list(reversed(patients)))


# ---------------------------------------------------------------------------
# Test 7: doctor override semantics (backend behaviour)
# ---------------------------------------------------------------------------


def test_doctor_override_preserves_ai_assessment():
    """The override contract: final level changes, AI assessment stays."""
    triage = compute_triage(["Persistent cough", "Fatigue", "Fever"])
    assert triage["final_triage_level"] == "YELLOW"

    # Simulate what the override endpoint does: only final_* fields change.
    overridden = dict(triage)
    overridden["final_triage_level"] = "RED"
    overridden["triage_source"] = "DOCTOR"
    overridden["doctor_override_reason"] = "Patient reports worsening symptoms."

    assert overridden["final_triage_level"] == "RED"
    assert overridden["triage_source"] == "DOCTOR"
    # Original AI result untouched.
    assert overridden["ai_triage_level"] == "YELLOW"
    assert overridden["ai_risk_score"] == triage["ai_risk_score"]


# ---------------------------------------------------------------------------
# Risk score behaviour
# ---------------------------------------------------------------------------


def test_risk_score_clamped_to_0_100():
    high = calculate_risk_score(
        ["Chest pain", "Shortness of breath", "Fever"],
        vitals={"temp": "38.7", "hr": "102", "spo2": "94", "rr": "26"},
        severity="Severe",
    )
    assert high >= 70
    assert high <= 100

    low = calculate_risk_score(["Mild rash"], vitals={"temp": "36.7"})
    assert 0 <= low < 40


def test_vital_signs_contribute_points():
    base = calculate_risk_score(["Fever"])
    with_vitals = calculate_risk_score(
        ["Fever"], vitals={"temp": "39.5", "spo2": "92", "rr": "28"}
    )
    assert with_vitals > base


def test_format_wait_time():
    assert format_wait_time(2) == "2 min"
    assert format_wait_time(18) == "18 min"
    assert format_wait_time(60) == "1 hr"
    assert format_wait_time(72) == "1 hr 12 min"
    assert format_wait_time(-5) == "0 min"
