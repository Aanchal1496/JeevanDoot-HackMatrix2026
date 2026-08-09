"""Runs the spec's test scenarios against the extractor + engine directly."""
import sys, json
sys.path.insert(0, 'app')

from app.symptom_extractor import analyze
from app.triage_engine import build_response, compute_risk

failures = []

def check(name, cond, detail=''):
    status = 'PASS' if cond else 'FAIL'
    print(f'[{status}] {name}' + (f' -- {detail}' if detail and not cond else ''))
    if not cond:
        failures.append(name)

# Test 1 - Low risk
r = build_response(analyze("I have a mild headache since this morning."))
check('T1 low risk level', r['risk_level'] == 'LOW', json.dumps({k: r[k] for k in ('risk_level','risk_score','symptoms')}))
check('T1 low score < 40', r['risk_score'] < 40, r['risk_score'])
check('T1 self-care precautions', len(r['precautions']) >= 3)
check('T1 no emergency', r['emergency'] is False)

# Test 2 - Medium risk
r = build_response(analyze("I have been vomiting repeatedly and feel very weak."))
check('T2 medium risk level', r['risk_level'] == 'MEDIUM', json.dumps({k: r[k] for k in ('risk_level','risk_score','symptoms')}))
check('T2 score in [40,75)', 40 <= r['risk_score'] < 75, r['risk_score'])
check('T2 seek medical attention', r['seek_medical_attention'] is True)
check('T2 warning signs present', len(r['warning_signs']) > 0)

# Test 3 - High risk
r = build_response(analyze("I have severe chest pain and difficulty breathing."))
check('T3 high risk level', r['risk_level'] == 'HIGH', json.dumps({k: r[k] for k in ('risk_level','risk_score','red_flags')}))
check('T3 score >= 80', r['risk_score'] >= 80, r['risk_score'])
check('T3 emergency true', r['emergency'] is True)
check('T3 red flag detected', len(r['red_flags']) > 0)

# Red-flag override: mild wording but red flag present must stay HIGH
r = build_response(analyze("I feel a little breathless since yesterday."))
check('T3b red-flag override', r['risk_level'] == 'HIGH' and r['risk_score'] >= 80, json.dumps({k: r[k] for k in ('risk_level','risk_score','symptoms')}))

# Test 5 - icon selection merged with text
r = build_response(analyze("I have a headache.", ['dizziness']))
check('T5 icons merged', set(r['symptoms']) == {'Headache', 'Dizziness'}, str(r['symptoms']))

# Spec example: headache + dizziness since morning -> MEDIUM
r = build_response(analyze("I have had a headache since morning and I feel slightly dizzy."))
check('T-example headache+dizziness MEDIUM', r['risk_level'] == 'MEDIUM', json.dumps({k: r[k] for k in ('risk_level','risk_score','symptoms','duration')}))

# No invented symptoms
r = build_response(analyze("I have been feeling strange all day."))
check('T7 no invented symptoms', r['symptoms'] == [], str(r['symptoms']))

# Extraction details: chest pain 20 minutes
a = analyze("I have had chest pain for 20 minutes and I'm having trouble breathing.")
check('T8 extraction symptoms', set(a.symptom_ids) == {'chest', 'breathing'}, str(a.symptom_ids))
check('T8 duration', a.duration == 'for 20 minutes', a.duration)
check('T8 red flags from text', len(build_response(a)['red_flags']) >= 2, str(build_response(a)['red_flags']))

# Regression: "a day ago" must not crash (single-group duration pattern)
a = analyze("I have had a cough for a day ago now.")
check('REG duration a day ago', a.duration == 'a day ago', a.duration)

# Regression: no symptoms in text but "other" icon only -> engine sees nothing
r = build_response(analyze("", ['other']))
check('REG other-only no invented symptoms', r['symptoms'] == [], str(r['symptoms']))

print()
if failures:
    print('FAILURES:', failures)
    sys.exit(1)
print('ALL BACKEND LOGIC TESTS PASSED')
