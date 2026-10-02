#!/usr/bin/env python3
"""Run real Godot rendering on a private virtual X display and Mesa Vulkan.

This is a desktop software-render QA harness, never a phone performance test.
Usage: python3 tools/render_godot.py --timeout 120 -- --path game SCENE --quit-after 180
Requires the pinned, scoped Debian packages documented in RENDER_TEST_ENVIRONMENT.md.
"""
import argparse
import os
from pathlib import Path
import secrets
import socket
import struct
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT / "tools/xvfb"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    args = options.args[1:] if options.args[:1] == ["--"] else options.args
    if not args:
        parser.error("provide Godot command arguments after --")
    xvfb = PACKAGES / "usr/bin/Xvfb"
    driver = PACKAGES / "usr/share/vulkan/icd.d/lvp_icd.json"
    if not xvfb.is_file() or not driver.is_file():
        parser.error("scoped Xvfb/Mesa packages are missing; see docs/RENDER_TEST_ENVIRONMENT.md")
    with tempfile.TemporaryDirectory(prefix="farshore-render-") as temp:
        base = Path(temp)
        env = os.environ.copy()
        for key, leaf in [("HOME", "home"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config"), ("XDG_RUNTIME_DIR", "runtime")]:
            directory = base / leaf
            directory.mkdir(mode=0o700)
            env[key] = str(directory)
        env["LD_LIBRARY_PATH"] = str(PACKAGES / "usr/lib/x86_64-linux-gnu") + ":" + env.get("LD_LIBRARY_PATH", "")
        env["VK_ICD_FILENAMES"] = str(driver)
        env["LIBGL_ALWAYS_SOFTWARE"] = "1"
        number = str(200 + secrets.randbelow(1500))
        # A throw-away IPC cookie belongs only to this private test display.
        # It is never printed, reused, persisted outside this temporary directory
        # or sent to a remote account. Normal X authentication stays enabled.
        authority = base / "display.auth"
        fields = [b"", number.encode(), b"MIT-MAGIC-COOKIE-1", secrets.token_bytes(16)]
        with authority.open("xb") as handle:
            os.chmod(authority, 0o600)
            handle.write(struct.pack(">H", 65535))
            for field in fields:
                handle.write(struct.pack(">H", len(field)) + field)
        env["XAUTHORITY"] = str(authority)
        server_log = (base / "xvfb.log").open("w+")
        # This execution sandbox isolates networking and prohibits Unix display
        # sockets. Keep X's normal host access control; only the same private
        # process namespace connects through its loopback address.
        server = subprocess.Popen([str(xvfb), ":" + number, "-auth", str(authority), "-screen", "0", "1080x1920x24", "-nolisten", "unix", "-nolisten", "local", "-listen", "tcp"], env=env, stdout=server_log, stderr=subprocess.STDOUT)
        try:
            ready = False
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline and server.poll() is None:
                try:
                    with socket.create_connection(("127.0.0.1", 6000 + int(number)), timeout=0.1):
                        ready = True
                        break
                except OSError:
                    time.sleep(0.05)
            if not ready:
                server_log.seek(0)
                raise RuntimeError("invalid display startup: " + server_log.read(8000))
            env["DISPLAY"] = "127.0.0.1:" + number
            print("DESKTOP_SOFTWARE_RENDER: private X display; Mesa lavapipe Vulkan; not Android hardware", flush=True)
            result = subprocess.run([os.environ.get("GODOT", "godot"), "--audio-driver", "Dummy", *args], cwd=ROOT, env=env, timeout=options.timeout)
            return result.returncode
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
            server_log.close()


if __name__ == "__main__":
    raise SystemExit(main())
