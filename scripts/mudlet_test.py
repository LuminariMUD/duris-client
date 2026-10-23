#!/usr/bin/env python3
"""Run the package in disposable, offline Mudlet profiles (Python stdlib only)."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import struct
import subprocess
import sys
import time
import uuid
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests/mudlet"
DEFAULT_ROOT = Path.home() / ".local/share/duris-client-dev/runs"


def command(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, text=True,
                          capture_output=True, timeout=30, **kwargs).stdout.strip()


def pointer_action(wid, action, scale):
    def move(x, y):
        xdo("mousemove", "--window", wid, str(round(x * scale)), str(round((y + 20) * scale)))
    move(action["x"], action["y"])
    button = str(action.get("button", 1))
    if action["type"] == "click":
        xdo("click", button)
    elif action["type"] == "scroll":
        xdo("click", "--repeat", "8", "--delay", "80", "5")
    elif action["type"] == "drag":
        try:
            xdo("mousedown", button)
            for step in range(1, 9):
                move(action["x"] + (action["to_x"] - action["x"]) * step / 8,
                     action["y"] + (action["to_y"] - action["y"]) * step / 8)
                time.sleep(.04)
        finally:
            xdo("mouseup", button)
    elif action["type"] != "hover":
        raise ValueError("Unknown pointer action: " + action["type"])


def write_json(path, value):
    path = Path(path)
    pending = path.with_suffix(".tmp")
    pending.write_text(json.dumps(value, indent=2) + "\n")
    pending.replace(path)


def wait_for(read, timeout=30, process=None):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = read()
        if value:
            return value
        if process is not None and process.poll() is not None:
            raise RuntimeError(f"Process exited before acknowledgment: {process.returncode}")
        time.sleep(.1)
    raise TimeoutError("Timed out waiting for matching acknowledgment")


def acknowledgment(path, run_id, scenario):
    try:
        value = json.loads(Path(path).read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    return value if value.get("run_id") == run_id and value.get("scenario") == scenario else None


def doctor(mudlet="mudlet"):
    names = [mudlet, "python3", "luac5.1", "xvfb-run", "Xvfb", "xauth",
             "openbox", "xdotool", "import", "fc-match"]
    paths = {name: shutil.which(name) for name in names}
    missing = [name for name, path in paths.items() if path is None]
    if missing:
        raise RuntimeError("Missing prerequisites: " + ", ".join(missing))
    version = command([paths[mudlet], "--version"], env={**os.environ, "QT_QPA_PLATFORM": "offscreen"})
    parsed_version = re.search(r"mudlet\s+(\d+)\.(\d+)", version, re.IGNORECASE)
    if not parsed_version or int(parsed_version[1]) < 5:
        raise RuntimeError("Automated profile isolation requires Mudlet 5.0+; use the manual portable workflow for 4.x")
    lua = command([paths["luac5.1"], "-v"])
    if "5.1" not in lua:
        raise RuntimeError("A real Lua 5.1 compiler is required")
    for p in [Path(paths[mudlet]).resolve().parent / "portable.txt", Path.home()/".config/mudlet/portable.txt"]:
        if p.exists():
            raise RuntimeError(f"Inspect portable override before running: {p}")
    return {"tools": paths, "mudlet": version, "lua": lua, "os": platform.platform(),
            "font": command(["fc-match", "Consolas"]), "locale": os.environ.get("LANG", "")}


def verify_candidate(candidate):
    version = (ROOT / "VERSION").read_text().strip()
    with zipfile.ZipFile(candidate) as z:
        if z.testzip():
            raise RuntimeError("Corrupt package archive")
        xml = z.read("Arjinius Client.xml")
        if b"@@SCRIPT:" in xml:
            raise RuntimeError("Unresolved script placeholders")
        scripts = ET.fromstring(xml).findall(".//Script")
        if {s.findtext("name") for s in scripts} != {"ArjUI", "ArjMapper", "ArjAuto"}:
            raise RuntimeError("Wrong package scripts")
        if f'ArjUI.VERSION = "{version}"' not in xml.decode():
            raise RuntimeError("Wrong injected script version")
        if f"version = [[{version}]]" not in z.read("config.lua").decode():
            raise RuntimeError("Wrong package metadata")
        for asset in (ROOT / "src/assets").rglob("*"):
            if asset.is_file() and z.read(str(asset.relative_to(ROOT / "src/assets"))) != asset.read_bytes():
                raise RuntimeError(f"Asset mismatch: {asset.name}")
        # ZIP timestamps vary across builds. Record a canonical payload identity
        # as well as the exact archive hash used by this specific Mudlet run.
        payload = hashlib.sha256()
        for name in sorted(z.namelist()):
            data = z.read(name)
            payload.update(name.encode() + b"\0" + str(len(data)).encode() + b"\0" + data)
    return {"version": version, "sha256": hashlib.sha256(candidate.read_bytes()).hexdigest(),
            "payload_sha256": payload.hexdigest()}


def bootstrap(run, config):
    """Restore an allowlisted profile exported from the proven manual UI setup."""
    profile = run / "config/mudlet/profiles/Duris-Visual"
    if profile.exists():
        raise RuntimeError("Refusing to overwrite an existing profile")
    (profile / "current").mkdir(parents=True)
    shutil.copyfile(TESTS / "profile.xml", profile / "current/2000-01-01#00-00-00.xml")
    (profile / "url").write_bytes(b"\x00\x00\x00\x12" + "127.0.0.1".encode("utf-16-be"))
    (profile / "port").write_bytes(b"\x00\x00\x00\x0a" + "65534".encode("utf-16-be"))
    config["profile"] = str(profile)
    script = (TESTS / "bootstrap.lua").read_text()
    package = ET.Element("MudletPackage", version="1.001")
    scripts = ET.SubElement(package, "ScriptPackage")
    node = ET.SubElement(scripts, "Script", isActive="yes", isFolder="no")
    ET.SubElement(node, "name").text = "Duris test companion"
    ET.SubElement(node, "script").text = script
    ET.SubElement(node, "eventHandlerList")
    with zipfile.ZipFile(run / "companion.mpackage", "w") as z:
        z.writestr("config.lua", 'mpackage = "Duris Test Companion"\n')
        z.writestr("Duris Test Companion.xml", ET.tostring(package, encoding="utf-8"))
        for fixture in (TESTS / "fixtures").rglob("*"):
            if fixture.is_file():
                z.write(fixture, "fixtures/" + str(fixture.relative_to(TESTS / "fixtures")))
    write_json(run / "run.json", config)


def xdo(*args):
    return command(["xdotool", *args])


def main_window():
    try:
        ids = xdo("search", "--onlyvisible", "--class", "mudlet").splitlines()
        for wid in ids:
            if "Duris-Visual - Mudlet" in xdo("getwindowname", wid):
                return wid
    except subprocess.CalledProcessError:
        pass
    return None


def geometry(wid):
    return dict(line.split("=", 1) for line in xdo("getwindowgeometry", "--shell", wid).splitlines())


def enter(wid, text):
    g = geometry(wid)
    xdo("windowactivate", "--sync", wid)
    xdo("mousemove", "--window", wid, "200", str(int(g["HEIGHT"]) - 20), "click", "1")
    xdo("key", "--clearmodifiers", "ctrl+a")
    xdo("type", "--clearmodifiers", "--delay", "1", text)
    xdo("key", "Return")


def capture(run, wid, name):
    command(["import", "-window", wid, run / (name + ".png")])


def stop_process(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


def session(run):
    config = json.loads((run / "run.json").read_text())
    children = []
    wid = None
    sys.path.insert(0, str(TESTS))
    from map_server import MapServer
    map_server = MapServer(run / "map-requests.json")
    config["map_base"] = map_server.base
    wire_server = None
    if config["scenario"] == "server-wire":
        from gmcp_server import GMCPServer
        wire_server = GMCPServer(run / "gmcp-client-messages.json")
        config["gmcp_port"] = wire_server.port
    write_json(run / "run.json", config)
    result = {"run_id": config["run_id"], "scenario": config["scenario"], "status": "FAIL",
              "visual_review": "NOT RUN", "error_review": "NOT RUN"}
    def interrupted(*_):
        raise RuntimeError("Test session interrupted")
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        for executable, args in [("openbox", []), (config["mudlet"], ["--offline", "--profile=Duris-Visual"])]:
            log = open(run / ("openbox.log" if executable == "openbox" else "mudlet.log"), "w")
            child = subprocess.Popen([executable, *args], stdout=log, stderr=subprocess.STDOUT)
            log.close()
            children.append(child)
        app = children[-1]
        wid = wait_for(main_window, config["timeout"], app)
        width, height = map(int, config["size"].split("x"))
        xdo("windowsize", "--sync", wid, str(width), str(height))
        config["geometry"] = geometry(wid)
        # Installation and checks use supported APIs through a passive test alias.
        enter(wid, 'lua installPackage(' + json.dumps(str(run / "duris-client.mpackage")) + ')')
        # The independent check is loaded only after the candidate, before the companion.
        enter(wid, 'lua dofile(' + json.dumps(str(run / "candidate-check.lua")) + ')')
        wait_for(lambda: acknowledgment(run / "candidate-ready.json", config["run_id"], "candidate"), config["timeout"], app)
        capture(run, wid, "candidate-only")
        enter(wid, 'lua installPackage(' + json.dumps(str(run / "companion.mpackage")) + ')')
        wait_for(lambda: acknowledgment(run / "ready.json", config["run_id"], "ready"), config["timeout"], app)
        enter(wid, "duris-test " + config["scenario"])
        seen_step = 0
        def scenario_progress():
            nonlocal seen_step
            checkpoint = acknowledgment(run / "checkpoint.json", config["run_id"], config["scenario"])
            if checkpoint and checkpoint["step"] > seen_step:
                seen_step = checkpoint["step"]
                capture(run, wid, f'{seen_step:02d}-{checkpoint["name"]}')
                for action in checkpoint.get("actions", []):
                    scale = config["scale"]
                    if action["type"] == "key":
                        xdo("key", "--clearmodifiers", action["key"])
                    else:
                        pointer_action(wid, action, scale)
                    time.sleep(.25)
                if checkpoint.get("actions"):
                    capture(run, wid, f'{seen_step:02d}-{checkpoint["name"]}-after-input')
                enter(wid, "lua DurisTest.resume()")
            return acknowledgment(run / "result.json", config["run_id"], config["scenario"])
        result = wait_for(scenario_progress, config["timeout"], app)
        # A separate delayed acknowledgment includes asynchronous error evidence.
        enter(wid, "lua DurisTest.collect()")
        errors = wait_for(lambda: acknowledgment(run / "errors.json", config["run_id"], "errors"), config["timeout"], app)
        result["errors"] = errors["errors"]
        result["error_review"] = "FAIL" if errors["errors"] else "PASS"
        if errors["errors"]:
            result["status"] = "FAIL"
        capture(run, wid, "scenario")
        result["visual_review"] = "NOT RUN"
        result["geometry"] = geometry(wid)
        if config["scenario"] == "maps":
            expected = {f"/zones/{zone}/map-data": count for zone, count in [(9001,2),(9002,1),(9003,1),(9004,1),(9005,1),(9006,1),(9007,1)]}
            observed = {path: map_server.requests.count(path) for path in set(map_server.requests)}
            result["map_requests"] = observed
            if observed != expected:
                result["status"] = "FAIL"
                result["error"] = "Unexpected map requests: " + str(observed)
        # Keep the main buffer and a real editor Errors-view capture for review.
        enter(wid, "lua DurisTest.save()")
        if config["scenario"] in {"lifecycle", "layout"} and result["status"] == "PASS":
            xdo("key", "alt+F4")
            app.wait(timeout=8)
            if app.returncode != 0:
                raise RuntimeError("Lifecycle save/close failed")
            for filename in ["candidate-ready.json", "ready.json", "result.json", "errors.json"]:
                (run / filename).unlink(missing_ok=True)
            with (run / "mudlet-reopen.log").open("w") as log:
                app = subprocess.Popen([config["mudlet"], "--offline", "--profile=Duris-Visual"], stdout=log, stderr=subprocess.STDOUT)
            children.append(app)
            wid = wait_for(main_window, config["timeout"], app)
            xdo("windowsize", "--sync", wid, str(width), str(height))
            wait_for(lambda: acknowledgment(run / "ready.json", config["run_id"], "ready"), config["timeout"], app)
            enter(wid, 'lua dofile(' + json.dumps(str(run / "candidate-check.lua")) + ')')
            wait_for(lambda: acknowledgment(run / "candidate-ready.json", config["run_id"], "candidate"), config["timeout"], app)
            capture(run, wid, "reopened-candidate")
            enter(wid, 'lua dofile(getMudletHomeDir().."/Duris Test Companion/fixtures/reopen.lua")')
            reopened = wait_for(lambda: acknowledgment(run / "result.json", config["run_id"], config["scenario"]), config["timeout"], app)
            result["reopen"] = reopened
            if reopened["status"] != "PASS":
                result["status"] = "FAIL"
            capture(run, wid, "reopened-fixture")
            enter(wid, "lua DurisTest.collect()")
            errors = wait_for(lambda: acknowledgment(run / "errors.json", config["run_id"], "errors"), config["timeout"], app)
            result["errors"].extend(errors["errors"])
            if result["errors"]:
                result["status"] = result["error_review"] = "FAIL"
        xdo("key", "alt+e")
        editors = wait_for(lambda: subprocess.run(
            ["xdotool", "search", "--onlyvisible", "--name", "Duris-Visual - Editor"],
            text=True, capture_output=True, timeout=2).stdout.strip(), 5, app)
        editor = editors.splitlines()[-1]
        xdo("windowsize", "--sync", editor, str(1100 * config["scale"]), str(850 * config["scale"]))
        xdo("windowactivate", "--sync", editor)
        xdo("key", "ctrl+8")
        time.sleep(.2)
        capture(run, "root", "errors-view")
        xdo("key", "alt+F4")
    except Exception as exc:
        result["status"] = "FAIL"
        result["error"] = str(exc)
        try:
            capture(run, "root", "failure")
            if wid:
                enter(wid, 'lua local f=assert(io.open(' + json.dumps(str(run / 'failure-console.txt')) + ',"w")); f:write(table.concat(getLines("main",0,getLastLineNumber("main")+1) or {},"\\n")); f:close()')
        except Exception:
            pass
    finally:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        if wid and children and children[-1].poll() is None:
            try:
                # Close the editor first if it is open, then the owned main window.
                xdo("windowactivate", "--sync", wid)
                xdo("key", "alt+F4")
                children[-1].wait(timeout=8)
            except (subprocess.SubprocessError, OSError):
                pass
        result["normal_shutdown"] = bool(children and children[-1].poll() == 0)
        for child in reversed(children):
            stop_process(child)
        map_server.close()
        if wire_server:
            wire_server.close()
        result["cleanup"] = all(child.poll() is not None for child in children)
        result["processes"] = [{"pid": child.pid, "exit_code": child.returncode} for child in children]
        if not result["normal_shutdown"] or not result["cleanup"]:
            result["status"] = "FAIL"
        result["automated_status"] = result["status"]
        if result["status"] == "PASS":
            result["status"] = "NOT RUN"  # Overall gate awaits actual screenshot review.
        config["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        config["screenshots"] = {}
        for png in run.glob("*.png"):
            data = png.read_bytes()
            config["screenshots"][png.name] = {"dimensions": struct.unpack(">II", data[16:24]), "sha256": hashlib.sha256(data).hexdigest()}
        write_json(run / "results.json", result)
        write_json(run / "manifest.json", config)
        (run / "report.md").write_text(f'# {config["scenario"]}\n\nAutomated: {result["automated_status"]}. Visual review: {result["visual_review"]}.\n\nCandidate: `{config["candidate"]["sha256"]}`.\n\nSee results.json for assertions, errors and cleanup; inspect relevant checkpoints and error evidence, and identify the reviewed images in the review note.\n')
    return 0 if result["automated_status"] == "PASS" else 1


def prepare(args):
    env = doctor(args.mudlet)
    run_id = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + "-" + uuid.uuid4().hex[:8]
    run = args.root.expanduser().resolve() / (run_id + "-" + args.scenario)
    run.mkdir(parents=True, mode=0o700)
    command([sys.executable, ROOT / "build.py", "--check"])
    command([sys.executable, ROOT / "build.py", "-o", run / "duris-client.mpackage"])
    candidate = verify_candidate(run / "duris-client.mpackage")
    config = {"run_id": run_id, "scenario": args.scenario, "candidate": candidate,
              "mudlet": env["tools"][args.mudlet], "environment": env,
              "source": command(["git", "rev-parse", "HEAD"], cwd=ROOT), "scale": args.scale,
              "size": args.size, "timeout": args.timeout, "network": "offline fixtures; loopback map and GMCP servers only"}
    config["started_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    config["fixtures"] = {str(f.relative_to(TESTS)): hashlib.sha256(f.read_bytes()).hexdigest()
                          for f in TESTS.rglob("*") if f.is_file() and "__pycache__" not in f.parts}
    (run / "source.diff").write_text(command(["git", "diff", "--binary", "HEAD"], cwd=ROOT))
    shutil.copytree(TESTS, run / "test-inputs", ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copyfile(__file__, run / "controller.py")
    config["fault"] = args.fault
    bootstrap(run, config)
    if args.fault == "wrong-profile":
        config["expected_profile"] = "wrong-profile"
        write_json(run / "run.json", config)
    check = '''local run = assert(os.getenv("DURIS_TEST_RUN"))
local f=assert(io.open(run.."/run.json")); local c=yajl.to_value(f:read("*a")); f:close()
tempTimer(1, function()
 assert(getProfileName()=="Duris-Visual" and getMudletHomeDir()==(c.expected_profile or c.profile), "wrong isolated profile")
 assert(select(3,getConnectionInfo())==false, "connected fixture profile")
 assert(ArjUI and ArjUI.VERSION==c.candidate.version and ArjUI.main, "wrong candidate")
 assert(ArjMapper and ArjMapper.ui.zoneContainer and ArjAuto, "scripts not ready")
 local o=assert(io.open(run.."/candidate-ready.json","w")); o:write(yajl.to_string({run_id=c.run_id,scenario="candidate"})); o:close()
end)
'''
    if args.fault == "wrong-candidate":
        check = check.replace("c.candidate.version", '"0.0.0"')
    (run / "candidate-check.lua").write_text(check)
    if args.fault == "no-readiness":
        (run / "candidate-check.lua").write_text("-- deliberate readiness timeout\n")
    return run


def run_desktop(run, args):
    env = {**os.environ, "XDG_CONFIG_HOME": str(run / "config"), "QT_QPA_PLATFORM": "xcb",
           "QT_SCALE_FACTOR": str(args.scale), "DURIS_TEST_RUN": str(run), "LC_ALL": "C.UTF-8"}
    display_size = "4096x2400x24" if args.scale == 2 else "2048x1200x24"
    proc = subprocess.Popen(["xvfb-run", "--auto-servernum", "--error-file=" + str(run / "xvfb.log"),
        "--server-args=-screen 0 " + display_size + " -dpi 96 -nolisten tcp", sys.executable,
        __file__, "_session", "--run-dir", str(run)], env=env, start_new_session=True)
    write_json(run / "owner.json", {"pid": proc.pid, "start": Path(f"/proc/{proc.pid}/stat").read_text().split()[21]})
    try:
        return proc.wait(timeout=args.timeout * 5 + 30)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(timeout=15)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
        write_json(run / "timeout.json", {"status": "FAIL", "reason": "desktop timeout"})
        return 1
    finally:
        (run / "owner.json").unlink(missing_ok=True)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("operation", choices=["doctor", "bootstrap", "run", "stop", "review", "_session"])
    p.add_argument("--mudlet", default="mudlet")
    p.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    p.add_argument("--run-dir", type=Path)
    p.add_argument("--scenario", default="lowhp")
    p.add_argument("--size", default="1366x768")
    p.add_argument("--scale", type=int, choices=[1, 2], default=1)
    p.add_argument("--timeout", type=float, default=35)
    p.add_argument("--fault", choices=["wrong-profile", "wrong-candidate", "no-readiness"])
    p.add_argument("--result", choices=["PASS", "FAIL"])
    p.add_argument("--note")
    args = p.parse_args()
    if not re.fullmatch(r"\d{3,4}x\d{3,4}", args.size):
        p.error("--size must be WIDTHxHEIGHT")
    if not re.fullmatch(r"[a-z0-9-]+", args.scenario):
        p.error("invalid scenario identifier")
    if args.operation == "doctor":
        print(json.dumps(doctor(args.mudlet), indent=2))
        return 0
    if args.operation == "_session":
        return session(args.run_dir.resolve())
    if args.operation == "review":
        if not args.run_dir or not args.result or not args.note:
            p.error("review needs --run-dir, --result and --note after inspecting the screenshots")
        path = args.run_dir / "results.json"
        result = json.loads(path.read_text())
        result["visual_review"] = args.result
        result["review_note"] = args.note
        result["status"] = "PASS" if result["automated_status"] == args.result == "PASS" else "FAIL"
        write_json(path, result)
        with (args.run_dir / "report.md").open("a") as f:
            f.write(f'\nVisual review: {args.result}. {args.note}\n\nOverall: {result["status"]}.\n')
        return 0 if result["status"] == "PASS" else 1
    if args.operation == "stop":
        owner = json.loads((args.run_dir / "owner.json").read_text())
        stat = Path(f'/proc/{owner["pid"]}/stat')
        if stat.exists() and stat.read_text().split()[21] == owner["start"]:
            os.killpg(owner["pid"], signal.SIGTERM)
        return 0
    run = prepare(args)
    print(run, flush=True)
    return run_desktop(run, args) if args.operation == "run" else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, subprocess.SubprocessError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
