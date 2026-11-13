#!/usr/bin/env python3
"""Validate extension traceability, not gameplay completion. No file writes."""

import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
STATES = {"pending", "in_progress", "partial", "blocked", "verified"}
GROUP_COUNTS = {
    "GOV": 2, "SCN": 3, "ERA": 4, "BIO": 6, "FAM": 6, "NAR": 10,
    "CAT": 5, "UX": 6, "ART": 3, "CORE": 5, "SAVE": 7, "VAL": 9, "DEL": 2,
}
MANDATORY_IDS = {
    f"BC2-{group}-{index:02d}"
    for group, count in GROUP_COUNTS.items() for index in range(1, count + 1)
}
DECISIONS = {
    "defaultOrigin": "prehistory", "alternateOrigin": "reconstruction",
    "personalAgency": "prominent_families_aggregate_population",
    "eraPacing": "generations_and_centuries", "minAndroidApi": 24,
    "referenceAndroidApi": 29, "referenceRamGiB": 4,
    "intimacy": "adult_non_graphic_ellipsis_only",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def object_pairs(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=object_pairs)


def nonempty_text(value):
    return isinstance(value, str) and bool(value.strip())


def unique_strings(values, label, allow_empty=False):
    require(isinstance(values, list), f"{label}: expected array")
    require(allow_empty or bool(values), f"{label}: empty array")
    require(all(nonempty_text(v) for v in values), f"{label}: expected nonempty strings")
    require(len(values) == len(set(values)), f"{label}: duplicates")
    return set(values)


def evidence(entries, label, verified=False):
    require(isinstance(entries, list), f"{label}: evidence must be an array")
    passed_behavior = False
    for entry in entries:
        require(isinstance(entry, dict), f"{label}: evidence must be objects")
        require(nonempty_text(entry.get("path")), f"{label}: evidence path missing")
        relative = Path(entry["path"])
        target = (ROOT / relative).resolve()
        require(not relative.is_absolute() and ".." not in relative.parts,
                f"{label}: unsafe evidence path")
        require(target.is_relative_to(ROOT) and target.is_file(),
                f"{label}: evidence file missing or outside repository")
        require(entry.get("result") in {"passed", "failed", "blocked", "not_run"},
                f"{label}: evidence result missing or unknown")
        require(entry.get("kind") in {"behavioral", "static", "build", "installation", "manual"},
                f"{label}: evidence kind missing or unknown")
        require(nonempty_text(entry.get("command")) and nonempty_text(entry.get("scope")),
                f"{label}: evidence needs command and scope")
        passed_behavior |= entry["result"] == "passed" and entry["kind"] in {"behavioral", "manual"}
    require(not verified or passed_behavior,
            f"{label}: verified needs passing behavioral/manual evidence; static checks are insufficient")


def validate(data, original):
    require(isinstance(data, dict) and data.get("schemaVersion") == 1, "Unsupported registry schema")
    require(data.get("scopeVersion") == "2.0", "Unknown scope version")
    for key, path in {"baseSpec": "PROJECT_SPEC.md", "extensionSpec": "docs/REDESIGN_SPEC.md",
                      "originalRegistry": "docs/requirements.json"}.items():
        require(data.get(key) == path, f"Unexpected {key}")
    base_hash = hashlib.sha256((ROOT / data["baseSpec"]).read_bytes()).hexdigest()
    require(base_hash == original.get("specSha256") == data.get("baseSpecSha256"),
            "Original specification hash differs from original/extension registry")
    extension_hash = hashlib.sha256((ROOT / data["extensionSpec"]).read_bytes()).hexdigest()
    require(extension_hash == data.get("extensionSpecSha256"), "Extension specification hash mismatch")
    require(nonempty_text(data.get("completionRule")), "Completion rule missing")
    require(data.get("acceptedDecisions") == DECISIONS, "Accepted product decisions changed")
    originals = original.get("requirements")
    require(isinstance(originals, list) and len(originals) == 106, "Original registry must retain 106 requirements")
    original_ids = unique_strings([row["id"] for row in originals], "Original IDs")
    require(data.get("originalRequirementCount") == len(original_ids), "Original requirement count mismatch")

    milestones = data.get("milestones")
    require(isinstance(milestones, list) and len(milestones) == 14, "Expected R0–R13 milestones")
    require(all(isinstance(row, dict) for row in milestones), "Invalid milestone object")
    milestone_ids = unique_strings([row.get("id") for row in milestones], "Milestone IDs")
    require(milestone_ids == {f"R{i}" for i in range(14)}, "Expected R0–R13 milestone IDs")
    dependencies = {}
    for row in milestones:
        label = row["id"]
        require(nonempty_text(row.get("name")), f"{label}: name missing")
        require(row.get("state") in STATES, f"{label}: invalid state")
        deps = unique_strings(row.get("dependencies"), f"{label} dependencies", allow_empty=True)
        require(deps <= milestone_ids and label not in deps, f"{label}: unknown/self dependency")
        dependencies[label] = deps
        evidence(row.get("evidence"), label, row["state"] == "verified")
    remaining = dict(dependencies)
    while remaining:
        ready = {key for key, deps in remaining.items() if not deps & remaining.keys()}
        require(bool(ready), "Milestone dependency cycle")
        remaining = {key: deps for key, deps in remaining.items() if key not in ready}

    mappings = data.get("originalRequirements")
    require(isinstance(mappings, list) and all(isinstance(row, dict) for row in mappings),
            "Original requirement mapping missing")
    mapped_ids = unique_strings([row.get("id") for row in mappings], "Mapped original IDs")
    require(mapped_ids == original_ids, "Original mapping missing or adds IDs")
    for row in mappings:
        refs = unique_strings(row.get("milestones"), f"{row['id']} milestones")
        require(refs <= milestone_ids, f"{row['id']}: unknown milestone mapping")

    requirements = data.get("requirements")
    require(isinstance(requirements, list) and all(isinstance(row, dict) for row in requirements),
            "Extension requirements missing")
    ids = unique_strings([row.get("id") for row in requirements], "Extension IDs")
    require(MANDATORY_IDS <= ids, f"Mandatory extension IDs removed: {sorted(MANDATORY_IDS - ids)}")
    for row in requirements:
        label = row["id"]
        require(re.fullmatch(r"BC2-[A-Z]+-\d{2}", label), f"{label}: invalid ID")
        require(row.get("milestone") in milestone_ids, f"{label}: unknown milestone")
        require(type(row.get("sourceSection")) is int and 1 <= row["sourceSection"] <= 12,
                f"{label}: invalid extension section")
        for key in ("requirement", "owner"):
            require(nonempty_text(row.get(key)), f"{label}: {key} missing")
        require(row.get("state") in STATES, f"{label}: invalid state")
        refs = unique_strings(row.get("originalRefs"), f"{label} original references")
        require(refs <= original_ids, f"{label}: unknown original reference")
        unique_strings(row.get("acceptance"), f"{label} acceptance")
        evidence(row.get("evidence"), label, row["state"] == "verified")
    for row in milestones:
        if row["state"] == "verified":
            require(all(req["state"] == "verified" for req in requirements if req["milestone"] == row["id"]),
                    f"{row['id']}: verified milestone has unfinished requirements")
            require(all(next(m for m in milestones if m["id"] == dep)["state"] == "verified"
                        for dep in dependencies[row["id"]]),
                    f"{row['id']}: verified milestone has unfinished dependencies")
    return len(original_ids), len(ids)


def self_test(data, original):
    mutations = {
        "duplicate ID": lambda d: d["requirements"].append(copy.deepcopy(d["requirements"][0])),
        "unknown original": lambda d: d["requirements"][0]["originalRefs"].append("S99-R99"),
        "missing original": lambda d: d["originalRequirements"].pop(),
        "changed original hash": lambda d: d.update(baseSpecSha256="0" * 64),
        "changed extension hash": lambda d: d.update(extensionSpecSha256="0" * 64),
        "missing acceptance": lambda d: d["requirements"][0].pop("acceptance"),
        "unsupported verified": lambda d: d["requirements"][0].update(state="verified", evidence=[]),
        "unknown milestone": lambda d: d["requirements"][0].update(milestone="R99"),
        "dependency cycle": lambda d: d["milestones"][0]["dependencies"].append("R1"),
        "empty requirements": lambda d: d.update(requirements=[]),
        "unsafe evidence": lambda d: d["requirements"][0]["evidence"].append({"path": "../outside"}),
        "unknown state": lambda d: d["requirements"][0].update(state="probably_done"),
        "changed decision": lambda d: d["acceptedDecisions"].update(minAndroidApi=26),
        "dropped extension": lambda d: d["requirements"].pop(),
    }
    for label, mutate in mutations.items():
        candidate = copy.deepcopy(data)
        mutate(candidate)
        try:
            validate(candidate, original)
        except ValueError:
            continue
        raise ValueError(f"Self-test failed to reject {label}")
    print(f"PASS: {len(mutations)} invalid registries rejected in memory")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        data = read_json(ROOT / "docs/redesign_requirements.json")
        original = read_json(ROOT / "docs/requirements.json")
        old_count, new_count = validate(data, original)
        if args.self_test:
            self_test(data, original)
        print(f"PASS: {old_count} original + {new_count} extension requirements; R0–R13 references valid")
        print("Static traceability only: this result does not demonstrate gameplay or milestone completion.")
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
