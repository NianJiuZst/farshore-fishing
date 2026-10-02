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
from content_export_contract import content_contract

root = Path(__file__).resolve().parent.parent
source = root/'game'
assert not source.is_symlink(), 'Primary project must be a real directory'
abi = sys.argv[1]
assert (source/'project.godot').is_file() and (source/'scripts/main.gd').stat().st_size > 1000
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
snapshot_dir = Path(os.environ.get('FARSHORE_BACKUP_DIR', str(root.parent/(root.name+'-checkpoints')))).expanduser().resolve()
assert not snapshot_dir.is_relative_to(root.resolve()), 'Source backups must be outside the project tree'
snapshot_dir.mkdir(parents=True, exist_ok=True)
stage = root/'build/android-workspaces'/f'{stamp}-{abi}'
stage.mkdir(parents=True)
assert stage.resolve().is_relative_to((root/'build/android-workspaces').resolve())
assert not stage.resolve().is_relative_to(source.resolve())

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
content = content_contract(source)
authoring_proof = None
if content.get('three_d'):
    authoring_hashes = content['three_d']['authoring_files_sha256']
    authoring_archive = snapshot_dir/f'authoring-{stamp}.tar.gz'
    with tarfile.open(authoring_archive, 'w:gz') as tar:
        for relative in authoring_hashes:
            tar.add(root/relative, arcname=relative, recursive=False)
    with tarfile.open(authoring_archive, 'r:gz') as tar:
        actual = {}
        for member in tar:
            assert member.isfile()
            with tar.extractfile(member) as stream:
                actual[member.name] = hashlib.file_digest(stream, 'sha256').hexdigest()
        assert actual == authoring_hashes, 'Authoring backup does not match source hashes'
    with authoring_archive.open('rb') as stream:
        authoring_proof = {'archive':str(authoring_archive), 'archive_sha256':hashlib.file_digest(stream,'sha256').hexdigest(), 'sha256':authoring_hashes}
assert not any(Path(p).suffix in {'.p12', '.jks', '.keystore'} for p in before), 'Signing material must never be inside game/'
archive = snapshot_dir/f'game-{stamp}.tar.gz'
with tarfile.open(archive, 'w:gz') as tar:
    for relative in before:
        tar.add(source/relative, arcname='game/'+relative, recursive=False)
with tarfile.open(archive, 'r:gz') as tar:
    archived = {}
    for member in tar:
        assert member.isfile(), 'Unexpected non-file entry in source backup'
        stream = tar.extractfile(member)
        assert stream is not None
        with stream:
            archived[member.name.removeprefix('game/')] = hashlib.file_digest(stream, 'sha256').hexdigest()
    assert archived == before, 'Source backup bytes do not match the source inventory'
with archive.open('rb') as stream:
    archive_sha256 = hashlib.file_digest(stream, 'sha256').hexdigest()
shutil.copytree(source, stage, dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('.godot', 'android', 'exported'))
after = digest_files(source)
copied = digest_files(stage)
if authoring_proof:
    for relative, expected in authoring_proof['sha256'].items():
        with (root/relative).open('rb') as stream:
            assert hashlib.file_digest(stream,'sha256').hexdigest() == expected, f'Authoring source changed during snapshot: {relative}'
if before != after or before != copied:
    changed = sorted(k for k in set(before)|set(after)|set(copied)
                     if before.get(k) != after.get(k) or before.get(k) != copied.get(k))
    invalid = archive.with_name(archive.name.removesuffix('.tar.gz')+'.unverified.tar.gz')
    archive.rename(invalid)
    invalid.with_suffix('.INVALID.txt').write_text('Concurrent source changes; not a verified restore checkpoint.\n'+'\n'.join(changed)+'\n')
    raise RuntimeError('Source changed during snapshot; no export performed. Changed: '+', '.join(changed))
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
assert 'res://../' not in text
assert all(value == 'res://android' for value in re.findall(r'gradle_build/gradle_build_directory="([^"]*)"', text))
# These are the two directories the official exporter recursively clears. Verify
# they resolve strictly inside the disposable copy, before invoking Godot.
cleanup_targets = [gradle/'src/main/assets', gradle/'assetPackInstallTime/src/main/assets']
for target in cleanup_targets:
    assert target.resolve().is_relative_to(stage.resolve())
    assert not target.resolve().is_relative_to(source.resolve())
    assert target.resolve() != stage.resolve()
    for parent in [target, *target.parents]:
        if parent == stage.parent:
            break
        assert not parent.is_symlink(), f'Symlink in Gradle cleanup target: {parent}'
(stage.parent/(stage.name+'.snapshot.json')).write_text(json.dumps({'archive':str(archive),'archive_sha256':archive_sha256,'authoring_backup':authoring_proof,'sha256':before,'content':content},indent=2)+'\n')
print(stage)
