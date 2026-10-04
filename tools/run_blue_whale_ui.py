#!/usr/bin/env python3
"""Run the real Mobile/Vulkan whale HUD in a disposable project copy.

The game model test never creates SaveStore. On macOS, omitting the inherited
home variable makes Godot's data path relative to this disposable working
directory. No global environment, installed bundle, or player profile changes.
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
    parser.add_argument("--capture-dir", type=Path, required=True)
    args = parser.parse_args()
    source_project = Path(__file__).resolve().parents[1] / "game"
    output = args.capture_dir.resolve()
    if "blue-whale" not in str(output):
        parser.error("Use an explicit blue-whale audit output directory")
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="farshore-whale-ui-", dir="/tmp") as isolated:
        isolated_root = Path(isolated)
        project = isolated_root / "project"
        # Full copy includes imported resources. Never mutate shared source or
        # import concurrently against the production project.
        shutil.copytree(source_project, project, symlinks=True)
        runtime_environment = {key: value for key, value in os.environ.items() if key != "HOME"}
        runtime_environment["FARSHORE_ISOLATED_ROOT"] = isolated
        command = [str(args.godot.resolve()), "--path", str(project),
                   "--rendering-method", "mobile", "--rendering-driver", "vulkan",
                   "--audio-driver", "Dummy", "--script", "res://tests/blue_whale_ui_tests.gd",
                   "--log-file", str(output / "godot.log"), "--", f"--capture-dir={output}"]
        print("WHALE_RENDER_TEST: Mobile / Vulkan; isolated project copy", flush=True)
        completed = subprocess.run(command, cwd=project, env=runtime_environment,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, timeout=120)
        print(completed.stdout, end="", flush=True)
        (output / "stdout.log").write_text(completed.stdout)
        manifest = {"rendering_method": "mobile", "rendering_driver": "vulkan",
                    "isolated_project": str(project), "player_save_access": False,
                    "inherited_home_removed": True, "exit_code": completed.returncode,
                    "captures": sorted(path.name for path in output.glob("*.png"))}
        (output / "run.json").write_text(json.dumps(manifest, indent=2) + "\n")
        return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
