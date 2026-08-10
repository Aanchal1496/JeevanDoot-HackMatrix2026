from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.migrations import run_migrations
from app.routers import (
    appointments,
    asha,
    auth,
    consultations,
    demo,
    doctors,
    family,
    followups,
    notifications,
    patients,
    prescriptions,
    referrals,
    triage,
)

# Import models so tables are registered on Base.metadata.
from app import models  # noqa: F401
from app.seed import seed, seed_demo


@asynccontextmanager
async def lifespan(app: FastAPI):
    run_migrations()
    db = SessionLocal()
    try:
        seed(db)
        seed_demo(db)
    finally:
        db.close()
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(doctors.router, prefix=settings.api_prefix)
app.include_router(triage.router, prefix=settings.api_prefix)
app.include_router(triage.triage_router, prefix=settings.api_prefix)
app.include_router(consultations.router, prefix=settings.api_prefix)
app.include_router(family.router, prefix=settings.api_prefix)
app.include_router(patients.router, prefix=settings.api_prefix)
app.include_router(appointments.router, prefix=settings.api_prefix)
app.include_router(demo.router, prefix=settings.api_prefix)
app.include_router(prescriptions.router, prefix=settings.api_prefix)
app.include_router(referrals.router, prefix=settings.api_prefix)
app.include_router(followups.router, prefix=settings.api_prefix)
app.include_router(notifications.router, prefix=settings.api_prefix)
app.include_router(asha.router, prefix=settings.api_prefix)


@app.get("/api/health")
def health():
    return {"status": "ok", "app": settings.app_name}