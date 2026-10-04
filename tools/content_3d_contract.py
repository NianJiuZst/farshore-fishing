"""Inspect the complete runtime 3D registry, worlds, rigs and authoring sources."""
from pathlib import Path
import gzip
import hashlib
import json
import re
import struct


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def glb_contract(path, clips):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from('<4sII', raw)
    assert magic == b'glTF' and version == 2 and length == len(raw), f'Invalid GLB: {path}'
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A
    doc = json.loads(raw[20:20+size])
    chunk_offset = 20 + size
    binary = None
    while chunk_offset < len(raw):
        chunk_size, chunk_type = struct.unpack_from('<II', raw, chunk_offset)
        chunk_offset += 8
        if chunk_type == 0x004E4942:
            binary = raw[chunk_offset:chunk_offset+chunk_size]
        chunk_offset += chunk_size
    assert binary is not None, f'Missing geometry buffer: {path}'
    geometry = hashlib.sha256()
    vertex_counts = []
    for mesh in doc.get('meshes', []):
        for primitive in mesh.get('primitives', []):
            position = primitive.get('attributes', {}).get('POSITION')
            assert position is not None, f'Missing vertex positions: {path}'
            vertex_counts.append(doc['accessors'][position]['count'])
            for accessor_id in [position, primitive.get('indices')]:
                if accessor_id is None: continue
                accessor = doc['accessors'][accessor_id]
                view = doc['bufferViews'][accessor['bufferView']]
                assert view.get('buffer', 0) == 0
                start, length = view.get('byteOffset', 0), view['byteLength']
                payload = binary[start:start+length]
                assert len(payload) == length
                geometry.update(struct.pack('<II', accessor['componentType'], accessor['count']))
                geometry.update(payload)
    animations = {a.get('name'): a for a in doc.get('animations', [])}
    skins = doc.get('skins', [])
    if clips:
        assert skins and all(s.get('joints') for s in skins), f'Missing deformation skeleton: {path}'
        assert set(clips).issubset(animations), f'Missing animation clips: {path}'
        weighted = sum('JOINTS_0' in p.get('attributes', {}) and 'WEIGHTS_0' in p.get('attributes', {})
                       for mesh in doc.get('meshes', []) for p in mesh.get('primitives', []))
        assert weighted > 0, f'Missing skin-weighted mesh: {path}'
        joints = {j for skin in skins for j in skin['joints']}
        for clip in clips:
            animation = animations[clip]
            assert any(c.get('target', {}).get('node') in joints for c in animation.get('channels', [])), f'Clip does not drive a bone: {path}/{clip}'
            assert all(doc['accessors'][s['input']]['count'] > 1 for s in animation['samplers']), f'Empty animation sampling: {path}/{clip}'
    else:
        weighted = 0
    assert doc.get('meshes'), f'Missing 3D geometry: {path}'
    # The authored models intentionally embed their source textures.
    assert all('bufferView' in im for im in doc.get('images', [])), f'External GLB texture dependency: {path}'
    return {'sha256': sha256(path), 'bytes': len(raw), 'meshes': len(doc['meshes']),
            'geometry_sha256':geometry.hexdigest(), 'primitive_vertex_counts':vertex_counts,
            'skins': len(skins), 'bones': sum(len(s['joints']) for s in skins),
            'weighted_primitives': weighted, 'required_clips': clips,
            'animations': sorted(animations), 'embedded_images': len(doc.get('images', []))}


def angler_provenance_contract(project, runtime, textures):
    """Bind the reviewed human GLB and all extracted images to their provenance."""
    root = project.parent
    provenance = root/'docs/ASSETS_3D_ANGLER_PROVENANCE.json'
    assert provenance.is_file() and not provenance.is_symlink(), 'Missing angler provenance'
    record = json.loads(provenance.read_text())
    assert record.get('schema_version') == 1
    assert record.get('runtime_contract') == runtime, 'Angler runtime differs from provenance'
    glb_path = project/'assets/3d/angler.glb'
    raw = glb_path.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == runtime['sha256'] and len(raw) == runtime['bytes'], 'Angler GLB differs from runtime contract'
    derived = [item for item in record.get('derived_files', []) if item.get('path') == 'game/assets/3d/angler.glb']
    assert len(derived) == 1 and derived[0].get('sha256') == runtime['sha256'] and derived[0].get('bytes') == len(raw), 'Angler GLB differs from derived provenance'
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A
    doc = json.loads(raw[20:20+size])
    binary_size, binary_kind = struct.unpack_from('<II', raw, 20+size)
    assert binary_kind == 0x004E4942
    binary = raw[28+size:28+size+binary_size]
    assert len(binary) == binary_size
    solid = {'Human.body', 'Human.male_casualsuit05', 'Human.shoes02'}
    cutout = {'Human.low-poly', 'Human.eyebrow001', 'Human.short02'}
    materials = doc.get('materials', [])
    names = [material.get('name') for material in materials]
    assert len(names) == len(set(names)) and set(names) == solid | cutout, 'Unexpected angler materials'
    material_report = []
    for material in materials:
        mode = material.get('alphaMode', 'OPAQUE')
        assert mode in {'OPAQUE', 'MASK'}, 'Angler BLEND/unknown material is forbidden'
        assert material['name'] not in solid or mode == 'OPAQUE', 'Angler body/suit/shoes must remain OPAQUE'
        material_report.append({'name': material['name'], 'alpha_mode': mode,
                                'alpha_cutoff': material.get('alphaCutoff'), 'depth_writing': True})
    assert record.get('runtime_materials') == material_report, 'Angler materials differ from provenance'
    images = doc.get('images', [])
    assert len(images) == 7, 'Exactly seven embedded angler textures required'
    embedded = {}
    for image in images:
        assert image.get('mimeType') == 'image/png'
        name = image.get('name', '')
        assert re.fullmatch('[a-z0-9_]+', name), 'Unsafe angler image name'
        relative = f'assets/3d/angler_{name}.png'
        assert relative not in embedded, 'Duplicate embedded angler image'
        view = doc['bufferViews'][image['bufferView']]
        assert view.get('buffer', 0) == 0
        start, length = view.get('byteOffset', 0), view['byteLength']
        payload = binary[start:start+length]
        assert len(payload) == length
        embedded[relative] = {'sha256': hashlib.sha256(payload).hexdigest(), 'bytes': length}
    items = record.get('derived_texture_files', [])
    paths = [item.get('path') for item in items]
    assert len(paths) == 7 and len(set(paths)) == 7 and set(paths) == {'game/' + p for p in embedded}, 'Angler texture provenance must cover all seven extracted images once'
    actual = {str(path.relative_to(project)) for path in (project/'assets/3d').glob('angler_*.png')}
    assert actual == set(embedded), 'Missing or stale extracted angler texture'
    verified = []
    for item in items:
        relative = item['path'].removeprefix('game/')
        path = project/relative
        assert path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(project.resolve()), 'Unsafe extracted angler texture'
        assert relative in textures, 'Angler texture is missing from export contract'
        expected = embedded[relative]
        assert item.get('sha256') == expected['sha256'] and item.get('bytes') == expected['bytes'], 'Angler embedded texture differs from provenance'
        assert path.stat().st_size == expected['bytes'] and sha256(path) == expected['sha256'], 'Extracted angler texture differs from embedded GLB/provenance'
        assert item.get('license') and item.get('source_url'), 'Missing angler texture attribution'
        verified.append({'path': relative, 'sha256': expected['sha256'], 'license': item['license'], 'source_url': item['source_url']})
    return {'provenance_sha256': sha256(provenance), 'runtime_glb_sha256': runtime['sha256'],
            'runtime_materials': material_report, 'textures': verified, 'embedded_images_match_extracted': True}


def three_d_contract(project, catalog_ids):
    registry_path = project/'data/fish_3d.json'
    if not registry_path.exists():
        return None
    registry = json.loads(registry_path.read_text())
    assert registry['schema_version'] == 1
    playable = sorted(registry['models'])
    assert set(playable) == set(catalog_ids) and len(playable) == 74, 'Every one of the 74 catalog species needs its own runtime model'
    fish_clips = registry['required_animation_clips']
    assert set(fish_clips) == {'swim','struggle','breach','landed'}
    for species, entry in registry['models'].items():
        assert entry['scene'] == f'res://assets/3d/{species}.glb', f'Non-species-specific model: {species}'
        assert entry['rest_length_m'] == 1.0
    world = json.loads((project/'data/world.json').read_text())
    region_ids = sorted(r['region_id'] for r in world['regions'])
    assert len(region_ids) == 9 and len(world['spots']) == 18
    assert all(spot['region_id'] in region_ids for spot in world['spots'])
    station_kinds = sorted({'boat' if spot['foreground'] == 'boat' else ('rock' if spot['foreground'] == 'rocks' else 'dock') for spot in world['spots']})
    assert station_kinds == ['boat','dock','rock']
    settings = (project/'project.godot').read_text()
    assert 'renderer/rendering_method="mobile"' in settings
    assert 'renderer/rendering_method.mobile="mobile"' in settings
    assert 'rendering_device/driver.android="vulkan"' in settings, 'Vulkan must be explicit for this trial'
    assert 'rendering_device/fallback_to_opengl3=false' in settings, 'Silent OpenGL fallback is not allowed for this trial'
    assert 'window/stretch/aspect="expand"' in settings
    assert 'anti_aliasing/quality/msaa_3d=2' in settings
    fish_models = {entry['scene'].removeprefix('res://'):fish_clips for entry in registry['models'].values()}
    regions = [f'assets/3d/environment/region_{name}.glb' for name in region_ids]
    stations = [f'assets/3d/environment/station_{name}.glb' for name in station_kinds]
    models = {'assets/3d/angler.glb':['idle','cast','wait','reel','lift'], **fish_models,
              **{name:[] for name in regions+stations}}
    glbs = {name: glb_contract(project/name, clips) for name, clips in models.items()}
    assert len({glbs[name]['sha256'] for name in fish_models}) == len(playable), 'Distinct species cannot share identical GLB bytes'
    assert len({glbs[name]['geometry_sha256'] for name in fish_models}) == len(playable), 'Distinct species cannot share identical geometry buffers'
    image_extensions = {'.png','.jpg','.jpeg','.webp','.hdr','.exr'}
    textures = sorted(str(p.relative_to(project)) for p in (project/'assets/3d').rglob('*') if p.is_file() and p.suffix.lower() in image_extensions)
    assert len(textures) >= 12, 'Expected fish base-color, normal and roughness texture imports'
    angler_provenance = angler_provenance_contract(project, glbs['assets/3d/angler.glb'], textures)
    shaders = sorted(str(p.relative_to(project)) for p in (project/'assets/shaders3d').glob('*.gdshader'))
    assert len(shaders) >= 5, 'Missing water/foliage/ripple/wood/riverbank shaders'
    shader_hashes = {p: sha256(project/p) for p in shaders}
    root = project.parent
    authoring = [f'art_masters/3d/{name}.blend' for name in ['angler', *playable]]
    authoring += sorted(str(p.relative_to(root)) for p in (root/'tools/art3d').rglob('*.py'))
    authoring += sorted(str(p.relative_to(root)) for p in (root/'art_masters/3d').rglob('*.blend') if str(p.relative_to(root)) not in authoring)
    authoring += sorted(str(p.relative_to(root)) for p in (root/'docs').glob('ASSETS_3D_*') if p.is_file())
    assert 'tools/art3d/fish_pipeline.py' in authoring
    assert len([p for p in authoring if p.startswith('tools/art3d/fish_profiles/')]) >= 42, 'Missing shared/profile authoring generators'
    third_party = list(angler_provenance['textures'])
    notices = {}
    provenance = root/'docs/ASSETS_3D_ENVIRONMENT_CC0.json'
    if provenance.exists():
        for item in json.loads(provenance.read_text())['files']:
            path = root/item['path']
            assert path.resolve().is_relative_to((project/'assets/3d').resolve()), 'Third-party asset escaped the 3D asset tree'
            assert sha256(path) == item['sha256'], f'Third-party asset differs from provenance record: {item["path"]}'
            relative = str(path.relative_to(project))
            assert relative in textures, f'Third-party texture is missing from export contract: {relative}'
            third_party.append({'path':relative,'sha256':item['sha256'],'license':item['license'],'source_url':item['source_url']})
        notice = 'data/THIRD_PARTY_ART.txt'
        assert (project/notice).is_file(), 'Third-party art notice must be bundled'
        notices[notice] = sha256(project/notice)
    for name in authoring:
        path = root/name
        assert path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(root.resolve()), f'Missing original authoring source: {name}'
        if path.suffix == '.blend':
            with path.open('rb') as stream:
                header = stream.read(7)
                if header[:4] == b'\x28\xb5\x2f\xfd':
                    import zstandard
                    stream.seek(0)
                    with zstandard.ZstdDecompressor().stream_reader(stream) as decoded:
                        header = decoded.read(7)
                elif header[:2] == b'\x1f\x8b':
                    stream.seek(0)
                    with gzip.GzipFile(fileobj=stream) as decoded:
                        header = decoded.read(7)
                assert header == b'BLENDER', f'Invalid Blender master: {name}' 
    return {'playable_species': playable, 'playable_species_count': len(playable),
            'playable_regions':len(region_ids), 'playable_locations':len(world['spots']),
            'all_catalog_species_have_3d_models':True,
            'registry_sha256':sha256(registry_path), 'region_scene_files':regions, 'station_scene_files':stations,
            'required_scene_count':len(models), 'rigged_model_count':1+len(playable),
            'configured_rendering_method': 'mobile',
            'configured_android_driver': 'vulkan',
            'configured_stretch_aspect':'expand', 'configured_msaa_3d':2,
            'opengl_fallback_disabled': 'rendering_device/fallback_to_opengl3=false' in settings,
            'glb_models': glbs, 'texture_files': textures, 'shader_sha256': shader_hashes,
            'third_party_textures':third_party, 'notice_sha256':notices,
            'angler_provenance': angler_provenance,
            'authoring_files_sha256': {p: sha256(root/p) for p in authoring},
            'provenance_scope': 'Editable Blender masters, original generators, and asset documentation with exact file hashes'}


if __name__ == '__main__':
    import sys
    project, report_path = Path(sys.argv[1]), Path(sys.argv[2])
    report = json.loads(report_path.read_text())
    assert not report['failures'] and len(report['models']) == report['required_scene_count']
    resources = {}
    for model in report['models']:
        mapping = (project/(model+'.import')).read_text()
        target = re.search(r'^path="(res://[^"]+)"', mapping, re.M).group(1)
        path = project/target.removeprefix('res://')
        assert path.resolve().is_relative_to(project.resolve()) and path.is_file()
        resources[target.removeprefix('res://')] = sha256(path)
    report['imported_scene_sha256'] = resources
    report_path.write_text(json.dumps(report,indent=2)+'\n')
