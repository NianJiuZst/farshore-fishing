"""Internal unsigned handoff audit. Never authorizes installation or publication.

All non-signature gates mirror the unchanged signed-release verifier. The public
certificate must already be pinned, but this file deliberately requires NO signature.
"""
if not __debug__:
    raise RuntimeError('Safety checks require unoptimized Python; -O and PYTHONOPTIMIZE are forbidden')

from pathlib import Path
import datetime
import hashlib
import json
import re
import struct
import subprocess
import sys
import tempfile
import zipfile
from godot_binary_settings import scalar_settings
from android_identity import expected_identity
from content_fish_art_contract import verify_exported_photo_art

assert len(sys.argv) == 7, 'Expected APK, ABI, audit directory, build-tools, frozen snapshot and public certificate SHA256'
apk, abi, out, bt = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), Path(sys.argv[4])
expected_snapshot = json.loads(Path(sys.argv[5]).read_text()) if len(sys.argv) > 5 else {}
expected_content = expected_snapshot.get('content')
identity = expected_identity(expected_content)
assert expected_content and identity['android_package_name'] == 'org.farshore.fishing.ocean'
assert re.fullmatch(r'[0-9a-f]{64}', sys.argv[6]) and identity['certificate_sha256'] == sys.argv[6], 'Expected public signer must be pinned before unsigned handoff'
assert 'UNSIGNED-INTERNAL' in apk.name, 'Unsigned handoff must be clearly labelled'
if identity.get('separate_installation'):
    assert expected_content and expected_content.get('photo_art'), 'Preview APK requires the frozen all74 photo contract'
out.mkdir(parents=True, exist_ok=True)

def run(args, filename):
    p = subprocess.run([str(a) for a in args], text=True, capture_output=True)
    (out / filename).write_text(p.stdout + p.stderr)
    if p.returncode:
        raise RuntimeError(f'{filename} failed with exit {p.returncode}')
    return p.stdout + p.stderr

badging = run([bt/'aapt', 'dump', 'badging', apk], 'badging.txt')
permissions = run([bt/'aapt', 'dump', 'permissions', apk], 'permissions.txt')
manifest = run([bt/'aapt', 'dump', 'xmltree', apk, 'AndroidManifest.xml'], 'manifest.txt')
# A successful signed verification is a failure for this unsigned handoff route.
probe = subprocess.run([str(bt/'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], text=True, capture_output=True)
signature = probe.stdout + probe.stderr
(out/'unsigned-signature-rejection.txt').write_text(signature)
assert probe.returncode != 0 and 'DOES NOT VERIFY' in signature, 'Handoff input must be rejected as unsigned'
assert 'Missing META-INF/MANIFEST.MF' in signature, 'Unexpected verification failure is not unsigned proof'
with zipfile.ZipFile(apk) as unsigned:
    assert not any(n.startswith('META-INF/') and n.upper().endswith(('.RSA', '.DSA', '.EC', '.SF')) for n in unsigned.namelist()), 'Signature material is forbidden'
    unsigned.fp.seek(unsigned.start_dir - 16)
    assert unsigned.fp.read(16) != b'APK Sig Block 42', 'APK signing block is forbidden'
cert_sha256 = None
run([bt/'zipalign', '-c', '-P', '16', '-v', '4', apk], 'zipalign16k.txt')
assert "package: name='" + identity['android_package_name'] + "'" in badging, 'Unexpected package identity'
assert "application-label:'" + identity['launcher_name'] + "'" in badging, 'Unexpected launcher name'
assert "sdkVersion:'29'" in badging, 'Minimum SDK must be Android 10 / API29'
assert "targetSdkVersion:'36'" in badging, 'Target SDK must be Android 16 / API36'
assert "application-debuggable" not in badging, 'Player release must not be debuggable'
requested = re.findall(r"uses-permission(?:-sdk-\d+)?: name='([^']+)'", permissions)
assert requested == ['android.permission.VIBRATE'], f'Unexpected requested permissions: {requested}'
assert re.search(r'android:allowBackup[^\n]*\(type 0x12\)0x0', manifest), 'Backup must remain disabled'
assert re.search(r'android:screenOrientation[^\n]*\(type 0x10\)0x1', manifest), 'Portrait orientation required'
version_code = int(re.search(r"versionCode='(\d+)'", badging).group(1))
version_name = re.search(r"versionName='([^']+)'", badging).group(1)
assert (identity['application_version'], identity['android_version_code']) in {('1.3.0', 7), ('1.4.0', 8), ('1.4.1', 9)}, 'Unreviewed ocean version/code pair'
assert expected_content['application_version'] == identity['application_version'], 'Frozen version is not the pinned ocean version'
assert expected_content['android_version_code'] == identity['android_version_code'], 'Frozen version code is not the pinned ocean code'
assert version_name == identity['application_version'], 'APK version name differs from pinned source'
assert version_code == identity['android_version_code'], 'APK version code differs from pinned source'
libs = []
three_d_audit = None
photo_art_audit = None
extract_native = bool(re.search(r'android:extractNativeLibs[^\n]*0xffffffff', manifest))
with zipfile.ZipFile(apk) as z:
    names = z.namelist()
    assert len(names) == len(set(names)), 'Duplicate APK members are forbidden'
    if expected_content and expected_content.get('photo_art'):
        photo_report = json.loads((out/'imported-fish-art.json').read_text())
        photo_art_audit = verify_exported_photo_art(z, expected_content['photo_art'], photo_report)
    if expected_content and identity.get('separate_installation'):
        identity_bytes = z.read('assets/data/android_build_identity.json')
        assert json.loads(identity_bytes) == identity, 'Bundled public identity differs from frozen manifest'
        assert hashlib.sha256(identity_bytes).hexdigest() == expected_snapshot['sha256']['data/android_build_identity.json']
    assert not any('.signing-private' in n or n.endswith(('.p12', '.jks', '.keystore')) for n in names)
    abis = sorted({n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('.so')})
    assert abis == [abi], f'Wrong native ABIs: {abis}'
    for name in names:
        if not name.startswith('lib/') or not name.endswith('.so'):
            continue
        raw = z.read(name)
        assert raw[:4] == b'\x7fELF' and raw[4] == 2 and raw[5] == 1, 'Expected little-endian ELF64'
        phoff = struct.unpack_from('<Q', raw, 32)[0]
        phentsize, phnum = struct.unpack_from('<HH', raw, 54)
        aligns = []
        for i in range(phnum):
            pos = phoff + i * phentsize
            typ = struct.unpack_from('<I', raw, pos)[0]
            if typ == 1:
                align = struct.unpack_from('<Q', raw, pos + 48)[0]
                assert align >= 16384, f'{name} LOAD is not 16 KiB aligned'
                aligns.append(align)
        assert aligns, 'Missing ELF LOAD segments'
        compressed = z.getinfo(name).compress_type != zipfile.ZIP_STORED
        assert not compressed, 'Native libraries must remain uncompressed'
        assert not extract_native, 'Uncompressed native libraries require extractNativeLibs=false'
        libs.append({'path': name, 'uncompressed_bytes': len(raw), 'compressed': compressed, 'elf_load_alignment': aligns})
    (out/'apk-file-list.txt').write_text('\n'.join(names)+'\n')
    catalog_files = expected_content['catalog_files'] if expected_content else [Path(n).name for n in names if re.fullmatch(r'assets/data/fish_[a-z0-9_]+\.json', n)]
    assert catalog_files, 'Fish catalogs missing from offline APK'
    fish = []
    for filename in catalog_files:
        name = 'assets/data/'+filename
        assert name in names, f'Missing authoritative fish catalog: {filename}'
        if expected_snapshot.get('sha256'):
            assert hashlib.sha256(z.read(name)).hexdigest() == expected_snapshot['sha256']['data/'+filename], f'Catalog bytes differ from frozen source: {filename}'
        fish.extend(json.loads(z.read(name)))
    fish_ids = sorted(f['species_id'] for f in fish)
    assert len(set(fish_ids)) == len(fish_ids) and fish_ids, 'Empty or duplicated fish catalog'
    world = json.loads(z.read('assets/data/world.json'))
    if expected_snapshot.get('sha256'):
        assert hashlib.sha256(z.read('assets/data/world.json')).hexdigest() == expected_snapshot['sha256']['data/world.json'], 'World/gear/bait data differs from frozen source'
    if expected_content:
        assert fish_ids == expected_content['species_ids'], 'APK fish inventory differs from frozen source'
        assert sorted(r['region_id'] for r in world['regions']) == expected_content['region_ids'], 'APK regions differ from frozen source'
        assert len(world['spots']) == expected_content['spot_count'], 'APK spot count differs from frozen source'
        assert len(world['gear']) == expected_content['gear_count'], 'APK gear count differs from frozen source'
        assert len(world['baits']) == expected_content['bait_count'], 'APK bait count differs from frozen source'
    for f in fish:
        for field in ['art', 'thumb']:
            mapped = 'assets/' + f[field].removeprefix('res://') + '.import'
            assert mapped in names, f'Missing artwork import mapping: {mapped}'
            mapping = z.read(mapped).decode()
            targets = re.findall(r'path(?:\.[a-z0-9_]+)?="(res://[^"]+)"', mapping)
            assert targets, f'Empty artwork import mapping: {mapped}'
            for target in targets:
                assert 'assets/'+target.removeprefix('res://') in names, f'Missing imported texture: {target}'
    assert any(n.endswith(('.ttf', '.otf', '.ttc', '.fontdata')) for n in names), 'Bundled font missing'
    ui_icons = expected_content.get('ui_icon_files', []) if expected_content else []
    for resource in ui_icons:
        mapped = 'assets/' + resource + '.import'
        assert mapped in names, f'Missing generated UI icon mapping: {mapped}'
        targets = re.findall(r'path(?:\.[a-z0-9_]+)?="(res://[^"]+)"', z.read(mapped).decode())
        assert targets, f'Empty UI icon import mapping: {mapped}'
        for target in targets:
            assert 'assets/'+target.removeprefix('res://') in names, f'Missing UI icon texture: {target}'
    if expected_content and expected_content.get('three_d'):
        contract = expected_content['three_d']
        registry_bytes = z.read('assets/data/fish_3d.json')
        assert hashlib.sha256(registry_bytes).hexdigest() == contract['registry_sha256'], '3D runtime registry differs from frozen source'
        registry = json.loads(registry_bytes)
        assert sorted(registry['models']) == contract['playable_species']
        settings = scalar_settings(z.read('assets/project.binary'))
        assert settings.get('rendering/renderer/rendering_method') == 'mobile', 'APK must use the Mobile renderer'
        assert settings.get('rendering/renderer/rendering_method.mobile', 'mobile') == 'mobile'
        # Vulkan is the pinned Godot4.6.3 Android default and may be omitted by
        # ProjectSettings when equal to its initial value. Source explicitly pins it.
        assert settings.get('rendering/rendering_device/driver.android', 'vulkan') == 'vulkan'
        assert settings.get('rendering/rendering_device/fallback_to_opengl3') is False, 'APK must disable silent OpenGL fallback'
        assert settings.get('display/window/stretch/aspect') == 'expand', 'APK must preserve expanded portrait layout'
        assert settings.get('rendering/anti_aliasing/quality/msaa_3d') == 2, 'APK must request4x MSAA'
        vulkan_features = [line.strip() for line in badging.splitlines() if line.strip().startswith('uses-feature') and 'android.hardware.vulkan.' in line]
        assert any(line.startswith('uses-feature:') and "name='android.hardware.vulkan.version'" in line for line in vulkan_features), 'APK must declare required Vulkan support'
        imported = json.loads((out/'imported-3d-scenes.json').read_text())
        assert not imported['failures'] and set(imported['models']) == set(contract['glb_models'])
        for model in contract['glb_models']:
            mapped = 'assets/' + model + '.import'
            assert mapped in names, f'Missing exported 3D model import: {model}'
            target = re.search(r'^path="res://([^"]+)"', z.read(mapped).decode(), re.M).group(1)
            assert target in imported['imported_scene_sha256']
            assert hashlib.sha256(z.read('assets/'+target)).hexdigest() == imported['imported_scene_sha256'][target], f'Exported scene differs from structurally inspected scene: {model}'
        for texture in contract['texture_files']:
            mapped = 'assets/' + texture + '.import'
            assert mapped in names, f'Missing 3D texture import: {texture}'
            targets = re.findall(r'path(?:\.[a-z0-9_]+)?="res://([^"]+)"', z.read(mapped).decode())
            assert targets and all('assets/'+p in names for p in targets), f'Missing 3D texture payload: {texture}'
        shader_payloads = {}
        for shader, expected in contract['shader_sha256'].items():
            direct = 'assets/'+shader
            if direct in names:
                assert hashlib.sha256(z.read(direct)).hexdigest() == expected, f'Shader bytes differ: {shader}'
                shader_payloads[shader] = direct
            else:
                mapped = direct+'.remap'
                assert mapped in names, f'Missing exported 3D shader: {shader}'
                target = re.search(r'path="res://([^"]+)"', z.read(mapped).decode()).group(1)
                assert 'assets/'+target in names and z.getinfo('assets/'+target).file_size > 0
                shader_payloads[shader] = 'assets/'+target
        assert 'assets/assets/3d/environment/manifest.json' in names
        for notice, expected in contract.get('notice_sha256', {}).items():
            assert hashlib.sha256(z.read('assets/'+notice)).hexdigest() == expected, f'Bundled art notice differs: {notice}'
        three_d_audit = {'playable_species':contract['playable_species'], 'playable_species_count':contract['playable_species_count'],
                        'playable_regions':contract['playable_regions'], 'playable_locations':contract['playable_locations'],
                        'all_catalog_species_have_3d_models':True,
                        'runtime_registry_sha256':contract['registry_sha256'],
                        'configured_renderer':'mobile', 'configured_android_driver':'vulkan',
                        'opengl_fallback_disabled':True,
                        'stretch_aspect':'expand', 'msaa_3d':2, 'requested_msaa_samples':4,
                        'vulkan_manifest_features':vulkan_features,
                        'imported_glb_scenes':len(imported['models']), 'rigged_models':contract['rigged_model_count'],
                        'region_scenes':len(contract['region_scene_files']), 'station_scenes':len(contract['station_scene_files']),
                        'texture_imports':len(contract['texture_files']), 'shader_payloads':shader_payloads,
                        'third_party_texture_sources':contract.get('third_party_textures', []),
                        'bundled_notices':list(contract.get('notice_sha256', {})),
                        'scope':'Exact exported imported-scene bytes matched pre-export Skeleton3D/AnimationPlayer/skin audit; runtime rendering requires separate evidence'}
    assert not any(n.startswith('assets/tests/') or n.endswith(('recover.gd','recovered.json')) for n in names), 'Development harness must not ship'
result = {
    'verified_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'apk': apk.name, 'bytes': apk.stat().st_size,
    'sha256': hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(),
    'package': identity['android_package_name'], 'launcher_name':identity['launcher_name'], 'min_sdk': 29, 'target_sdk': 36,
    'compile_sdk': 36, 'version_code': version_code, 'version_name': version_name,
    'abi': abi, 'debuggable': False, 'permissions': requested,
    'signature_v2': False, 'signature_v3': False, 'zip_alignment_kib': 16,
    'expected_future_certificate_sha256': identity['certificate_sha256'],
    'unsigned_rejected_by_apksigner': True, 'release_ready': False,
    'scope': 'UNSIGNED-INTERNAL handoff only; signing and signed verification remain required',
    'certificate_sha256': cert_sha256,
    'native_libraries': libs,
    'fish_species': sum(f.get('animal_kind', 'fish') == 'fish' and f.get('fishing_enabled', True) is True for f in fish),
    'catalog_species': len(fish),
    'mammal_species': sum(f.get('animal_kind', 'fish') == 'mammal' for f in fish),
    'challenge_species_ids': sorted(f['species_id'] for f in fish if f.get('encounter_type') == 'fantasy_challenge'),
    'fish_catalog_files':catalog_files, 'regions':len(world['regions']), 'fishing_spots':len(world['spots']),
    'gear_options':len(world['gear']), 'bait_options':len(world['baits']),
    'generated_ui_icons':len(ui_icons),
    'three_d':three_d_audit,
    'photo_art':photo_art_audit,
    'extract_native_libraries': extract_native,
    'runtime_test': 'Separate evidence required; binary inspection is not an installation test',
}
(out/'build-manifest.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
