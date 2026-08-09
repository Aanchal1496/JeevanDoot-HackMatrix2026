"""Live smoke test: patient + doctor over real HTTP + WebSocket."""
import asyncio, json, urllib.request
import websockets

BASE = 'http://127.0.0.1:8000'
WS = 'ws://127.0.0.1:8000'


def post(path, body, token=None, timeout=10):
    url = BASE + path + (f'?token={token}' if token else '')
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


async def main():
    print('STEP 1: auth')
    post('/api/auth/request-otp', {'phone': '9876543210'})
    ptok = post('/api/auth/verify-otp', {'phone': '9876543210', 'otp': '123456'})['token']
    dtok = post('/api/auth/doctor-login', {'medical_id': 'DR-PRIYA', 'password': 'doctor123'})['token']
    print('STEP 2: create consultation')
    cid = post('/api/consultations/session', {'appointment_id': 'APT-1', 'requester_role': 'patient'}, ptok)['consultation']['id']
    print(f'consultation {cid} created')

    print('STEP 3: patient WS')
    async with websockets.connect(f'{WS}/api/consultations/session/{cid}/signaling?token={ptok}', open_timeout=10) as p:
        joined_p = json.loads(await asyncio.wait_for(p.recv(), timeout=10))
        print('patient:', joined_p['type'], '| peer_present =', joined_p['peer_present'])
        print('STEP 4: doctor WS')
        async with websockets.connect(f'{WS}/api/consultations/session/{cid}/signaling?token={dtok}', open_timeout=10) as d:
            joined_d = json.loads(await asyncio.wait_for(d.recv(), timeout=10))
            print('doctor:', joined_d['type'], '| peer_present =', joined_d['peer_present'])
            user_joined = json.loads(await asyncio.wait_for(p.recv(), timeout=10))
            print('patient sees:', user_joined['type'])
            await p.send(json.dumps({'type': 'OFFER', 'sdp': 'live-sdp', 'candidate': None}))
            offer = json.loads(await asyncio.wait_for(d.recv(), timeout=10))
            print('doctor got:', offer['type'], '| sdp =', offer['sdp'], '| from =', offer['from'])
            await d.send(json.dumps({'type': 'ANSWER', 'sdp': 'live-answer'}))
            ans = json.loads(await asyncio.wait_for(p.recv(), timeout=10))
            print('patient got:', ans['type'], '| sdp =', ans['sdp'])
            await p.send(json.dumps({'type': 'CHAT', 'message': 'Hello doctor'}))
            chat = json.loads(await asyncio.wait_for(d.recv(), timeout=10))
            print('doctor got:', chat['type'], '| message =', chat['message'])
            await d.send(json.dumps({'type': 'CALL_ENDED'}))
            ended = json.loads(await asyncio.wait_for(p.recv(), timeout=10))
            print('patient got:', ended['type'], '| from =', ended['from'])
    print('LIVE SMOKE TEST PASSED')


asyncio.run(main())

