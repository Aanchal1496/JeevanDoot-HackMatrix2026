"""Optional AI explanation service (OpenAI-compatible chat completions).

The AI NEVER computes the risk score or the risk level - those always come
from the deterministic triage engine (triage_engine.py). The AI is only
allowed to reword the plain-language summary and explanation.

Configuration comes from the environment (.env file):

    AI_API_KEY      API key (e.g. a Groq API key)
    AI_BASE_URL     OpenAI-compatible base URL, default Groq
    AI_MODEL        Model name, default llama-3.3-70b-versatile

If no key is configured, or the request fails or times out, the backend
silently falls back to the built-in template explanations. A risk score is
never fabricated.

Privacy: patient symptom text is sent only to the configured AI endpoint
when a key is present, and it is never written to logs.
"""
import json
import os
import urllib.error
import urllib.request
from typing import Dict, List, Optional

try:  # optional dependency - the engine works without it
    from dotenv import load_dotenv

    load_dotenv()
    _HAS_DOTENV = True
except ImportError:  # pragma: no cover
    _HAS_DOTENV = False

AI_API_KEY = os.environ.get("AI_API_KEY", "").strip()
AI_BASE_URL = os.environ.get(
    "AI_BASE_URL", "https://api.groq.com/openai/v1"
).rstrip("/")
AI_MODEL = os.environ.get("AI_MODEL", "llama-3.3-70b-versatile")
AI_TIMEOUT_SECONDS = float(os.environ.get("AI_TIMEOUT_SECONDS", "10"))

_SYSTEM_PROMPT = (
    "You are a cautious health-information assistant inside a symptom "
    "triage app. You are given the deterministic risk level and risk score "
    "computed by the app's safety engine, which you MUST NOT change or "
    "contradict. Your only job is to reword a plain-language explanation "
    "and a one-line summary for a patient.\n"
    "Rules:\n"
    "- Never claim to diagnose a disease. Say causes are not known and the "
    "tool cannot diagnose.\n"
    "- Never reassure a HIGH risk patient that they are safe; emphasize that "
    "urgent medical attention may be needed.\n"
    "- Use simple words, short sentences, no medical jargon.\n"
    "- Do not mention medicines or doses.\n"
    "- Do not invent symptoms or facts.\n"
    "- Respond ONLY with a JSON object of the form "
    '{"summary": "one line", "explanation": "2-3 sentences"}.'
)


def ai_enabled() -> bool:
    """True when an AI key is configured and the service may be called."""
    return bool(AI_API_KEY)


def generate_explanation(
    *,
    symptoms: List[str],
    duration: str,
    severity: str,
    red_flags: List[str],
    risk_level: str,
    risk_score: int,
    factors: List[str],
) -> Optional[Dict[str, str]]:
    """Ask the AI to reword the explanation. Returns None on any failure.

    The caller must fall back to the template explanation when None.
    """
    if not ai_enabled():
        return None

    context = {
        "risk_level": risk_level,
        "risk_score": risk_score,
        "detected_symptoms": symptoms,
        "duration": duration or "not specified",
        "severity": severity or "not specified",
        "red_flags": red_flags,
        "scoring_factors": factors,
    }
    user_prompt = (
        "Reword the explanation and one-line summary for this patient. "
        f"Context (already computed, do not change the risk level or score): "
        f"{json.dumps(context, ensure_ascii=False)}\n"
        'Return only JSON: {"summary": "...", "explanation": "..."}.'
    )

    payload = {
        "model": AI_MODEL,
        "messages": [
            {"role": "system", "content": _SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": 0.3,
        "max_tokens": 250,
        "response_format": {"type": "json_object"},
    }

    # A browser-like User-Agent is required: Groq's edge (Cloudflare) rejects
    # plain urllib user agents with HTTP 403 / error code 1010.
    _USER_AGENT = (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
    )
    request = urllib.request.Request(
        f"{AI_BASE_URL}/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {AI_API_KEY}",
            "User-Agent": _USER_AGENT,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=AI_TIMEOUT_SECONDS) as resp:
            body = json.loads(resp.read().decode("utf-8"))
        content = body["choices"][0]["message"]["content"]
        parsed = json.loads(content)
        summary = str(parsed.get("summary", "")).strip()[:300]
        explanation = str(parsed.get("explanation", "")).strip()[:600]
        if not summary or not explanation:
            return None
        return {"summary": summary, "explanation": explanation}
    except (
        urllib.error.URLError,
        KeyError,
        IndexError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
        TimeoutError,
    ):
        # Fail safe: the deterministic engine already produced an answer.
        return None
