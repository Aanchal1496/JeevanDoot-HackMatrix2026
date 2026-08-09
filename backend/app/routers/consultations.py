"""Consultation endpoints: session lifecycle, ICE/TURN config, and the
WebSocket signaling server that coordinates WebRTC between patient and doctor.

Media (audio/video) never travels through this backend - only signaling
(SDP offers/answers, ICE candidates, presence, call events, chat) does.
"""
import os
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect

from ..db import get_connection
from ..schemas import ConsultationCreate, ConsultationEnd

router = APIRouter(prefix="/api/consultations", tags=["consultations"])

# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------


def _auth_user(conn, token: str):
    """Resolve a bearer token to (role, user_id) or raise 401."""
    row = conn.execute(
        "SELECT role, user_id FROM auth_tokens WHERE token = ?", (token,)
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    return row["role"], row["user_id"]


def _authorize_consultation(conn, consultation_id: str, role: str, user_id: str) -> dict:
    """Return the consultation row only if the user may access it."""
    row = conn.execute(
        "SELECT * FROM consultations WHERE id = ?", (consultation_id,)
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Consultation not found.")
    data = dict(row)
    if role == "patient" and data["patient_id"] != user_id:
        raise HTTPException(status_code=403, detail="You are not authorized for this consultation.")
    if role == "doctor" and data["doctor_id"] != user_id:
        raise HTTPException(status_code=403, detail="You are not authorized for this consultation.")
    return data


def _consultation_payload(row: dict) -> dict:
    return {
        "id": row["id"],
        "appointment_id": row["appointment_id"],
        "patient_id": row["patient_id"],
        "doctor_id": row["doctor_id"],
        "status": row["status"],
        "started_at": row["started_at"],
        "ended_at": row["ended_at"],
        "duration_seconds": row["duration_seconds"],
        "connection_quality": row["connection_quality"],
    }


# ---------------------------------------------------------------------------
# TURN / ICE configuration
# ---------------------------------------------------------------------------

_DEFAULT_STUN = ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"]


@router.get("/turn-config")
def turn_config(token: str = ""):
    """ICE server list for WebRTC peer connections.

    TURN credentials come from environment variables and are NEVER baked into
    the Flutter app. When unset, public STUN servers are used (works for most
    networks; strict NATs need a real TURN provider).
    """
    if not token:
        raise HTTPException(status_code=401, detail="Missing token.")
    conn = get_connection()
    try:
        _auth_user(conn, token)
    finally:
        conn.close()

    ice_servers = [{"urls": _DEFAULT_STUN}]
    turn_url = os.environ.get("TURN_SERVER_URL", "").strip()
    turn_user = os.environ.get("TURN_USERNAME", "").strip()
    turn_cred = os.environ.get("TURN_CREDENTIAL", "").strip()
    if turn_url and turn_user and turn_cred:
        ice_servers.append(
            {"urls": turn_url, "username": turn_user, "credential": turn_cred}
        )
    return {"ice_servers": ice_servers, "turn_enabled": len(ice_servers) > 1}


# ---------------------------------------------------------------------------
# REST: session lifecycle
# ---------------------------------------------------------------------------


@router.post("")
def create_consultation(payload: ConsultationCreate, token: str = ""):
    """Create (or return the existing) consultation for an appointment.

    Only the patient on the appointment or the doctor assigned to it may
    create/join. The consultation is idempotent per appointment.
    """
    if not token:
        raise HTTPException(status_code=401, detail="Missing token.")
    conn = get_connection()
    try:
        role, user_id = _auth_user(conn, token)
        existing = conn.execute(
            "SELECT * FROM consultations WHERE appointment_id = ?",
            (payload.appointment_id,),
        ).fetchone()
        if existing is not None:
            data = dict(existing)
            _authorize_consultation(conn, data["id"], role, user_id)
            return {"consultation": _consultation_payload(data)}

        appt = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (payload.appointment_id,)
        ).fetchone()
        if appt is None:
            raise HTTPException(status_code=404, detail="Appointment not found.")
        appt_data = dict(appt)

        doctor_id = appt_data.get("doctor_id") or "DR-PRIYA"
        if role == "patient" and appt_data["patient_id"] != user_id:
            raise HTTPException(status_code=403, detail="You are not authorized for this appointment.")
        if role == "doctor" and user_id != doctor_id:
            raise HTTPException(status_code=403, detail="You are not authorized for this appointment.")

        cid = "CONS-" + uuid.uuid4().hex[:6].upper()
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            """INSERT INTO consultations
               (id, appointment_id, patient_id, doctor_id, scheduled_start,
                scheduled_end, status, started_at)
               VALUES (?,?,?,?,?,?,?,?)""",
            (
                cid,
                appt_data["id"],
                appt_data["patient_id"],
                doctor_id,
                appt_data.get("date_label") or "",
                appt_data.get("time") or "",
                "WAITING",
                now,
            ),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM consultations WHERE id = ?", (cid,)
        ).fetchone()
        return {"consultation": _consultation_payload(dict(row))}
    finally:
        conn.close()


@router.get("/{consultation_id}")
def get_consultation(consultation_id: str, token: str = ""):
    if not token:
        raise HTTPException(status_code=401, detail="Missing token.")
    conn = get_connection()
    try:
        role, user_id = _auth_user(conn, token)
        data = _authorize_consultation(conn, consultation_id, role, user_id)
        return {"consultation": _consultation_payload(data)}
    finally:
        conn.close()


@router.post("/{consultation_id}/end")
def end_consultation(
    consultation_id: str, payload: ConsultationEnd, token: str = ""
):
    """Mark a consultation COMPLETED and record duration + quality summary.

    Does NOT delete anything - the consultation record (without any media) is
    the durable artifact. Recording audio/video is intentionally out of scope.
    """
    if not token:
        raise HTTPException(status_code=401, detail="Missing token.")
    conn = get_connection()
    try:
        role, user_id = _auth_user(conn, token)
        _authorize_consultation(conn, consultation_id, role, user_id)
        now = datetime.now(timezone.utc).isoformat()
        conn.execute(
            """UPDATE consultations
               SET status = 'COMPLETED', ended_at = ?, duration_seconds = ?,
                   connection_quality = ?
               WHERE id = ?""",
            (
                now,
                payload.duration_seconds if payload.duration_seconds is not None else 0,
                payload.connection_quality or "",
                consultation_id,
            ),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM consultations WHERE id = ?", (consultation_id,)
        ).fetchone()
        return {"consultation": _consultation_payload(dict(row))}
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# WebSocket signaling
# ---------------------------------------------------------------------------

_rooms: dict[str, dict[str, WebSocket]] = {}


async def _signaling_send(ws: WebSocket, message: dict) -> None:
    try:
        await ws.send_json(message)
    except Exception:
        pass


async def _broadcast_room(room_id: str, message: dict, exclude: str | None = None) -> None:
    room = _rooms.get(room_id)
    if not room:
        return
    for uid, ws in list(room.items()):
        if uid == exclude:
            continue
        await _signaling_send(ws, message)


@router.websocket("/{consultation_id}/signaling")
async def signaling(websocket: WebSocket, consultation_id: str):
    """Authenticated WebSocket signaling for a single consultation.

    Events (client -> server):
        OFFER / ANSWER / ICE_CANDIDATE   (relayed to the peer)
        MEDIA_STATE_CHANGED              {mic_on, camera_on}
        CONNECTION_STATE_CHANGED         {state}
        CHAT                             {message}
        LEAVE_ROOM / CALL_ENDED
    Events (server -> client):
        JOINED {consultation_id, role, user_id, peer_present}
        USER_JOINED / USER_LEFT {role, user_id}
        ROOM_CLOSED
    """
    token = websocket.query_params.get("token", "")
    conn = get_connection()
    try:
        row = conn.execute(
            "SELECT role, user_id FROM auth_tokens WHERE token = ?", (token,)
        ).fetchone()
    finally:
        conn.close()
    if row is None:
        await websocket.close(code=4401)
        return
    role, user_id = row["role"], row["user_id"]

    conn = get_connection()
    try:
        consult = conn.execute(
            "SELECT * FROM consultations WHERE id = ?", (consultation_id,)
        ).fetchone()
    finally:
        conn.close()
    if consult is None:
        await websocket.close(code=4404)
        return
    consult = dict(consult)
    if role == "patient" and consult["patient_id"] != user_id:
        await websocket.close(code=4403)
        return
    if role == "doctor" and consult["doctor_id"] != user_id:
        await websocket.close(code=4403)
        return

    await websocket.accept()

    room = _rooms.setdefault(consultation_id, {})
    # A reconnect replaces the stale connection instead of duplicating it.
    room[user_id] = websocket
    peers = [u for u in room if u != user_id]

    await _signaling_send(
        websocket,
        {
            "type": "JOINED",
            "consultation_id": consultation_id,
            "role": role,
            "user_id": user_id,
            "peer_present": bool(peers),
        },
    )
    await _broadcast_room(
        consultation_id,
        {"type": "USER_JOINED", "role": role, "user_id": user_id},
        exclude=user_id,
    )

    try:
        while True:
            message = await websocket.receive_json()
            mtype = message.get("type")
            if mtype in ("OFFER", "ANSWER", "ICE_CANDIDATE", "CHAT"):
                await _broadcast_room(
                    consultation_id,
                    {**message, "from": user_id, "role": role},
                    exclude=user_id,
                )
            elif mtype in ("MEDIA_STATE_CHANGED", "CONNECTION_STATE_CHANGED"):
                await _broadcast_room(
                    consultation_id,
                    {**message, "from": user_id, "role": role},
                    exclude=user_id,
                )
            elif mtype == "CALL_ENDED":
                await _broadcast_room(
                    consultation_id,
                    {"type": "CALL_ENDED", "from": user_id, "role": role},
                    exclude=user_id,
                )
                break
            elif mtype == "LEAVE_ROOM":
                break
            # Unknown types are ignored silently.
    except WebSocketDisconnect:
        pass
    finally:
        # Only remove this socket if it is still the room's entry for the user.
        # A reconnecting client replaces room[user_id] with a fresh socket; the
        # stale coroutine must not evict the new connection when it closes.
        if room.get(user_id) is websocket:
            room.pop(user_id, None)
        if not room:
            _rooms.pop(consultation_id, None)
        await _broadcast_room(
            consultation_id, {"type": "USER_LEFT", "role": role, "user_id": user_id}
        )
