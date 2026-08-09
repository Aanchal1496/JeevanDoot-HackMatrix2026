"""Deterministic symptom extraction from free-text patient descriptions.

The extractor is intentionally conservative. It only reports symptoms,
red flags, duration, severity, onset and frequency details that appear
literally in the patient's own words (phrase/keyword matching over the
lowercased text). It never invents symptoms the patient did not mention.

Symptom ids here are the canonical ids also used by the Flutter icon
selector, so icon selections and spoken/text descriptions are merged on
the backend into a single de-duplicated set.
"""
import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional

# ---------------------------------------------------------------------------
# Symptom catalogue
# ---------------------------------------------------------------------------
# id -> {label, keywords}. Keywords are matched case-insensitively; longer
# phrases are checked first so "difficulty breathing" wins over "breathing".
SYMPTOM_CATALOGUE: Dict[str, Dict[str, object]] = {
    "fever": {
        "label": "Fever",
        "keywords": [
            "running a temperature", "high temperature", "feeling feverish",
            "feverish", "fever", "temperature of 10", "temperature is 10",
            "chills", "shivering", "feeling hot",
        ],
    },
    "headache": {
        "label": "Headache",
        "keywords": [
            "pain in my head", "head pain", "splitting head", "headache",
            "head ache", "migraine",
        ],
    },
    "cough": {
        "label": "Cough",
        "keywords": [
            "dry cough", "wet cough", "coughing", "hacking cough", "cough",
            "cough at night",
        ],
    },
    "breathing": {
        "label": "Breathing difficulty",
        "keywords": [
            "struggling to breathe", "shortness of breath", "difficulty breathing",
            "trouble breathing", "hard to breathe", "cannot breathe",
            "can't breathe", "couldn't breathe", "breathless", "breathlessness",
            "wheezing", "suffocating", "gasping for air", "short of breath",
        ],
    },
    "chest": {
        "label": "Chest discomfort",
        "keywords": [
            "pain in my chest", "pressure in my chest", "tightness in my chest",
            "chest pain", "chest pressure", "chest tightness", "chest discomfort",
            "heart pain", "crushing chest",
        ],
    },
    "nausea": {
        "label": "Nausea",
        "keywords": [
            "want to throw up", "feel sick", "feeling sick", "nauseous",
            "nausea", "queasy", "upset stomach",
        ],
    },
    "vomiting": {
        "label": "Vomiting",
        "keywords": [
            "throwing up", "threw up", "puking", "puked", "being sick",
            "vomiting", "vomited", "vomit",
        ],
    },
    "diarrhea": {
        "label": "Diarrhea",
        "keywords": [
            "loose motions", "loose motion", "loose stools", "loose stool",
            "watery stool", "watery stools", "frequent stools", "diarrhoea",
            "diarrhea", "bad runs",
        ],
    },
    "dizziness": {
        "label": "Dizziness",
        "keywords": [
            "light headed", "light-headed", "lightheaded", "feeling faint",
            "dizzy spells", "dizziness", "dizzy", "vertigo", "rooms spinning",
        ],
    },
    "fatigue": {
        "label": "Fatigue",
        "keywords": [
            "no energy", "worn out", "exhaustion", "exhausted", "lethargic",
            "very weak", "feeling weak", "weakness", "fatigue", "tired all the time",
            "tired", "weak",
        ],
    },
    "cold": {
        "label": "Cold",
        "keywords": [
            "runny nose", "stuffy nose", "blocked nose", "nasal congestion",
            "caught a cold", "have a cold", "common cold", "cold and cough",
            "sneezing", "congested",
        ],
    },
    "sore_throat": {
        "label": "Sore throat",
        "keywords": [
            "scratchy throat", "painful throat", "throat hurts", "sore throat",
            "throat pain", "swollen throat",
        ],
    },
    "pain": {
        "label": "Pain",
        "keywords": [
            "aching all over", "body ache", "body pain", "muscle pain",
            "muscle ache", "joint pain", "back pain", "leg pain", "arm pain",
            "pain in my legs", "pain in my back", "aches and pains", "aching",
            "aches", "pain all over",
        ],
    },
    "stomach": {
        "label": "Stomach pain",
        "keywords": [
            "stomach ache", "stomachache", "abdominal pain", "belly pain",
            "tummy ache", "stomach pain", "cramps in my stomach", "stomach cramps",
        ],
    },
}

# ---------------------------------------------------------------------------
# Red-flag phrases (literal matches only). Matching one forces HIGH risk.
# ---------------------------------------------------------------------------
RED_FLAG_PHRASES: Dict[str, Dict[str, object]] = {
    "breathing_difficulty": {
        "label": "Difficulty breathing",
        "phrases": [
            "difficulty breathing", "shortness of breath", "trouble breathing",
            "hard to breathe", "cannot breathe", "can't breathe",
            "couldn't breathe", "breathless", "breathlessness", "suffocating",
            "struggling to breathe", "gasping for air", "short of breath",
            "wheezing",
        ],
    },
    "severe_chest_pain": {
        "label": "Severe chest pain",
        "phrases": [
            "severe chest pain", "crushing chest pain", "worst chest pain",
            "chest pain and difficulty breathing", "chest pain and breathing",
        ],
    },
    "sudden_severe_headache": {
        "label": "Sudden severe headache",
        "phrases": [
            "worst headache of my life", "sudden severe headache",
            "most severe headache", "excruciating headache",
        ],
    },
    "fainting": {
        "label": "Fainting or loss of consciousness",
        "phrases": [
            "passed out", "passing out", "lost consciousness",
            "loss of consciousness", "fainted", "blacked out",
        ],
    },
    "confusion": {
        "label": "Confusion or disorientation",
        "phrases": [
            "feeling confused", "very confused", "disoriented",
            "disorientation", "not making sense",
        ],
    },
    "stroke_like": {
        "label": "Stroke-like symptoms",
        "phrases": [
            "slurred speech", "slurring my words", "face drooping",
            "facial droop", "drooping on one side", "weakness on one side",
            "numbness on one side", "sudden vision loss", "can't move my arm",
            "cannot move my arm",
        ],
    },
    "seizure": {
        "label": "Seizure",
        "phrases": [
            "seizure", "seizures", "convulsion", "convulsions", "fitting",
            "had a fit",
        ],
    },
    "severe_bleeding": {
        "label": "Severe bleeding",
        "phrases": [
            "severe bleeding", "bleeding heavily", "bleeding a lot",
            "vomiting blood", "throwing up blood", "blood in my stool",
            "blood in stool", "blood in my vomit",
        ],
    },
    "severe_abdominal": {
        "label": "Severe abdominal pain",
        "phrases": [
            "severe abdominal pain", "severe stomach pain",
            "severe stomach ache", "unbearable stomach pain",
        ],
    },
    "self_harm": {
        "label": "Thoughts of self-harm",
        "phrases": [
            "want to hurt myself", "end my life", "killing myself", "suicidal",
        ],
    },
}

# ---------------------------------------------------------------------------
# Duration / severity / onset / frequency patterns
# ---------------------------------------------------------------------------
# (regex with value group, display format, unit index for day estimation)
_DURATION_PATTERNS = [
    (r"for (the last |about |almost )?(\d+)\s*(minute|minutes)", "for {v} minutes", 0),
    (r"for (the last |about |almost )?(\d+)\s*(hour|hours)", "for {v} hours", 1),
    (r"for (the last |about |almost )?(\d+)\s*(day|days)", "for {v} days", 2),
    (r"for (the last |about |almost )?(\d+)\s*(week|weeks)", "for {v} weeks", 3),
    (r"for (the last |about |almost )?(\d+)\s*(month|months)", "for {v} months", 4),
    (r"(\d+)\s*(minute|minutes)\s*ago", "{v} minutes ago", 0),
    (r"(\d+)\s*(hour|hours)\s*ago", "{v} hours ago", 1),
    (r"(\d+)\s*(day|days)\s*ago", "{v} days ago", 2),
    (r"(\d+)\s*(week|weeks)\s*ago", "{v} weeks ago", 3),
    (r"a (day|week|month) ago", "a {u} ago", 0),
]

_UNIT_DAYS = {
    0: 0.01,     # minutes
    1: 1 / 24,   # hours
    2: 1.0,      # days
    3: 7.0,      # weeks
    4: 30.0,     # months
}

_DURATION_PHRASES = [
    (r"since (this )?morning", "since morning", None),
    (r"since (this )?afternoon", "since afternoon", None),
    (r"since (last )?night", "since last night", None),
    (r"since (last )?(yesterday|evening)", "since yesterday", None),
    (r"since (last )?week", "since last week", 7.0),
    (r"since (last )?month", "since last month", 30.0),
    (r"all (day|week|morning|night) long", "all day", None),
    (r"whole (day|week)", "all day", None),
    (r"for days", "for several days", 3.0),
    (r"for weeks", "for several weeks", 14.0),
]

_SEVERITY_PATTERNS = [
    (r"\bsevere(ly)?\b|\bextreme(ly)?\b|\bunbearable\b|\bcrushing\b|\bvery (bad|painful)\b|\bworst\b", "severe"),
    (r"\bmoderate(ly)?\b|\bquite bad\b|\bhigh fever\b|\bhigh temperature\b", "moderate"),
    (r"\bmild(ly)?\b|\bslight(ly)?\b|\bminor\b|\blittle\b", "mild"),
]

_ONSET_PATTERNS = [
    (r"\bsudden(ly)?\b|\ball of a sudden\b|\babrupt(ly)?\b|\bcame on suddenly\b", "sudden"),
    (r"\bgradual(ly)?\b|\bslowly\b|\bbuild(ing)? up\b", "gradual"),
]

_FREQUENCY_PATTERNS = [
    (r"\brepeatedly\b|\bmultiple times\b|\bover and over\b|\bnon-?stop\b|\bcontinuously\b|\bconstant(ly)?\b|\bkept (vomiting|throwing|puking)\b|\bkeeps (vomiting|throwing|puking)\b", "constant or repeated"),
    (r"\bevery few (hours|minutes)\b|\btwice a day\b|\bthree times\b|\bfrequently\b|\boften\b", "frequent"),
    (r"\bintermittent(ly)?\b|\boff and on\b|\boccasionally\b|\bsometimes\b", "intermittent"),
]

_WORSENING_PATTERNS = [
    r"\bgetting worse\b", r"\bworsen(ing|ed)?\b", r"\bworse than (before|earlier|yesterday)\b",
    r"\bnot improving\b", r"\bgetting (more|worse)\b", r"\bgetting stronger\b",
]

_CONTEXT_PHRASES = [
    (r"after eating", "after eating"),
    (r"after meals", "after meals"),
    (r"during exercise", "during exercise"),
    (r"when i (lie|lay) down", "when lying down"),
    (r"at night", "at night"),
    (r"in the morning", "in the morning"),
]


@dataclass
class SymptomAnalysis:
    """Structured, conservative interpretation of the patient's words."""

    symptom_ids: List[str] = field(default_factory=list)
    symptom_labels: List[str] = field(default_factory=list)
    red_flags: List[str] = field(default_factory=list)
    duration: str = ""
    duration_days: Optional[float] = None
    severity: str = "unknown"  # mild | moderate | severe | unknown
    onset: str = ""
    frequency: str = ""
    worsening: bool = False
    context: List[str] = field(default_factory=list)


def _match_longest(text: str, phrases: List[str]) -> bool:
    """True if any phrase (longest-first) appears literally in text."""
    for phrase in sorted(phrases, key=len, reverse=True):
        if phrase in text:
            return True
    return False


def analyze(text: str, selected_ids: Optional[List[str]] = None) -> SymptomAnalysis:
    """Extract a structured analysis from free text + icon selections.

    Args:
        text: The patient's description (may be empty).
        selected_ids: Canonical symptom ids the patient picked from the icon
            grid (always trusted, even if not repeated in the text).
    """
    selected_ids = [s for s in (selected_ids or []) if s in SYMPTOM_CATALOGUE]
    normalized = (text or "").lower()

    analysis = SymptomAnalysis()

    # --- Symptoms mentioned in text ---------------------------------------
    text_ids: List[str] = []
    for sid, meta in SYMPTOM_CATALOGUE.items():
        keywords = [k.lower() for k in meta["keywords"]]
        if _match_longest(normalized, keywords):
            text_ids.append(sid)

    # Merge: text mentions first, then icon selections (de-duplicated).
    merged: List[str] = []
    for sid in text_ids + selected_ids:
        if sid not in merged:
            merged.append(sid)
    analysis.symptom_ids = merged
    analysis.symptom_labels = [
        str(SYMPTOM_CATALOGUE[sid]["label"]) for sid in merged
    ]

    # --- Red flags (literal matches only) ----------------------------------
    for flag_id, meta in RED_FLAG_PHRASES.items():
        phrases = [p.lower() for p in meta["phrases"]]
        if _match_longest(normalized, phrases):
            analysis.red_flags.append(str(meta["label"]))

    # --- Duration ----------------------------------------------------------
    for pattern, fmt, unit_idx in _DURATION_PATTERNS:
        m = re.search(pattern, normalized)
        if not m or m.lastindex is None:
            continue
        if m.lastindex >= 2:
            # Multi-group patterns: group 2 is the numeric value.
            value = m.group(2)
            unit = m.group(3) if m.lastindex >= 3 else ""
            try:
                days = float(value) * _UNIT_DAYS[unit_idx]
            except (ValueError, KeyError, TypeError):
                days = None
        else:
            # Single-group patterns such as "a (day|week|month) ago".
            unit = m.group(1)
            value = unit
            days = {"day": 1.0, "week": 7.0, "month": 30.0}.get(unit)
        analysis.duration = fmt.format(v=value, u=unit).replace("  ", " ")
        analysis.duration_days = days
        break
    if not analysis.duration:
        for pattern, display, days in _DURATION_PHRASES:
            if re.search(pattern, normalized):
                analysis.duration = display
                analysis.duration_days = days
                break

    # --- Severity ----------------------------------------------------------
    for pattern, label in _SEVERITY_PATTERNS:
        if re.search(pattern, normalized):
            analysis.severity = label
            break

    # --- Onset -------------------------------------------------------------
    for pattern, label in _ONSET_PATTERNS:
        if re.search(pattern, normalized):
            analysis.onset = label
            break

    # --- Frequency ---------------------------------------------------------
    for pattern, label in _FREQUENCY_PATTERNS:
        if re.search(pattern, normalized):
            analysis.frequency = label
            break

    # --- Worsening ---------------------------------------------------------
    analysis.worsening = any(
        re.search(p, normalized) for p in _WORSENING_PATTERNS
    )

    # --- Context -----------------------------------------------------------
    for pattern, label in _CONTEXT_PHRASES:
        if re.search(pattern, normalized):
            analysis.context.append(label)

    return analysis
