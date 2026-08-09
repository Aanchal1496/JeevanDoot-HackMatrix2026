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
| POST | `/api/symptom-check` | AI symptom check: free text + icon selections -> risk score (LOW/MEDIUM/HIGH), explanation, precautions |
| GET | `/api/self-care` | Self-care advice list |
| GET | `/api/appointments/slots` | Available dates + time slots (legacy) |
| POST | `/api/appointments` | Book an appointment (legacy) |
| GET | `/api/appointments/mine?patient_id=...` | Patient's appointments (legacy) |
| GET | `/api/consultations/specialties` | Teleconsultation specialties |
| GET | `/api/consultations/doctors?specialty=&q=` | Doctors (filter by specialty / search) |
| GET | `/api/consultations/doctors/{id}/dates` | Bookable dates for a doctor (14 days) |
| GET | `/api/consultations/doctors/{id}/slots?date=YYYY-MM-DD` | Slots for a doctor/date (available/booked/unavailable) |
| POST | `/api/consultations/book` | Book a consultation (concurrency-safe; 409 on double booking) |
| GET | `/api/consultations/upcoming?patient_id=...` | Patient's upcoming consultations |
| GET | `/api/consultations/history?patient_id=...` | Patient's past consultations |
| GET | `/api/consultations/{id}?patient_id=...` | Single appointment detail |
| PATCH | `/api/consultations/{id}/cancel` | Cancel an appointment (releases slot) |
| PATCH | `/api/consultations/{id}/reschedule` | Reschedule an appointment |
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

## Optional AI explanations

The symptom checker is fully functional without any AI: symptom extraction,
red-flag detection and the risk score are deterministic and computed locally.
To get AI-polished plain-language explanations, copy `.env.example` to `.env`
and add a Groq (or any OpenAI-compatible) API key:

```env
AI_API_KEY=your_groq_api_key
AI_BASE_URL=https://api.groq.com/openai/v1
AI_MODEL=llama-3.3-70b-versatile
```

If the AI call fails or times out, the backend falls back to the built-in
template explanations. The AI can never change the risk score or level.

## Testing the symptom checker

Run the deterministic logic tests:

```bat
.venv\Scripts\python symptom_check_tests.py
```

Or exercise the endpoint directly:

```bat
curl -X POST http://localhost:8000/api/symptom-check ^
  -H "Content-Type: application/json" ^
  -d "{"text": "I have a mild headache since this morning."}"
```

## Notes

- CORS is wide open for development; tighten before production.
- Auth tokens are stored in SQLite for demo purposes. OTP is a static
  `123456` — replace with a real SMS provider before production.
