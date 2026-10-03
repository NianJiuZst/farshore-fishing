"""Guarded isolated ARM64 export using a verified commit-exact source ZIP first.

Recovered pre-reset pipeline: do not run until a fresh source freeze and signing
identity are explicitly approved. This file does not create or replace any key.
The complete external source ZIP doubles as the runtime/authoring backup.
"""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from content_export_contract import content_contract
from release_source_zip import inventory, verify_zip, digest
from normalize_android_features import normalize_apk
from android_identity import expected_identity
from content_fish_art_contract import validate_import_audit, verify_exported_photo_art, photo_authoring_files, require_photo_archive_members
from content_natural_history_contract import natural_history_contract, require_natural_history_archive_members, verify_exported_natural_history


def source_inventory(base):
    result = {}
    for path in sorted(base.rglob('*')):
        relative = path.relative_to(base)
        if any(p in {'.godot', 'android', 'exported', '__pycache__'} for p in relative.parts):
            continue
        if path.is_file():
            assert not path.is_symlink()
            result[str(relative)] = digest(path)
    return result


def assert_source(root, snapshot):
    assert source_inventory(root / 'game') == snapshot['sha256'], 'Primary source drifted during export'
    for name, wanted in snapshot['authoring_backup']['sha256'].items():
        assert digest(root / name) == wanted, 'Primary authoring file drifted: ' + name


def command(args, env, log):
    with log.open('w') as output:
        subprocess.run([str(a) for a in args], env=env, stdout=output, stderr=subprocess.STDOUT, check=True)
    assert not re.search(r'SCRIPT ERROR:|Parse Error:|Failed to load script|Export failed|^ERROR:', log.read_text(), re.M), 'Engine errors in ' + str(log)


def checked_staging_parent(root, staging_parent=None):
    parent = Path('/tmp') if staging_parent is None else Path(staging_parent)
    assert parent.is_absolute(), 'Staging parent must be an absolute external directory'
    for part in (parent, *parent.parents):
        assert not part.is_symlink(), 'Staging parent and ancestors must not be symlinks'
    parent = parent.resolve()
    assert parent != Path('/') and not parent.is_relative_to(Path(root).resolve()), 'Staging parent must be outside the primary repository'
    assert not parent.exists() or parent.is_dir(), 'Staging parent is not a directory'
    return parent


def create_staging_work(root, version, staging_parent=None):
    parent = checked_staging_parent(root, staging_parent)
    assert re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', version), 'Unsafe staging version'
    parent.mkdir(parents=True, exist_ok=True)
    assert checked_staging_parent(root, parent) == parent
    work = Path(tempfile.mkdtemp(prefix='farshore-prebuilt-' + version + '-', dir=parent))
    assert not work.is_symlink() and work.resolve().parent == parent
    stat = work.stat()
    return work, (stat.st_dev, stat.st_ino)


def remove_staging_work(root, work, owned_identity, staging_parent=None):
    """Remove only the exact new directory this invocation created, after success."""
    parent = checked_staging_parent(root, staging_parent)
    work = Path(work)
    assert work.parent == parent and re.fullmatch(r'farshore-prebuilt-[A-Za-z0-9._-]+', work.name), 'Cleanup target is not an owned staging directory'
    assert work.is_dir() and not work.is_symlink() and work.resolve().parent == parent, 'Unsafe staging cleanup target'
    stat = work.stat()
    assert (stat.st_dev, stat.st_ino) == owned_identity, 'Owned staging directory was replaced'
    assert shutil.rmtree.avoids_symlink_attacks, 'Safe staging cleanup requires descriptor-based removal'
    shutil.rmtree(work)


def build(root, source_zip, manifest_path, template_path, output, staging_parent=None):
    root, source_zip, manifest_path, template_path, output = map(lambda p: Path(p).resolve(), [root, source_zip, manifest_path, template_path, output])
    staging_parent = checked_staging_parent(root, staging_parent)
    assert not source_zip.is_relative_to(root), 'Source release archive must be outside project'
    assert not output.exists(), 'Never overwrite an existing player release'
    report = json.loads(manifest_path.read_text())
    commit, tracked = inventory(root, report['source_commit'])
    assert digest(source_zip) == report['source_archive']['sha256']
    assert set(tracked) == set(report['files'])
    verified = verify_zip(source_zip, tracked, report['source_archive']['prefix'])
    for name, expected in verified.items():
        assert digest(root / name) == expected['sha256'], 'Source differs from frozen commit: ' + name
    source = root / 'game'
    content = content_contract(source)
    content['natural_history'] = natural_history_contract(source, content['species_ids'])
    require_photo_archive_members(root, verified, content['photo_art'])
    require_natural_history_archive_members(root, verified, content['natural_history'])
    identity = expected_identity(content)
    is_preview = identity['android_package_name'] == 'org.farshore.fishing.preview'
    default_signing = Path('/workspace/shared/.signing-private/farshore-fishing-preview') if is_preview else root.parent/'.signing-private/farshore-fishing'
    signing = Path(os.environ.get('FARSHORE_SIGNING_DIR', str(default_signing)))
    key = Path(os.environ.get('FARSHORE_KEYSTORE', str(signing/('farshore-preview-release.p12' if is_preview else 'farshore-release.p12'))))
    password = Path(os.environ.get('FARSHORE_PASSWORD_FILE', str(signing/'keystore-password.txt')))
    alias = os.environ.get('FARSHORE_KEY_ALIAS', 'farshore-preview-release' if is_preview else 'farshore-release')
    assert key.is_file() and password.is_file(), 'Restore the already-approved signing identity before export'
    public_certificate = subprocess.check_output([str(root/'tools/jdk/jdk-21.0.12.1+1/bin/keytool'), '-exportcert', '-alias', alias,
                                                  '-keystore', str(key), '-storepass:file', str(password)], stderr=subprocess.PIPE)
    assert hashlib.sha256(public_certificate).hexdigest() == identity['certificate_sha256'], 'Protected key differs from frozen public identity'
    version = content['application_version']
    assert content['android_version_code'] > 3
    audit = root / 'build/audit' / version / 'arm64'
    audit.mkdir(parents=True, exist_ok=False)
    snapshot = {'source_commit': commit, 'archive': str(source_zip), 'archive_kind': 'verified_release_zip',
                'archive_sha256': digest(source_zip), 'sha256': source_inventory(source), 'content': content,
                'authoring_backup': {'archive': str(source_zip), 'archive_kind': 'verified_release_zip',
                                    'archive_sha256': digest(source_zip),
                                    'sha256': {**content['three_d']['authoring_files_sha256'], **photo_authoring_files(root, content['photo_art'])}}}
    for name, sha in snapshot['sha256'].items():
        assert verified['game/' + name]['sha256'] == sha, 'Source archive is missing a current game input: ' + name
    for name, sha in snapshot['authoring_backup']['sha256'].items():
        assert verified[name]['sha256'] == sha, 'Source archive is missing a current authoring input: ' + name
    work, staging_identity = create_staging_work(root, version, staging_parent)
    stage = work / 'game'
    shutil.copytree(source, stage, ignore=shutil.ignore_patterns('android', 'exported', '__pycache__'))
    assert source_inventory(stage) == snapshot['sha256']
    for name in snapshot['sha256']:
        assert not os.path.samestat((source/name).stat(), (stage/name).stat()), 'Mutable source was hardlinked'
    assert_source(root, snapshot)
    shutil.rmtree(stage / 'tests')
    android = stage / 'android'; android.mkdir(); (android / '.gdignore').touch()
    preset = stage / 'export_presets.cfg'
    original_preset = preset.read_text()
    settings = original_preset.replace('gradle_build/use_gradle_build=true', 'gradle_build/use_gradle_build=false')
    settings = settings.replace('custom_template/release=""', 'custom_template/release=' + json.dumps(str(template_path)))
    settings = re.sub(r'^gradle_build/(min_sdk|target_sdk)="[^"]*"', r'gradle_build/\1=""', settings, flags=re.M)
    assert 'res://../' not in settings and 'gradle_build/gradle_build_directory="res://android"' in settings
    preset.write_text(settings)
    snapshot['staging'] = {'path': str(stage), 'parent': str(staging_parent), 'owned_directory_identity': list(staging_identity),
                           'source_copy_verified_before_preset_changes': True,
                           'hardlinks': False, 'gradle_directory': 'res://android', 'export_method': 'official_derived_prebuilt_template',
                           'source_preset_sha256': hashlib.sha256(original_preset.encode()).hexdigest(),
                           'staged_preset_sha256': digest(preset), 'derived_template_sha256': digest(template_path),
                           'changes': ['Disable Gradle only in disposable copy', 'Select audited derived official template',
                                       'Clear Gradle-only min/target override fields; actual template is API29/36', 'Omit source tests only from disposable copy']}
    snapshot_path = work / 'source-snapshot.json'
    snapshot_path.write_text(json.dumps(snapshot, indent=2) + '\n')
    shutil.copy2(snapshot_path, audit / 'source-snapshot-manifest.json')
    env = os.environ.copy()
    env.update(JAVA_HOME=str(root/'tools/jdk/jdk-21.0.12.1+1'), ANDROID_HOME=str(root/'tools/android-sdk'),
               ANDROID_SDK_ROOT=str(root/'tools/android-sdk'), XDG_CONFIG_HOME=str(work/'config'),
               XDG_DATA_HOME=str(work/'data'), XDG_CACHE_HOME=str(work/'cache'), GRADLE_USER_HOME=str(work/'unused-gradle'),
               ANDROID_USER_HOME=str(root/'build/android-user'), FARSHORE_ROOT=str(root),
               FARSHORE_EXISTING_KEY=str(key))
    env['PATH'] = env['JAVA_HOME'] + '/bin:' + env['PATH']
    subprocess.run([sys.executable, str(root/'tools/prepare_android_environment.py')], check=True, env=env)
    godot = os.environ.get('GODOT', shutil.which('godot'))
    assert subprocess.check_output([godot, '--version'], text=True).strip() == '4.6.3.stable.official.7d41c59c4'
    command([godot, '--headless', '--path', stage, '--import'], env, audit/'import.log')
    command([godot, '--headless', '--path', stage, '--script', root/'tools/inspect_imported_fish_art.gd', '--', snapshot_path, audit/'imported-fish-art.json'], env, audit/'imported-fish-art.log')
    photo_audit = json.loads((audit/'imported-fish-art.json').read_text())
    validate_import_audit(content['photo_art'], photo_audit)
    command([godot, '--headless', '--path', stage, '--script', root/'tools/inspect_imported_3d.gd', '--', snapshot_path, audit/'imported-3d-scenes.json'], env, audit/'imported-3d.log')
    subprocess.run([sys.executable, str(root/'tools/content_3d_contract.py'), str(stage), str(audit/'imported-3d-scenes.json')], check=True)
    unsigned, aligned = work/'unsigned.apk', work/'aligned.apk'
    command([godot, '--headless', '--path', stage, '--export-release', 'Android ARM64 Release', unsigned], env, audit/'export.log')
    normalized = work/'normalized-unsigned.apk'
    normalization = normalize_apk(unsigned, normalized)
    (audit/'vulkan-type-normalization.json').write_text(json.dumps(normalization, indent=2)+'\n')
    unsigned.unlink()
    unsigned = normalized
    assert_source(root, snapshot)
    with zipfile.ZipFile(unsigned) as archive:
        assert archive.testzip() is None and 'assets/project.binary' in archive.namelist()
        assert all(i.compress_type == zipfile.ZIP_STORED for i in archive.infolist() if i.filename.startswith('lib/') and i.filename.endswith('.so'))
        # Reject stale/remapped photo payloads before invoking the signing tool.
        verify_exported_photo_art(archive, content['photo_art'], photo_audit)
        verify_exported_natural_history(archive, content['natural_history'])
    verify_zip(source_zip, report['files'], report['source_archive']['prefix'])
    assert digest(source_zip) == report['source_archive']['sha256']
    bt = root/'tools/android-sdk/build-tools/36.1.0'
    subprocess.run([str(bt/'zipalign'), '-P', '16', '-f', '4', str(unsigned), str(aligned)], env=env, check=True)
    unsigned.unlink()
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([str(bt/'apksigner'), 'sign', '--ks', str(key), '--ks-key-alias', alias,
                    '--ks-pass', 'file:' + str(password), '--v1-signing-enabled', 'false',
                    '--v2-signing-enabled', 'true', '--v3-signing-enabled', 'true', '--v4-signing-enabled', 'false',
                    '--out', str(output), str(aligned)], env=env, check=True)
    with (audit/'verification.log').open('w') as log:
        subprocess.run([sys.executable, str(root/'tools/verify_android_apk.py'), str(output), 'arm64-v8a', str(audit), str(bt), str(snapshot_path)],
                       env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
    with zipfile.ZipFile(template_path) as template, zipfile.ZipFile(output) as apk:
        natural_history_audit = verify_exported_natural_history(apk, content['natural_history'])
        (audit/'exported-natural-history.json').write_text(json.dumps(natural_history_audit, indent=2) + '\n')
        native_hashes = {}
        for name in template.namelist():
            if name.startswith('lib/') and name.endswith('.so'):
                assert apk.read(name) == template.read(name), 'Packaged native bytes differ from reviewed official template'
                native_hashes[name] = hashlib.sha256(apk.read(name)).hexdigest()
    assert_source(root, snapshot)
    result = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source_commit': commit,
              'apk': str(output), 'bytes': output.stat().st_size, 'sha256': digest(output),
              'source_zip_sha256': digest(source_zip), 'source_and_authoring_unchanged': True,
              'native_bytes_match_official_template': native_hashes, 'all_existing_static_gates_passed': True,
              'natural_history': natural_history_audit,
              'runtime_boundary': 'Desktop gameplay evidence is separate. Android beta runtime and physical ARM64 performance remain unverified.',
              'root_free_bytes': shutil.disk_usage(root).free, 'tmp_free_bytes': shutil.disk_usage('/tmp').free}
    (audit/'prebuilt-finalization.json').write_text(json.dumps(result, indent=2) + '\n')
    remove_staging_work(root, work, staging_identity, staging_parent)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--source-zip', type=Path, required=True)
    parser.add_argument('--source-manifest', type=Path, required=True)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--staging-parent', type=Path, help='Absolute directory outside the repository for a new owned staging directory (default: /tmp)')
    args = parser.parse_args()
    build(args.root, args.source_zip, args.source_manifest, args.template, args.output, args.staging_parent)
