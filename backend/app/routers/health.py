"""Health endpoints: triage assessment + self-care advice."""
from fastapi import APIRouter

from ..schemas import TriageRequest
from ..triage import ADVICE, run_triage

router = APIRouter(prefix="/api", tags=["health"])


@router.post("/triage")
def triage(payload: TriageRequest):
    return run_triage(payload.symptoms)


@router.get("/self-care")
def self_care():
    return {"advice": ADVICE["low"]}
