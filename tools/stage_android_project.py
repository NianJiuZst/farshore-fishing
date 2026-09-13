"""Snapshot and copy source before exporting from an isolated, in-project Gradle tree.

Never pass res://../ paths to Godot's Gradle exporter. It performs recursive asset
directory cleanup and must only see a throwaway project with a standard android/.
"""
from pathlib import Path
import datetime
import hashlib
import json
import os
import shutil
import sys
import tarfile
import zipfile
import re

root = Path(__file__).resolve().parent.parent
source = root/'game'
abi = sys.argv[1]
assert (source/'project.godot').is_file() and (source/'scripts/main.gd').stat().st_size > 1000
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
snapshot_dir = root/'build/source-snapshots'
snapshot_dir.mkdir(parents=True, exist_ok=True)
stage = root/'build/android-workspaces'/f'{stamp}-{abi}'
stage.mkdir(parents=True)

def digest_files(base):
    result = {}
    for path in sorted(base.rglob('*')):
        if not path.is_file() or any(p in {'.godot', 'android', 'exported'} for p in path.relative_to(base).parts):
            continue
        rel = str(path.relative_to(base))
        assert not path.is_symlink(), 'Symlinked source files are not accepted in an export snapshot'
        with path.open('rb') as f:
            result[rel] = hashlib.file_digest(f, 'sha256').hexdigest()
    return result

before = digest_files(source)
assert len(before) > 75, 'Incomplete project: refusing export'
assert len(list((source/'assets/fish').glob('*_thumb.png'))) == 32, 'Missing fish artwork: refusing export'
assert not any(Path(p).suffix in {'.p12', '.jks', '.keystore'} for p in before), 'Signing material must never be inside game/'
archive = snapshot_dir/f'game-{stamp}.tar.gz'
with tarfile.open(archive, 'w:gz') as tar:
    for relative in before:
        tar.add(source/relative, arcname='game/'+relative, recursive=False)
shutil.copytree(source, stage, dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('.godot', 'android', 'exported'))
after = digest_files(source)
copied = digest_files(stage)
if before != after or before != copied:
    raise RuntimeError('Source changed during snapshot; retry after source freeze, no export performed')
(snapshot_dir/f'game-{stamp}.sha256.json').write_text(json.dumps(before, indent=2)+'\n')
# Physically omit development tests from the exported copy; never remove source tests.
if (stage/'tests').exists():
    shutil.rmtree(stage/'tests')
for temporary in ['recover.gd', 'recover.gd.uid', 'recovered.json']:
    if (stage/temporary).exists():
        (stage/temporary).unlink()
android = stage/'android'
gradle = android/'build'
gradle.mkdir(parents=True)
(android/'.gdignore').touch()
(android/'.build_version').write_text('4.6.3.stable\n')
with zipfile.ZipFile(root/'tools/godot-templates/4.6.3.stable/android_source.zip') as z:
    for info in z.infolist():
        if not (gradle/info.filename).resolve().is_relative_to(gradle.resolve()):
            raise RuntimeError('Unsafe template archive path')
    z.extractall(gradle)
(gradle/'gradlew').chmod(0o755)
presets = stage/'export_presets.cfg'
text = presets.read_text()
text = re.sub(r'gradle_build/gradle_build_directory="[^"]*"', 'gradle_build/gradle_build_directory="res://android"', text)
if os.environ.get('FARSHORE_TEST_VERSION_CODE'):
    version = int(os.environ['FARSHORE_TEST_VERSION_CODE'])
    assert version > 1
    text = re.sub(r'version/code=\d+', f'version/code={version}', text)
presets.write_text(text)
(stage.parent/(stage.name+'.snapshot.json')).write_text(json.dumps({'archive':str(archive),'sha256':before},indent=2)+'\n')
print(stage)
