"""Bounded unsigned minimal-project smoke for the derived prebuilt export route."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile
from godot_binary_settings import scalar_settings
from normalize_android_features import normalize_apk
from android_identity import project_identity


def smoke(root, template, evidence):
    root, template, evidence = map(lambda p: Path(p).resolve(), [root, template, evidence])
    assert not evidence.exists()
    evidence.mkdir(parents=True)
    work = Path(tempfile.mkdtemp(prefix='farshore-template-smoke-'))
    project = work/'game'; project.mkdir()
    shutil.copy2(root/'game/assets/ui/icons/badge.png', project/'icon.png')
    (project/'main.tscn').write_text('[gd_scene format=3]\n\n[node name="TemplateSmoke" type="Node3D"]\n')
    (project/'project.godot').write_text('''config_version=5
[application]
config/name="Farshore isolated packaging smoke"
config/version="1.2.0-beta.2"
config/icon="res://icon.png"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.6", "Mobile")
[display]
window/size/viewport_width=430
window/size/viewport_height=932
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
rendering_device/driver.android="vulkan"
rendering_device/fallback_to_opengl3=false
anti_aliasing/quality/msaa_3d=2
textures/vram_compression/import_etc2_astc=true
''')
    presets = (root/'game/export_presets.cfg').read_text().replace('gradle_build/use_gradle_build=true', 'gradle_build/use_gradle_build=false')
    identity = project_identity(root/'game', presets, '1.2.0-beta.2', 4)
    presets = presets.replace('custom_template/release=""', 'custom_template/release='+json.dumps(str(template)))
    presets = re.sub(r'^gradle_build/(min_sdk|target_sdk)="[^"]*"', r'gradle_build/\1=""', presets, flags=re.M)
    presets = re.sub(r'^(launcher_icons/[^=]+)="[^"]*"', r'\1=""', presets, flags=re.M)
    (project/'export_presets.cfg').write_text(presets)
    (project/'android').mkdir(); (project/'android/.gdignore').touch()
    # The pinned official exporter returns before automatic debug-key generation
    # when this existing marker path is configured (export_plugin.cpp:909-911).
    # It is intentionally not a credential and never used for signing.
    marker = work/'unsigned-smoke-no-keystore.txt'
    marker.write_text('Unsigned packaging smoke only. This is not a key.\n')
    env = os.environ.copy()
    env.update(JAVA_HOME=str(root/'tools/jdk/jdk-21.0.12.1+1'), ANDROID_HOME=str(root/'tools/android-sdk'),
               ANDROID_SDK_ROOT=str(root/'tools/android-sdk'), XDG_CONFIG_HOME=str(work/'config'),
               XDG_DATA_HOME=str(work/'data'), XDG_CACHE_HOME=str(work/'cache'), GRADLE_USER_HOME=str(work/'unused-gradle'),
               FARSHORE_ROOT=str(root))
    env['PATH'] = env['JAVA_HOME']+'/bin:'+env['PATH']
    config=Path(env['XDG_CONFIG_HOME'])/'godot'; config.mkdir(parents=True)
    (config/'editor_settings-4.6.tres').write_text('\n'.join([
        '[gd_resource type="EditorSettings" format=3]', '', '[resource]',
        'export/android/java_sdk_path='+json.dumps(env['JAVA_HOME']),
        'export/android/android_sdk_path='+json.dumps(env['ANDROID_HOME']),
        'export/android/debug_keystore='+json.dumps(str(marker)),
        'export/android/debug_keystore_user=""', 'export/android/debug_keystore_pass=""', '']))
    templates=Path(env['XDG_DATA_HOME'])/'godot/export_templates/4.6.3.stable'
    templates.parent.mkdir(parents=True)
    templates.symlink_to(root/'tools/godot-templates/4.6.3.stable')
    def run(command, file):
        result = subprocess.run(list(map(str, command)), env=env, capture_output=True, text=True)
        (evidence/file).write_text(result.stdout+result.stderr)
        assert result.returncode == 0, str(command[0])+' failed: '+file
        return result.stdout+result.stderr
    run(['godot', '--headless', '--path', project, '--import'], 'import.log')
    apk, aligned = work/'smoke-unsigned.apk', work/'smoke-aligned.apk'
    exported = run(['godot', '--headless', '--path', project, '--export-release', 'Android ARM64 Release', apk], 'export.log')
    assert not re.search(r'SCRIPT ERROR:|Parse Error:|Export failed|^ERROR:', exported, re.M)
    normalized=work/'smoke-normalized.apk'
    normalization=normalize_apk(apk,normalized)
    (evidence/'vulkan-type-normalization.json').write_text(json.dumps(normalization,indent=2)+'\n')
    apk=normalized
    bt = root/'tools/android-sdk/build-tools/36.1.0'
    badging = run([bt/'aapt', 'dump', 'badging', apk], 'badging.txt')
    permissions = run([bt/'aapt', 'dump', 'permissions', apk], 'permissions.txt')
    manifest = run([bt/'aapt', 'dump', 'xmltree', apk, 'AndroidManifest.xml'], 'manifest.txt')
    assert "package: name='"+identity['android_package_name']+"'" in badging
    assert "versionName='1.2.0-beta.2'" in badging and "versionCode='4'" in badging
    assert "sdkVersion:'29'" in badging and "targetSdkVersion:'36'" in badging
    assert "application-debuggable" not in badging
    assert re.findall(r"uses-permission(?:-sdk-\d+)?: name='([^']+)'", permissions) == ['android.permission.VIBRATE']
    assert re.search(r'android:extractNativeLibs[^\n]*0x0\b', manifest)
    assert re.search(r'android:allowBackup[^\n]*0x0\b', manifest)
    assert any(line.strip().startswith('uses-feature:') and "name='android.hardware.vulkan.version'" in line for line in badging.splitlines())
    libs = {}
    with zipfile.ZipFile(apk) as archive, zipfile.ZipFile(template) as original:
        assert archive.testzip() is None
        native = [i for i in archive.infolist() if i.filename.startswith('lib/') and i.filename.endswith('.so')]
        assert len(native) == 2 and all(i.filename.startswith('lib/arm64-v8a/') for i in native)
        for info in native:
            data = archive.read(info)
            assert info.compress_type == zipfile.ZIP_STORED and data == original.read(info.filename)
            start = struct.unpack_from('<Q', data, 32)[0]; size, count = struct.unpack_from('<HH', data, 54)
            aligns = [struct.unpack_from('<Q', data, start+n*size+48)[0] for n in range(count) if struct.unpack_from('<I', data, start+n*size)[0] == 1]
            assert aligns and all(n >= 16384 for n in aligns)
            libs[info.filename] = {'sha256': hashlib.sha256(data).hexdigest(), 'compression': 0, 'elf_load_alignment': aligns}
        settings = scalar_settings(archive.read('assets/project.binary'))
        assert settings['rendering/renderer/rendering_method'] == 'mobile'
        assert settings.get('rendering/rendering_device/driver.android', 'vulkan') == 'vulkan'
        assert settings['rendering/rendering_device/fallback_to_opengl3'] is False
        assert settings['rendering/anti_aliasing/quality/msaa_3d'] == 2
        assert settings['display/window/stretch/aspect'] == 'expand'
    run([bt/'zipalign', '-P', '16', '-f', '4', apk, aligned], 'alignment.log')
    run([bt/'zipalign', '-c', '-P', '16', '-v', '4', aligned], 'zipalign16k.txt')
    assert not any(p.suffix in {'.keystore','.p12','.jks'} for p in work.rglob('*') if p.is_file()), 'Unexpected credential generation'
    report = {'result': 'PASS', 'scope': 'Unsigned minimal-project packaging smoke only; no gameplay or device-runtime claim',
              'unsigned_apk_bytes': apk.stat().st_size, 'unsigned_apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
              'package': identity['android_package_name'], 'version': '1.2.0-beta.2', 'version_code': 4,
              'min_sdk': 29, 'target_sdk': 36, 'extract_native_libraries': False, 'allow_backup': False,
              'vulkan_required': True, 'renderer': 'mobile', 'opengl_fallback_disabled': True,
              'permissions': ['android.permission.VIBRATE'], 'native_libraries': libs, 'zip_alignment_kib': 16,
              'primary_game_not_exported': True, 'credentials_created': False, 'disposable_workspace_removed': True}
    assert work.parent == Path('/tmp') and work.name.startswith('farshore-template-smoke-')
    shutil.rmtree(work)
    (evidence/'summary.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args=parser.parse_args()
    smoke(args.root, args.template, args.evidence)
