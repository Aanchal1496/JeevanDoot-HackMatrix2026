"""End-to-end smoke test for the prescription writer (run against a live server)."""
import json
import sqlite3
import sys
import urllib.request

BASE = "http://127.0.0.1:8020"


def call(method, path, body=None, token=None, raw=False):
    req = urllib.request.Request(BASE + path, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    data = json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(req, data=data) as resp:
            if raw:
                return resp.read()
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode()[:300]}


ok = True


def check(label, cond, detail=""):
    global ok
    status = "PASS" if cond else "FAIL"
    if not cond:
        ok = False
    print(f"[{status}] {label} {detail}")


# 1. Login as doctor
login = call("POST", "/api/auth/doctor-login",
             {"medical_id": "DR-PRIYA", "password": "doctor123"})
token = login.get("token", "")
check("doctor login", bool(token))

# 2. Common medicines (configurable quick select)
common = call("GET", "/api/doctor/medicines/common", token=token)
names = [m["name"] for m in common.get("medicines", [])]
check("common medicines configured", len(names) > 3, str(names))
check("paracetamol in quick select", "Paracetamol" in names)

# 3. Medicine search by generic prefix
search = call("GET", "/api/doctor/medicines?q=para", token=token)
found = [m["name"] for m in search.get("medicines", [])]
check("search 'para' returns medicines", any("aracetamol" in n for n in found), str(found))

# 4. Create draft for penicillin-allergic patient PT-9942 (Rahul Sharma)
draft = call("POST", "/api/doctor/prescriptions",
             {"patient_id": "PT-9942", "consultation_id": "CONS-DEMO"}, token=token)
rx = draft.get("prescription", {})
rx_id = rx.get("id", "")
check("draft created", bool(rx_id) and rx.get("status") == "DRAFT", rx_id)

# 5. Add Paracetamol (no allergy conflict)
item = call("POST", f"/api/doctor/prescriptions/{rx_id}/items", {
    "medicine_id": "1", "dose": "1 tablet", "frequency": "Twice daily",
    "duration": "3", "duration_unit": "days", "route": "Oral",
    "timing": "After food", "instructions": "Take with water.",
}, token=token)
warns = item.get("safety", {}).get("warnings", [])
check("paracetamol added", len(item.get("prescription", {}).get("medicines", [])) == 1)
check("no allergy warning for paracetamol", not warns, str(warns))

# 6. Add Amoxicillin -> allergy warning expected (penicillin family)
item2 = call("POST", f"/api/doctor/prescriptions/{rx_id}/items", {
    "medicine_id": "6", "dose": "1 capsule", "frequency": "Three times daily",
    "duration": "5", "duration_unit": "days", "route": "Oral",
}, token=token)
warns2 = item2.get("safety", {}).get("warnings", [])
kinds = [w.get("type") for w in warns2]
check("allergy warning for amoxicillin", "ALLERGY_WARNING" in kinds, str(warns2))

# 7. Add Paracetamol again -> duplicate warning
item3 = call("POST", f"/api/doctor/prescriptions/{rx_id}/items", {
    "medicine_id": "2", "dose": "1 tablet", "frequency": "Once daily",
    "duration": "2", "duration_unit": "days", "route": "Oral",
}, token=token)
warns3 = item3.get("safety", {}).get("warnings", [])
kinds3 = [w.get("type") for w in warns3]
check("duplicate warning on second paracetamol", "DUPLICATE_WARNING" in kinds3, str(warns3))

# 8. Autosave notes
saved = call("PATCH", f"/api/doctor/prescriptions/{rx_id}/notes",
             {"additional_instructions": "Rest and maintain hydration."}, token=token)
check("notes autosaved", "Rest and maintain hydration" in saved.get("prescription", {}).get("additional_instructions", ""))

# 9. Draft recovery (fresh GET)
recovered = call("GET", "/api/doctor/prescriptions/drafts?patient_id=PT-9942", token=token)
check("draft recovery returns draft", recovered.get("prescription", {}).get("id") == rx_id)
check("draft status still DRAFT", recovered.get("prescription", {}).get("status") == "DRAFT")

# 10. Issue
issued = call("POST", f"/api/doctor/prescriptions/{rx_id}/issue", {}, token=token)
check("prescription issued", issued.get("prescription", {}).get("status") == "ISSUED")
check("issued_at set", bool(issued.get("prescription", {}).get("issued_at")))

# 11. Edit after issue -> blocked
edit_attempt = call("PATCH", f"/api/doctor/prescriptions/{rx_id}/items/1",
                    {"dose": "2 tablets"}, token=token)
check("edit blocked after issue", edit_attempt.get("_http_error") in (400, 409),
      str(edit_attempt.get("_body", ""))[:120])

# 12. PDF
pdf = call("GET", f"/api/doctor/prescriptions/{rx_id}/pdf", token=token, raw=True)
check("PDF generated", isinstance(pdf, bytes) and pdf[:4] == b"%PDF", f"{len(pdf) if isinstance(pdf, bytes) else 'n/a'} bytes")
# PDF without token -> 401
pdf_unauth = call("GET", f"/api/doctor/prescriptions/{rx_id}/pdf")
check("PDF requires auth", pdf_unauth.get("_http_error") == 401)

# 13. Patient view sees only ISSUED
patient_rx = call("GET", "/api/prescriptions?patient_id=PT-9942")
patient_list = patient_rx.get("prescriptions", [])
check("patient sees issued prescription", any(p["id"] == rx_id for p in patient_list))
check("no drafts exposed to patient", all(p["status"] == "ISSUED" for p in patient_list))

# 14. Audit trail
conn = sqlite3.connect("app/jeevandoot.db")
actions = [r[0] for r in conn.execute(
    "SELECT action FROM prescription_audit_log WHERE prescription_id=? ORDER BY id", (rx_id,))]
conn.close()
for expected in ("DRAFT_CREATED", "MEDICINE_ADDED", "PRESCRIPTION_REVIEWED", "PRESCRIPTION_ISSUED"):
    check(f"audit {expected}", expected in actions)
check("audit has no duplicates of ISSUED", actions.count("PRESCRIPTION_ISSUED") == 1)

print("\n" + ("ALL SMOKE CHECKS PASSED" if ok else "SOME CHECKS FAILED"))
sys.exit(0 if ok else 1)
