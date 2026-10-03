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
from unittest import mock
import warnings
import zipfile
import zlib
import release_source_zip as source
import derive_android_template as template
import park_android_ndk as ndk
import normalize_android_features as normalization
import android_identity
import content_fish_art_contract as photos
import content_3d_contract as three_d
import content_natural_history_contract as natural
import android_prebuilt_build as prebuilt


class NaturalHistoryPackagingTests(unittest.TestCase):
    """Small synthetic all44 fixtures; no editor, APK build or signing access."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='farshore-encyclopedia-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)/'repo'
        self.project = self.root/'game'
        self.ids = [f'fish_{index}' for index in range(44)]
        self.documents = {}
        entry = {'accepted_scientific_name': 'Micropterus nigricans',
                 'taxonomy': {'family_scientific': 'Centrarchidae', 'family_zh': '太阳鱼科',
                              'genus_scientific': 'Micropterus', 'genus_zh': '黑鲈属', 'source_ids': ['s1']},
                 'max_length': {'value_cm': 97.0, 'length_type': 'TL', 'text': 'Published maximum length', 'source_ids': ['s1']},
                 'max_weight': {'value_kg': None, 'text': 'No reliable species-wide maximum', 'source_ids': ['s2'], 'record_label': 'Regional report'},
                 'story': {'title': 'A documented history', 'text': 'Verified narrative', 'source_ids': ['s2']},
                 'sources': [{'id': 's1', 'title': 'Taxonomy and length', 'publisher': 'Reference One', 'url': 'https://example.org/species', 'accessed': '2026-10-03'},
                             {'id': 's2', 'title': 'Natural history', 'publisher': 'Reference Two', 'url': 'https://research.example.org/paper?version=1#results', 'accessed': '2026-10-03'}]}
        entry.update({key: {'text': 'Documented ' + key, 'source_ids': ['s1']} for key in natural.TEXT_FIELDS})
        for index, path in enumerate(natural.DATA_FILES):
            self.documents[path] = {'schema_version': 1, 'entries': [{**copy.deepcopy(entry), 'species_id': species} for species in self.ids[index*11:(index+1)*11]]}
        self.write('project.godot', b'[application]\nconfig/version="1.2.0"\n')
        self.write('scripts/catalog.gd', b'const FILES = ["fish_a.json"]\n')
        # The accepted name is independent of the saved identity/old catalog name.
        self.write('data/fish_a.json', json.dumps([{'species_id': species, 'scientific_name': 'Oldgenus oldname'} for species in self.ids]).encode())
        self.module = ('extends RefCounted\nconst FILES: Array[String] = ' + json.dumps(['res://' + path for path in natural.DATA_FILES]) + '\n').encode()
        self.write(natural.MODULE, self.module)
        self.save_documents()
        self.contract = natural.natural_history_contract(self.project)
        self.payloads = {path: (self.project/path).read_bytes() for path in natural.DATA_FILES}
        self.target = str(Path(natural.MODULE).with_suffix('.gdc'))
        self.payloads[natural.MODULE + '.remap'] = ('[remap]\npath="res://' + self.target + '"\n').encode()
        self.payloads[self.target] = b'GDSC-fixture-compiled-natural-history'

    def write(self, path, raw):
        destination = self.project/path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(raw)

    def save_documents(self):
        for path, document in self.documents.items():
            self.write(path, json.dumps(document, ensure_ascii=False).encode())

    def files(self):
        return {str(path.relative_to(self.root)): {'sha256': photos.sha256(path.read_bytes())} for path in self.root.rglob('*') if path.is_file()}

    def verify(self, payloads=None, prefix='assets/', duplicate=None):
        stream = io.BytesIO()
        contents = self.payloads if payloads is None else payloads
        with zipfile.ZipFile(stream, 'w') as archive:
            for path, raw in contents.items(): archive.writestr(prefix + path, raw)
            if duplicate:
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', UserWarning)
                    archive.writestr(prefix + duplicate, contents[duplicate])
        stream.seek(0)
        with zipfile.ZipFile(stream) as archive:
            return natural.verify_exported_natural_history(archive, self.contract, prefix)

    def test_complete44_source_compiled_and_plain_export_roundtrip(self):
        self.assertEqual(self.contract['species_ids'], sorted(self.ids))
        self.assertEqual(set(self.contract['resource_sha256']), {natural.MODULE, *natural.DATA_FILES})
        for prefix in ('assets/', ''):
            proof = self.verify(prefix=prefix)
            self.assertTrue(proof['exact_frozen_json_bytes'])
            self.assertEqual(proof['module_export_target'], self.target)
            self.assertEqual(proof['module_payload_sha256'], photos.sha256(self.payloads[self.target]))
            self.assertEqual(set(proof['data_payload_sha256']), set(natural.DATA_FILES))
        direct = self.payloads.copy()
        direct.pop(natural.MODULE + '.remap'); direct.pop(self.target)
        direct[natural.MODULE] = self.module
        self.assertEqual(self.verify(direct)['module_payload_sha256'], photos.sha256(self.module))

    def test_required_sources_loader_inventory_and_symlinks_fail_closed(self):
        for path in (natural.MODULE, *natural.DATA_FILES):
            raw = (self.project/path).read_bytes(); (self.project/path).unlink()
            with self.subTest(missing=path), self.assertRaises(AssertionError): natural.natural_history_contract(self.project)
            self.write(path, raw)
        for loaded in (natural.DATA_FILES[:-1], natural.DATA_FILES + (natural.DATA_FILES[0],), natural.DATA_FILES[:-1] + ('data/encyclopedia_extra.json',)):
            self.write(natural.MODULE, ('const FILES: Array[String] = ' + json.dumps(['res://' + path for path in loaded])).encode())
            with self.subTest(loader=loaded), self.assertRaises(AssertionError): natural.natural_history_contract(self.project)
        self.write(natural.MODULE, self.module)
        extra = self.project/'data/encyclopedia_extra.json'; extra.write_text('{}')
        with self.assertRaises(AssertionError): natural.natural_history_contract(self.project)
        extra.unlink()
        module = self.project/natural.MODULE; module.unlink()
        outside = Path(self.temp.name)/'outside.gd'; outside.write_bytes(self.module); module.symlink_to(outside)
        with self.assertRaisesRegex(AssertionError, 'Missing/unsafe source'): natural.natural_history_contract(self.project)

    def test_schema_and_exact44_identity_fail_closed(self):
        original = copy.deepcopy(self.documents)
        for mutation in ('old_schema', 'boolean_schema', 'non_object', 'missing_entries', 'empty_file', 'non_entry', 'missing_species', 'duplicate_species', 'unknown_species'):
            self.documents = copy.deepcopy(original)
            first = self.documents[natural.DATA_FILES[0]]
            if mutation == 'old_schema': first['schema_version'] = 0
            if mutation == 'boolean_schema': first['schema_version'] = True
            if mutation == 'non_object': self.documents[natural.DATA_FILES[0]] = []
            if mutation == 'missing_entries': first.pop('entries')
            if mutation == 'empty_file': first['entries'] = []
            if mutation == 'non_entry': first['entries'][0] = 'invalid'
            if mutation == 'missing_species': first['entries'].pop()
            if mutation == 'duplicate_species': first['entries'][0]['species_id'] = first['entries'][1]['species_id']
            if mutation == 'unknown_species': first['entries'][0]['species_id'] = 'unknown_fish'
            self.save_documents()
            with self.subTest(mutation=mutation), self.assertRaises(AssertionError): natural.natural_history_contract(self.project)
        self.documents = original; self.save_documents()
        for invalid_ids in (self.ids[:-1], self.ids[:-1] + [self.ids[0]], self.ids + ['extra'], self.ids[:-1] + [None]):
            with self.subTest(ids=invalid_ids[-1]), self.assertRaises(AssertionError): natural.natural_history_contract(self.project, invalid_ids)
        for raw in (b'{"schema_version":1,"schema_version":1,"entries":[]}', b'{"schema_version":1,"entries":[{"species_id":"fish_0","species_id":"fish_1"}]}', b'{"schema_version":1,"entries":[NaN]}', b'{not json}'):
            self.write(natural.DATA_FILES[0], raw)
            with self.subTest(raw=raw), self.assertRaises((AssertionError, ValueError)): natural.natural_history_contract(self.project)

    def test_taxonomy_and_all_sourced_text_fields_fail_closed(self):
        original = self.documents[natural.DATA_FILES[0]]['entries'][0]
        for key in ('species_id', 'accepted_scientific_name'):
            for bad in ('', ' ', None, 12, 'Oldgenus', '../escape'):
                entry = copy.deepcopy(original); entry[key] = bad
                with self.subTest(key=key, value=bad), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for key in ('family_scientific', 'family_zh', 'genus_scientific', 'genus_zh'):
            entry = copy.deepcopy(original); entry['taxonomy'][key] = ''
            with self.subTest(taxonomy=key), self.assertRaises(AssertionError): natural.validate_entry(entry)
        entry = copy.deepcopy(original); entry['taxonomy']['genus_scientific'] = 'Oldgenus'
        with self.assertRaisesRegex(AssertionError, 'name and genus differ'): natural.validate_entry(entry)
        for key in ('taxonomy', *natural.TEXT_FIELDS, 'max_length', 'max_weight', 'story'):
            for replacement in (None, {}, {'text': 17, 'source_ids': ['s1']}):
                entry = copy.deepcopy(original); entry[key] = replacement
                with self.subTest(field=key, value=replacement), self.assertRaises(AssertionError): natural.validate_entry(entry)
        entry = copy.deepcopy(original); entry['story'].pop('title')
        with self.assertRaises(AssertionError): natural.validate_entry(entry)

    def test_source_metadata_safe_urls_and_field_references_fail_closed(self):
        original = self.documents[natural.DATA_FILES[0]]['entries'][0]
        for unsafe in ('http://example.org/x', 'https://user:pass@example.org/x', 'https://example.org:443/x', 'https://example.org\\evil',
                       'https://example.org/\nsecret', 'https://example.org/\x00', 'https://example.org/\x7f', 'https://example.org/ white',
                       'https://localhost/x', 'https://bad..org/x', 'https://-bad.org/x', 'https://example.org@evil.org/x',
                       'https://example%2eorg/x', 'https://[broken/x', 'javascript:alert(1)', None, 'https://example.org/' + 'x'*2048):
            entry = copy.deepcopy(original); entry['sources'][0]['url'] = unsafe
            with self.subTest(url=unsafe), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for key in ('id', 'title', 'publisher', 'accessed'):
            for invalid in ('', None, 19):
                entry = copy.deepcopy(original); entry['sources'][0][key] = invalid
                with self.subTest(source=key, value=invalid), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for bad in ('2026-02-30', '20261003'):
            entry = copy.deepcopy(original); entry['sources'][0]['accessed'] = bad
            with self.subTest(date=bad), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for sources in ([], original['sources'][:1], [original['sources'][0]]*2, [None, None]):
            entry = copy.deepcopy(original); entry['sources'] = sources
            with self.subTest(sources=sources), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for key in ('taxonomy', *natural.TEXT_FIELDS, 'max_length', 'max_weight', 'story'):
            for refs in ([], None, 's1', ['undefined'], [1], ['s1', 's1']):
                entry = copy.deepcopy(original); entry[key]['source_ids'] = refs
                with self.subTest(field=key, refs=refs), self.assertRaises(AssertionError): natural.validate_entry(entry)

    def test_numeric_null_length_types_and_optional_scoped_record_labels(self):
        original = self.documents[natural.DATA_FILES[0]]['entries'][0]
        for field, unit in (('max_length', 'value_cm'), ('max_weight', 'value_kg')):
            for valid in (None, 12, 1.25):
                entry = copy.deepcopy(original); entry[field][unit] = valid
                natural.validate_entry(entry)
            for invalid in (True, False, '12', '', 0, -1, float('nan'), float('inf'), -float('inf'), [], {}):
                entry = copy.deepcopy(original); entry[field][unit] = invalid
                with self.subTest(field=field, value=invalid), self.assertRaises(AssertionError): natural.validate_entry(entry)
            entry = copy.deepcopy(original); entry[field].pop(unit)
            with self.assertRaises(AssertionError): natural.validate_entry(entry)
            for invalid in ('', ' ', None, 1, []):
                entry = copy.deepcopy(original); entry[field]['record_label'] = invalid
                with self.subTest(field=field, label=invalid), self.assertRaises(AssertionError): natural.validate_entry(entry)
        for length_type in ('TL', 'FL', 'SL', 'unspecified'):
            entry = copy.deepcopy(original); entry['max_length']['length_type'] = length_type
            natural.validate_entry(entry)
        for invalid in ('', None, 'total', 'cm', 1):
            entry = copy.deepcopy(original); entry['max_length']['length_type'] = invalid
            with self.subTest(length_type=invalid), self.assertRaises(AssertionError): natural.validate_entry(entry)

    def test_export_missing_changed_extra_remapped_and_duplicate_json_fails_closed(self):
        for path in natural.DATA_FILES:
            for mutation in ('missing', 'changed', 'substituted', 'remapped'):
                payloads = self.payloads.copy()
                if mutation == 'missing': payloads.pop(path)
                if mutation == 'changed': payloads[path] += b' '
                if mutation == 'substituted': payloads[path] = payloads[natural.DATA_FILES[(natural.DATA_FILES.index(path)+1)%4]]
                if mutation == 'remapped': payloads[path + '.remap'] = b'[remap]\npath="res://other.json"\n'
                with self.subTest(path=path, mutation=mutation), self.assertRaises(AssertionError): self.verify(payloads)
        payloads = {**self.payloads, 'data/encyclopedia_extra.json': b'{}'}
        with self.assertRaises(AssertionError): self.verify(payloads)
        with self.assertRaisesRegex(AssertionError, 'Duplicate archive'): self.verify(duplicate=natural.DATA_FILES[0])

    def test_export_module_remap_payload_and_source_fail_closed(self):
        for mutation in ('missing_remap', 'missing_payload', 'wrong_target', 'traversal', 'duplicate_path', 'invalid_bytecode', 'header_only', 'source_and_remap', 'changed_source', 'source_and_bytecode'):
            payloads = self.payloads.copy()
            if mutation == 'missing_remap': payloads.pop(natural.MODULE + '.remap')
            if mutation == 'missing_payload': payloads.pop(self.target)
            if mutation == 'wrong_target': payloads[natural.MODULE + '.remap'] = b'[remap]\npath="res://scripts/main.gdc"\n'
            if mutation == 'traversal': payloads[natural.MODULE + '.remap'] = b'[remap]\npath="res://../outside.gdc"\n'
            if mutation == 'duplicate_path': payloads[natural.MODULE + '.remap'] += payloads[natural.MODULE + '.remap']
            if mutation == 'invalid_bytecode': payloads[self.target] = b'invalid bytecode'
            if mutation == 'header_only': payloads[self.target] = b'GDSC'
            if mutation == 'source_and_remap': payloads[natural.MODULE] = self.module
            if mutation in ('changed_source', 'source_and_bytecode'):
                payloads.pop(natural.MODULE + '.remap'); payloads[natural.MODULE] = self.module
                if mutation == 'changed_source':
                    payloads.pop(self.target); payloads[natural.MODULE] += b'#drift'
            with self.subTest(mutation=mutation), self.assertRaises(AssertionError): self.verify(payloads)

    def test_archive_requires_all_five_hashes_and_rejects_source_drift(self):
        files = self.files()
        required = natural.require_natural_history_archive_members(self.root, files)
        self.assertEqual(len(required), 5)
        for path in required:
            for mutation in ('missing', 'changed', 'missing_digest'):
                altered = copy.deepcopy(files)
                if mutation == 'missing': altered.pop(path)
                if mutation == 'changed': altered[path]['sha256'] = '0'*64
                if mutation == 'missing_digest': altered[path] = {}
                with self.subTest(path=path, mutation=mutation), self.assertRaises(AssertionError): natural.require_natural_history_archive_members(self.root, altered, self.contract)
        self.write(natural.DATA_FILES[0], (self.project/natural.DATA_FILES[0]).read_bytes() + b' ')
        with self.assertRaisesRegex(AssertionError, 'source differs'): natural.require_natural_history_archive_members(self.root, files, self.contract)
        for path in (natural.MODULE, *natural.DATA_FILES): (self.project/path).unlink()
        with self.assertRaises(AssertionError): natural.require_natural_history_archive_members(self.root, self.files())

    def test_source_zip_integration_validates_content_before_creating_archive(self):
        def inventory():
            result = {}
            for path in self.root.rglob('*'):
                if path.is_file():
                    with path.open('rb') as stream: sha1, unused = source.stream_hashes(stream, path.stat().st_size)
                    result[str(path.relative_to(self.root))] = {'mode': '100644', 'git_blob_sha1': sha1, 'bytes': path.stat().st_size}
            return '0'*40, result
        output = Path(self.temp.name)/'fixture-source.zip'
        with mock.patch.object(source, 'inventory', return_value=inventory()):
            report = source.create(self.root, 'fixture', output, 'fixture')
        self.assertTrue({'game/' + path for path in (natural.MODULE, *natural.DATA_FILES)}.issubset(report['files']))
        self.documents[natural.DATA_FILES[0]]['entries'][0]['max_weight']['value_kg'] = -1
        self.save_documents()
        invalid = Path(self.temp.name)/'invalid.zip'
        with mock.patch.object(source, 'inventory', return_value=inventory()), self.assertRaisesRegex(AssertionError, 'positive finite'):
            source.create(self.root, 'fixture', invalid, 'invalid')
        self.assertFalse(invalid.exists())
        self.assertFalse(invalid.with_name(invalid.name + '.pending').exists())


class IsolatedStagingTests(unittest.TestCase):
    def test_default_and_external_staging_create_and_owned_cleanup(self):
        with tempfile.TemporaryDirectory(prefix='farshore-staging-test-') as folder:
            root = Path(folder)/'repo'; root.mkdir()
            self.assertEqual(prebuilt.checked_staging_parent(root), Path('/tmp'))
            parent = Path(folder)/'external/builds'
            work, identity = prebuilt.create_staging_work(root, '1.2.0', parent)
            self.assertEqual(work.parent, parent)
            (work/'fixture.txt').write_text('owned')
            (parent/'unrelated.txt').write_text('preserve')
            prebuilt.remove_staging_work(root, work, identity, parent)
            self.assertFalse(work.exists())
            self.assertEqual((parent/'unrelated.txt').read_text(), 'preserve')

    def test_unsafe_staging_and_replaced_cleanup_targets_fail_closed(self):
        with tempfile.TemporaryDirectory(prefix='farshore-staging-test-') as folder:
            base = Path(folder); root = base/'repo'; root.mkdir()
            parent = base/'external'; parent.mkdir()
            link = base/'linked'; link.symlink_to(parent, target_is_directory=True)
            regular = base/'regular'; regular.write_text('preserve')
            for invalid in (root, root/'game', Path('relative'), Path('/'), link, link/'child', regular):
                with self.subTest(parent=invalid), self.assertRaises(AssertionError): prebuilt.create_staging_work(root, '1.2.0', invalid)
            with self.assertRaises(AssertionError): prebuilt.create_staging_work(root, '../escape', parent)
            work, identity = prebuilt.create_staging_work(root, '1.2.0', parent)
            (work/'fixture.txt').write_text('preserve')
            with self.assertRaises(AssertionError): prebuilt.remove_staging_work(root, work, (identity[0], identity[1]+1), parent)
            with self.assertRaises(AssertionError): prebuilt.remove_staging_work(root, root, identity, parent)
            moved = work.with_name(work.name + '-preserved'); work.rename(moved)
            work.symlink_to(moved, target_is_directory=True)
            with self.assertRaises(AssertionError): prebuilt.remove_staging_work(root, work, identity, parent)
            self.assertEqual((moved/'fixture.txt').read_text(), 'preserve')


class AnglerPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='farshore-angler-contract-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name); self.project = self.root/'game'
        (self.project/'assets/3d').mkdir(parents=True); (self.root/'docs').mkdir()
        self.provenance = {'schema_version': 1, 'derived_texture_files': []}
        self.doc = {'images': [], 'bufferViews': [], 'materials': []}
        self.binary = b''; self.originals = {}
        for index in range(7):
            name = f'image_{index}'; raw = b'PNG fixture ' + bytes([index])
            relative = f'assets/3d/angler_{name}.png'
            self.originals[relative] = raw; (self.project/relative).write_bytes(raw)
            self.doc['images'].append({'name': name, 'mimeType': 'image/png', 'bufferView': index})
            self.doc['bufferViews'].append({'buffer': 0, 'byteOffset': len(self.binary), 'byteLength': len(raw)})
            self.binary += raw
            self.provenance['derived_texture_files'].append({'path': 'game/' + relative, 'bytes': len(raw),
                'sha256': photos.sha256(raw), 'license': 'CC0-1.0', 'source_url': 'https://example.org/fixture'})
        for name in ('Human.body', 'Human.male_casualsuit05', 'Human.shoes02', 'Human.low-poly', 'Human.eyebrow001', 'Human.short02'):
            self.doc['materials'].append({'name': name, **({'alphaMode': 'MASK', 'alphaCutoff': .35} if len(self.doc['materials']) >= 3 else {})})
        self.write_glb()

    def write_glb(self):
        document = json.dumps(self.doc).encode(); document += b' ' * (-len(document) % 4)
        binary = self.binary + b'\0' * (-len(self.binary) % 4)
        raw = struct.pack('<4sII', b'glTF', 2, 28 + len(document) + len(binary))
        raw += struct.pack('<II', len(document), 0x4E4F534A) + document
        raw += struct.pack('<II', len(binary), 0x004E4942) + binary
        (self.project/'assets/3d/angler.glb').write_bytes(raw)
        self.runtime = {'sha256': photos.sha256(raw), 'bytes': len(raw)}
        self.provenance['runtime_contract'] = self.runtime.copy()
        self.provenance['derived_files'] = [{'path': 'game/assets/3d/angler.glb', **self.runtime}]
        self.provenance['runtime_materials'] = [{'name': m['name'], 'alpha_mode': m.get('alphaMode', 'OPAQUE'),
            'alpha_cutoff': m.get('alphaCutoff'), 'depth_writing': m.get('alphaMode') != 'BLEND'} for m in self.doc['materials']]

    def verify(self):
        (self.root/'docs/ASSETS_3D_ANGLER_PROVENANCE.json').write_text(json.dumps(self.provenance))
        return three_d.angler_provenance_contract(self.project, self.runtime, list(self.originals))

    def test_angler_provenance_binds_glb_and_all_seven_extracted_images(self):
        result = self.verify()
        self.assertEqual(len(result['textures']), 7)
        self.assertTrue(result['embedded_images_match_extracted'])
        self.assertEqual(result['runtime_glb_sha256'], self.runtime['sha256'])

    def test_angler_stale_or_incomplete_provenance_and_extraction_fail_closed(self):
        valid = copy.deepcopy(self.provenance)
        first = next(iter(self.originals)); path = self.project/first
        for mutation in ('stale_runtime', 'stale_glb_record', 'missing_glb_record', 'missing_texture_record',
                         'duplicate_texture_record', 'stale_texture_record', 'missing_extracted', 'stale_extracted', 'rehashed_stale_extracted', 'extra_extracted'):
            self.provenance = copy.deepcopy(valid); path.write_bytes(self.originals[first])
            extra = self.project/'assets/3d/angler_stale.png'
            if extra.exists(): extra.unlink()
            if mutation == 'stale_runtime': self.provenance['runtime_contract']['sha256'] = '0'*64
            if mutation == 'stale_glb_record': self.provenance['derived_files'][0]['sha256'] = '0'*64
            if mutation == 'missing_glb_record': self.provenance['derived_files'] = []
            if mutation == 'missing_texture_record': self.provenance['derived_texture_files'].pop()
            if mutation == 'duplicate_texture_record': self.provenance['derived_texture_files'][-1] = self.provenance['derived_texture_files'][0].copy()
            if mutation == 'stale_texture_record': self.provenance['derived_texture_files'][0]['sha256'] = '0'*64
            if mutation == 'missing_extracted': path.unlink()
            if mutation in {'stale_extracted', 'rehashed_stale_extracted'}: path.write_bytes(b'stale extraction')
            if mutation == 'rehashed_stale_extracted':
                self.provenance['derived_texture_files'][0].update(sha256=photos.sha256(path.read_bytes()), bytes=path.stat().st_size)
            if mutation == 'extra_extracted': extra.write_bytes(b'stale extra image')
            with self.subTest(mutation=mutation), self.assertRaises(AssertionError): self.verify()

    def test_angler_raw_material_policy_fails_even_with_updated_provenance(self):
        original = copy.deepcopy(self.doc)
        for name in ('Human.body', 'Human.male_casualsuit05', 'Human.shoes02', 'Human.low-poly', 'Human.eyebrow001', 'Human.short02'):
            modes = ('MASK', 'BLEND') if name in {'Human.body', 'Human.male_casualsuit05', 'Human.shoes02'} else ('BLEND',)
            for mode in modes:
                self.doc = copy.deepcopy(original)
                next(m for m in self.doc['materials'] if m['name'] == name)['alphaMode'] = mode
                self.write_glb()
                with self.subTest(material=name, mode=mode), self.assertRaises(AssertionError): self.verify()


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
        exported = self.verify()
        self.assertEqual(exported['texture_payloads'], 88)
        self.assertEqual(set(exported['static_ui_payload_sha256']), set(photos.UI_RESOURCES))
        for resource, target in exported['static_ui_resources'].items():
            self.assertEqual(exported['static_ui_payload_sha256'][resource], photos.sha256(self.payloads[target]))
        self.assertEqual(self.verify(prefix='')['species_count'], 44)
        self.assertFalse(any(n.endswith('.png') for n in self.payloads))

    def test_beta3_ui_sources_are_required(self):
        required = {'scripts/fish_notebook_ui.gd', 'scripts/fishing_menu_pages.gd',
                    'scripts/fishing_failure_modal.gd'}
        self.assertEqual(set(photos.BETA3_UI_RESOURCES), required)
        self.assertTrue(required.issubset(self.contract['ui_resource_sha256']))
        for resource in sorted(required):
            raw = (self.project/resource).read_bytes()
            (self.project/resource).unlink()
            with self.subTest(resource=resource), self.assertRaisesRegex(AssertionError, 'Missing/unsafe source'):
                photos.photo_art_contract(self.project, self.catalog)
            self.write(resource, raw)

    def test_beta3_ui_export_remaps_payloads_and_source_hashes_fail_closed(self):
        self.assert_script_exports_fail_closed(photos.BETA3_UI_RESOURCES)

    def test_formal_float_encounter_source_is_required(self):
        required = ('scripts/float_encounter.gd',)
        self.assertEqual(photos.FORMAL_GAMEPLAY_RESOURCES, required)
        for resource in required:
            self.assertIn(resource, self.contract['ui_resource_sha256'])
            (self.project/resource).unlink()
            with self.assertRaisesRegex(AssertionError, 'Missing/unsafe source'):
                photos.photo_art_contract(self.project, self.catalog)

    def test_formal_float_encounter_export_fails_closed(self):
        self.assert_script_exports_fail_closed(photos.FORMAL_GAMEPLAY_RESOURCES)

    def test_formal_float_shader_source_and_export_fail_closed(self):
        required = ('assets/shaders3d/float_lacquer.gdshader',)
        self.assertEqual(photos.FORMAL_SHADER_RESOURCES, required)
        for resource in required:
            self.assertIn(resource, self.contract['ui_resource_sha256'])
            source_path = self.project/resource
            original = source_path.read_bytes()
            source_path.unlink()
            with self.assertRaisesRegex(AssertionError, 'Missing/unsafe source'):
                photos.photo_art_contract(self.project, self.catalog)
            source_path.write_bytes(original)
            for mutation in ('missing', 'changed', 'remapped'):
                payloads = self.payloads.copy()
                if mutation == 'missing': payloads.pop(resource)
                if mutation == 'changed': payloads[resource] += b' changed shader'
                if mutation == 'remapped':
                    payloads.pop(resource)
                    payloads[resource + '.remap'] = b'[remap]\npath="res://assets/fish_silhouette.gdshader"\n'
                with self.subTest(resource=resource, mutation=mutation), self.assertRaises(AssertionError):
                    self.verify(payloads)
            result = self.verify()
            self.assertEqual(result['static_ui_resources'][resource], resource)
            self.assertEqual(result['static_ui_payload_sha256'][resource], photos.sha256(original))

    def assert_script_exports_fail_closed(self, resources):
        for resource in resources:
            target = str(Path(resource).with_suffix('.gdc'))
            for mutation in ('missing_remap', 'missing_payload', 'wrong_target', 'duplicate_target', 'invalid_bytecode', 'changed_source'):
                payloads = self.payloads.copy()
                if mutation == 'missing_remap': payloads.pop(resource + '.remap')
                if mutation == 'missing_payload': payloads.pop(target)
                if mutation == 'wrong_target': payloads[resource + '.remap'] = b'[remap]\npath="res://scripts/main.gdc"\n'
                if mutation == 'duplicate_target': payloads[resource + '.remap'] += b'path="res://scripts/main.gdc"\n'
                if mutation == 'invalid_bytecode': payloads[target] = b'not compiled GDScript'
                if mutation == 'changed_source': payloads[resource] = b'old UI source'
                with self.subTest(resource=resource, mutation=mutation), self.assertRaises(AssertionError):
                    self.verify(payloads)
            payloads = self.payloads.copy()
            payloads[resource] = (self.project/resource).read_bytes()
            payloads.pop(resource + '.remap'); payloads.pop(target)
            self.assertEqual(self.verify(payloads)['static_ui_resources'][resource], resource)

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
        for resource in photos.BETA3_UI_RESOURCES + photos.FORMAL_GAMEPLAY_RESOURCES + photos.FORMAL_SHADER_RESOURCES:
            self.assertIn('game/' + resource, required)
            missing_ui = files.copy(); missing_ui.pop('game/' + resource)
            with self.subTest(resource=resource), self.assertRaisesRegex(AssertionError, 'omits required photo inputs'):
                photos.require_photo_archive_members(self.root, missing_ui, contract)
        missing = files.copy(); missing.pop('art_masters/fish_photoreal_v2/masters/fish_43.png')
        with self.assertRaises(AssertionError): photos.require_photo_archive_members(self.root, missing, contract)
        (base/'masters/fish_43.png').write_bytes(b'corrupt original')
        with self.assertRaises(AssertionError): photos.require_photo_archive_members(self.root, files, contract)


class PackagingTests(unittest.TestCase):
    def test_formal_identity_preserves_preview_package_and_certificate(self):
        formal = {**android_identity.FORMAL, 'separate_installation': True}
        self.assertEqual(android_identity.expected_identity({'android_identity': formal}), formal)
        self.assertEqual(formal['android_package_name'], android_identity.PREVIEW['android_package_name'])
        self.assertEqual(formal['certificate_sha256'], android_identity.PREVIEW['certificate_sha256'])
        for field, invalid in [('android_package_name', 'org.farshore.fishing'),
                               ('certificate_sha256', android_identity.LEGACY['certificate_sha256']),
                               ('launcher_name', android_identity.PREVIEW['launcher_name']),
                               ('application_version', '1.2.0-beta.3'),
                               ('android_version_code', 5),
                               ('separate_installation', False)]:
            with self.subTest(field=field), self.assertRaises(AssertionError):
                android_identity.validate_identity({**formal, field: invalid})
        with tempfile.TemporaryDirectory(prefix='farshore-formal-identity-test-') as folder:
            project = Path(folder); (project/'data').mkdir()
            (project/'data/android_build_identity.json').write_text(json.dumps(formal))
            presets = 'package/unique_name="org.farshore.fishing.preview"\npackage/name="远岸钓记"\n'
            self.assertEqual(android_identity.project_identity(project, presets, '1.2.0', 6), formal)
            for version, code in [('1.2.0-beta.3', 6), ('1.2.0', 5)]:
                with self.subTest(version=version, code=code), self.assertRaises(AssertionError):
                    android_identity.project_identity(project, presets, version, code)
            with self.assertRaises(AssertionError):
                android_identity.project_identity(project, presets.replace('远岸钓记', '远岸钓记·试钓版'), '1.2.0', 6)

    def test_exact_preview_identity_and_legacy_default(self):
        self.assertEqual(android_identity.expected_identity(),android_identity.LEGACY)
        preview={**android_identity.PREVIEW,'separate_installation':True,'application_version':'1.2.0-beta.3','android_version_code':5}
        self.assertEqual(android_identity.expected_identity({'android_identity':preview}),preview)
        bad={**preview,'certificate_sha256':android_identity.LEGACY['certificate_sha256']}
        with self.assertRaises(AssertionError):android_identity.validate_identity(bad)
        with self.assertRaises(AssertionError):android_identity.validate_identity({**preview,'android_package_name':'org.farshore.other'})
        with tempfile.TemporaryDirectory(prefix='farshore-identity-test-') as folder:
            project=Path(folder);(project/'data').mkdir();(project/'data/android_build_identity.json').write_text(json.dumps(preview))
            presets='package/unique_name="org.farshore.fishing.preview"\npackage/name="远岸钓记·试钓版"\n'
            self.assertEqual(android_identity.project_identity(project,presets,'1.2.0-beta.3',5),preview)
            with self.assertRaises(AssertionError):android_identity.project_identity(project,presets,'1.2.0-beta.3',4)
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
