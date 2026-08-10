# FEATURE_STATUS

Honest, dated status of each feature. Statuses are only marked **Tested** when covered
by the automated backend suite or verified manually end-to-end; **Wired** means the
Flutter UI calls the live backend API (compiles clean via `flutter analyze`) but has not
had automated coverage; **Placeholder** means static/mock data still exists.

Legend: ✅ Tested · 🔵 Wired (manual smoke) · 🟡 Partial/Manual · ⛔ Placeholder/Not done

---

## Backend — automated test coverage

Run: `.venv\Scripts\python.exe -m pytest -q` → **26 passed**

| Area | Status | Notes |
|------|--------|-------|
| Triage/analysis engine (`normalizer` + `analyze`) | ✅ Tested | deterministic scoring, red flags, uppercase risk |
| Auth + JWT + role-based access (`require_roles`) | ✅ Tested | 401 unauth, role enforcement |
| Family member ownership (cross-owner 403) | ✅ Tested | |
| Appointment double-booking (409) | ✅ Tested | unique slot enforcement |
| Prescriptions (verified-doctor-only: 201 / unverified 403) | ✅ Tested | |
| ASHA vitals + escalation | ✅ Tested | |
| Doctor queue (risk-sorted HIGH→LOW) | ✅ Tested | |
| Consultation record create (doctor for patient) | 🔵 Wired | new capability; no dedicated pytest yet |
| Notifications, audit log, general CRUD | 🟡 Partial | endpoints exist; not all covered by suite |

---

## Patient portal (Flutter)

| Feature | Status | Notes |
|---------|--------|-------|
| Login (patient) | 🔵 Wired | real `/auth/login`, `/auth/signup`, token saved |
| Family members (list / add) | 🔵 Wired | `GET/POST /family`, ownership enforced |
| My Appointments (list / cancel) | 🔵 Wired | `/appointments` |
| Book Consultation → `POST /appointments` | 🔵 Wired | loads real doctors, ISO schedule, loading/error |
| My Records (health records + vitals + prescriptions) | 🔵 Wired | `/patients/me/...`, live, pull-to-refresh |
| Notifications | 🔵 Wired | `/notifications`, mark-read |
| Symptom checker (icon / voice text) | 🔵 Wired | `/symptom-check`, offline-aware |
| Book via video/audio call UI | ⛔ Placeholder | WebRTC not configured; part of booking only |

---

## Doctor portal (Flutter)

| Feature | Status | Notes |
|---------|--------|-------|
| Patient queue (live, search, risk filter) | 🔵 Wired | `GET /doctors/queue` |
| Profile header (name / specialization) | 🔵 Wired | `GET /doctors/me` |
| New Prescription (add medicines → create) | 🔵 Wired | opens consultation + `POST /prescriptions` |
| Referral (urgency, facility → create) | 🔵 Wired | `POST /referrals`, valid enum |
| Dashboard (urgent case, next consult, stats) | 🔵 Wired | live `/doctors/queue` (highest-risk patient) |
| Doctor appointments tab | 🔵 Wired | live `GET /consultations` (+ patient names) |
| Consult tab (start/resume consultation) | 🔵 Wired | live queue with active/upcoming state |
| Video consult screen | ⛔ Placeholder | signaling/unconfigured |

---

## ASHA portal (Flutter)

| Feature | Status | Notes |
|---------|--------|-------|
| Portal entry (Patient/Doctor/ASHA login tabs) | 🔵 Wired | Patient signs in via `/auth`; Doctor & ASHA tabs currently route client-side without server-side auth |
| Dashboard (assigned families + pending count) | 🔵 Wired | `GET /asha/assignments` (+`/tasks`) |
| Record Vitals | 🔵 Wired | `POST /asha/patients/{id}/vitals`, assignment-guarded |
| Assisted Symptom Entry | 🔵 Wired | runs triage engine; HIGH auto-notifies |
| Escalate to Doctor | 🔵 Wired | URGENT referral + notifications |
| Tasks list UI with status transitions | ⛔ Placeholder | `PUT /asha/tasks/{id}` ready; no UI yet |

---

## Offline / Sync

| Feature | Status | Notes |
|---------|--------|-------|  
| `SyncQueue` (persisted, states, replay) | 🔵 Wired | `shared_preferences`, `/api/health` probe |
| Offline status screen (live) | 🔵 Wired | real queue contents + Sync Now |
| Offline-aware symptom check | 🔵 Wired | enqueues when unreachable; queued triage state |

---

## Diagnostics / external integrations (provisioned, not live)

| Item | Status | Notes |
|------|--------|-------|
| AI consultation summary | 🔵 Provisioned | env config + graceful fallback; not enabled |
| WebRTC video (signaling/TURN) | ⛔ Not live | needs `webrtc_signaling_url`/TURN creds |
| Push (FCM), SMS, IVR | ⛔ Not live | provider config in `.env.example` |
| Maps / nearest hospital | ⛔ Not live | needs `maps_api_key` |
| Emergency referral | 🟡 Partial | ASHA escalation live; nearest-hospital screen pending |

---

## Known remaining gaps
- ASHA tasks-list UI is still static (`PUT /asha/tasks/{id}` ready; list view pending).
- WebRTC/push/SMS/IVR/maps are config-only (no live provider credentials) — by design, they fall back gracefully rather than fake.
- No automated Flutter tests yet; UI wiring is at `flutter analyze` + manual-smoke level.