#!/usr/bin/env python3
"""Native camera regression on an emulator. Backs up/restores every save byte.

Requires a declared checkpoint fixture and adb on PATH. Never overwrites output
or retained app data. Frame timings describe this device, not a reference phone.
"""
import argparse
import hashlib
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--apk", required=True, type=Path)
parser.add_argument("--checkpoint", required=True, type=Path)
parser.add_argument("--out", required=True, type=Path)
parser.add_argument("--tag", required=True)
parser.add_argument("--expected-settlements", type=int, default=32)
parser.add_argument("--renderer", choices=["default", "skia", "software"], default="default")
parser.add_argument("--follow-smoke", action="store_true",
                    help="Check final package installation, follow persistence and reopening without repeating all camera profiles")
parser.add_argument("--skip-frame-metrics", action="store_true",
                    help="Functional UI/recovery only; no FPS or rendered-count approval")
args = parser.parse_args()
assert re.fullmatch(r"[a-z0-9_]+", args.tag)
args.out.mkdir(parents=True, exist_ok=False)
pkg = "com.barriocero.eras"
folder = "app_flutter/barrio_cero"
before = f"app_flutter/native_before_{args.tag}"
after = f"app_flutter/native_after_{args.tag}"
result = {"scope": "UI and exact checkpoint recovery only; no frame performance or rendered-count acceptance" if args.skip_frame_metrics else "Continuous camera and declared settlement fixture; not phone acceptance",
          "apkSha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
          "requestedRenderer": args.renderer, "followSmokeOnly": args.follow_smoke,
          "frameMetricsRequested": not args.skip_frame_metrics}


def adb(*cmd):
    return subprocess.check_output(["adb", "-s", "emulator-5554", *cmd], timeout=120)


def run(*cmd):
    return adb("shell", "run-as", pkg, *cmd)


def exists(path):
    return subprocess.run(["adb", "-s", "emulator-5554", "shell", "run-as", pkg,
                           "ls", "-d", path], capture_output=True, timeout=30).returncode == 0


def stop():
    adb("shell", "am", "force-stop", pkg)


def launch():
    cmd = ["shell", "am", "start", "-W", "-n", pkg + "/.MainActivity"]
    if args.renderer in {"skia", "software"}:
        cmd.extend(["--ez", "enable-impeller", "false"])
    if args.renderer == "software":
        cmd.extend(["--ez", "enable-software-rendering", "true"])
    return adb(*cmd).decode()


def inventory():
    rows = {}
    for name in run("ls", "-1", folder).decode().splitlines():
        assert re.fullmatch(r"[a-zA-Z0-9_.-]+", name)
        data = adb("exec-out", "run-as", pkg, "cat", folder + "/" + name)
        rows[name] = hashlib.sha256(data).hexdigest()
    return rows


def checkpoint():
    return adb("exec-out", "run-as", pkg, "cat", folder + "/world_0.json")


def hierarchy():
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        reply = adb("shell", "uiautomator", "dump", "/sdcard/barrio-planet.xml")
        if b"dumped to:" not in reply:
            time.sleep(.25)
            continue
        xml = adb("exec-out", "cat", "/sdcard/barrio-planet.xml")
        (args.out / "last-window.xml").write_bytes(xml)
        return list(ET.fromstring(xml).iter("node"))
    raise RuntimeError("No fresh UI hierarchy")


def text(node):
    return node.get("text") or node.get("content-desc") or ""


def tap(label):
    for _ in range(3):
        nodes = hierarchy()
        for node in nodes:
            value = text(node)
            if value == label or value.startswith(label + "\n") or value.startswith(label + ":"):
                x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
                adb("shell", "input", "tap", str((x1+x2)//2), str((y1+y2)//2))
                print("Tap: " + label, flush=True)
                return
        time.sleep(.3)
    raise RuntimeError("Control unavailable: " + label + "; " + repr([text(n) for n in nodes if text(n)]))


profile_count = 0


def profile(lod, minimum_towns=None, minimum_sites=None, maximum_towns=None):
    global profile_count
    if args.skip_frame_metrics:
        label = "PLANETA" if lod == "Mundo" else lod.upper()
        deadline = time.monotonic() + 30
        while True:
            labels = [text(n) for n in hierarchy()]
            if any("No se pudo abrir la vista" in value for value in labels):
                raise RuntimeError("Map asset loading failed")
            if any(label in value for value in labels) and not any("Preparando vista" in value for value in labels):
                return {"lod": lod, "verified": "UI label and captured scene", "frameMetrics": "not requested", "renderedCountsVerified": False}
            if time.monotonic() >= deadline:
                raise RuntimeError("Expected loaded UI view: " + label)
            time.sleep(.2)
    profile_count += 1
    adb("logcat", "-c")
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        raw = adb("logcat", "-d", "-v", "raw", "-s", "flutter:I").decode(errors="replace")
        (args.out / f"profile-{profile_count}.log").write_text(raw)
        for line in reversed(raw.splitlines()):
            if "BARRIO_SCENE_STATS " not in line:
                continue
            entry = json.loads(line.split("BARRIO_SCENE_STATS ", 1)[1])
            if entry["lod"] != lod:
                continue
            if minimum_towns is not None and entry["visibleSettlements"] < minimum_towns:
                continue
            if minimum_sites is not None and entry["visibleSites"] < minimum_sites:
                continue
            if maximum_towns is not None and entry["visibleSettlements"] > maximum_towns:
                continue
            return entry
        time.sleep(.5)
    raise RuntimeError("No stable profile window for " + lod)


def capture(name):
    (args.out / name).write_bytes(adb("exec-out", "screencap", "-p"))
    if args.skip_frame_metrics:
        return
    memory = adb("shell", "dumpsys", "meminfo", pkg).decode(errors="replace")
    (args.out / (name + ".meminfo.txt")).write_text(memory)


moved = False
try:
    result["device"] = {
        "serial": "emulator-5554",
        "hardware": adb("shell", "getprop", "ro.hardware").decode().strip(),
        "api": adb("shell", "getprop", "ro.build.version.sdk").decode().strip(),
        "model": adb("shell", "getprop", "ro.product.model").decode().strip(),
        "referencePhoneAcceptance": False,
    }
    stop()
    assert not exists(before) and not exists(after), "Refusing to replace retained data"
    original = inventory()
    (args.out / "original-inventory.json").write_text(json.dumps(original, indent=2) + "\n")
    result["installation"] = adb("install", "-r", str(args.apk)).decode()
    run("mv", folder, before)
    moved = True
    run("mkdir", folder)
    adb("push", str(args.checkpoint), "/data/local/tmp/barrio-planet-fixture.json")
    run("cp", "/data/local/tmp/barrio-planet-fixture.json", folder + "/world_0.json")
    baseline = args.checkpoint.read_bytes()
    assert checkpoint() == baseline
    w = json.loads(baseline)["payload"]["world"]
    assert len(w["societies"]) == args.expected_settlements and w["controlledId"] is None
    result["fixture"] = {"size": w["size"], "settlements": args.expected_settlements, "normalOpening": args.expected_settlements == 6 and w["day"] == 0,
                         "day": w["day"], "runtimeInjections": False}
    adb("logcat", "-c")
    result["launchOutput"] = launch()
    tap("Continuar historia")
    result["worldProfile"] = profile("Mundo", minimum_towns=args.expected_settlements)
    capture("01-planet-settlements.png")
    if not args.follow_smoke:
        tap("Ver región")
        result["regionProfile"] = profile("Región")
        capture("02-connected-region.png")
        tap("Seguir")
        tap("Ver todo el asentamiento")
        result["cityProfile"] = profile("Asentamiento", minimum_sites=1)
        capture("03-city-in-the-planet.png")
        for _ in range(4):
            adb("shell", "input", "swipe", "250", "280", "50", "180", "450")
        result["outsideCityProfile"] = profile("Asentamiento", maximum_towns=0)
        capture("04-continuous-ground-outside-city.png")
        tap("Centrar comunidad")
        result["recenteredProfile"] = profile("Asentamiento", minimum_sites=1)
        capture("05-city-recentered.png")
    assert checkpoint() == baseline
    result["cameraPreservesExactCheckpoint"] = True
    tap("Seguir")
    deadline = time.monotonic() + 5
    while True:
        preference = json.loads(adb("exec-out", "run-as", pkg, "cat", folder + "/view_0.json"))
        if preference.get("active") is True or time.monotonic() >= deadline:
            break
        time.sleep(.1)
    assert preference["active"] is True
    assert preference["individualId"] == w["societies"][0]["people"][0]["id"]
    result["protagonistPreference"] = preference
    assert checkpoint() == baseline
    stop()
    launch()
    tap("Continuar historia")
    result["reopenedFollowProfile"] = profile("Asentamiento", minimum_sites=1)
    assert any("Siguiendo a " in text(n) for n in hierarchy())
    result["protagonistRestored"] = True
    capture("06-reopened-protagonist.png")
    tap("Mundo")
    profile("Mundo", minimum_towns=args.expected_settlements)
    capture("07-reopened-planet.png")
    assert checkpoint() == baseline
    result["reopenExact"] = True
except Exception as error:
    result["error"] = repr(error)
    print(repr(error), flush=True)
    try:
        capture("failure.png")
        (args.out / "failure-logcat.txt").write_bytes(adb("logcat", "-d", "-t", "400"))
    except Exception:
        pass
finally:
    if moved:
        stop()
        if exists(after):
            raise RuntimeError("Refusing to overwrite retained test data")
        if exists(folder):
            run("mv", folder, after)
        assert not exists(folder)
        run("mv", before, folder)
        result["originalSavesRestoredExactly"] = inventory() == original
        assert result["originalSavesRestoredExactly"]
    result["passed"] = "error" not in result and result.get("reopenExact") is True
    (args.out / "results.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(result, ensure_ascii=False), flush=True)
if not result["passed"]:
    raise SystemExit(1)
