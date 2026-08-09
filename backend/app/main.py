"""JeevanDoot backend API entrypoint.

Run with:
    pip install -r requirements.txt
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import init_db
from .routers import (
    appointments,
    auth,
    consultations,
    doctor,
    health,
    prescriptions,
    profile,
)
from .seed import seed_if_empty, seed_teleconsultation


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    seed_if_empty()
    seed_teleconsultation()
    yield

app = FastAPI(
    title="JeevanDoot Backend",
    description="Health assistant API for the JeevanDoot Flutter app.",
    version="1.0.0",
    lifespan=lifespan,
)

# Allow the Flutter app (web/desktop/mobile) to call this API during development.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(health.router)
app.include_router(appointments.router)
app.include_router(consultations.router)
app.include_router(doctor.router)
app.include_router(prescriptions.router)
app.include_router(profile.router)


@app.get("/")
def root():
    return {
        "service": "JeevanDoot Backend",
        "docs": "/docs",
        "status": "running",
    }


@app.get("/api/health")
def health_check():
    return {"status": "ok"}
