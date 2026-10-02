"""Local regressions; official-template test needs the verified template restored."""
from pathlib import Path
import copy
import io
import json
import os
import subprocess
import struct
import tempfile
import unittest
import zipfile
import zlib
import release_source_zip as source
import derive_android_template as template
import park_android_ndk as ndk
import normalize_android_features as normalization
import android_identity
import content_fish_art_contract as photos


class PhotoPackagingTests(unittest.TestCase):
    """Credential-free synthetic44 fixture, including stripped export remaps."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='farshore-photo-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root/'game'
        self.catalog = []
        self.entries = []
        self.payloads = {}
        def png(size, color):
            def chunk(kind, raw):
                return struct.pack('>I', len(raw)) + kind + raw + struct.pack('>I', zlib.crc32(kind + raw))
            return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress((b'\0' + bytes(color)*size)*size)) + chunk(b'IEND', b'')
        for index in range(44):
            species = 'fish_' + str(index)
            entry = {'species_id': species, 'runtime': f'res://assets/fish/{species}.png',
                     'thumb': f'res://assets/fish/{species}_thumb.png', 'master': f'masters/{species}.png'}
            self.catalog.append({'species_id': species, 'art': entry['runtime'], 'thumb': entry['thumb']})
            for thumb in (False, True):
                resource = photos.local_resource(entry['thumb' if thumb else 'runtime'])
                size = 2 if thumb else 4
                raw = png(size, (index, 90, 120, 180))
                self.write(resource, raw)
                key = 'thumb_' if thumb else ''
                entry[key + 'sha256'] = photos.sha256(raw)
                entry[key + 'image_sha256'] = photos.sha256(bytes((index, 90, 120, 180))*size*size)
                entry[key + 'width'] = entry[key + 'height'] = size
                entry[key + 'subject_bbox_px'] = [0, 0, size, size]
                target = '.godot/imported/' + Path(resource).name + '-canonical.ctex'
                mapping = f'[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="res://{target}"\n'
                self.write(resource + '.import', (mapping + f'[deps]\nsource_file="res://{resource}"\ndest_files=["res://{target}"]\n[params]\ncompress/mode=0\nmipmaps/generate=false\n').encode())
                self.payloads[resource + '.import'] = (mapping + '\0').encode()
                self.payloads[target] = b'GST2-test-payload-' + resource.encode()
            self.entries.append(entry)
        for resource in photos.UI_RESOURCES:
            self.write(resource, ('test static resource ' + resource).encode())
        self.write('scripts/fish_art_catalog.gd', b'const REQUIRE_PHOTOREAL: bool = true\nconst EXPECTED_COUNT: int = 44\nconst MANIFEST_PATH = "res://data/fish_art.json"\n')
        self.write('scripts/main.gd', b'res://scripts/fish_art_catalog.gd\nres://scripts/fish_art_view.gd\nif not fish_art.load_all(catalog):\nvar rect: FishArtView = FishArtViewScript.new()\n')
        self.write('scripts/catalog.gd', b'"fish_a.json"\n')
        self.write('data/fish_a.json', json.dumps(self.catalog).encode())
        self.manifest = {'format_version': 1, 'complete': True, 'asset_count': 44, 'assets': self.entries}
        self.save_manifest()
        self.contract = photos.photo_art_contract(self.project, self.catalog)
        self.report = {'failures': [], 'complete': True, 'species_ids': self.contract['species_ids'],
                       'manifest_sha256': self.contract['manifest_sha256'], 'textures': {}}
        for resource, entry in self.contract['textures'].items():
            raw = self.payloads[entry['target']]
            self.report['textures'][resource] = {**entry, 'payload_sha256': photos.sha256(raw), 'payload_bytes': len(raw)}
        self.payloads[photos.MANIFEST] = (self.project/photos.MANIFEST).read_bytes()
        for resource in photos.UI_RESOURCES:
            if resource.endswith('.gd'):
                target = str(Path(resource).with_suffix('.gdc'))
                self.payloads[resource + '.remap'] = f'[remap]\npath="res://{target}"\n'.encode()
                self.payloads[target] = b'GDSC' + resource.encode()
            elif resource.endswith('.tscn'):
                target = '.godot/exported/test/export-hash-main.scn'
                self.payloads[resource + '.remap'] = f'[remap]\npath="res://{target}"\n'.encode()
                self.payloads[target] = b'RSCC-fixture'
            else:
                self.payloads[resource] = (self.project/resource).read_bytes()

    def write(self, relative, raw):
        path = self.project/relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(raw)

    def save_manifest(self):
        self.write(photos.MANIFEST, json.dumps(self.manifest).encode())

    def verify(self, payloads=None, report=None, prefix='assets/'):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            for name, raw in (self.payloads if payloads is None else payloads).items():
                archive.writestr(prefix + name, raw)
        stream.seek(0)
        with zipfile.ZipFile(stream) as archive:
            return photos.verify_exported_photo_art(archive, self.contract, self.report if report is None else report, prefix)

    def test_complete_source_import_and_stripped_export_roundtrip(self):
        self.assertEqual(self.contract['texture_count'], 88)
        self.assertEqual(self.verify()['texture_payloads'], 88)
        self.assertEqual(self.verify(prefix='')['species_count'], 44)
        self.assertFalse(any(n.endswith('.png') for n in self.payloads))

    def test_source_manifest_and_png_fail_closed(self):
        original = copy.deepcopy(self.manifest)
        for mutation in ('incomplete', 'missing', 'duplicate', 'wrong_path', 'raw_hash', 'decoded_hash', 'dimensions'):
            with self.subTest(mutation=mutation):
                self.manifest = copy.deepcopy(original)
                entry = self.manifest['assets'][0]
                if mutation == 'incomplete': self.manifest['complete'] = False
                if mutation == 'missing': self.manifest['assets'].pop()
                if mutation == 'duplicate': self.manifest['assets'][-1] = copy.deepcopy(entry)
                if mutation == 'wrong_path': entry['runtime'] = 'res://assets/fish/fish_1.png'
                if mutation == 'raw_hash': entry['sha256'] = '0'*64
                if mutation == 'decoded_hash': entry.pop('thumb_image_sha256')
                if mutation == 'dimensions': entry['width'] += 1
                self.save_manifest()
                with self.assertRaises(AssertionError): photos.photo_art_contract(self.project, self.catalog)
        self.manifest = original; self.save_manifest()
        self.write('assets/fish/fish_0.png.import', b'[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="res://../other.ctex"\n')
        with self.assertRaises(AssertionError): photos.photo_art_contract(self.project, self.catalog)

    def test_audit_pixel_source_geometry_target_and_completeness_fail_closed(self):
        resource = next(iter(self.contract['textures']))
        for field in ('source_sha256', 'image_sha256', 'width', 'alpha_bounds', 'import_mapping_sha256', 'target', 'payload_sha256', 'payload_bytes'):
            with self.subTest(field=field):
                report = copy.deepcopy(self.report)
                report['textures'][resource][field] = None
                with self.assertRaises(AssertionError): photos.validate_import_audit(self.contract, report)
        for mutation in ('failure', 'missing_texture', 'missing_species', 'wrong_manifest', 'not_complete'):
            report = copy.deepcopy(self.report)
            if mutation == 'failure': report['failures'] = ['decoded pixels changed']
            if mutation == 'missing_texture': report['textures'].pop(resource)
            if mutation == 'missing_species': report['species_ids'].pop()
            if mutation == 'wrong_manifest': report['manifest_sha256'] = '0'*64
            if mutation == 'not_complete': report['complete'] = False
            with self.subTest(mutation=mutation), self.assertRaises(AssertionError): self.verify(report=report)

    def test_export_missing_retargeted_stale_and_static_ui_fail_closed(self):
        resource = next(iter(self.contract['textures']))
        target = self.contract['textures'][resource]['target']
        for mutation in ('missing_manifest', 'changed_manifest', 'missing_thumb', 'missing_payload', 'stale_payload', 'swapped_target', 'extra_target', 'missing_script', 'wrong_script', 'shader_changed', 'wrong_scene', 'wrong_optional_png'):
            payloads = self.payloads.copy()
            if mutation == 'missing_manifest': payloads.pop(photos.MANIFEST)
            if mutation == 'changed_manifest': payloads[photos.MANIFEST] += b' '
            if mutation == 'missing_thumb': payloads.pop('assets/fish/fish_0_thumb.png.import')
            if mutation == 'missing_payload': payloads.pop(target)
            if mutation == 'stale_payload': payloads[target] = b'x'*len(payloads[target])
            if mutation == 'swapped_target': payloads[resource+'.import'] = payloads['assets/fish/fish_1.png.import']
            if mutation == 'extra_target': payloads[resource+'.import'] = payloads[resource+'.import'].rstrip(b'\0') + b'path.s3tc="res://.godot/imported/other.ctex"\n'
            if mutation == 'missing_script': payloads.pop('scripts/fish_art_view.gdc')
            if mutation == 'wrong_script': payloads['scripts/fish_art_view.gd.remap'] = b'[remap]\npath="res://scripts/main.gdc"\n'
            if mutation == 'shader_changed': payloads['assets/fish_silhouette.gdshader'] += b'//motion'
            if mutation == 'wrong_scene': payloads['scenes/main.tscn.remap'] = b'[remap]\npath="res://old_main.scn"\n'
            if mutation == 'wrong_optional_png': payloads[resource] = b'old PNG'
            with self.subTest(mutation=mutation), self.assertRaises(AssertionError): self.verify(payloads)

    def test_archive_requires_all44_originals_and_derivatives(self):
        base = self.root/'art_masters/fish_photoreal_v2'
        entries = copy.deepcopy(self.entries)
        for entry in entries:
            species = entry['species_id']
            entry['runtime'] = f'runtime/{species}.png'
            entry['thumb'] = f'thumbs/{species}_thumb.png'
            for key in ('master', 'runtime', 'thumb'):
                destination = base/entry[key]; destination.parent.mkdir(parents=True, exist_ok=True)
                suffix = '_thumb.png' if key == 'thumb' else '.png'
                destination.write_bytes((self.project/f'assets/fish/{species}{suffix}').read_bytes())
        artist = base/'asset_manifest.json'
        artist.write_text(json.dumps({'format_version': 1, 'complete': True, 'asset_count': 44, 'assets': entries}))
        for name in ('build_asset_variants.py', 'art_provenance.json'): (base/name).write_text('fixture')
        self.manifest['source_manifest_sha256'] = photos.sha256(artist.read_bytes()); self.save_manifest()
        contract = photos.photo_art_contract(self.project, self.catalog)
        files = {str(p.relative_to(self.root)): {'sha256': photos.sha256(p.read_bytes())} for p in self.root.rglob('*') if p.is_file()}
        required = photos.require_photo_archive_members(self.root, files, contract)
        self.assertEqual(len(photos.photo_authoring_files(self.root, contract)), 135)
        self.assertIn('art_masters/fish_photoreal_v2/masters/fish_43.png', required)
        missing = files.copy(); missing.pop('art_masters/fish_photoreal_v2/masters/fish_43.png')
        with self.assertRaises(AssertionError): photos.require_photo_archive_members(self.root, missing, contract)
        (base/'masters/fish_43.png').write_bytes(b'corrupt original')
        with self.assertRaises(AssertionError): photos.require_photo_archive_members(self.root, files, contract)


class PackagingTests(unittest.TestCase):
    def test_exact_preview_identity_and_legacy_default(self):
        self.assertEqual(android_identity.expected_identity(),android_identity.LEGACY)
        preview={**android_identity.PREVIEW,'separate_installation':True,'application_version':'1.2.0-beta.2','android_version_code':4}
        self.assertEqual(android_identity.expected_identity({'android_identity':preview}),preview)
        bad={**preview,'certificate_sha256':android_identity.LEGACY['certificate_sha256']}
        with self.assertRaises(AssertionError):android_identity.validate_identity(bad)
        with self.assertRaises(AssertionError):android_identity.validate_identity({**preview,'android_package_name':'org.farshore.other'})
        with tempfile.TemporaryDirectory(prefix='farshore-identity-test-') as folder:
            project=Path(folder);(project/'data').mkdir();(project/'data/android_build_identity.json').write_text(json.dumps(preview))
            presets='package/unique_name="org.farshore.fishing.preview"\npackage/name="远岸钓记·试钓版"\n'
            self.assertEqual(android_identity.project_identity(project,presets,'1.2.0-beta.2',4),preview)
            with self.assertRaises(AssertionError):android_identity.project_identity(project,presets,'1.2.0-beta.2',3)
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
