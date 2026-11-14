#!/usr/bin/env python3
"""Check traceability only. Success does not establish gameplay acceptance."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate(plan):
    sources = {}
    for file in ["docs/requirements.json", "docs/redesign_requirements.json"]:
        for row in json.loads((ROOT / file).read_text())["requirements"]:
            assert row["id"] not in sources, "Duplicated original ID"
            sources[row["id"]] = (file, row)
    assert len(sources) == 174
    rows = plan["requirements"]
    assert len(rows) == 174 and len({r["id"] for r in rows}) == 174
    assert {r["id"] for r in rows} == sources.keys(), "Lost or invented requirement"
    assert plan["originalCount"] == 106 and plan["extensionCount"] == 68
    for name, expected in plan["sourceHashes"].items():
        assert hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == expected
    for row in rows:
        file, original = sources[row["id"]]
        assert row["sourceRegistry"] == file
        assert row["sourceRequirement"] == original["requirement"]
        assert row["ownerMilestone"] in plan["milestoneStates"]
        assert row["owner"] and row["acceptance"] and row["nextCheck"]
        assert row["legacyMilestones"] and row["legacyBatches"]
        assert row["finalAcceptance"] in ["pending", "verified"]
        if row["finalAcceptance"] == "verified":
            evidence = row.get("finalEvidence", [])
            assert evidence, "Final acceptance without evidence"
            assert all(e["result"] == "passed" and e["scope"] and
                       (ROOT / e["path"]).is_file() for e in evidence)
    for milestone, state in plan["milestoneStates"].items():
        assert state in {"pending", "in_progress", "verified"}
        if state != "verified":
            continue
        evidence = plan.get("milestoneEvidence", {}).get(milestone, [])
        assert evidence, f"{milestone}: no executed evidence"
        for item in evidence:
            path = ROOT / item["path"]
            assert path.is_file() and item["scope"] and item["result"] == "passed"
            if path.name == "results.json":
                report = json.loads(path.read_text())
                assert report.get("passed", report.get("allSelectedChecksPassed")) is True, \
                    f"{milestone}: failed report presented as approved"
    return len(rows)


if __name__ == "__main__":
    plan = json.loads((ROOT / "docs/planet_requirements.json").read_text())
    print(f"{validate(plan)} original/extension IDs preserved; owners and criteria linked.")
    print("Structural traceability only; no gameplay requirement closed by this check.")
