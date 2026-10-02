"""Stop only this owned build process group before generated files fill the disk."""
from pathlib import Path
import datetime
import json
import os
import shutil
import signal
import subprocess
import sys
import time

root = Path(__file__).resolve().parent.parent
start_minimum = 4 * 1024**3
stop_floor = 768 * 1024**2
available = shutil.disk_usage(root).free
if sys.argv[1:] == ['--check']:
    print(json.dumps({'available_bytes':available,'start_minimum_bytes':start_minimum,'stop_floor_bytes':stop_floor}))
    raise SystemExit(0 if available >= start_minimum else 95)
if available < start_minimum:
    raise SystemExit('Build not started: fewer than4GiB free; retain sources/backups and review generated caches')
env = os.environ.copy()
env['FARSHORE_BUILD_SPACE_GUARDED'] = '1'
started = datetime.datetime.now(datetime.timezone.utc)
child = subprocess.Popen(['bash',str(root/'tools/android_build.sh'),*sys.argv[1:]],cwd=root,env=env,start_new_session=True)
minimum = available
stopped_for_space = False
while child.poll() is None:
    free = shutil.disk_usage(root).free
    minimum = min(minimum,free)
    if free < stop_floor:
        stopped_for_space = True
        print('Stopping owned Android build before disk exhaustion; source/backups are preserved',flush=True)
        os.killpg(child.pid,signal.SIGTERM)
        try: child.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid,signal.SIGKILL)
            child.wait()
        break
    time.sleep(0.25)
report = {'started_utc':started.isoformat(),'arguments':sys.argv[1:],
          'initial_free_bytes':available,'minimum_observed_free_bytes':minimum,
          'final_free_bytes':shutil.disk_usage(root).free,'stop_floor_bytes':stop_floor,
          'stopped_for_space':stopped_for_space,'returncode':child.returncode}
folder = root/'build/logs'
folder.mkdir(parents=True,exist_ok=True)
(folder/f'space-guard-{started.strftime("%Y%m%dT%H%M%SZ")}.json').write_text(json.dumps(report,indent=2)+'\n')
raise SystemExit(95 if stopped_for_space else (child.returncode or 0))
