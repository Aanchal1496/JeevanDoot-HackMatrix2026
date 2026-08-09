# JeevanDoot Backend

Python (FastAPI) backend for the JeevanDoot Flutter app. Data is stored in a
local SQLite database (`app/jeevandoot.db`) that is auto-created and seeded on
first startup.

## Quick start (Windows)

```bat
run.bat
```

Or manually:

```powershell
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API docs: http://localhost:8000/docs

## Demo credentials

| Role | Identifier | Password |
| ---- | ---------- | -------- |
| Patient | Any 10-digit mobile (e.g. `9876543210`) | OTP `123456` |
| Doctor | `DR-PRIYA` | `doctor123` |

## Endpoints

| Method | Path | Description |
| ------ | ---- | ----------- |
| POST | `/api/auth/request-otp` | Sends demo OTP for a phone number |
| POST | `/api/auth/verify-otp` | Verifies OTP, returns token + patient profile |
| POST | `/api/auth/doctor-login` | Doctor login, returns token + doctor profile |
| POST | `/api/auth/logout?token=...` | Invalidates a token |
| POST | `/api/triage` | Rule-based triage from symptom ids |
| GET | `/api/self-care` | Self-care advice list |
| GET | `/api/appointments/slots` | Available dates + time slots |
| POST | `/api/appointments` | Book an appointment |
| GET | `/api/appointments/mine?patient_id=...` | Patient's appointments |
| GET | `/api/doctor/patients` | Patient queue |
| GET | `/api/doctor/patients/{id}` | Full patient case (vitals + history) |
| GET | `/api/doctor/appointments` | Doctor's schedule |
| GET | `/api/doctor/stats` | Dashboard stats / urgent case / next consultation |
| GET | `/api/doctor/medicines?q=...` | Medicine search |
| GET | `/api/prescriptions?patient_id=...` | Patient's prescriptions |
| POST | `/api/prescriptions` | Create a prescription |
| GET/PUT | `/api/profile?patient_id=...` | Read / update patient profile |
| GET | `/api/records?patient_id=...` | Patient records |
| GET | `/api/reminders?patient_id=...` | Patient reminders |
| POST | `/api/reminders/{id}/done` | Mark reminder done |

## Notes

- CORS is wide open for development; tighten before production.
- Auth tokens are stored in SQLite for demo purposes. OTP is a static
  `123456` — replace with a real SMS provider before production.
