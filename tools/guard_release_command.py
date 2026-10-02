"""Run one owned packaging command with measured disk/tmpfs/memory floors."""
from pathlib import Path
import argparse
import datetime
import json
import os
import shutil
import signal
import subprocess
import time


def resource_state(root):
    memory = int(next(p.split()[1] for p in Path('/proc/meminfo').read_text().splitlines() if p.startswith('MemAvailable:'))) * 1024
    return [shutil.disk_usage(root).free, shutil.disk_usage('/tmp').free, memory]


def run(command, root, log, proof, env=None):
    floors = [768 * 1024**2, 512 * 1024**2, 1024**3]
    initial = resource_state(root)
    assert all(a > b for a, b in zip(initial, floors)), 'Insufficient initial disk/tmpfs/memory budget'
    minimum = initial.copy()
    stopped = False
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open('w') as output:
        child = subprocess.Popen(command, cwd=root, env=env, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
        while child.poll() is None:
            current = resource_state(root)
            minimum = [min(a, b) for a, b in zip(minimum, current)]
            if any(a < b for a, b in zip(current, floors)):
                stopped = True
                os.killpg(child.pid, signal.SIGTERM)
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
                break
            time.sleep(.1)
    report = {'command': command, 'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'initial_root_tmp_memory_bytes': initial, 'minimum_root_tmp_memory_bytes': minimum,
              'final_root_tmp_memory_bytes': resource_state(root), 'floors_root_tmp_memory_bytes': floors,
              'stopped_by_guard': stopped, 'returncode': child.returncode}
    proof.write_text(json.dumps(report, indent=2) + '\n')
    return 95 if stopped else child.returncode


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--log', type=Path, required=True)
    parser.add_argument('--proof', type=Path, required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command and args.command[0] == '--' else args.command
    assert command
    raise SystemExit(run(command, args.root, args.log, args.proof))
