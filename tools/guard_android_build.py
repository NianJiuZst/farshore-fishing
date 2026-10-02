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
tmp_cache = Path(os.environ.get('GRADLE_USER_HOME',str(root/'build/gradle-home'))).resolve().is_relative_to(Path('/tmp'))
constrained = tmp_cache and os.environ.get('FARSHORE_REQUIRE_BACKUP_REUSE') == '1'
start_minimum = int((3.5 if constrained else 4) * 1024**3)
stop_floor = 768 * 1024**2
memory_floor = 1024**3
tmp_floor = 512 * 1024**2
def memory_available():
    for line in Path('/proc/meminfo').read_text().splitlines():
        if line.startswith('MemAvailable:'):return int(line.split()[1])*1024
    raise RuntimeError('Linux available-memory measurement is missing')
available = shutil.disk_usage(root).free
if sys.argv[1:] == ['--check']:
    print(json.dumps({'available_bytes':available,'start_minimum_bytes':start_minimum,'stop_floor_bytes':stop_floor,'memory_available_bytes':memory_available(),'tmpfs_free_bytes':shutil.disk_usage('/tmp').free}))
    raise SystemExit(0 if available >= start_minimum else 95)
if available < start_minimum:
    raise SystemExit('Build not started: disk budget below the guarded start threshold; retain sources/backups and review generated caches')
assert not tmp_cache or (memory_available() >= int(2.5*1024**3) and shutil.disk_usage('/tmp').free >= 1024**3), 'Insufficient memory/tmpfs budget for the scoped cache'
env = os.environ.copy()
env['FARSHORE_BUILD_SPACE_GUARDED'] = '1'
started = datetime.datetime.now(datetime.timezone.utc)
child = subprocess.Popen(['bash',str(root/'tools/android_build.sh'),*sys.argv[1:]],cwd=root,env=env,start_new_session=True)
minimum = available
stopped_for_space = False
stop_reason = None
minimum_memory = memory_available()
minimum_tmp = shutil.disk_usage('/tmp').free
while child.poll() is None:
    free = shutil.disk_usage(root).free
    minimum = min(minimum,free)
    minimum_memory = min(minimum_memory,memory_available())
    minimum_tmp = min(minimum_tmp,shutil.disk_usage('/tmp').free)
    if free < stop_floor or (tmp_cache and (minimum_memory < memory_floor or minimum_tmp < tmp_floor)):
        stopped_for_space = True
        stop_reason = 'root_disk' if free < stop_floor else ('available_memory' if minimum_memory < memory_floor else 'tmpfs')
        print('Stopping owned Android build at resource guard:',stop_reason,'; source/backups are preserved',flush=True)
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
report.update({'stop_reason':stop_reason,'minimum_available_memory_bytes':minimum_memory,'minimum_tmpfs_free_bytes':minimum_tmp,'tmpfs_cache':tmp_cache})
folder = root/'build/logs'
folder.mkdir(parents=True,exist_ok=True)
(folder/f'space-guard-{started.strftime("%Y%m%dT%H%M%SZ")}.json').write_text(json.dumps(report,indent=2)+'\n')
raise SystemExit(95 if stopped_for_space else (child.returncode or 0))
