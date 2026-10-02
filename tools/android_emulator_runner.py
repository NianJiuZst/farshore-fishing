"""Workspace-only Android16 test session, with file-queued adb commands.

The executor gives each command a separate network namespace, so the emulator and
adb must remain in this one process tree. Run only with authorized SDK/adb setup.
Write numbered JSON requests into build/android-control/requests/. Supported:
{"args":["shell","getprop","sys.boot_completed"],"timeout":30}
{"args":["exec-out","screencap","-p"],"binary_output":"screenshots/name.png"}
{"action":"stop"}. Results appear in build/android-control/results/.
"""
from pathlib import Path
import datetime
import json
import os
import subprocess
import time

root = Path(__file__).resolve().parent.parent
control = root/'build/android-control'
requests = control/'requests'; results = control/'results'
requests.mkdir(parents=True, exist_ok=True); results.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env.update({
    'HOME': str(root/'build/emulator-home'),
    'XDG_RUNTIME_DIR': str(root/'build/emulator-runtime'),
    'ANDROID_HOME': str(root/'tools/android-sdk'),
    'ANDROID_SDK_ROOT': str(root/'tools/android-sdk'),
    'ANDROID_USER_HOME': str(root/'build/android-user'),
    'ANDROID_AVD_HOME': str(root/'build/android-avd'),
})
for key in ['HOME', 'XDG_RUNTIME_DIR', 'ANDROID_USER_HOME']:
    Path(env[key]).mkdir(parents=True, exist_ok=True); Path(env[key]).chmod(0o700)
adb = root/'tools/android-sdk/platform-tools/adb'
subprocess.run([str(adb), 'start-server'], env=env, capture_output=True, timeout=30, check=True)
log = (root/'build/logs/emulator-run.log').open('wb')
emulator = subprocess.Popen([
    str(root/'tools/android-sdk/emulator/emulator'), '-avd', os.environ.get('FARSHORE_EMULATOR_AVD','farshore_api36_persistent'),
    '-no-window', '-no-snapshot', '-no-audio', '-no-boot-anim',
    '-no-metrics', '-accel', 'off', '-gpu', os.environ.get('FARSHORE_EMULATOR_GPU', 'swangle'), '-memory', os.environ.get('FARSHORE_EMULATOR_MEMORY','2560'),
    '-cores', '2', '-camera-back', 'none', '-camera-front', 'none',
], env=env, stdout=log, stderr=subprocess.STDOUT)
print('Android16 emulator session started', flush=True)
last_check = 0
try:
    while emulator.poll() is None:
        now = time.time()
        if now-last_check > 20:
            last_check = now
            try:
                p = subprocess.run([str(adb), '-s', 'emulator-5554', 'shell', 'getprop', 'sys.boot_completed'],
                                   env=env, capture_output=True, text=True, timeout=8)
                status = {'boot_completed': p.stdout.strip() == '1', 'adb_output': p.stdout.strip(),
                          'adb_error': p.stderr.strip(), 'checked_utc': datetime.datetime.now(datetime.timezone.utc).isoformat()}
            except subprocess.TimeoutExpired:
                status = {'boot_completed': None, 'adb_error': 'ADB boot query timed out'}
            (control/'state.json').write_text(json.dumps(status, indent=2)+'\n')
        for request in sorted(requests.glob('*.json')):
            reply = results/request.name
            if reply.exists():
                continue
            data = json.loads(request.read_text())
            if data.get('action') == 'stop':
                reply.write_text('{"stopped":true}\n')
                raise SystemExit(0)
            args = data['args']
            assert isinstance(args, list) and args and all(isinstance(x, str) for x in args)
            assert args[0] in {'shell', 'exec-out', 'install', 'logcat', 'get-state', 'get-serialno', 'emu'}, 'Unsupported adb test action'
            if args[0] == 'emu':
                assert args[1:] == ['kill'], 'Only emulator shutdown is supported'
            timeout = max(1, min(int(data.get('timeout', 60)), 240))
            try:
                p = subprocess.run([str(adb), '-s', 'emulator-5554', *args], env=env,
                                   capture_output=True, timeout=timeout)
                answer = {'returncode': p.returncode, 'stderr': p.stderr.decode(errors='replace')}
                if data.get('binary_output'):
                    target = (root/'build/android'/data['binary_output']).resolve()
                    assert target.is_relative_to((root/'build/android').resolve())
                    target.parent.mkdir(parents=True, exist_ok=True); target.write_bytes(p.stdout)
                    answer.update({'file': str(target), 'bytes':len(p.stdout)})
                else:
                    answer['stdout'] = p.stdout.decode(errors='replace')
            except subprocess.TimeoutExpired:
                answer = {'returncode': -1, 'stderr': 'ADB action timed out'}
            reply.write_text(json.dumps(answer, ensure_ascii=False, indent=2)+'\n')
        time.sleep(1)
    print('Emulator exited with code', emulator.returncode, flush=True)
finally:
    terminal = {'emulator_running':False, 'exit_code':emulator.poll(),
                'checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    if (control/'state.json').exists():
        previous = json.loads((control/'state.json').read_text())
        terminal['last_boot_query'] = previous
    (control/'state.json').write_text(json.dumps(terminal, indent=2)+'\n')
    emulator.terminate()
    try: emulator.wait(timeout=20)
    except subprocess.TimeoutExpired: emulator.kill(); emulator.wait()
    subprocess.run([str(adb), 'kill-server'], env=env, capture_output=True, timeout=10)
    log.close()
