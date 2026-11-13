"""Validate traceability without claiming gameplay acceptance."""
import hashlib,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=(root/'PROJECT_SPEC.md').read_bytes()
data=json.loads((root/'docs/requirements.json').read_text())
assert data['specSha256']==hashlib.sha256(spec).hexdigest(), 'Specification changed: review requirement mapping'
items=data['requirements']
assert len({r['id'] for r in items})==len(items), 'Duplicate requirement ID'
assert {r['section'] for r in items}==set(range(1,21)), 'Missing specification section'
for r in items:
    assert r['requirement'] in spec.decode(), r['id']+' no longer matches specification'
    assert r['status'] in {'unverified','partial','absent','blocked','verified'}, r['id']
    assert re.fullmatch(r'H(?:[0-9]|10|11)',r['milestone']), r['id']
    if r['status']=='verified':
        assert r['evidence'], r['id']+' needs executed evidence'
        for evidence in r['evidence']:
            assert (root/evidence['path']).is_file(), r['id']+' evidence missing'
            assert evidence['result']=='passed', r['id']+' evidence did not pass'
counts={s:sum(r['status']==s for r in items) for s in ['verified','partial','blocked','absent','unverified']}
print('Traceability PASS:',len(items),'blocks,20 sections; coverage statuses:',counts)
print('This check validates the register, not game behavior.')
