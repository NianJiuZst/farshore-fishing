"""Build an explicitly internal unsigned APK for owner-controlled local signing.

This is not a release builder. It never signs, installs, uploads, runs adb/keytool,
or creates credentials. A frozen full source ZIP and approved public certificate
pin are mandatory. The normal signed builder and verifier remain unchanged.
"""
if not __debug__:
    raise RuntimeError('Safety checks require unoptimized Python; -O and PYTHONOPTIMIZE are forbidden')

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
import unicodedata
from android_identity import expected_identity, PREVIEW, LEGACY
from android_prebuilt_build import source_inventory, command, checked_staging_parent
from content_export_contract import content_contract
from content_fish_art_contract import validate_import_audit, require_photo_archive_members, photo_authoring_files
from content_natural_history_contract import natural_history_contract, require_natural_history_archive_members, verify_exported_natural_history
from normalize_android_features import normalize_apk
from release_source_zip import inventory, verify_zip, digest

GODOT_VERSION = '4.6.3.stable.official.7d41c59c4'
TEMPLATE_SHA256 = '27dcf3ecf8dbf48725d8fc5a9c8d807385c9586d8a6c2d00a69ad7833e7c5eca'
UPSTREAM_SHA256 = '9bb2416174a1e262a4282baaf346b118be921d4e3d78755743e1b1a6cb21bfd4'
UPSTREAM_URL = 'https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp'


def require_public_signer(content, public_certificate):
    assert isinstance(public_certificate, str) and re.fullmatch(r'[0-9a-f]{64}', public_certificate), 'A lowercase public certificate SHA256 is required'
    assert public_certificate not in {PREVIEW['certificate_sha256'], LEGACY['certificate_sha256']}, 'Old package signers must not be substituted'
    identity = expected_identity(content)  # Retains the strict provisioned-signer gate.
    assert identity['android_package_name'] == 'org.farshore.fishing.ocean', 'Only the authorized separate ocean package is allowed'
    assert identity['launcher_name'] == '远岸钓鱼·海洋'
    assert identity['application_version'] == '1.3.0' and identity['android_version_code'] == 7
    assert identity['certificate_sha256'] == public_certificate, 'Provided public certificate differs from pinned source'
    assert identity.get('separate_installation') is True
    return identity


def external_path(root, path, *, absent=False):
    root, path = Path(root).resolve(), Path(path)
    assert path.is_absolute(), 'Use absolute external paths'
    assert all(not p.is_symlink() for p in (path, *path.parents)), 'Symlinked output/ancestor refused'
    path = path.resolve()
    assert path != Path('/') and not path.is_relative_to(root) and not root.is_relative_to(path), 'Path must be outside, and not an ancestor of, the primary repository'
    if absent:
        assert not path.exists(), 'Existing outputs and audit evidence are immutable'
    return path


def parse_canonical_presets(text):
    """Parse the small frozen ConfigFile subset and reject ambiguous assignments.

    Godot permits whitespace around names and duplicate later assignments. This
    deliberately accepts only the checked-in canonical form, rather than counting
    false lines that a later noncanonical assignment could override.
    """
    assert all(character == '\n' or unicodedata.category(character) not in {'Cc', 'Cf', 'Zl', 'Zp'} for character in text), 'Control or separator characters in presets refused'
    sections, current = {}, None
    for line in text.split('\n'):
        if line == '':
            continue
        assert line == line.strip(), 'Noncanonical preset whitespace refused'
        if line.startswith(';'):
            continue
        section = re.fullmatch(r'\[(preset\.[01](?:\.options)?)\]', line)
        if section:
            current = section.group(1)
            assert current not in sections, 'Duplicate preset section refused'
            sections[current] = {}
            continue
        assignment = re.fullmatch(r'([A-Za-z0-9_/.-]+)=(.*)', line)
        assert current is not None and assignment, 'Noncanonical preset assignment refused'
        key, value = assignment.groups()
        if value.startswith('"'):
            try:
                parsed = json.loads(value)
            except (ValueError, TypeError) as error:
                raise AssertionError('Incomplete or noncanonical string value refused: ' + key) from error
            assert isinstance(parsed, str), 'Expected a single complete quoted string'
        else:
            assert value in {'true', 'false', 'PackedStringArray()'} or re.fullmatch(r'-?(0|[1-9][0-9]*)', value), 'Unsupported or multiline preset value refused: ' + key
        assert key not in sections[current], 'Duplicate preset setting refused: ' + key
        assert not key.startswith('keystore/'), 'Credential settings refused'
        sections[current][key] = value
    assert set(sections) == {'preset.0', 'preset.0.options', 'preset.1', 'preset.1.options'}, 'Expected exactly two complete presets'
    return sections


def staged_presets(text, template):
    sections = parse_canonical_presets(text)
    for index in range(2):
        preset, options = sections[f'preset.{index}'], sections[f'preset.{index}.options']
        assert preset.get('runnable') == 'false', 'Runnable presets can start adb; refusing'
        assert options.get('package/signed') == 'false', 'Only unsigned export is authorized'
        assert options.get('gradle_build/gradle_build_directory') == '"res://android"', 'Unsafe Gradle directory refused'
        assert options.get('gradle_build/use_gradle_build') == 'true', 'Unexpected source export route'
        assert options.get('custom_template/release') == '""', 'Source template override refused'
    assert 'res://../' not in text
    assert sections['preset.0']['name'] == '"Android ARM64 Release"'
    result = text.replace('gradle_build/use_gradle_build=true', 'gradle_build/use_gradle_build=false')
    result = result.replace('custom_template/release=""', 'custom_template/release=' + json.dumps(str(template)))
    result = re.sub(r'^gradle_build/(min_sdk|target_sdk)="[^\"]*"', r'gradle_build/\1=""', result, flags=re.M)
    staged = parse_canonical_presets(result)
    for index in range(2):
        assert staged[f'preset.{index}']['runnable'] == 'false'
        assert staged[f'preset.{index}.options']['package/signed'] == 'false'
        assert staged[f'preset.{index}.options']['gradle_build/use_gradle_build'] == 'false'
    return result


def assert_frozen_files(root, files):
    for name, wanted in files.items():
        path = root/name
        assert path.is_file() and not path.is_symlink(), 'Missing or unsafe frozen input: ' + name
        assert digest(path) == wanted['sha256'], 'Working input differs from frozen commit: ' + name


def credential_candidates(work):
    return sorted(str(p.relative_to(work)) for p in work.rglob('*') if p.is_file() and
                  (p.suffix.lower() in {'.p12', '.jks', '.keystore', '.pem', '.key'} or p.name.startswith('adbkey')))


def isolated_environment(root, work):
    sentinel = work/'INERT-NONKEY-DO-NOT-SIGN.txt'
    sentinel.write_text('INERT TEXT. Not a keystore, key or credential. Unsigned internal export only.\n')
    config = work/'config/godot'
    config.mkdir(parents=True)
    java, sdk = root/'tools/jdk/jdk-21.0.12.1+1', root/'tools/android-sdk'
    assert (java/'bin/java').is_file() and (sdk/'build-tools/36.1.0/apksigner').is_file()
    assert (sdk/'platform-tools/adb').is_file(), 'Restore official platform-tools without running adb'
    settings = '\n'.join([
        '[gd_resource type="EditorSettings" format=3]', '', '[resource]',
        'export/android/java_sdk_path=' + json.dumps(str(java)),
        'export/android/android_sdk_path=' + json.dumps(str(sdk)),
        'export/android/debug_keystore=' + json.dumps(str(sentinel)),
        'export/android/debug_keystore_user=""', 'export/android/debug_keystore_pass=""',
        'export/android/shutdown_adb_on_exit=false', '',
    ])
    (config/'editor_settings-4.6.tres').write_text(settings)
    templates = work/'data/godot/export_templates/4.6.3.stable'
    templates.parent.mkdir(parents=True)
    templates.symlink_to(root/'tools/godot-templates/4.6.3.stable', target_is_directory=True)
    env = os.environ.copy()
    env.pop('PYTHONOPTIMIZE', None)
    for key in list(env):
        if 'KEYSTORE' in key or re.search(r'FARSHORE_(SIGNING|KEY|PASSWORD)', key):
            env.pop(key)
    env.update(HOME=str(work/'home'), JAVA_HOME=str(java), ANDROID_HOME=str(sdk), ANDROID_SDK_ROOT=str(sdk),
               XDG_CONFIG_HOME=str(work/'config'), XDG_DATA_HOME=str(work/'data'), XDG_CACHE_HOME=str(work/'cache'),
               GRADLE_USER_HOME=str(work/'unused-gradle'), ANDROID_USER_HOME=str(work/'android-user'),
               TMPDIR=str(work/'tmp'), PYTHONPATH=str(root/'tools'), GODOT_SILENCE_ROOT_WARNING='1')
    env['PATH'] = str(java/'bin') + ':' + env['PATH']
    for name in ['home', 'cache', 'tmp', 'android-user']:
        (work/name).mkdir()
    return env, sentinel


def verify_isolated_controls(work, sentinel, sentinel_sha, preset, preset_sha):
    assert sentinel.is_file() and not sentinel.is_symlink() and digest(sentinel) == sentinel_sha, 'Inert guard file changed'
    assert digest(preset) == preset_sha, 'Staged export controls changed'
    settings = (work/'config/godot/editor_settings-4.6.tres').read_text()
    for name, wanted in [('debug_keystore', str(sentinel)), ('debug_keystore_user', ''), ('debug_keystore_pass', '')]:
        values = re.findall(r'^export/android/' + name + r'\s*=\s*(.*?)\s*$', settings, re.M)
        assert len(values) == 1 and json.loads(values[0]) == wanted, 'Isolated editor credential controls changed: ' + name
    assert credential_candidates(work) == [], 'Unexpected generated credential files'


def owned_cleanup(root, work, owner):
    work = Path(work)
    external_path(root, work)
    assert work.name.startswith('farshore-UNSIGNED-INTERNAL-') and work.is_dir() and not work.is_symlink()
    assert (work.stat().st_dev, work.stat().st_ino) == owner, 'Owned workspace identity changed'
    assert shutil.rmtree.avoids_symlink_attacks
    shutil.rmtree(work)


def build(root, source_zip, source_manifest, template, output, audit, public_certificate, upstream_source, staging_parent=None):
    root = Path(root).resolve()
    source_zip = external_path(root, source_zip)
    source_manifest = external_path(root, source_manifest)
    output = external_path(root, output, absent=True)
    audit = external_path(root, audit, absent=True)
    assert 'UNSIGNED-INTERNAL' in output.name and output.suffix == '.apk', 'Output must be visibly marked UNSIGNED-INTERNAL'
    assert not output.is_relative_to(audit) and not audit.is_relative_to(output)
    template, upstream_source = Path(template).resolve(), Path(upstream_source).resolve()
    assert digest(template) == TEMPLATE_SHA256, 'Only the reviewed official-derived ARM64 template is allowed'
    assert digest(upstream_source) == UPSTREAM_SHA256, 'Pinned Godot exporter source proof is required'
    parent = checked_staging_parent(root, staging_parent or root.parent/'farshore-unsigned-workspaces')
    report = json.loads(source_manifest.read_text())
    commit, tracked = inventory(root, report['source_commit'])
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip() == commit, 'Freeze must be current HEAD'
    assert digest(source_zip) == report['source_archive']['sha256']
    assert set(tracked) == set(report['files'])
    verified = verify_zip(source_zip, tracked, report['source_archive']['prefix'])
    assert all(verified[n]['sha256'] == report['files'][n]['sha256'] for n in verified)
    required_helpers = ['tools/android_unsigned_handoff.py', 'tools/verify_unsigned_android_handoff.py']
    assert all(name in verified for name in required_helpers), 'Handoff helpers must be part of the frozen source ZIP'
    assert_frozen_files(root, verified)
    source = root/'game'
    content = content_contract(source)
    identity = require_public_signer(content, public_certificate)
    assert content['species_count'] == 74 and content['bait_count'] == 12 and len(content['ui_icon_files']) == 35, 'Final ocean content freeze is incomplete'
    content['natural_history'] = natural_history_contract(source, content['species_ids'])
    require_photo_archive_members(root, verified, content['photo_art'])
    require_natural_history_archive_members(root, verified, content['natural_history'])
    source_hashes = source_inventory(source)
    assert {'game/' + n for n in source_hashes} == {n for n in verified if n.startswith('game/')}, 'Untracked or omitted game input'
    assert all(source_hashes[n] == verified['game/' + n]['sha256'] for n in source_hashes)
    original_preset = (source/'export_presets.cfg').read_text()
    changed_preset = staged_presets(original_preset, template)  # Check before creating any editor settings.
    godot = os.environ.get('GODOT', shutil.which('godot'))
    assert godot and subprocess.check_output([godot, '--version'], text=True).strip() == GODOT_VERSION
    audit.mkdir(parents=True)
    parent.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix='farshore-UNSIGNED-INTERNAL-', dir=parent))
    owner = (work.stat().st_dev, work.stat().st_ino)
    stage = work/'game'
    snapshot = {'source_commit': commit, 'archive': str(source_zip), 'archive_kind': 'verified_release_zip',
                'archive_sha256': digest(source_zip), 'sha256': source_hashes, 'content': content,
                'authoring_backup': {'sha256': {**content['three_d']['authoring_files_sha256'], **photo_authoring_files(root, content['photo_art'])}},
                'scope': 'Unsigned internal transfer for owner-controlled signing; no release authority'}
    snapshot_path = audit/'source-snapshot-manifest.json'
    snapshot_path.write_text(json.dumps(snapshot, ensure_ascii=False, indent=2) + '\n')
    shutil.copytree(source, stage, ignore=shutil.ignore_patterns('.godot', 'android', 'exported', '__pycache__'))
    assert source_inventory(stage) == source_hashes
    for name in source_hashes:
        assert not os.path.samestat((source/name).stat(), (stage/name).stat()), 'Hardlinks forbidden'
    (stage/'export_presets.cfg').write_text(changed_preset)
    shutil.rmtree(stage/'tests')  # Only this verified, newly owned copy.
    (stage/'android').mkdir(); (stage/'android/.gdignore').touch()
    env, sentinel = isolated_environment(root, work)
    sentinel_sha = digest(sentinel)
    provenance = {'source_commit': commit, 'work': str(work), 'owned_identity': owner, 'hardlinks': False,
                  'template_sha256': digest(template), 'upstream_source_sha256': digest(upstream_source), 'upstream_source_url': UPSTREAM_URL,
                  'source_preset_sha256': hashlib.sha256(original_preset.encode()).hexdigest(), 'staged_preset_sha256': digest(stage/'export_presets.cfg'),
                  'sentinel_sha256': sentinel_sha, 'public_certificate_sha256': public_certificate,
                  'package': identity['android_package_name'], 'signing_enabled': False, 'runnable_presets': False,
                  'credential_prevention': 'Pinned source: existing configured file prevents debug-key generation; all non-runnable presets prevent adb polling; package/signed=false skips signing',
                  'dynamic_exec_tracing': 'Not available in this container; ptrace denied. No claim of syscall tracing.'}
    (audit/'unsigned-staging-provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    successful = False
    def run_godot(args, log):
        verify_isolated_controls(work, sentinel, sentinel_sha, stage/'export_presets.cfg', provenance['staged_preset_sha256'])
        command(args, env, log)
        verify_isolated_controls(work, sentinel, sentinel_sha, stage/'export_presets.cfg', provenance['staged_preset_sha256'])
    try:
        run_godot([godot, '--headless', '--path', stage, '--import'], audit/'import.log')
        run_godot([godot, '--headless', '--path', stage, '--script', root/'tools/inspect_imported_fish_art.gd', '--', snapshot_path, audit/'imported-fish-art.json'], audit/'imported-fish-art.log')
        validate_import_audit(content['photo_art'], json.loads((audit/'imported-fish-art.json').read_text()))
        run_godot([godot, '--headless', '--path', stage, '--script', root/'tools/inspect_imported_3d.gd', '--', snapshot_path, audit/'imported-3d-scenes.json'], audit/'imported-3d.log')
        subprocess.run([sys.executable, str(root/'tools/content_3d_contract.py'), str(stage), str(audit/'imported-3d-scenes.json')], env=env, check=True)
        raw, normalized, aligned = work/'raw.apk', work/'normalized.apk', work/'candidate-UNSIGNED-INTERNAL.apk'
        run_godot([godot, '--headless', '--path', stage, '--export-release', 'Android ARM64 Release', raw], audit/'export.log')
        normalization = normalize_apk(raw, normalized)
        (audit/'vulkan-type-normalization.json').write_text(json.dumps(normalization, indent=2) + '\n')
        bt = root/'tools/android-sdk/build-tools/36.1.0'
        subprocess.run([str(bt/'zipalign'), '-P', '16', '-f', '4', str(normalized), str(aligned)], env=env, check=True)
        with (audit/'verification.log').open('w') as log:
            subprocess.run([sys.executable, str(root/'tools/verify_unsigned_android_handoff.py'), str(aligned), 'arm64-v8a', str(audit), str(bt), str(snapshot_path), public_certificate], env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
        with zipfile.ZipFile(template) as template_zip, zipfile.ZipFile(aligned) as apk:
            assert apk.testzip() is None
            natural = verify_exported_natural_history(apk, content['natural_history'])
            native_hashes = {}
            template_natives = {name for name in template_zip.namelist() if name.startswith('lib/') and name.endswith('.so')}
            apk_natives = {name for name in apk.namelist() if name.startswith('lib/') and name.endswith('.so')}
            assert apk_natives == template_natives, 'Extra or missing native libraries refused'
            for name in template_zip.namelist():
                if name.startswith('lib/') and name.endswith('.so'):
                    assert apk.read(name) == template_zip.read(name), 'Native bytes differ from audited official template'
                    native_hashes[name] = hashlib.sha256(apk.read(name)).hexdigest()
        assert_frozen_files(root, verified)
        assert source_inventory(source) == source_hashes, 'Primary source drifted during export'
        verify_zip(source_zip, verified, report['source_archive']['prefix'])
        assert digest(source_zip) == report['source_archive']['sha256']
        assert digest(sentinel) == sentinel_sha and credential_candidates(work) == [], 'Unexpected credential material'
        assert not output.exists()
        output.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive create prevents a concurrent output from being overwritten.
        with aligned.open('rb') as src, output.open('xb') as dest:
            shutil.copyfileobj(src, dest, length=1024 * 1024)
        assert digest(output) == digest(aligned)
        result = {'verified_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'source_commit': commit,
                  'source_zip_sha256': digest(source_zip), 'apk': str(output), 'bytes': output.stat().st_size, 'sha256': digest(output),
                  'package': identity['android_package_name'], 'public_certificate_for_owner_signing': public_certificate,
                  'native_bytes_match_official_template': native_hashes, 'natural_history': natural,
                  'all_non_signature_static_gates_passed': True, 'unsigned_rejected_by_apksigner': True,
                  'no_credentials_generated': True, 'source_unchanged': True,
                  'signed': False, 'installed': False, 'published': False, 'release_ready': False,
                  'remaining': 'Owner-controlled local signing, exact pinned certificate and v2/v3 signed verification, then device testing; any transfer/publication requires separate authorization'}
        (audit/'unsigned-handoff-finalization.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        successful = True
        print(json.dumps(result, ensure_ascii=False, indent=2))
    finally:
        proof = {'success': successful, 'work': str(work), 'no_credentials_generated': credential_candidates(work) == [],
                 'sentinel_unchanged': digest(sentinel) == sentinel_sha, 'source_used_for_export': str(stage), 'primary_exported': False}
        (audit/'unsigned-cleanup-proof.json').write_text(json.dumps(proof, indent=2) + '\n')
        if successful:
            owned_cleanup(root, work, owner)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--source-zip', type=Path, required=True)
    parser.add_argument('--source-manifest', type=Path, required=True)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--upstream-source', type=Path, required=True)
    parser.add_argument('--expected-certificate-sha256', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--audit', type=Path, required=True)
    parser.add_argument('--staging-parent', type=Path)
    args = parser.parse_args()
    build(args.root, args.source_zip, args.source_manifest, args.template, args.output, args.audit,
          args.expected_certificate_sha256, args.upstream_source, args.staging_parent)


if __name__ == '__main__':
    main()
