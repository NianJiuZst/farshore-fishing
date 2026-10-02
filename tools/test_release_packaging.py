"""Local regressions; official-template test needs the verified template restored."""
from pathlib import Path
import json
import os
import subprocess
import struct
import tempfile
import unittest
import zipfile
import release_source_zip as source
import derive_android_template as template
import park_android_ndk as ndk
import normalize_android_features as normalization


class PackagingTests(unittest.TestCase):
    def test_vulkan_types_exact_reversal_and_rejection(self):
        raw=(Path(__file__).resolve().parent/'tests/fixtures/prebuilt-vulkan-string-manifest.bin').read_bytes()
        corrected, proof=normalization.normalize_manifest(raw)
        self.assertEqual(len(proof['changes']),4)
        restored=bytearray(corrected)
        for change in proof['changes']:
            at=change['data_offset']
            struct.pack_into('<I',restored,at-8,change['old_string_pool_index'])
            restored[at-1]=3
            struct.pack_into('<I',restored,at,change['old_string_pool_index'])
        self.assertEqual(bytes(restored),raw)
        with self.assertRaises(AssertionError):normalization.normalize_manifest(corrected)
        invalid_type=bytearray(raw);invalid_type[proof['changes'][0]['data_offset']-1]=0x12
        with self.assertRaises(AssertionError):normalization.normalize_manifest(invalid_type)
        invalid_index=bytearray(raw);at=proof['changes'][0]['data_offset'];struct.pack_into('<I',invalid_index,at,0)
        with self.assertRaises(AssertionError):normalization.normalize_manifest(invalid_index)
        with tempfile.TemporaryDirectory(prefix='farshore-feature-test-') as folder:
            folder=Path(folder);before=folder/'before.apk';after=folder/'after.apk'
            with zipfile.ZipFile(before,'x',compression=zipfile.ZIP_DEFLATED) as z:
                z.writestr('AndroidManifest.xml',raw)
                z.writestr('assets/unchanged.txt',b'identical payload'*500)
            result=normalization.normalize_apk(before,after)
            self.assertEqual(result['only_changed_member'],'AndroidManifest.xml')
            with zipfile.ZipFile(before) as old,zipfile.ZipFile(after) as new:
                self.assertEqual(old.read('assets/unchanged.txt'),new.read('assets/unchanged.txt'))
                def compressed_bytes(archive):
                    info=archive.getinfo('assets/unchanged.txt');archive.fp.seek(info.header_offset)
                    head=struct.unpack('<IHHHHHIIIHH',archive.fp.read(30));archive.fp.read(head[-2]+head[-1])
                    return archive.fp.read(info.compress_size)
                self.assertEqual(compressed_bytes(old),compressed_bytes(new))

    def test_raw_payload_copy_with_git_timestamp_and_utf8(self):
        with tempfile.TemporaryDirectory(prefix='farshore-zip-extra-test-') as folder:
            folder = Path(folder)
            old, new = folder/'old.zip', folder/'new.zip'
            info = zipfile.ZipInfo('old/鱼.txt')
            info.compress_type = zipfile.ZIP_DEFLATED
            info.extra = struct.pack('<HHBI', 0x5455, 5, 1, 1790966400)
            payload = 'unchanged fishing source'.encode() * 100
            with zipfile.ZipFile(old, 'x') as z: z.writestr(info, payload)
            with zipfile.ZipFile(old) as a, zipfile.ZipFile(new, 'x') as b:
                source.raw_copy_member(a, a.getinfo('old/鱼.txt'), b, 'new/鱼.txt')
            with zipfile.ZipFile(new) as z:
                self.assertIsNone(z.testzip())
                self.assertEqual(z.read('new/鱼.txt'), payload)
                self.assertEqual(z.getinfo('new/鱼.txt').extra, info.extra)

    def test_source_roundtrip_reuse_changed_added_and_corruption(self):
        with tempfile.TemporaryDirectory(prefix='farshore-package-test-') as folder:
            root = Path(folder) / 'repo'; root.mkdir()
            def git(*args):
                return subprocess.check_output(['git', *args], cwd=root, stderr=subprocess.DEVNULL, text=True).strip()
            git('init'); git('config', 'user.name', 'Packaging Test'); git('config', 'user.email', 'test@example.invalid')
            (root/'old.txt').write_text('unchanged payload' * 100)
            (root/'change.txt').write_text('old')
            (root/'remove.txt').write_text('removed from next source')
            git('add', '.'); git('commit', '-m', 'baseline')
            first = Path(folder)/'first.zip'; manifest = Path(folder)/'first.json'
            data = source.create(root, 'HEAD', first, 'first')
            manifest.write_text(json.dumps(data))
            original_hash = source.digest(first)
            (root/'change.txt').write_text('changed')
            (root/'added.txt').write_text('added')
            (root/'remove.txt').unlink()
            git('add', '.'); git('commit', '-m', 'new')
            second = Path(folder)/'second.zip'
            result = source.create(root, 'HEAD', second, 'second', first, manifest)
            self.assertEqual(result['source_archive']['compressed_members_reused'], 1)
            self.assertEqual(result['source_archive']['new_or_changed_members'], 2)
            self.assertEqual(source.digest(first), original_hash)
            with self.assertRaises(AssertionError):
                source.create(root, 'HEAD', second, 'second', first, manifest)
            (root/'added.txt').write_text('uncommitted')
            with self.assertRaises(AssertionError):
                source.create(root, 'HEAD', Path(folder)/'drift.zip', 'third')
            (root/'added.txt').write_text('added')
            first.write_bytes(first.read_bytes()[:-20])
            with self.assertRaises(AssertionError):
                source.create(root, 'HEAD', Path(folder)/'bad.zip', 'third', first, manifest)

    def test_sdk_symlink_mode_hash_roundtrip(self):
        with tempfile.TemporaryDirectory(prefix='farshore-ndk-test-') as folder:
            root = Path(folder); original = root/'original'; original.mkdir()
            (original/'lib').mkdir(); (original/'lib/blob').write_bytes(b'NDK\0' * 1000)
            (original/'lib/blob').chmod(0o751)
            (original/'link').symlink_to('lib/blob')
            expected = ndk.inventory(original)
            archive = root/'archive.tar.gz'
            ndk.archive_tree(original, archive, expected)
            ndk.verify_archive(archive, expected)
            restored = root/'restored'; restored.mkdir()
            ndk.verify_archive(archive, expected, restored)
            self.assertEqual(ndk.inventory(restored), expected)
            corrupt = {k: dict(v) for k,v in expected.items()}; corrupt['lib/blob']['sha256'] = '0' * 64
            with self.assertRaises(AssertionError): ndk.verify_archive(archive, corrupt)

    def test_official_template_manifest_fail_closed(self):
        root = Path(__file__).resolve().parent.parent
        original_template = Path(os.environ.get('FARSHORE_OFFICIAL_TEMPLATE', str(root/'tools/godot-templates/4.6.3.stable/android_release.apk')))
        if not original_template.exists():
            self.skipTest('Verified official template unavailable after executor reset; not a pass')
        self.assertEqual(source.digest(original_template), template.OFFICIAL_TEMPLATE_SHA256)
        with zipfile.ZipFile(original_template) as archive:
            original = archive.read('AndroidManifest.xml')
        changed, proof = template.patch_manifest(original)
        self.assertEqual(len(proof), 2)
        attrs = template.manifest_attributes(changed)
        self.assertEqual(next(p['value'] for p in attrs if p['name'] == 'minSdkVersion'), 29)
        self.assertEqual(next(p['value'] for p in attrs if p['name'] == 'extractNativeLibs'), 0)
        with self.assertRaises(AssertionError): template.patch_manifest(changed)


if __name__ == '__main__': unittest.main(verbosity=2)
