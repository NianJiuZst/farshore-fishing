#!/usr/bin/env python3
"""Strict full44 QA on isolated data, recording runtime-input hashes before/after.

No export, signing, credentials, production saves or network access are involved.
Run only once fish producers have declared their runtime assets stable. A source
change during the run fails the stability gate, even when individual tests pass.
Desktop rendering, if requested, remains software-render evidence, not Android.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
SUITES = [
    ("camera_aspect", "camera_aspect_tests.gd", []),
    ("save", "save_tests.gd", []),
    ("core", "core_tests.gd", []),
    ("session_observation", "session_observation_tests.gd", []),
    ("hazard_boundary", "fishing_hazard_boundary_tests.gd", []),
    ("guard_trace", "fishing_guard_trace_tests.gd", []),
    ("float_observation", "float_observation_tests.gd", []),
    ("fish_art", "fish_art_tests.gd", []),
    ("fish_art_ui", "fish_art_ui_tests.gd", []),
    ("tackle", "tackle_tests.gd", []),
    ("bait_balance", "bait_balance_tests.gd", []),
    ("registry", "fish_3d_registry_tests.gd", ["--require-all"]),
    ("fish_preview", "fish_preview_tests.gd", []),
    ("main_travel", "main_travel_tests.gd", []),
    ("slice3d", "slice3d_tests.gd", []),
    ("ui_style", "ui_style_tests.gd", []),
    ("touch", "touch_scroll_tests.gd", ["--production", "--require-full"]),
    ("historical_trial", "trial_fishery_tests.gd", []),
    ("angler_anatomy", "angler_anatomy_tests.gd", []),
]


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def manifest() -> dict[str, str]:
    paths = [ROOT / "game/project.godot", ROOT / "game/default_bus_layout.tres"]
    for name in ["scripts", "tests", "data", "scenes", "assets"]:
        paths.extend(p for p in (ROOT / "game" / name).rglob("*") if p.is_file())
    return {str(p.relative_to(ROOT)): digest(p) for p in sorted(set(paths))}


def isolated_env(base: Path) -> dict[str, str]:
    result = os.environ.copy()
    result.pop("DISPLAY", None)
    for key, leaf in [("HOME", "home"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config"), ("XDG_RUNTIME_DIR", "runtime")]:
        path = base / leaf
        path.mkdir(mode=0o700)
        result[key] = str(path)
    return result


def execute(name: str, command: list[str], output: Path, timeout: float = 300) -> dict:
    started = time.monotonic()
    log = output / f"{name}.log"
    with tempfile.TemporaryDirectory(prefix="farshore-fullqa-") as temp:
        env = isolated_env(Path(temp))
        with log.open("w") as stream:
            stream.write("COMMAND: " + " ".join(command) + "\n")
            stream.flush()
            try:
                completed = subprocess.run(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
                code = completed.returncode
            except subprocess.TimeoutExpired:
                stream.write("\nQA_TIMEOUT: command did not finish within the test budget\n")
                code = 124
    lines = log.read_text(errors="replace").splitlines()
    errors = [line for line in lines if "SCRIPT ERROR:" in line or line.startswith("ERROR:") or line.startswith("FAIL")]
    warnings = [line for line in lines if line.startswith("WARNING:")]
    result = {"name": name, "exit_code": code, "passed": code == 0 and not errors, "seconds": round(time.monotonic()-started, 2), "log": str(log.relative_to(ROOT)), "errors": errors, "warnings": warnings, "summary_lines": [line for line in lines if "TESTS:" in line or "SCOPE:" in line or "checked_models" in line]}
    print(json.dumps(result, ensure_ascii=False), flush=True)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="New output directory beneath repository build/")
    parser.add_argument("--tall", action="store_true", help="Use representative720x1584 physical/logical viewport for layout suites")
    parser.add_argument("--suites", help="Optional comma-separated suite names; summary explicitly records the narrowed scope")
    parser.add_argument("--skip-import", action="store_true", help="Use assets already imported by the coordinated producer")
    parser.add_argument("--render", action="store_true", help="Also run strict slice3d, UI style and touch through private Mobile/Vulkan software renderer")
    parser.add_argument("--render-timeout", type=float, default=1200, help="Per-suite software renderer budget; full44,4x MSAA,tall frames and full license scrolling exceed the old180s budget")
    args = parser.parse_args()
    output = (ROOT / args.output).resolve()
    if ROOT / "build" not in output.parents:
        parser.error("output must be a new subdirectory under repository build/")
    output.mkdir(parents=True, exist_ok=False)
    godot = os.environ.get("GODOT", "godot")
    selected = SUITES
    if args.suites:
        wanted = args.suites.split(",")
        unknown = sorted(set(wanted)-{row[0] for row in SUITES})
        if unknown:
            parser.error("unknown suites: " + ", ".join(unknown))
        selected = [row for row in SUITES if row[0] in wanted]
    results = []
    before_import = manifest()
    (output / "before_import_sha256.json").write_text(json.dumps(before_import, indent=2)+"\n")
    if not args.skip_import:
        result = execute("import", [godot, "--headless", "--audio-driver", "Dummy", "--path", "game", "--import"], output, 600)
        results.append(result)
        if not result["passed"]:
            (output / "summary.json").write_text(json.dumps({"passed": False, "blocker": "asset import failed", "results": results}, indent=2)+"\n")
            return 1
    before = manifest()
    (output / "runtime_before_sha256.json").write_text(json.dumps(before, indent=2)+"\n")
    existing_import_changes = sorted(p for p in before_import if before.get(p) != before_import[p])
    # Import legitimately regenerates metadata and extracted3D textures. Raw
    # GLBs, scripts, scenes and data must not change while this occurs.
    source_import_changes = [p for p in existing_import_changes if Path(p).suffix in {".glb", ".gd", ".gdshader", ".json", ".tscn", ".tres", ".godot"}]
    for name, script, original_extra in selected:
        extra = original_extra + (["--tall"] if args.tall and name in ["slice3d","ui_style","touch","fish_art_ui"] else [])
        command = [godot, "--headless", "--audio-driver", "Dummy", "--path", "game", "--script", "res://tests/"+script]
        if extra:
            command += ["--", *extra]
        results.append(execute(name, command, output))
    results.append(execute("binary_catalog", ["python3", "tools/audit_fish_catalog_3d.py", "--require-all", "--output", str(output / "binary_catalog.json")], output))
    if args.render:
        for name, script, original_extra in [row for row in selected if row[0] in ["slice3d", "ui_style", "touch"]]:
            extra = original_extra + (["--tall"] if args.tall else [])
            command = ["python3", "tools/render_godot.py", "--timeout", str(args.render_timeout), "--", "--path", "game", "--rendering-method", "mobile", "--rendering-driver", "vulkan", "--script", "res://tests/"+script]
            if extra:
                command += ["--", *extra]
            results.append(execute(name+"_vulkan", command, output, args.render_timeout+60))
    after = manifest()
    (output / "runtime_after_sha256.json").write_text(json.dumps(after, indent=2)+"\n")
    changed = sorted(p for p in before.keys() | after.keys() if before.get(p) != after.get(p))
    passed = not changed and not source_import_changes and all(r["passed"] for r in results)
    summary = {"passed": passed, "selected_suites": [row[0] for row in selected], "representative_tall_layout": args.tall, "runtime_files": len(before), "runtime_unchanged": not changed, "runtime_changes": changed, "existing_files_changed_during_import": existing_import_changes, "source_changes_during_import": source_import_changes, "results": results, "scope": "Full44 production source/control integration plus optional desktop software-render checks. Not art signoff, Android export/device certification or release authorization."}
    (output / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2)+"\n")
    print(json.dumps({"passed": passed, "runtime_unchanged": not changed, "runtime_changes": changed, "source_changes_during_import": source_import_changes, "summary": str(output.relative_to(ROOT) / "summary.json")}), flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
