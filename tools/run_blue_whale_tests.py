#!/usr/bin/env python3
"""Run whale gameplay, touch UI and production Main in an isolated project.

Each Store test also injects an explicit /tmp save fixture. The source project,
player data and installed runtime remain untouched.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if "blue-whale" not in str(output):
        parser.error("Use an explicit blue-whale audit output directory")
    output.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).resolve().parents[1] / "game"
    results = []
    with tempfile.TemporaryDirectory(prefix="farshore-whale-suite-", dir="/tmp") as isolated:
        project = Path(isolated) / "project"
        shutil.copytree(source, project, symlinks=True)
        environment = {key: value for key, value in os.environ.items() if key != "HOME"}
        environment["FARSHORE_ISOLATED_ROOT"] = isolated
        for name in ("challenge", "ui", "main"):
            script = f"res://tests/blue_whale_{name}_tests.gd"
            command = [str(args.godot.resolve()), "--headless", "--path", str(project),
                       "--rendering-method", "mobile", "--rendering-driver", "vulkan",
                       "--audio-driver", "Dummy", "--script", script,
                       "--log-file", str(output / f"{name}.godot.log")]
            if name == "challenge":
                command += ["--", "--require-whale-model"]
            completed = subprocess.run(command, cwd=project, env=environment,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                       text=True, timeout=180)
            print(f"WHALE_ISOLATED_TEST={name}", flush=True)
            print(completed.stdout, end="", flush=True)
            (output / f"{name}.stdout.log").write_text(completed.stdout)
            results.append({"name": name, "exit_code": completed.returncode,
                            "script": script, "headless": True})
        (output / "run.json").write_text(json.dumps({"player_save_access": False,
             "isolated_project": str(project), "inherited_home_removed": True,
             "tests": results}, indent=2) + "\n")
    return int(any(item["exit_code"] != 0 for item in results))


if __name__ == "__main__":
    raise SystemExit(main())
