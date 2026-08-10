"""Symptom normalization and natural-language extraction.

This is the deterministic layer that converts free-form patient text and
explicit symptom selections into a canonical, de-duplicated set of structured
symptoms (plus severity/duration). It is intentionally AI-free so the triage
engine has a stable, explainable input.
"""
from __future__ import annotations

import re
from typing import Iterable

# Canonical symptom definitions.
# `synonyms` are matched (lower-cased, substring) against raw text.
# `red_flag` marks symptoms that must NEVER be downgraded to low risk.
SYMPTOM_DEFS: dict[str, dict] = {
    "fever": {
        "label": "Fever",
        "severity_weight": 25,
        "red_flag": False,
        "synonyms": [
            "fever", "feverish", "temperature", "body hot", "heat",
            # Hindi / Marathi / Gujarati (Romanized + native script)
            "bukhar", "bukhaar", "taap", "tahap", "tapesh", "garam sharir",
            "badan garam", "sharir garam", "ताप", "बुखार", "ताव", "તાવ",
            "बुखार", "બુખાર",
        ],
    },
    "cold": {
        "label": "Cold / cough",
        "severity_weight": 12,
        "red_flag": False,
        "synonyms": [
            "cold", "cough", "coughing", "runny nose", "sneezing",
            "sore throat", "congestion", "stuffy nose", "blocked nose",
            "nose block", "nose is blocked", "throat", "throat pain",
            "soreness in the throat",
            # Hindi / Marathi / Gujarati
            "khansi", "khokla", "zukam", "jukham", "jukaam", "thand",
            "sardi", "sardi lagna", "thand lagna", "naka te pani",
            "nak se paani", "naka vahnu", "chheenk", "chink", "gala dard",
            "gala kharaab", "throat dard", "khoans", "ખાંસી", "खांसी",
            "ખંખિ", "खाँसी",
            "जुखाम", "ઝુકામ", "सर्दी", "ठंडी", "ઠંડી", "ખાઁસી",
        ],
    },
    "dizziness": {
        "label": "Dizziness",
        "severity_weight": 10,
        "red_flag": False,
        "synonyms": [
            "dizziness", "dizzy", "lightheaded", "light-headed", "vertigo",
            "spinning", "woozy",
            # Hindi / Marathi / Gujarati
            "chakkar", "chakkar aana", "ghoom raha", "sir ghoom", "matha ghoom",
            "bhovnu", "bhovnat", "dabkach", "chakkar aay", "chakkar aa",
            "ચક્કર", "ચક્કર આવવા", "चक्कर", "चक्कर आना", "भोवणे", "भोवर",
        ],
    },
    "headache": {
        "label": "Headache",
        "severity_weight": 15,
        "red_flag": False,
        "synonyms": [
            "headache", "head ache", "head hurts", "pain in my head",
            "head pain", "migraine",
            # Hindi / Marathi / Gujarati
            "sir dard", "sar dard", "sardard", "matha dard", "sar me dard",
            "dok du", "dokdu", "dok dukh", "matha dukhe", "dokkumbhar",
            "matem dukhe",
            "माथे", "माथामा", "माथेदुख", "डोकेदुखी", "मાથાનો દુખાવો",
            "सिरदर्द", "सर दर्द", "ડોક",
        ],
    },
    "stomach": {
        "label": "Stomach pain",
        "severity_weight": 20,
        "red_flag": False,
        "synonyms": [
            "stomach", "tummy", "belly", "abdominal", "nausea",
            "vomit", "diarrh","cramps",
            # Latin single-word forms for romanized speech
            "pet", "pait", "pota", "udar", "potte",
            # Hindi / Marathi / Gujarati
            "pet dard", "pait dard", "pet kharaab", "pait kharaab",
            "pet me dard", "pet dukhe", "pot dukh", "pota dukh", "ooki",
            "oshi", "ulti", "matli", "zivede dukh", "potachi takleef",
            "પેટ", "પેટનો દુખાવો", "પેટ ખરાબ", "पेट दर्द", "पेट",
            "पेट खराब", "उलटी", "ઉલટી", "पोटदुखी",
        ],
    },
    "body": {
        "label": "Body pain",
        "severity_weight": 10,
        "red_flag": False,
        "synonyms": ["body pain", "body ache", "muscle", "fatigue", "tired",
            # Hindi / Marathi / Gujarati
            "badan dard", "sharir dard", "sarir dard", "badan dukh",
            "sharir dukh", "thakaan", "thakav", "kamzori", "ang dard",
            "anga dukh", "angle dukhe", "શરીર", "શરીરનો દુખાવો", "बदन",
            "शरीर", "बदन दर्द", "शरीर दुखणे", "थकान", "थकवा",
        ],
    },
    "skin": {
        "label": "Skin issue",
        "severity_weight": 10,
        "red_flag": False,
        "synonyms": ["skin", "rash", "itch", "hives", "bump",
            # Hindi / Marathi / Gujarati
            "chamdi", "khujli", "khaj", "twacha", "dada", "dag", "raaj",
            "raash", "chamaan", "ચામડી", "ખંજવાળ", "चमड़ी", "खुजली",
            "त्वचा", "ત્વચા", "rash nikla", "kushta",
        ],
    },
    "breathing": {
        "label": "Breathing difficulty",
        "severity_weight": 60,
        "red_flag": True,
        "synonyms": [
            "breath", "shortness of breath", "difficulty breathing",
            "cannot breathe", "wheez", "choking", "suffocating",
            # Hindi / Marathi / Gujarati
            "saans lene me takleef", "saans me takleef", "saans nahi",
            "saans phul rahi", "saans fut", "saans na aana", "shwas",
            "dam ghusna", "saas lene me taklif", "saas na awu",
            "સાસ નથી", "શ્વાસ", "સાંસ", "सांस", "श्वास", "सांस नहीं",
            "श्वास घेणे", "dam lag raha", "saans",
        ],
    },
    "chest": {
        "label": "Chest pain / pressure",
        "severity_weight": 60,
        "red_flag": True,
        "synonyms": [
            "chest pain", "chest pressure", "chest tightness",
            "heart", "palpitation",
            # Hindi / Marathi / Gujarati
            "chhati me dard", "seene me dard", "chhati dard", "seene dard",
            "chhati dukhe", "dil dard", "chhadi jalna",
            "છાતી", "છાતીનો દુખાવો", "छाती", "छाती में दर्द", "हृदय",
            "सीने में दर्द", "chhati",
        ],
    },
    # Emergency red-flag symptom categories.
    "unconsciousness": {
        "label": "Loss of consciousness",
        "severity_weight": 90,
        "red_flag": True,
        "synonyms": ["unconscious", "fainted", "passing out", "faint",
            # Hindi / Marathi / Gujarati
            "behosh", "bekhud", "besudh", "behoshi", "gash", "murchha",
            "murch", "gash kha", "બેહોશ", "बेहोश", "मुर्छा",
            "बेसुध", "beshuddh",
        ],
    },
    "severe_bleeding": {
        "label": "Severe bleeding",
        "severity_weight": 85,
        "red_flag": True,
        "synonyms": ["bleeding", "hemorrhage", "bleeding heavily", "blood loss",
            # Hindi / Marathi / Gujarati
            "khoon bahana", "khoon niklana", "raktasrav", "rakta ye",
            "bharpur khoon", "lohi niklwu", "lohi avu", "khun", "khoon",
            "રક્તસ્રાવ", "લોહી", "खून बहना", "रक्तस्राव", "खून निकलना",
            "rakat",
        ],
    },
    "stroke": {
        "label": "Stroke-like symptoms",
        "severity_weight": 85,
        "red_flag": True,
        "synonyms": [
            "stroke", "slurred speech", "facial droop", "drooping face",
            "weakness on one side", "numbness", "severe dizziness",
            # Hindi / Marathi / Gujarati
            "aadhrang", "pakshaghat", "lakuwa", "lakwa", "laku",
            "ek taraf kamzor", "hath pair kamjor", "bolne me takleef",
            "chehra tilka", "aadhang", "पक्षाघात", "લકવો", "लकवा",
            "आधारघात", "આઘાત", "paxghat",
        ],
    },
    "allergic_react": {
        "label": "Severe allergic reaction",
        "severity_weight": 85,
        "red_flag": True,
        "synonyms": [
            "allergic reaction", "anaphylaxis", "swelling of the face",
            "swollen lips", "swollen throat",
            # Hindi / Marathi / Gujarati
            "elergi", "allergi", "chehra sujan", "mukh sujan", "sharir sujan",
            "sujan", "soojan", "suzana", "chamdi sujan", "એલર્જી", "एलर्जी",
            "सूजन", "સૂજન", "chehra fool gaya", "body sooji",
        ],
    },
}

SEVERITY_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\bsevere(ly)?\b|\bvery (high|bad|painful)\b|\bintense\b", re.I), "severe"),
    (re.compile(r"\bmoderate\b|\bsome\b|\bfair amount\b", re.I), "moderate"),
    (re.compile(r"\bmild(ly)?\b|\bslight(ly)?\b|\ba little\b|\blow\b", re.I), "mild"),
    # Regional severity (Hindi / Marathi / Gujarati)
    (re.compile(r"\b(tej|tez|ughda|ghana|khub|bharpur|guru|sakta|tivra)\b", re.I), "severe"),
    (re.compile(r"\b(madhyam|sadharan|saadhaaran|kich|thodi|thoda|madhya)\b", re.I), "moderate"),
    (re.compile(r"\b(halka|kam|kamtad|mild|sinch|hangse)\b", re.I), "mild"),
    # Devanagari severity (Hindi / Marathi / Gujarati scripts).
    # NOTE: no \b here -- Python \b treats Devanagari combining marks as
    # non-word chars, which breaks boundaries. Substring match is fine.
    (re.compile(r"(तेज़|तेज|घना|घोर|भरपूर|तिव्र|गंभीर|ઘણું|ગંભીર)"), "severe"),
    (re.compile(r"(मध्यम|साधारण|थोड़ा|थोडा|મધ્યમ|સાધારણ|થોડું)"), "moderate"),
    (re.compile(r"(हल्का|कम|હળવું|ઓછું)"), "mild"),
]

DURATION_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\bsince (?P<d>\d+)\s*(day|days)\b", re.I), "days"),
    (re.compile(r"\bfor (?P<d>\d+)\s*(day|days)\b", re.I), "days"),
    (re.compile(r"\byesterday\b", re.I), "1 day"),
    (re.compile(r"\b(today|this morning)\b", re.I), "same day"),
    (re.compile(r"\bfor (?P<d>\d+)\s*(week|weeks)\b", re.I), "weeks"),
    # Regional duration
    (re.compile(r"\bkal se\b|\bkal\b|\bgatak\b", re.I), "1 day"),
    (re.compile(r"\baaj\b|\baaj subah\b|\baj\b|\baaj s", re.I), "same day"),
    (re.compile(r"\bpichhle (?P<d>\d+)\s*din\b", re.I), "days"),
    (re.compile(r"\b(?P<d>\d+)\s*din (se|purve)\b", re.I), "days"),
    (re.compile(r"\b(?P<d>\d+)\s*(hapta|hapte|divas)\b", re.I), "weeks"),
    (re.compile(r"\bhapta bhar se\b|\bhapte se\b", re.I), "weeks"),
    # Devanagari duration (no \b -- see note above)
    (re.compile(r"(कल से|कल\b)"), "1 day"),
    (re.compile(r"(आज)"), "same day"),
    (re.compile(r"(?P<d>\d+)\s*दिन से"), "days"),
    (re.compile(r"(?P<d>\d+)\s*(हफ्ता|हफ्ते|दिवस|અઠવાડિયા)"), "weeks"),
    (re.compile(r"(हफ्ता भर से|हफ्ते से)"), "weeks"),
]

VALID_IDS = set(SYMPTOM_DEFS)


def _clean_text(value: str) -> str:
    return re.sub(r"\s+", " ", (value or "").lower())


# Romanized-Indian spelling tolerances. Hindi/Marathi/Gujarati words get written
# many ways in Latin script (e.g. "chhati"/"chati", "mai"/"me", "taap"/"tap").
# We normalise BOTH the incoming text and every synonym through this phonetic
# form so those variants all match, without affecting native-script (Devanagari).
_COLLAPSE = re.compile(r"(.)\1+")


def _match_form(value: str) -> str:
    """Lowercase + collapse doubled letters so 'chhati' and 'chati' become equal.

    Applied identically to input text and to synonyms so matching stays
    consistent. Devanagari/Gujarati script has no adjacent doubled Latin
    letters and its geminates are split by a virama, so they are unaffected.
    """
    v = (value or "").lower()
    v = _COLLAPSE.sub(r"\1", v)
    return v


def extract_severity(text: str) -> str | None:
    for pattern, label in SEVERITY_PATTERNS:
        if pattern.search(text):
            return label
    return None


def extract_duration(text: str) -> str | None:
    for pattern, label in DURATION_PATTERNS:
        m = pattern.search(text)
        if not m:
            continue
        if label == "1 day":
            return "1 day"
        if label == "same day":
            return "same day"
        days = m.groupdict().get("d")
        if days:
            return f"~{days} {label}"
    return None


def extract_symptoms(text: str) -> set[str]:
    """Return canonical symptom ids matched in free text."""
    cleaned = _match_form(_clean_text(text))
    found: set[str] = set()
    for sid, meta in SYMPTOM_DEFS.items():
        for syn in meta["synonyms"]:
            if _match_form(syn) in cleaned:
                found.add(sid)
                break
    return found


def normalize_input(
    symptoms: Iterable[str],
    text: str,
    severity: str | None = None,
    duration: str | None = None,
) -> dict:
    """Combine explicit selections + free-text into normalized output.

    Returns the analysis-friendly input dict.
    """
    cleaned_selected = {s.strip().lower() for s in symptoms if s and s.strip()}
    text_symptoms = extract_symptoms(text) if text else set()

    normalized_ids = set()
    for sid in list(cleaned_selected) + sorted(text_symptoms):
        # Accept canonical ids directly.
        if sid in VALID_IDS:
            normalized_ids.add(sid)
            continue
        # Otherwise try mapping the label back to an id.
        for cand, meta in SYMPTOM_DEFS.items():
            if cand == sid or meta["label"].lower() == sid:
                normalized_ids.add(cand)
                break

    full_text = _clean_text(text or "")
    if severity is None:
        severity = extract_severity(full_text)
    if duration is None:
        duration = extract_duration(full_text)

    return {
        "symptoms": sorted(normalized_ids),
        "severity": severity,
        "duration": duration,
    }