#!/usr/bin/env bash
# Records the current source identity and actual exit status of every check.
# No dependency installation, formatting, or content regeneration is performed.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source tool/development_env.sh
python3 - "$@" <<'PY'
import argparse, datetime, hashlib, json, os, pathlib, shutil, subprocess, sys
root = pathlib.Path.cwd()
parser = argparse.ArgumentParser(description='Validation by scope; no profile declares the game finished.')
parser.add_argument('--profile', choices=['quick', 'integration', 'release'], default='quick')
parser.add_argument('--tests', nargs='+', default=[], help='Focused test files for the quick profile')
parser.add_argument('--dry-run', action='store_true', help='List commands without executing checks or recording passes')
args = parser.parse_args()
if args.tests and args.profile != 'quick':
    parser.error('--tests is only used with --profile quick; other profiles run the full Flutter suite')
for name in args.tests:
    path = pathlib.Path(name)
    if path.is_absolute() or not path.parts or path.parts[0] != 'test' or '..' in path.parts or path.suffix != '.dart' or not path.is_file():
        parser.error('Test files must be existing .dart files inside test/')
now = datetime.datetime.now(datetime.timezone.utc)
out = root / 'build' / 'acceptance' / now.strftime('%Y%m%dT%H%M%S.%fZ')
def git(*args):
    p = subprocess.run(['git', *args], capture_output=True, text=True)
    return p.stdout.strip() if p.returncode == 0 else None
sources = {}
for name in ['lib', 'assets', 'test', 'tool', 'android']:
    for path in sorted((root / name).rglob('*')):
        if not path.is_file() or any(part in {'.gradle','build','__pycache__'} for part in path.parts):
            continue
        if path.name in {'local.properties', 'key.properties'}:
            continue
        sources[str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
for name in ['pubspec.yaml', 'pubspec.lock', 'PROJECT_SPEC.md']:
    path = root / name
    if path.exists(): sources[name] = hashlib.sha256(path.read_bytes()).hexdigest()
report = {
    'startedAt': now.isoformat(), 'commit': git('rev-parse', 'HEAD'),
    'gitStatus': git('status', '--porcelain=v1'),
    'specSha256': sources['PROJECT_SPEC.md'],
    'sourceTreeSha256': hashlib.sha256(json.dumps(sources, sort_keys=True).encode()).hexdigest(),
    'sourceFiles': sources, 'checks': [], 'profile': args.profile,
    'scope': 'Only the automated checks selected by this profile; not full game acceptance',
    'releaseAcceptanceSatisfied': False,
    'manualAcceptance': ['Android installation and gameplay', 'Reference-phone performance', 'Mandatory requirement evidence review'],
}
toolchains = pathlib.Path(os.environ.get('BARRIO_TOOLCHAINS', '/workspace/toolchains'))
sdk_dart = toolchains / 'flutter/bin/cache/dart-sdk/bin/dart'
flutter = shutil.which('flutter') or str(toolchains / 'flutter/bin/flutter')
dart = str(sdk_dart) if sdk_dart.is_file() else shutil.which('dart')
# Do not call Flutter's bootstrap wrapper when its SDK is missing: a validation
# runner must not silently install tooling or repeatedly retry a known blocker.
flutter_cache = pathlib.Path(flutter).resolve().parent / 'cache/dart-sdk/bin/dart'
flutter_ready = pathlib.Path(flutter).is_file() and flutter_cache.is_file()
available = [
 ('requirements', ['python3', 'tool/verify_requirements.py'], None),
 ('redesign', ['python3', 'tool/verify_redesign_requirements.py'], None),
 ('execution-coverage', ['python3', 'tool/verify_execution_batches.py'], None),
 ('catalog-source', ['python3', 'tool/generate_catalog.py', '--check'], None),
 ('content', ['python3', 'tool/validate_content.py'], None),
 ('analyze', [flutter, 'analyze'], None if flutter_ready else 'Flutter Dart SDK is unavailable'),
 ('simulation', [dart or 'dart', 'run', 'tool/simulation_check.dart'], None if dart else 'Dart SDK is unavailable'),
 ('flutter_tests', [flutter, 'test'], None if flutter_ready else 'Flutter Dart SDK is unavailable'),
 ('benchmark', [dart or 'dart', 'run', 'tool/benchmark.dart'], None if dart else 'Dart SDK is unavailable'),
 ('mature-benchmark', [dart or 'dart', 'run', 'tool/sustained_benchmark.dart'], None if dart else 'Dart SDK is unavailable'),
 ('android_build', [flutter, 'build', 'apk', '--profile'], None if flutter_ready else 'Flutter Dart SDK is unavailable'),
]
static_ids = {'requirements', 'redesign', 'execution-coverage', 'catalog-source', 'content', 'analyze'}
selected = static_ids | ({'flutter_tests', 'android_build'} if args.profile == 'integration' else set())
if args.profile == 'release':
    selected = {name for name, _, _ in available}
checks = [check for check in available if check[0] in selected]
if args.profile == 'quick' and args.tests:
    checks.append(('focused_tests', [flutter, 'test', *args.tests], None if flutter_ready else 'Flutter Dart SDK is unavailable'))
report['deferredChecks'] = [name for name, _, _ in available if name not in selected]
report['behavioralChecksRequested'] = [name for name, _, _ in checks if name in {'simulation', 'flutter_tests', 'focused_tests', 'benchmark', 'mature-benchmark'}]
if args.dry_run:
    print('DRY RUN: ' + args.profile + '; no checks executed or marked passed')
    for name, command, blocker in checks:
        print(name + ': ' + json.dumps(command) + (' [blocked: ' + blocker + ']' if blocker else ''))
    print('Deferred: ' + ', '.join(report['deferredChecks']))
    sys.exit(0)
out.mkdir(parents=True)
failed = False
for name, command, blocker in checks:
    record = {'id': name, 'command': command, 'startedAt': datetime.datetime.now(datetime.timezone.utc).isoformat()}
    if blocker:
        record.update(status='blocked', reason=blocker, exitCode=None)
        failed = True
    else:
        log = out / (name + '.log')
        try:
            with log.open('w') as stream:
                process = subprocess.run(command, cwd=root, stdout=stream, stderr=subprocess.STDOUT)
            record.update(status='passed' if process.returncode == 0 else 'failed', exitCode=process.returncode, log=str(log.relative_to(root)))
            failed |= process.returncode != 0
        except OSError as error:
            record.update(status='blocked', reason=str(error), exitCode=None)
            failed = True
    record['finishedAt'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    report['checks'].append(record)
    (out / 'results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2))
    print(name + ': ' + record['status'], flush=True)
report['finishedAt'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
report['allPassed'] = not failed
report['allSelectedChecksPassed'] = not failed
(out / 'results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2))
print('Evidence: ' + str(out / 'results.json'))
sys.exit(1 if failed else 0)
PY
