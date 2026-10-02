"""Create a smaller writable workspace AVD; does not start an emulator.

Requires the already-authorized official SDK/system image. This device stores only
the game's test data, allowing save/update tests across emulator restarts.
"""
from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parent.parent
env = os.environ.copy()
env.update({
    'JAVA_HOME':str(root/'tools/jdk/jdk-21.0.12.1+1'),
    'HOME':str(root/'build/emulator-home'),
    'ANDROID_HOME':str(root/'tools/android-sdk'),
    'ANDROID_SDK_ROOT':str(root/'tools/android-sdk'),
    'ANDROID_USER_HOME':str(root/'build/android-user'),
    'ANDROID_AVD_HOME':str(root/'build/android-avd'),
})
name = 'farshore_api36_persistent'
config = Path(env['ANDROID_AVD_HOME'])/(name+'.avd/config.ini')
if not config.exists():
    result = subprocess.run([
        str(root/'tools/android-sdk/cmdline-tools/latest/bin/avdmanager'),
        'create','avd','--name',name,'--package','system-images;android-36;default;x86_64',
        '--device','pixel_4a',
    ], input='no\n', text=True, env=env, capture_output=True, timeout=120)
    (root/'build/logs/persistent-avd-create.txt').write_text(result.stdout+result.stderr)
    assert result.returncode == 0 and config.is_file(), 'AVD creation failed; inspect build/logs/persistent-avd-create.txt'
changes = {
    'hw.lcd.width':'480','hw.lcd.height':'854','hw.lcd.density':'213',
    'hw.ramSize':'2560','hw.cpu.ncore':'2','disk.dataPartition.size':'6G',
    'hw.camera.back':'none','hw.camera.front':'none','hw.gpu.enabled':'yes',
    'hw.gpu.mode':'swangle','hw.audioInput':'no','hw.gps':'no','hw.sdCard':'no',
    'showDeviceFrame':'no','firstboot.saveToLocalSnapshot':'no',
    'fastboot.forceFastBoot':'no','fastboot.forceColdBoot':'yes',
}
lines = []
for line in config.read_text().splitlines():
    key=line.split('=',1)[0].strip()
    lines.append(key+'='+changes.pop(key) if key in changes else line)
lines.extend(k+'='+v for k,v in changes.items())
config.write_text('\n'.join(lines)+'\n')
print('Writable API36 test AVD prepared:480x854,213dpi,2560MiB RAM,6GiB data,swangle; emulator not started')
