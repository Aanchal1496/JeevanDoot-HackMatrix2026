import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.analysis import analyze
from app.database import get_db
from app.models import TriageRecord, User
from app.normalizer import normalize_input
from app.routers.auth import get_current_user
from app.schemas import (
    SymptomCheckRequest,
    SymptomCheckResponse,
    TriageRequest,
    TriageResponse,
)

router = APIRouter(prefix="/symptom-check", tags=["triage"])

logger = logging.getLogger("jeevandoot.symptom_check")

# Backward-compatible alias router (older clients use /api/triage).
triage_router = APIRouter(prefix="/triage", tags=["triage"])


@router.post("", response_model=SymptomCheckResponse)
def run_symptom_check(
    payload: SymptomCheckRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    logger.info(
        "symptom check input_type=%s raw_symptoms=%s raw_text_len=%d severity=%s duration=%s",
        payload.input_type,
        payload.symptoms,
        len(payload.text),
        payload.severity,
        payload.duration,
    )

    if not payload.text and not payload.symptoms:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Please enter or select at least one symptom.",
        )

    # Deterministic extraction + normalization (no LLM involvement).
    normalized = normalize_input(
        payload.symptoms,
        payload.text,
        severity=payload.severity,
        duration=payload.duration,
    )
    logger.info(
        "normalized symptoms=%s severity=%s duration=%s",
        normalized["symptoms"],
        normalized["severity"],
        normalized["duration"],
    )

    if not normalized["symptoms"]:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="We couldn't identify any symptoms in what you entered. Please try again.",
        )

    try:
        result = analyze(
            normalized["symptoms"],
            severity=normalized["severity"],
            duration=normalized["duration"],
        )
    except Exception:
        logger.exception("analysis failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to analyze your symptoms right now. Please try again.",
        )

    db.add(
        TriageRecord(
            user_id=user.id,
            symptoms=", ".join(s["name"] for s in result["symptoms"]),
            level=result["risk_level"],
            advice=result["explanation"],
        )
    )
    db.commit()
    return SymptomCheckResponse(**result)


@triage_router.post("", response_model=SymptomCheckResponse)
def run_triage_legacy(
    payload: TriageRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return run_symptom_check(
        SymptomCheckRequest(symptoms=payload.symptoms),
        db=db,
        user=user,
    )