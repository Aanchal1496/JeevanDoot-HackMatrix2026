# JeevanDoot (Flutter Patient & Doctor App)

Patient and doctor app for JeevanDoot — includes symptom checking with voice
input, appointments, prescriptions, records, and **low-bandwidth
video/audio teleconsultations** (WebRTC).

## Teleconsultation feature

Patient and doctor can start a video/audio consultation from their upcoming
appointments. The call adapts to network conditions automatically so the
consultation survives poor mobile networks.

### Flow

```
Patient: home -> Join Consultation -> pick appointment
Doctor:  home -> Consultations tab -> pick appointment
   -> Device check (camera/mic/network)
   -> Waiting room (real-time presence via WebSocket)
   -> Consultation (WebRTC audio+video, adaptive quality)
   -> End call -> Consultation completed (doctor continues to notes/prescription)
```

### Low-bandwidth behaviour

- Starts at 640×360 @ 15 fps, then adapts via `getStats()` monitoring
  (packet loss, RTT, available bitrate, frames dropped).
- Quality levels: GOOD 360p → FAIR 240p → POOR 180p → CRITICAL video OFF.
  Bitrate is capped through WebRTC sender parameters (250–500 kbps standard,
  100–250 kbps data saver, 50–150 kbps very poor).
- **Audio is always prioritised over video** — video degrades first and is
  disabled before audio is ever reduced.
- Manual modes: Settings → Data Usage (Standard / Data Saver / Audio Only).
- Automatic reconnection with exponential backoff (1s, 2s, 4s, 8s, 16s,
  max 5 attempts); old connections are cleaned up before new ones are made.
- Network indicator + "Video quality reduced to keep your call connected"
  messages in plain language.

### Key files

```
lib/services/consultation_api_service.dart       REST calls + appointment mapping
lib/services/consultation_signaling_service.dart WebSocket client (auth + reconnect)
lib/services/network_quality_controller.dart     Adaptive quality / stats classifier
lib/services/webrtc_call_service.dart            Peer connection + media controls
lib/screens/consultation_hub_screen.dart         Upcoming consultation list (both roles)
lib/screens/consultation_device_check_screen.dart Pre-call device checks
lib/screens/consultation_waiting_room_screen.dart Waiting room with presence
lib/screens/consultation_screen.dart             Live call UI (controls/chat/settings)
lib/screens/consultation_completed_screen.dart   Post-call summary
```

### Dependencies added

- `flutter_webrtc` — WebRTC peer connection, media devices, stats.
- `web_socket_channel` — signaling WebSocket.
- `speech_to_text` — symptom checker voice input.

Android: `CAMERA` and `MODIFY_AUDIO_SETTINGS` permissions were added to
`android/app/src/main/AndroidManifest.xml`, and `minSdk` is 23+ (required by
flutter_webrtc). iOS: the app already declared `NSCameraUsageDescription` /
`NSMicrophoneUsageDescription`; verify they remain in `ios/Runner/Info.plist`.

## Backend

The backend is FastAPI + SQLite in the sibling `backend/` folder. Start it
before running the app:

```bash
cd backend && run.bat        # Windows
# or: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The app talks to `http://localhost:8000` (Android emulator uses
`http://10.0.2.2:8000` automatically). For a physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## TURN for strict networks

If consultations fail to connect on some mobile networks (NAT traversal), run a
TURN server and set `TURN_SERVER_URL`, `TURN_USERNAME`, `TURN_CREDENTIAL` in
`backend/.env`. The app fetches these at call time via
`/api/consultations/turn-config` — never hardcode credentials in the app.

## Testing

- `flutter analyze` — static analysis.
- `flutter test` — widget/model tests.
- Backend: `backend/consultation_tests.py` (REST + signaling, 16 scenarios)
  and `backend/symptom_check_tests.py`.
- Live smoke test: run the backend, then `backend/live_smoke.py`.
- Bandwidth behaviour: use a throttled network (Chrome DevTools/Android
  Network Profiler/`tc netem`) and watch the quality indicator degrade then
  recover.

## Privacy & security

- Consultations are never recorded; only the consultation record (duration,
  quality summary) is stored.
- No patient data in logs or analytics.
- WebSocket signaling validates the token and only allows the appointment's
  patient and doctor to join.
