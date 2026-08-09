from app.analysis import (
    build_self_care,
    classify,
    compute_score,
    detect_red_flags,
    analyze,
)
from app.normalizer import (
    extract_duration,
    extract_severity,
    extract_symptoms,
    normalize_input,
)


# --------------------------- Normalization ---------------------------

def test_synonyms_normalized():
    text = "I have a headache and mild fever since 2 days, my head hurts"
    syms = extract_symptoms(text)
    assert "headache" in syms
    assert "fever" in syms
    assert extract_severity(text) == "mild"
    assert extract_duration(text) == "~2 days"


def test_duplicate_symptoms_removed():
    result = normalize_input(["headache", "headache", "fever"], "")
    assert result["symptoms"] == ["fever", "headache"]


def test_empty_input_yields_no_symptoms():
    result = normalize_input([], "")
    assert result["symptoms"] == []


def test_invalid_symptom_ignored():
    result = normalize_input(["banana", "fever"], "")
    assert result["symptoms"] == ["fever"]


def test_combines_selected_and_text():
    result = normalize_input(["cold"], "I have a headache")
    assert "cold" in result["symptoms"]
    assert "headache" in result["symptoms"]


# --------------------------- Red flags ---------------------------

def test_chest_is_red_flag():
    assert detect_red_flags(["chest"]) == ["Chest pain / pressure"]


def test_breathing_is_red_flag():
    assert detect_red_flags(["breathing"]) == ["Breathing difficulty"]


# --------------------------- Scoring ---------------------------

def test_red_flag_forces_high():
    score = compute_score(["headache"], "mild", ["Chest pain / pressure"])
    assert score == 100


def test_low_severity_medium_score():
    # fever(25) + headache(15) mild => 40*0.6=24 -> not medium
    score = compute_score(["fever", "headache"], "mild", [])
    assert score == 24


def test_moderate_fever_headache_medium():
    score = compute_score(["fever", "headache"], "moderate", [])
    assert score == 40


def test_classify_thresholds():
    assert classify(24, []) == "LOW"
    assert classify(40, []) == "MEDIUM"
    assert classify(100, []) == "HIGH"
    assert classify(20, ["Stroke-like symptoms"]) == "HIGH"


# --------------------------- End-to-end ---------------------------

def test_low_risk_scenario():
    r = analyze(["headache"], severity="mild")
    assert r["risk_level"] == "LOW"
    assert r["risk_score"] == 9
    assert r["self_care"] != []
    assert not r["red_flags"]


def test_medium_risk_scenario():
    r = analyze(["fever", "headache"], severity="moderate")
    assert r["risk_level"] == "MEDIUM"
    assert any("book a consultation" in c.lower() or "evaluated by a doctor" in c.lower() for c in r["self_care"])


def test_high_risk_red_flag_not_downgraded():
    r = analyze(["chest"], severity="mild")
    assert r["risk_level"] == "HIGH"
    assert r["risk_score"] == 100
    assert r["red_flags"]


def test_explanation_is_plain_language_and_no_diagnosis():
    r = analyze(["headache"], severity="mild")
    assert "diagnosis" in r["explanation"] and "not a diagnosis" in r["explanation"]
    assert "risk" in r["explanation"]


def test_high_risk_self_care_is_escalation():
    r = analyze(["chest"], severity="mild")
    assert any("emergency" in c.lower() for c in r["self_care"])
    assert "book a consultation" not in " ".join(r["self_care"]).lower()


def test_low_risk_self_care_includes_escalation():
    r = analyze(["headache"], severity="mild")
    assert any("worsen" in c.lower() for c in r["self_care"])


# --------------------------- Malformed / fallback ---------------------------

def test_symptoms_missing_from_defs_filtered():
    r = analyze(["unknown_symptom_xyz"])
    assert r["symptoms"] == []
    assert r["risk_level"] == "LOW"


def test_self_care_empty_for_high_uses_escalation():
    sc = build_self_care("High", ["chest"], ["Chest pain / pressure"])
    assert any("emergency" in c.lower() for c in sc)