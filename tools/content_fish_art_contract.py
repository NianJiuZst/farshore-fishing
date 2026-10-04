"""Fail-closed source, imported-pixel and exported-byte contract for all74 photos.

Godot exports stripped .import remaps and .ctex payloads, not the original PNGs.
The source hashes and decoded RGBA8 hashes therefore have separate proof chains.
"""
from pathlib import Path, PurePosixPath
import hashlib
import json
import math
import re
import struct

MANIFEST = 'data/fish_art.json'
# These native modules must be present in the frozen source, source archive,
# and exported resources. Godot compiles scripts to matching .gdc targets.
BETA3_UI_RESOURCES = ('scripts/fish_notebook_ui.gd', 'scripts/fishing_menu_pages.gd',
                      'scripts/fishing_failure_modal.gd')
FORMAL_GAMEPLAY_RESOURCES = ('scripts/float_encounter.gd',)
FORMAL_SHADER_RESOURCES = ('assets/shaders3d/float_lacquer.gdshader',)
DIVERSITY_RESOURCES = ('scripts/blue_whale_challenge.gd', 'scripts/whale_challenge_stage_3d.gd',
                       'scripts/whale_challenge_ui.gd', 'scripts/encounter.gd',
                       'scripts/catalog.gd', 'scripts/save_store.gd',
                       'assets/shaders3d/whale_ocean.gdshader')
# Keep the established evidence field name for the combined runtime-resource gate.
UI_RESOURCES = ('scripts/fish_art_catalog.gd', 'scripts/fish_art_view.gd',
                'scripts/measure_ruler.gd', 'scripts/main.gd',
                'scenes/main.tscn', 'assets/fish_silhouette.gdshader') + BETA3_UI_RESOURCES + FORMAL_GAMEPLAY_RESOURCES + FORMAL_SHADER_RESOURCES


def sha256(raw):
    return hashlib.sha256(raw).hexdigest()


def valid_hash(value):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{64}', value) is not None


def local_resource(resource):
    assert isinstance(resource, str) and resource.startswith('res://'), 'Invalid resource path'
    relative = resource.removeprefix('res://')
    assert relative and '\\' not in relative and not relative.startswith('/')
    assert all(p not in {'', '.', '..'} for p in relative.split('/')), 'Unsafe resource path'
    return relative


def read_source(project, relative):
    local_resource('res://' + relative)
    path = project / relative
    assert path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(project.resolve()), 'Missing/unsafe source: ' + relative
    return path.read_bytes()


def import_target(raw):
    text = raw.decode('utf-8').rstrip('\0')
    assert 'importer="texture"' in text and 'type="CompressedTexture2D"' in text, 'Expected native texture import'
    targets = re.findall(r'^path(?:\.[a-z0-9_]+)?="(res://[^"]+)"\s*$', text, re.M)
    assert len(targets) == 1, 'Photo must have exactly one lossless imported target'
    target = local_resource(targets[0])
    assert target.startswith('.godot/imported/') and target.endswith('.ctex'), 'Unexpected photo payload'
    return target


def photo_art_contract(project, catalog):
    project = Path(project)
    raw = read_source(project, MANIFEST)
    manifest = json.loads(raw)
    assert manifest.get('format_version') == 1 and manifest.get('complete') is True, 'Complete photo manifest required'
    entries = manifest.get('assets')
    gate = read_source(project, 'scripts/fish_art_catalog.gd').decode()
    counts = re.findall(r'^const EXPECTED_COUNT: int = (\d+)\s*$', gate, re.M)
    assert len(counts) == 1, 'Expected a pinned runtime art count'
    expected_count = int(counts[0])
    assert expected_count in (74, 111), 'Unsupported canonical artwork scope'
    assert isinstance(entries, list) and len(entries) == manifest.get('asset_count') == expected_count, 'Exact canonical artwork coverage required'
    fish = {entry['species_id']: entry for entry in catalog}
    assert len(catalog) == len(fish) == expected_count, 'Exact canonical catalog animal coverage required'
    ids = [entry['species_id'] for entry in entries]
    assert len(set(ids)) == expected_count and set(ids) == set(fish), 'Photo manifest must match all canonical species once'
    textures = {}
    for entry in entries:
        species = entry['species_id']
        for thumbnail in (False, True):
            resource = f'assets/fish/{species}' + ('_thumb.png' if thumbnail else '.png')
            assert fish[species]['thumb' if thumbnail else 'art'] == 'res://' + resource, 'Noncanonical catalog photo path'
            assert entry.get('thumb' if thumbnail else 'runtime') == 'res://' + resource, 'Noncanonical manifest photo path'
            source_hash = entry.get('thumb_sha256' if thumbnail else 'sha256')
            image_hash = entry.get('thumb_image_sha256' if thumbnail else 'image_sha256')
            assert valid_hash(source_hash) and valid_hash(image_hash), 'Missing source/imported image digest: ' + resource
            png = read_source(project, resource)
            assert sha256(png) == source_hash, 'PNG source differs from photo manifest: ' + resource
            assert len(png) >= 33 and png[:8] == b'\x89PNG\r\n\x1a\n' and png[12:16] == b'IHDR', 'Expected PNG source'
            width, height = struct.unpack_from('>II', png, 16)
            assert width == entry.get('thumb_width' if thumbnail else 'width') and height == entry.get('thumb_height' if thumbnail else 'height'), 'PNG dimensions differ'
            bounds = entry.get('thumb_subject_bbox_px' if thumbnail else 'subject_bbox_px')
            assert isinstance(bounds, list) and len(bounds) == 4 and all(isinstance(n, (int, float)) and not isinstance(n, bool) and math.isfinite(n) and int(n) == n for n in bounds), 'Invalid alpha bounds'
            assert 0 <= bounds[0] < bounds[2] <= width and 0 <= bounds[1] < bounds[3] <= height, 'Alpha bounds outside PNG'
            mapping = read_source(project, resource + '.import')
            target = import_target(mapping)
            mapping_text = mapping.decode()
            assert f'source_file="res://{resource}"' in mapping_text, 'Import does not reference canonical PNG'
            assert f'dest_files=["res://{target}"]' in mapping_text, 'Import destination mismatch'
            assert re.search(r'^compress/mode=0$', mapping_text, re.M) and re.search(r'^mipmaps/generate=false$', mapping_text, re.M), 'Photo import must remain lossless without mipmaps'
            textures[resource] = {'species_id': species, 'thumbnail': thumbnail, 'source_sha256': source_hash,
                                  'image_sha256': image_hash, 'width': width, 'height': height,
                                  'alpha_bounds': bounds, 'import_mapping_sha256': sha256(mapping), 'target': target}
    assert len({v['target'] for v in textures.values()}) == expected_count * 2, 'Photo imports must have two distinct payloads per animal'
    actual_pngs = {str(p.relative_to(project)) for p in (project/'assets/fish').glob('*.png')}
    assert actual_pngs == set(textures), 'Unexpected or absent canonical fish PNG'
    resources = UI_RESOURCES + (DIVERSITY_RESOURCES if expected_count == 111 else ())
    ui = {p: sha256(read_source(project, p)) for p in resources}
    assert re.search(r'^const REQUIRE_PHOTOREAL: bool = true$', gate, re.M), 'Strict runtime photo gate is disabled'
    assert 'res://' + MANIFEST in gate
    main = read_source(project, 'scripts/main.gd').decode()
    assert 'res://scripts/fish_art_catalog.gd' in main and 'res://scripts/fish_art_view.gd' in main
    assert 'if not fish_art.load_all(catalog):' in main and 'var rect: FishArtView = FishArtViewScript.new()' in main, 'Native photo UI is not wired to strict manifest'
    return {'format_version': 1, 'manifest': MANIFEST, 'manifest_sha256': sha256(raw),
            'species_ids': sorted(ids), 'species_count': expected_count, 'texture_count': expected_count * 2,
            'textures': textures, 'ui_resource_sha256': ui,
            'scope': 'All canonical animal masters and thumbnails; exact source and decoded imported RGBA8 hashes'}


def photo_authoring_files(root, contract):
    """Require hash-bound original/derivative sets across retained and new art."""
    root = Path(root)
    runtime = json.loads(read_source(root, 'game/' + MANIFEST))
    manifest_specs = runtime.get('source_manifests')
    if manifest_specs is None:
        # Synthetic regression fixtures retain the original single-manifest flow.
        manifest_specs = [{'path': 'art_masters/fish_photoreal_v2/asset_manifest.json',
                           'sha256': runtime.get('source_manifest_sha256')}]
    assert isinstance(manifest_specs, list) and 1 <= len(manifest_specs) <= 3, 'Invalid photo source manifests'
    allowed = {'art_masters/fish_photoreal_v2/asset_manifest.json',
               'art_masters/fish_photoreal_ocean/asset_manifest.json',
               'art_masters/fish_photoreal_diversity/asset_manifest.json'}
    paths = [item.get('path') for item in manifest_specs if isinstance(item, dict)]
    assert len(paths) == len(manifest_specs) and len(set(paths)) == len(paths) and set(paths).issubset(allowed), 'Unexpected source-art manifest path'
    if len(paths) == 2:
        assert set(paths) == allowed - {'art_masters/fish_photoreal_diversity/asset_manifest.json'}, 'Legacy and ocean artwork must both be archived'
    if len(paths) == 3:
        assert set(paths) == allowed, 'Retained and new artwork must all be archived'
    files, ids = {}, []
    for spec in manifest_specs:
        manifest_path = spec['path']
        base = str(PurePosixPath(manifest_path).parent) + '/'
        raw = read_source(root, manifest_path)
        assert spec.get('sha256') == sha256(raw), 'Artist manifest differs from canonical provenance hash'
        if 'fish_photoreal_v2/' in manifest_path:
            assert runtime.get('source_manifest_sha256') == sha256(raw), 'Legacy art provenance has changed'
        artist = json.loads(raw)
        assert artist.get('complete') is True and artist.get('format_version') == 1
        entries = artist.get('assets', [])
        assert isinstance(entries, list) and len(entries) == artist.get('asset_count') and entries
        if len(paths) >= 2:
            expected = 44 if 'fish_photoreal_v2/' in manifest_path else (30 if 'fish_photoreal_ocean/' in manifest_path else 37)
            assert len(entries) == expected, 'Exact retained and new authoring artwork coverage required'
        files[manifest_path] = sha256(raw)
        for entry in entries:
            species = entry['species_id']
            assert species not in ids and species in contract['species_ids'], 'Duplicate/unknown source-art identity'
            ids.append(species)
            for field, expected_path, thumbnail in [('master', f'masters/{species}.png', False),
                                                   ('runtime', f'runtime/{species}.png', False),
                                                   ('thumb', f'thumbs/{species}_thumb.png', True)]:
                assert entry.get(field) == expected_path, 'Noncanonical artist source path'
                resource = f'assets/fish/{species}' + ('_thumb.png' if thumbnail else '.png')
                expected = contract['textures'][resource]['source_sha256']
                assert entry.get('thumb_sha256' if thumbnail else 'sha256') == expected, 'Artist/runtime manifest digest differs'
                path = base + expected_path
                actual = sha256(read_source(root, path))
                assert actual == expected, 'Original photo/derivative differs from runtime: ' + path
                files[path] = actual
        for filename in ('build_asset_variants.py', 'art_provenance.json'):
            path = base + filename
            files[path] = sha256(read_source(root, path))
    assert len(ids) == contract['species_count'] and sorted(ids) == contract['species_ids'], 'Artist manifests must cover all canonical species'
    return files


def require_photo_archive_members(root, files, contract=None):
    root = Path(root)
    if not (root/'game'/MANIFEST).exists():
        return {}  # Generic source ZIP regression projects and historical sources.
    if contract is None:
        loader = (root/'game/scripts/catalog.gd').read_text()
        catalogs = list(dict.fromkeys(re.findall(r'"(fish_[a-z0-9_]+\.json)"', loader)))
        entries = sum((json.loads(read_source(root, 'game/data/' + p)) for p in catalogs), [])
        contract = photo_art_contract(root/'game', entries)
    required = {'game/' + contract['manifest']: contract['manifest_sha256']}
    required.update({'game/' + p: sha for p, sha in contract['ui_resource_sha256'].items()})
    for resource, expected in contract['textures'].items():
        required['game/' + resource] = expected['source_sha256']
        required['game/' + resource + '.import'] = expected['import_mapping_sha256']
    required.update(photo_authoring_files(root, contract))
    assert set(required).issubset(files), 'Source archive omits required photo inputs: ' + ', '.join(sorted(set(required) - set(files)))
    for path, expected in required.items():
        if files[path].get('sha256'):
            assert files[path]['sha256'] == expected, 'Archived photo source differs: ' + path
    return required


def validate_import_audit(contract, report):
    assert report.get('failures') == [], 'Imported photograph audit failed'
    assert report.get('manifest_sha256') == contract['manifest_sha256'], 'Imported audit manifest differs'
    assert report.get('species_ids') == contract['species_ids'] and report.get('complete') is True
    assert set(report.get('textures', {})) == set(contract['textures']), 'Imported audit must cover all148 textures'
    for resource, expected in contract['textures'].items():
        actual = report['textures'][resource]
        for field in ('source_sha256', 'image_sha256', 'width', 'height', 'alpha_bounds', 'import_mapping_sha256', 'target'):
            assert actual.get(field) == expected[field], f'Imported photo {field} differs: {resource}'
        size = actual.get('payload_bytes')
        assert valid_hash(actual.get('payload_sha256')) and isinstance(size, (int, float)) and not isinstance(size, bool) and math.isfinite(size) and int(size) == size and size > 0, 'Imported texture bytes were not audited'


def verify_exported_photo_art(archive, contract, report, prefix='assets/'):
    """Verify an APK (assets/) or disposable resource-only ZIP (empty prefix)."""
    validate_import_audit(contract, report)
    names = archive.namelist()
    assert len(names) == len(set(names)), 'Duplicate archive members are forbidden'
    def read(relative):
        name = prefix + relative
        assert name in names, 'Missing exported photo resource: ' + relative
        return archive.read(name)
    assert sha256(read(contract['manifest'])) == contract['manifest_sha256'], 'Exported photo manifest differs from frozen source'
    for resource, expected in contract['textures'].items():
        target = import_target(read(resource + '.import'))
        assert target == expected['target'], 'Exported photo remap differs from canonical import: ' + resource
        payload = read(target)
        audited = report['textures'][resource]
        assert len(payload) == audited['payload_bytes'] and sha256(payload) == audited['payload_sha256'], 'Exported texture differs from decoded/imported audit: ' + resource
        if prefix + resource in names:
            assert sha256(read(resource)) == expected['source_sha256'], 'Optional exported PNG differs'
    ui_payloads = {}
    ui_payload_hashes = {}
    for resource, expected_hash in contract['ui_resource_sha256'].items():
        if prefix + resource in names:
            assert sha256(read(resource)) == expected_hash, 'Exported static UI source differs: ' + resource
            ui_payloads[resource] = resource
            ui_payload_hashes[resource] = expected_hash
            continue
        # Godot4.6.3 exports GDScript as .gdc and main.tscn as an exported .scn.
        mapping = read(resource + '.remap').decode()
        matches = re.findall(r'^path="(res://[^"]+)"\s*$', mapping, re.M)
        assert len(matches) == 1, 'Invalid static UI remap: ' + resource
        target = local_resource(matches[0])
        if resource.endswith('.gd'):
            assert target == str(PurePosixPath(resource).with_suffix('.gdc')), 'Unexpected static UI script target'
            assert read(target).startswith(b'GDSC'), 'Invalid compiled static UI script'
        elif resource == 'scenes/main.tscn':
            assert target.startswith('.godot/exported/') and target.endswith('-main.scn'), 'Unexpected main-scene target'
            assert read(target)[:4] in (b'RSRC', b'RSCC'), 'Invalid exported main scene'
        else:
            raise AssertionError('Static shader must export byte-identical source: ' + resource)
        ui_payloads[resource] = target
        ui_payload_hashes[resource] = sha256(read(target))
    count = contract['species_count']
    return {'species_count': count, 'full_photos': count, 'thumbnails': count, 'texture_payloads': count * 2,
            'manifest_sha256': contract['manifest_sha256'], 'exact_imported_texture_bytes': True,
            'decoded_rgba8_hashes_match_manifest': True, 'canonical_import_targets': True,
            'static_ui_resources': ui_payloads,
            'static_ui_payload_sha256': ui_payload_hashes,
            'scope': 'Source PNG hashes and staged decoded RGBA8/alpha geometry bound to exact exported .ctex bytes; separate runtime/device evidence required'}


if __name__ == '__main__':
    import argparse
    import zipfile
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('snapshot', type=Path)
    parser.add_argument('audit', type=Path)
    parser.add_argument('--archive', type=Path)
    args = parser.parse_args()
    contract = json.loads(args.snapshot.read_text())['content']['photo_art']
    report = json.loads(args.audit.read_text())
    validate_import_audit(contract, report)
    if args.archive:
        with zipfile.ZipFile(args.archive) as archive:
            print(json.dumps(verify_exported_photo_art(archive, contract, report), indent=2))
    else:
        print('PASS: 74 canonical photographs and74 thumbnails matched staged source/imported-pixel audit')
