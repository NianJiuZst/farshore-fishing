"""Pure guard regressions: no engine launch, signing, key generation or export."""
from pathlib import Path
import copy
import json
import os
import tempfile
import subprocess
import sys
import unittest
from unittest import mock
import android_identity
import android_unsigned_handoff as handoff


class UnsignedHandoffTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='farshore-unsigned-guard-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base/'repo'; self.root.mkdir()
        self.content = {'android_identity': {**android_identity.OCEAN, 'separate_installation': True}}
        self.pin = android_identity.OCEAN['certificate_sha256']
        self.assertRegex(self.pin, r'^[0-9a-f]{64}$')
        self.presets = (Path(__file__).resolve().parent.parent/'game/export_presets.cfg').read_text()

    def test_public_pin_roundtrip_and_exact_identity(self):
        self.assertEqual(handoff.require_public_signer(self.content, self.pin), self.content['android_identity'])
        for field, value in [('android_package_name', 'org.farshore.fishing.preview'), ('launcher_name', 'Other'),
                             ('application_version', '1.2.0'), ('android_version_code', 6), ('separate_installation', False)]:
            changed = copy.deepcopy(self.content); changed['android_identity'][field] = value
            with self.subTest(field=field), self.assertRaises(AssertionError): handoff.require_public_signer(changed, self.pin)

    def test_null_boolean_nul_and_old_signers_rejected(self):
        for invalid in (None, False, True, '', self.pin + '\0', '\0' + self.pin, self.pin.upper(), '0'*64,
                        android_identity.PREVIEW['certificate_sha256'], android_identity.LEGACY['certificate_sha256']):
            with self.subTest(invalid=repr(invalid)), self.assertRaises(AssertionError): handoff.require_public_signer(self.content, invalid)
        for invalid in (None, False, '', self.pin + '\0', android_identity.PREVIEW['certificate_sha256']):
            changed = copy.deepcopy(self.content); changed['android_identity']['certificate_sha256'] = invalid
            with self.subTest(identity_value=repr(invalid)), self.assertRaises(AssertionError): handoff.require_public_signer(changed, self.pin)

    def test_pending_identity_cannot_use_source_qa_exception(self):
        pending = {**android_identity.OCEAN, 'certificate_sha256': None, 'signing_status': 'pending_user_controlled_key'}
        content = {'android_identity': {**pending, 'separate_installation': True}}
        with mock.patch.object(android_identity, 'OCEAN', pending):
            self.assertEqual(android_identity.validate_identity(content['android_identity'], require_signer=False)['certificate_sha256'], None)
            with self.assertRaises(AssertionError): handoff.require_public_signer(content, self.pin)

    def test_preset_changes_only_enable_reviewed_prebuilt_unsigned_route(self):
        output = handoff.staged_presets(self.presets, Path('/safe/template.apk'))
        self.assertEqual(output.count('runnable=false'), 2)
        self.assertEqual(output.count('package/signed=false'), 2)
        self.assertEqual(output.count('gradle_build/use_gradle_build=false'), 2)
        self.assertEqual(output.count('gradle_build/min_sdk=""'), 2)
        self.assertEqual(output.count('gradle_build/target_sdk=""'), 2)
        self.assertEqual(output.count('custom_template/release="/safe/template.apk"'), 2)
        self.assertEqual(output.count('gradle_build/gradle_build_directory="res://android"'), 2)
        self.assertIn('gradle_build/use_gradle_build=true', self.presets)

    def test_runnable_signed_credential_and_escaped_presets_fail_closed(self):
        mutations = [self.presets.replace('runnable=false', 'runnable=true', 1),
                     self.presets.replace('package/signed=false', 'package/signed=true', 1),
                     self.presets.replace('runnable=false\n', '', 1),
                     self.presets.replace('res://android', 'res://../android'),
                     self.presets + '\nkeystore/release=""\n',
                     self.presets + '\n[preset.2]\n',
                     self.presets.replace('package/signed=false', 'package/signed=false\npackage/signed = true', 1),
                     self.presets.replace('runnable=false', 'runnable=false\n runnable=true', 1),
                     self.presets.replace('runnable=false', 'runnable=false\nrunnable=true', 1),
                     self.presets + '\nkeystore/release = "ignored"\n',
                     self.presets + '\n keystore/release="ignored"\n',
                     self.presets + '\0',
                     self.presets.replace('package/signed=false', 'dummy="\npackage/signed=false\ndummy2="', 1),
                     self.presets.replace('runnable=false', 'dummy="\nrunnable=false\ndummy2="', 1),
                     self.presets + '\ndummy="closed" trailing\n',
                     self.presets + '\ndummy=PackedStringArray("a")\n',
                     self.presets.replace('package/signed=false', '#comment\npackage/signed=false', 1),
                     self.presets.replace('runnable=false', '#comment\nrunnable=false', 1),
                     self.presets.replace('package/signed=false', '\u00a0;comment\npackage/signed=false', 1),
                     self.presets.replace('package/signed=false', '\u00a0\npackage/signed=false', 1)]
        mutations.extend(self.presets.replace('package/signed=false', ';comment' + separator + 'package/signed=false', 1) for separator in ('\x85', '\u2028', '\u2029', '\v', '\f', '\r'))
        for text in mutations:
            with self.subTest(text=text[-50:]), self.assertRaises(AssertionError): handoff.staged_presets(text, Path('/safe/template.apk'))

    def test_external_paths_reject_primary_ancestors_existing_and_symlinks(self):
        outside = self.base/'external'; outside.mkdir()
        wanted = outside/'new.apk'
        self.assertEqual(handoff.external_path(self.root, wanted, absent=True), wanted)
        for bad in (Path('relative.apk'), self.root/'out.apk', self.root, self.base, Path('/')):
            with self.subTest(path=str(bad)), self.assertRaises(AssertionError): handoff.external_path(self.root, bad)
        wanted.touch()
        with self.assertRaises(AssertionError): handoff.external_path(self.root, wanted, absent=True)
        link = self.base/'linked'; link.symlink_to(outside, target_is_directory=True)
        with self.assertRaises(AssertionError): handoff.external_path(self.root, link/'out.apk')

    def test_frozen_bytes_and_symlink_changes_rejected(self):
        file = self.root/'input.txt'; file.write_text('frozen')
        manifest = {'input.txt': {'sha256': handoff.digest(file)}}
        handoff.assert_frozen_files(self.root, manifest)
        file.write_text('changed')
        with self.assertRaises(AssertionError): handoff.assert_frozen_files(self.root, manifest)
        file.unlink(); outside = self.base/'outside.txt'; outside.write_text('frozen'); file.symlink_to(outside)
        with self.assertRaises(AssertionError): handoff.assert_frozen_files(self.root, manifest)

    def test_isolated_settings_use_inert_existing_text_and_remove_signing_env(self):
        work = self.base/'owned'; work.mkdir()
        # Existence checks are mocked; no fake SDK executable or credential is created.
        with mock.patch.object(Path, 'is_file', return_value=True), mock.patch.dict(os.environ, {
                'GODOT_ANDROID_KEYSTORE_RELEASE_PATH': 'test-only-value', 'FARSHORE_KEYSTORE': 'test-only-value', 'PYTHONOPTIMIZE': '2'}):
            env, sentinel = handoff.isolated_environment(self.root, work)
        self.assertTrue(sentinel.is_file())
        self.assertIn('Not a keystore', sentinel.read_text())
        self.assertNotIn('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', env)
        self.assertNotIn('FARSHORE_KEYSTORE', env)
        self.assertNotIn('PYTHONOPTIMIZE', env)
        self.assertEqual(env['HOME'], str(work/'home'))
        self.assertEqual(env['ANDROID_USER_HOME'], str(work/'android-user'))
        settings = (work/'config/godot/editor_settings-4.6.tres').read_text()
        self.assertIn('export/android/debug_keystore=' + json.dumps(str(sentinel)), settings)
        self.assertIn('export/android/debug_keystore_user=""', settings)
        self.assertIn('export/android/debug_keystore_pass=""', settings)
        self.assertIn('export/android/shutdown_adb_on_exit=false', settings)
        self.assertEqual(handoff.credential_candidates(work), [])
        preset = work/'export_presets.cfg'; preset.write_text(self.presets)
        sentinel_sha, preset_sha = handoff.digest(sentinel), handoff.digest(preset)
        handoff.verify_isolated_controls(work, sentinel, sentinel_sha, preset, preset_sha)
        preset.write_text('changed')
        with self.assertRaises(AssertionError): handoff.verify_isolated_controls(work, sentinel, sentinel_sha, preset, preset_sha)
        preset.write_text(self.presets)
        settings_path = work/'config/godot/editor_settings-4.6.tres'
        settings_path.write_text(settings.replace('export/android/debug_keystore_user=""', 'export/android/debug_keystore_user="changed"'))
        with self.assertRaises(AssertionError): handoff.verify_isolated_controls(work, sentinel, sentinel_sha, preset, preset_sha)

    def test_cleanup_requires_exact_owned_identity_and_internal_name(self):
        work = self.base/'farshore-UNSIGNED-INTERNAL-test'; work.mkdir(); (work/'generated').write_text('owned')
        owner = (work.stat().st_dev, work.stat().st_ino)
        with self.assertRaises(AssertionError): handoff.owned_cleanup(self.root, work, (owner[0], owner[1]+1))
        self.assertTrue(work.exists())
        handoff.owned_cleanup(self.root, work, owner)
        self.assertFalse(work.exists())
        other = self.base/'other'; other.mkdir()
        with self.assertRaises(AssertionError): handoff.owned_cleanup(self.root, other, (other.stat().st_dev, other.stat().st_ino))

    def test_optimized_python_is_explicitly_refused_before_any_action(self):
        for filename in ('android_unsigned_handoff.py', 'verify_unsigned_android_handoff.py'):
            script = Path(__file__).with_name(filename)
            for flag in ('-O', '-OO'):
                result = subprocess.run([sys.executable, flag, str(script), '--help'], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Safety checks require unoptimized Python', result.stderr)
            env = dict(os.environ, PYTHONOPTIMIZE='1')
            result = subprocess.run([sys.executable, str(script), '--help'], env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Safety checks require unoptimized Python', result.stderr)

    def test_unsigned_verifier_retains_signature_absence_and_public_pin_gates(self):
        verifier = (Path(__file__).with_name('verify_unsigned_android_handoff.py')).read_text()
        for required in ('identity = expected_identity(expected_content)', "identity['certificate_sha256'] == sys.argv[6]",
                         "'Missing META-INF/MANIFEST.MF'", "b'APK Sig Block 42'", "'signature_v2': False, 'signature_v3': False",
                         'verify_exported_photo_art', 'elf_load_alignment', 'fallback_to_opengl3', 'imported_scene_sha256'):
            self.assertIn(required, verifier)
        self.assertNotIn("'signature_v2': True", verifier)
        self.assertNotIn("'signature_v3': True", verifier)


if __name__ == '__main__': unittest.main(verbosity=2)
