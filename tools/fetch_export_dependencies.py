"""Fetch pinned, checksum-verified official Godot/JDK packages into tools/.

Android SDK licensing/setup is intentionally separate. This never creates keys.
"""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import tarfile
import zipfile

root = Path(__file__).resolve().parent.parent
downloads = root / 'tools/downloads'
downloads.mkdir(parents=True, exist_ok=True)

def fetch(url, filename, algorithm, expected):
    path = downloads / filename
    if not path.exists():
        subprocess.run(['curl', '-fLsS', '--retry', '2', '--connect-timeout', '20',
                        '--max-time', '1200', url, '-o', str(path)], check=True)
    with path.open('rb') as f:
        got = hashlib.file_digest(f, algorithm).hexdigest()
    if got != expected:
        raise RuntimeError(f'Checksum mismatch: {filename}; do not use this file')
    print(f'Verified {filename}: {algorithm} {got}')
    return path

godot_base = 'https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/'
templates = fetch(godot_base + 'Godot_v4.6.3-stable_export_templates.tpz',
    'Godot_v4.6.3-stable_export_templates.tpz', 'sha512',
    'da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68')
template_dir = root/'tools/godot-templates/4.6.3.stable'
template_dir.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(templates) as z:
    for name in ['android_source.zip', 'android_release.apk', 'android_debug.apk', 'version.txt']:
        target = template_dir/name
        if not target.exists():
            target.write_bytes(z.read('templates/'+name))
gradle = root/'tools/android-gradle/build'
if not (gradle/'build.gradle').is_file():
    gradle.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(template_dir/'android_source.zip') as z:
        for info in z.infolist():
            target = (gradle/info.filename).resolve()
            if not target.is_relative_to(gradle.resolve()):
                raise RuntimeError('Unsafe archive path')
        z.extractall(gradle)
    (gradle/'gradlew').chmod(0o755)
    (gradle.parent/'.build_version').write_text('4.6.3.stable\n')

jdk_archive = fetch(
    'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz',
    'OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz', 'sha256',
    'ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94')
jdk = root/'tools/jdk/jdk-21.0.12.1+1'
if not (jdk/'bin/javac').is_file():
    jdk.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(jdk_archive) as t:
        t.extractall(jdk.parent, filter='data')

# The editor is normally already provided by the workspace. If absent, use the
# official release's published checksum list, then extract its sole Linux binary.
editor = shutil.which(os.environ.get('GODOT', 'godot'))
if not editor:
    sums = downloads/'Godot-4.6.3-SHA512-SUMS.txt'
    if not sums.exists():
        subprocess.run(['curl', '-fLsS', '--retry', '2', godot_base+'SHA512-SUMS.txt', '-o', str(sums)], check=True)
    filename = 'Godot_v4.6.3-stable_linux.x86_64.zip'
    checksum = next(line.split()[0] for line in sums.read_text().splitlines() if line.split()[-1] == filename)
    archive = fetch(godot_base+filename, filename, 'sha512', checksum)
    dest = root/'tools/godot'
    dest.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        name = 'Godot_v4.6.3-stable_linux.x86_64'
        (dest/name).write_bytes(z.read(name))
        (dest/name).chmod(0o755)
print('Official Godot/JDK prerequisites ready; Android SDK setup and existing signing-key restoration remain separate')
