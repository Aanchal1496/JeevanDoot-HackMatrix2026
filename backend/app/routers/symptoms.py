"""Symptom-check endpoint: free text + icon selections -> risk assessment.

The backend performs all analysis itself. Risk scores produced by the
frontend are never trusted; the response is computed here from the
patient's words using the deterministic extractor + triage engine, with an
optional AI rewording of the explanation.
"""
from fastapi import APIRouter, HTTPException

from .. import ai_service
from ..schemas import SymptomCheckRequest
from ..symptom_extractor import SYMPTOM_CATALOGUE, analyze
from ..triage_engine import build_response

router = APIRouter(prefix="/api", tags=["symptom-check"])

MAX_TEXT_LENGTH = 5000


@router.post("/symptom-check")
def symptom_check(payload: SymptomCheckRequest):
    text = (payload.text or "").strip()
    # Only accept canonical symptom ids; ignore anything unknown.
    selected = [
        s.strip()
        for s in (payload.selected_symptoms or [])
        if s.strip() in SYMPTOM_CATALOGUE
    ]

    if not text and not selected:
        raise HTTPException(
            status_code=422,
            detail="Please describe at least one symptom.",
        )
    if len(text) > MAX_TEXT_LENGTH:
        raise HTTPException(
            status_code=422,
            detail="Please keep your description under 5000 characters.",
        )

    # Deterministic analysis + risk score (never from the AI).
    analysis = analyze(text, selected)
    response = build_response(analysis)

    # Optional: let the AI reword the explanation only. On any failure the
    # template explanation already present in the response is kept.
    if ai_service.ai_enabled():
        ai = ai_service.generate_explanation(
            symptoms=response["symptoms"],
            duration=response["duration"],
            severity=response["severity"],
            red_flags=response["red_flags"],
            risk_level=response["risk_level"],
            risk_score=response["risk_score"],
            factors=response["factors"],
        )
        if ai:
            response["summary"] = ai["summary"]
            response["explanation"] = ai["explanation"]

    return response
