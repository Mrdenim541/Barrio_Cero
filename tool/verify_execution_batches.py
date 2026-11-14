#!/usr/bin/env python3
"""Check execution grouping against existing requirements; never approve gameplay."""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    plan = json.loads((ROOT / 'docs/execution_batches.json').read_text())
    base = json.loads((ROOT / 'docs/requirements.json').read_text())
    extension = json.loads((ROOT / 'docs/redesign_requirements.json').read_text())
    require(plan['schemaVersion'] == 1, 'Unknown execution schema')
    for key, name in [('baseSpecSha256', 'PROJECT_SPEC.md'), ('extensionSpecSha256', 'docs/REDESIGN_SPEC.md')]:
        require(plan[key] == hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), 'Specification changed: ' + name)
    batches = {b['id']: b for b in plan['batches']}
    require(len(batches) == len(plan['batches']) == 6, 'Expected six distinct batches')
    require(set(batches) == {'E1', 'E2', 'E3', 'E4', 'E5', 'E6'}, 'Batch identifiers changed')
    visited, active = set(), set()

    def visit(name):
        require(name in batches and name not in active, 'Missing dependency or cycle: ' + name)
        if name in visited:
            return
        active.add(name)
        for dependency in batches[name]['dependencies']:
            visit(dependency)
        active.remove(name)
        visited.add(name)

    for name, batch in batches.items():
        visit(name)
        for field in ['deliverables', 'modules', 'closeWhen']:
            require(batch[field] and all(isinstance(s, str) and s.strip() for s in batch[field]), 'Empty batch scope: ' + name)
    references = {r['id']: r['milestones'] for r in extension['originalRequirements']}
    expected = {r['id']: ('docs/requirements.json', references[r['id']]) for r in base['requirements']}
    expected.update({r['id']: ('docs/redesign_requirements.json', [r['milestone']]) for r in extension['requirements']})
    actual = {r['id']: r for r in plan['requirements']}
    require(len(actual) == len(plan['requirements']) == 174, 'Requirements duplicated or missing')
    require(set(actual) == set(expected), 'Execution grouping dropped or invented requirements')
    for identity, entry in actual.items():
        registry, milestones = expected[identity]
        require(entry['registry'] == registry and entry['milestones'] == milestones, 'Source mismatch: ' + identity)
        require(entry['batches'] and len(set(entry['batches'])) == len(entry['batches']) and set(entry['batches']) <= set(batches), 'Invalid grouping: ' + identity)
        require(entry['ownerBatch'] in entry['batches'], 'Missing requirement owner: ' + identity)
    require(plan['originalCount'] == len(base['requirements']) == 106, 'Original count changed')
    require(plan['extensionCount'] == len(extension['requirements']) == 68, 'Extension count changed')
    require(plan['finalAcceptanceBatch'] == 'E6', 'Final acceptance missing')
    print('PASS: all 106 original + 68 extension requirements grouped, with owners and acyclic dependencies')
    print('Execution coverage only; implementation and gameplay acceptance remain in the original registries.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, TypeError) as error:
        print('FAIL: ' + str(error), file=sys.stderr)
        sys.exit(1)
