# JeevanDoot

A rural healthcare platform with three portals — **Patient**, **Doctor**, and **ASHA**
(village health worker) — plus offline-first support and a deterministic symptom
checker / triage engine.

Built on a **FastAPI + SQLAlchemy + SQLite** backend and a **Flutter** mobile client.

## Repository layout

```
backend/           FastAPI application
  app/             routes, models, schemas, engine, auth, audit, notifications
  tests/           pytest suite (analysis + role-flow E2E)
jeevandoot/        Flutter app
  lib/             ui screens, api services, models, theme, widgets, sync queue
```

## Backend

### Requirements
- Python 3.10+
- Dependencies in `backend/requirements.txt` (FastAPI, SQLAlchemy, SQLAlchemy-Utils,
  PyJWT, bcrypt, pytest, httpx, uvicorn)

### Run
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate            # Windows (PowerShell)
pip install -r requirements.txt
set PYTHONPATH=.
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The DB (`app/jeevandoot.db`, SQLite) is created and migrated idempotently on startup,
and seeded with demo accounts (see below).

### Environment
External services (AI summaries, WebRTC signaling, push, SMS/IVR, maps) are read from
`.env` (see `.env.example`). All are optional: when credentials are absent the related
features degrade gracefully instead of failing — nothing is faked.

### Demo accounts (seeded)
| Role   | Email                 | Password     |
|--------|-----------------------|--------------|
| Doctor | `doctor@jeevandoot.in`| `doctor123`  |
| ASHA   | `asha@jeevandoot.in`  | `asha@123`   |
| Patient| `rajesh@jeevandoot.in`| `rajesh@123` |

### Tests
```bash
cd backend
.venv\Scripts\python.exe -m pytest -q
```
The suite covers the triage/analysis engine and end-to-end role flows
(authentication, family ownership, double-booking prevention, verified-doctor
prescriptions, ASHA vitals + escalation).

## Flutter app

### Run
```bash
cd jeevandoot/jeevandoot
flutter pub get
# Point the app at your backend's LAN IP:
flutter run --dart-define=API_BASE_URL=http://<host-ip>:8000/api
```

Use the **Patient**, **Doctor**, or **ASHA** tab at login to open the matching portal.

See `FEATURE_STATUS.md` for what is implemented, wired end-to-end, and tested.