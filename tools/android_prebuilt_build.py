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


def build(root, source_zip, manifest_path, template_path, output):
    root, source_zip, manifest_path, template_path, output = map(lambda p: Path(p).resolve(), [root, source_zip, manifest_path, template_path, output])
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
                                    'archive_sha256': digest(source_zip), 'sha256': content['three_d']['authoring_files_sha256']}}
    for name, sha in snapshot['sha256'].items():
        assert verified['game/' + name]['sha256'] == sha, 'Source archive is missing a current game input: ' + name
    for name, sha in snapshot['authoring_backup']['sha256'].items():
        assert verified[name]['sha256'] == sha, 'Source archive is missing a current authoring input: ' + name
    work = Path(tempfile.mkdtemp(prefix='farshore-prebuilt-' + version + '-'))
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
    snapshot['staging'] = {'path': str(stage), 'source_copy_verified_before_preset_changes': True,
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
              'runtime_boundary': 'Desktop gameplay evidence is separate. Android beta runtime and physical ARM64 performance remain unverified.',
              'root_free_bytes': shutil.disk_usage(root).free, 'tmp_free_bytes': shutil.disk_usage('/tmp').free}
    (audit/'prebuilt-finalization.json').write_text(json.dumps(result, indent=2) + '\n')
    assert work.parent == Path('/tmp') and work.name.startswith('farshore-prebuilt-') and not work.is_symlink()
    shutil.rmtree(work)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--source-zip', type=Path, required=True)
    parser.add_argument('--source-manifest', type=Path, required=True)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    build(args.root, args.source_zip, args.source_manifest, args.template, args.output)
