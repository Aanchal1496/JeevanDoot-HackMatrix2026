"""Tests for the consultation REST endpoints + WebSocket signaling.

Run:  .venv/Scripts/python consultation_tests.py
"""
import os
from fastapi.testclient import TestClient

os.environ.setdefault("JEEVANDOOT_DB", os.path.join(os.path.dirname(__file__), "test_consult.db"))
if os.path.exists(os.environ["JEEVANDOOT_DB"]):
    os.remove(os.environ["JEEVANDOOT_DB"])

from app.main import app  # noqa: E402
from app.db import init_db  # noqa: E402
from app.seed import seed_if_empty  # noqa: E402

init_db()
seed_if_empty()
client = TestClient(app)
failures = []


def check(name, cond, detail=""):
    status = "PASS" if cond else "FAIL"
    print(f"[{status}] {name} {detail}")
    if not cond:
        failures.append(name)


def patient_token() -> str:
    r = client.post("/api/auth/request-otp", json={"phone": "9876543210"})
    assert r.status_code == 200
    r = client.post("/api/auth/verify-otp", json={"phone": "9876543210", "otp": "123456"})
    assert r.status_code == 200, r.text
    return r.json()["token"]


def doctor_token() -> str:
    r = client.post("/api/auth/doctor-login", json={"medical_id": "DR-PRIYA", "password": "doctor123"})
    assert r.status_code == 200, r.text
    return r.json()["token"]


# ---- 1. TURN config requires auth ---------------------------------------
r = client.get("/api/consultations/turn-config")
check("T1 turn-config without token -> 401", r.status_code == 401, f"got {r.status_code}")

ptok = patient_token()
r = client.get(f"/api/consultations/turn-config?token={ptok}")
check("T2 turn-config with token -> 200 + STUN", r.status_code == 200 and r.json().get("ice_servers"), str(r.json())[:120])

# ---- 2. Create consultation from an appointment ---------------------------
r = client.post(
    "/api/consultations",
    json={"appointment_id": "APT-1", "requester_role": "patient"},
    params={"token": ptok},
)
check("T3 patient creates consultation -> 200", r.status_code == 200, r.text[:120])
consultation = r.json()["consultation"]
cid = consultation["id"]
check("T4 consultation WAITING w/ patient+doctor", consultation["status"] == "WAITING" and consultation["patient_id"] == "PT-RAMESH" and consultation["doctor_id"] == "DR-PRIYA", str(consultation))

r2 = client.post(
    "/api/consultations",
    json={"appointment_id": "APT-1", "requester_role": "patient"},
    params={"token": ptok},
)
check("T5 create is idempotent", r2.json()["consultation"]["id"] == cid)

# ---- 3. Authorization ------------------------------------------------------
r = client.get(f"/api/consultations/{cid}")
check("T6 get without token -> 401", r.status_code == 401, f"got {r.status_code}")

dtok = doctor_token()
r = client.get(f"/api/consultations/{cid}", params={"token": dtok})
check("T7 doctor can read consultation -> 200", r.status_code == 200, r.text[:100])

# ---- 4. End consultation ---------------------------------------------------
r = client.post(
    f"/api/consultations/{cid}/end",
    json={"duration_seconds": 754, "connection_quality": "POOR"},
    params={"token": dtok},
)
check("T8 end -> COMPLETED + duration", r.status_code == 200 and r.json()["consultation"]["status"] == "COMPLETED" and r.json()["consultation"]["duration_seconds"] == 754, r.text[:120])

# ---- 5. WebSocket signaling: patient + doctor relay ------------------------
cid2 = client.post(
    "/api/consultations",
    json={"appointment_id": "APT-3", "requester_role": "patient"},
    params={"token": ptok},
).json()["consultation"]["id"]

with client.websocket_connect(f"/api/consultations/{cid2}/signaling?token={ptok}") as pws:
    joined_p = pws.receive_json()
    check("T9 patient JOINED event", joined_p["type"] == "JOINED" and joined_p["peer_present"] is False, str(joined_p)[:100])
    with client.websocket_connect(f"/api/consultations/{cid2}/signaling?token={dtok}") as dws:
        joined_d = dws.receive_json()
        check("T10 doctor JOINED event", joined_d["type"] == "JOINED" and joined_d["peer_present"] is True, str(joined_d)[:100])
        user_joined = pws.receive_json()
        check("T11 patient sees USER_JOINED", user_joined["type"] == "USER_JOINED" and user_joined["role"] == "doctor", str(user_joined)[:100])
        pws.send_json({"type": "OFFER", "sdp": "fake-sdp-patient"})
        offer = dws.receive_json()
        check("T12 OFFER relayed to doctor", offer["type"] == "OFFER" and offer["from"] == "PT-RAMESH", str(offer)[:120])
        dws.send_json({"type": "CHAT", "message": "Please check your temperature."})
        chat = pws.receive_json()
        check("T13 CHAT relayed to patient", chat["type"] == "CHAT" and chat["message"] == "Please check your temperature.", str(chat)[:120])
        dws.send_json({"type": "CALL_ENDED"})
        call_ended = pws.receive_json()
        check("T14 CALL_ENDED relayed", call_ended["type"] == "CALL_ENDED", str(call_ended)[:100])
        user_left = pws.receive_json()
        check("T15 USER_LEFT relayed", user_left["type"] == "USER_LEFT" and user_left["role"] == "doctor", str(user_left)[:100])

# ---- 6. Unauthorized WebSocket ---------------------------------------------
try:
    with client.websocket_connect(f"/api/consultations/{cid2}/signaling?token=bogus") as ws:
        ws.send_json({"type": "OFFER", "sdp": "x"})
        ws.receive_json()
        check("T16 bad token rejected", False, "server accepted a message from a bad token")
except Exception:
    check("T16 bad token rejected", True)

# ---- 7. CALL_ENDED is not echoed back to the sender -------------------------
cid3 = client.post(
    "/api/consultations",
    json={"appointment_id": "APT-2", "requester_role": "patient"},
    params={"token": ptok},
).json()["consultation"]["id"]
with client.websocket_connect(f"/api/consultations/{cid3}/signaling?token={ptok}") as pws2:
    pws2.receive_json()  # JOINED
    with client.websocket_connect(f"/api/consultations/{cid3}/signaling?token={dtok}") as dws2:
        dws2.receive_json()  # JOINED
        pws2.receive_json()  # USER_JOINED
        dws2.send_json({"type": "CALL_ENDED"})
        # The doctor (sender) must NOT receive its own CALL_ENDED echo.
        # The patient receives CALL_ENDED then USER_LEFT.
        import threading
        echo_box = {}
        def _try_recv():
            try:
                echo_box["msg"] = dws2.receive_json()
            except Exception as exc:  # server closed the socket -> no echo
                echo_box["closed"] = True
        t = threading.Thread(target=_try_recv, daemon=True)
        t.start()
        t.join(timeout=3)
        # The regression: the sender must receive NO message (no echo).
        # The old code delivered the sender's own CALL_ENDED back to it.
        check("T17 CALL_ENDED not echoed to sender", "msg" not in echo_box, str(echo_box)[:120])
        got = pws2.receive_json()
        check("T17 peer receives CALL_ENDED", got["type"] == "CALL_ENDED", str(got)[:80])
        got2 = pws2.receive_json()
        check("T18 USER_LEFT after CALL_ENDED", got2["type"] == "USER_LEFT", str(got2)[:80])

# ---- 8. Reconnect replaces stale socket without evicting the new one ---------
cid4 = client.post(
    "/api/consultations",
    json={"appointment_id": "APT-3", "requester_role": "patient"},
    params={"token": ptok},
).json()["consultation"]["id"]
# First patient socket (will be replaced).
with client.websocket_connect(f"/api/consultations/{cid4}/signaling?token={ptok}") as pws3:
    pws3.receive_json()  # JOINED
    # Patient reconnects with a second socket - this replaces the first.
    with client.websocket_connect(f"/api/consultations/{cid4}/signaling?token={ptok}") as pws4:
        joined4 = pws4.receive_json()
        check("T19 reconnect gets JOINED peer_present False", joined4["type"] == "JOINED" and joined4["peer_present"] is False, str(joined4)[:80])
        # Doctor joins while the patient's SECOND socket is live.
        with client.websocket_connect(f"/api/consultations/{cid4}/signaling?token={dtok}") as dws4:
            dws4.receive_json()  # JOINED (peer present = True)
            pws4.receive_json()  # USER_JOINED
            # Send a chat from doctor -> must reach the patient's new socket.
            dws4.send_json({"type": "CHAT", "message": "reconnect-test"})
            chat = pws4.receive_json()
            check("T20 chat reaches new patient socket", chat["type"] == "CHAT" and chat["message"] == "reconnect-test", str(chat)[:80])
    # First socket context exits here; if the stale-socket cleanup bug existed,
    # it would have popped the NEW socket and the doctor's USER_LEFT would be
    # lost. Doctor still receives USER_LEFT from the patient's new socket close.

print()
if failures:
    print(f"FAILED: {len(failures)}: {failures}")
    raise SystemExit(1)
print("All consultation tests passed.")
