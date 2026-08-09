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

The Flutter app targets `http://localhost:8000` by default. If you run the
backend on a different host/port, override the base URL when launching the app:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8020
```

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
| GET | `/api/doctor/queue` | Risk-sorted queue (RED→YELLOW→GREEN) + summary counts |
| GET | `/api/doctor/patients` | Flat risk-sorted list of active patients |
| GET | `/api/doctor/patients/{id}` | Full patient case (triage, vitals, history, triage history) |
| GET | `/api/doctor/patients/{id}/case-file` | **Pre-consultation case file** (aggregated: summary, history, vitals, risk, flags, insights) — requires doctor Bearer token |
| POST | `/api/doctor/patients/{id}/case-file/generate` | Regenerate the case file from latest data (preserves doctor edits) |
| PATCH | `/api/doctor/patients/{id}/case-file/summary` | Save doctor-edited summary (original AI content preserved, audit logged) |
| POST | `/api/doctor/patients/{id}/triage/override` | Doctor triage override (records audit entry) |
| POST | `/api/doctor/patients/{id}/consultation/start` | WAITING → IN_CONSULTATION |
| POST | `/api/doctor/patients/{id}/consultation/complete` | IN_CONSULTATION → COMPLETED |
| GET | `/api/doctor/appointments` | Doctor's schedule |
| GET | `/api/doctor/stats` | Dashboard stats / urgent case / next consultation |
| GET | `/api/doctor/medicines?q=...` | Structured medicine catalog search (generic/brand/category/strength) |
| GET | `/api/doctor/medicines/common` | Configurable common-medicine quick-select set |
| POST | `/api/doctor/prescriptions` | Create (or reopen) a prescription draft for a patient |
| GET | `/api/doctor/prescriptions/{id}` | Fetch a prescription (review) |
| GET | `/api/doctor/prescriptions/drafts?patient_id=...` | Recover the patient's unfinished draft (404 if none) |
| GET | `/api/doctor/prescriptions/history?patient_id=...` | Issued prescription history (doctor view) |
| POST | `/api/doctor/prescriptions/{id}/items` | Add a medicine with dose/frequency/duration/route/timing/instructions; returns safety warnings (allergy / duplicate) |
| PATCH | `/api/doctor/prescriptions/{id}/items/{item_id}` | Update an item on a draft |
| DELETE | `/api/doctor/prescriptions/{id}/items/{item_id}` | Remove an item from a draft |
| PATCH | `/api/doctor/prescriptions/{id}/notes` | Autosave additional instructions (never issues) |
| POST | `/api/doctor/prescriptions/{id}/issue` | Issue the prescription (server revalidates everything; DRAFT → ISSUED) |
| GET | `/api/doctor/prescriptions/{id}/pdf` | Authenticated prescription PDF (reportlab) |
| GET | `/api/prescriptions?patient_id=...` | Patient's prescriptions (**ISSUED only**, never drafts) |
| POST | `/api/prescriptions` | Create a prescription (legacy patient-facing) |
| GET/PUT | `/api/profile?patient_id=...` | Read / update patient profile |
| GET | `/api/records?patient_id=...` | Patient records |
| GET | `/api/reminders?patient_id=...` | Patient reminders |
| POST | `/api/reminders/{id}/done` | Mark reminder done |
| POST | `/api/consultations` | Create (or return) the consultation for an appointment. Auth via `?token=...` |
| GET | `/api/consultations/{id}` | Fetch a consultation. Only patient/doctor of the appointment may read it |
| POST | `/api/consultations/{id}/end` | Mark a consultation COMPLETED, record duration + connection quality |
| GET | `/api/consultations/turn-config` | ICE server list (STUN + optional TURN) for the WebRTC peer connection |
| WS | `/api/consultations/{id}/signaling` | Authenticated WebSocket signaling (see below) |

## Teleconsultation (video/audio) — WebSocket signaling

Media never travels through this backend. WebRTC carries audio/video
peer-to-peer; the WebSocket below only exchanges signaling, presence and chat.

### WebSocket events

**Client -> server** (all relayed to the peer except `LEAVE_ROOM`/`CALL_ENDED`):

```json
{ "type": "JOIN_ROOM", "consultation_id": "CONS-ABC123", "user_id": "PT-123", "role": "patient" }
{ "type": "OFFER", "sdp": "..." }
{ "type": "ANSWER", "sdp": "..." }
{ "type": "ICE_CANDIDATE", "candidate": { "candidate": "...", "sdpMid": "0", "sdpMLineIndex": 0 } }
{ "type": "MEDIA_STATE_CHANGED", "mic_on": true, "camera_on": false }
{ "type": "CONNECTION_STATE_CHANGED", "state": "connected" }
{ "type": "CHAT", "message": "Please check your temperature." }
{ "type": "CALL_ENDED" }
{ "type": "LEAVE_ROOM" }
```

**Server -> client**:

```json
{ "type": "JOINED", "consultation_id": "CONS-ABC123", "role": "doctor", "user_id": "DR-PRIYA", "peer_present": true }
{ "type": "USER_JOINED", "role": "patient", "user_id": "PT-123" }
{ "type": "USER_LEFT", "role": "patient", "user_id": "PT-123" }
```

Auth: the socket URL must carry `?token=<auth-token>`. The server resolves the
role from the token — a caller-supplied `role`/`user_id` is never trusted. Only
the patient and doctor on the appointment can join (others get close code 4403).
A reconnecting client replaces its stale socket instead of creating duplicates.

### TURN configuration

Copy `.env.example` to `.env` and fill in the TURN vars when clients are behind
strict NATs. Without them the backend serves public STUN servers, which works
for most home/office networks. TURN credentials are served only to
authenticated clients via `/api/consultations/turn-config`.

```env
TURN_SERVER_URL=turn:your-turn.example.com:3478?transport=udp
TURN_USERNAME=user
TURN_CREDENTIAL=secret
```

In production use short-lived credentials (e.g. coturn REST API or a TURN
provider) and serve everything over HTTPS/wss.

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

## Testing

Run the deterministic logic tests:

```bat
.venv\Scripts\python symptom_check_tests.py
.venv\Scripts\python consultation_tests.py
```

Or exercise the endpoint directly:

```bat
curl -X POST http://localhost:8000/api/symptom-check ^
  -H "Content-Type: application/json" ^
  -d "{\"text\": \"I have a mild headache since this morning.\"}"
```

## Tests

```
python -m pytest tests/ -v
```

Covers triage level boundaries (85→RED, 55→YELLOW, 25→GREEN), safety
escalation, queue ordering (level → risk score → wait time), determinism, the
doctor-override contract, the pre-consultation case file (vital
interpretation, symptom extraction, no-fabrication rules, empty states,
doctor-edit preservation, risk propagation and auth 401/403), and the
prescription writer (add medicine, quick-select semantics, medicine search,
allergy flag, duplicate detection, draft recovery, review, issue, edit-after-
issue blocked, patient sees only ISSUED, PDF bytes, audit events).

## Notes

- The queue sorts on the backend: `RED > YELLOW > GREEN`, then highest risk
  score, then longest wait. Waiting time is derived from `arrival_time` and
  never stored.
- Triage is an assistive clinical decision-support feature; the UI always
  shows the AI's original assessment and every change is written to the
  `triage_history` audit table.
- The pre-consultation case file is an aggregated single-request endpoint
  (no N+1 page loads). Vital thresholds live only in `app/vitals.py`;
  symptom extraction, AI summary and flags are in `app/casefile.py` and never
  fabricate unreported clinical detail. Case-file actions are recorded in the
  `case_file_audit_log` table (`CASE_FILE_VIEWED`, `AI_SUMMARY_GENERATED`,
  `SUMMARY_EDITED`, `VITALS_UPDATED`, `RISK_UPDATED`).
- The prescription writer is a documentation/workflow tool, **not** an
  autonomous prescriber: quick-select only pre-fills the medicine form, every
  item must be explicitly configured and confirmed, only the issuing endpoint
  moves DRAFT → ISSUED, and issued prescriptions are immutable (edit blocked,
  never deleted). Safety checks are conservative: allergy conflicts are
  flagged for professional review (never blocking), duplicates are warned
  (never merged), and no drug-interaction claims are invented — interactions
  surface as "safety check unavailable". The medicine catalog, quick-select
  set and all thresholds are backend-configurable. Medicine snapshots are
  stored per item so history stays accurate. Prescription actions are audited
  in `prescription_audit_log` (`DRAFT_CREATED`, `MEDICINE_ADDED`,
  `MEDICINE_UPDATED`, `MEDICINE_REMOVED`, `PRESCRIPTION_REVIEWED`,
  `PRESCRIPTION_ISSUED`, `PRESCRIPTION_CANCELLED`,
  `PRESCRIPTION_SUPERSEDED`). PDFs require the doctor Bearer token.
- CORS is wide open for development; tighten before production.
- Auth tokens are stored in SQLite for demo purposes. OTP is a static
  `123456` — replace with a real SMS provider before production.
