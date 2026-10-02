"""Inspect the complete runtime 3D registry, worlds, rigs and authoring sources."""
from pathlib import Path
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


def three_d_contract(project, catalog_ids):
    registry_path = project/'data/fish_3d.json'
    if not registry_path.exists():
        return None
    registry = json.loads(registry_path.read_text())
    assert registry['schema_version'] == 1
    playable = sorted(registry['models'])
    assert set(playable) == set(catalog_ids) and len(playable) == 44, 'Every one of the 44 catalog species needs its own runtime model'
    fish_clips = registry['required_animation_clips']
    assert set(fish_clips) == {'swim','struggle','breach','landed'}
    for species, entry in registry['models'].items():
        assert entry['scene'] == f'res://assets/3d/{species}.glb', f'Non-species-specific model: {species}'
        assert entry['rest_length_m'] == 1.0
    world = json.loads((project/'data/world.json').read_text())
    region_ids = sorted(r['region_id'] for r in world['regions'])
    assert len(region_ids) == 6 and len(world['spots']) == 12
    assert all(spot['region_id'] in region_ids for spot in world['spots'])
    station_kinds = sorted({'boat' if spot['foreground'] == 'boat' else ('rock' if spot['foreground'] == 'rocks' else 'dock') for spot in world['spots']})
    assert station_kinds == ['boat','dock','rock']
    settings = (project/'project.godot').read_text()
    assert 'renderer/rendering_method="mobile"' in settings
    assert 'renderer/rendering_method.mobile="mobile"' in settings
    assert 'rendering_device/driver.android="vulkan"' in settings, 'Vulkan must be explicit for this trial'
    assert 'rendering_device/fallback_to_opengl3=false' in settings, 'Silent OpenGL fallback is not allowed for this trial'
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
    third_party = []
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
                assert stream.read(7) == b'BLENDER', f'Invalid Blender master: {name}'
    return {'playable_species': playable, 'playable_species_count': len(playable),
            'playable_regions':len(region_ids), 'playable_locations':len(world['spots']),
            'all_catalog_species_have_3d_models':True,
            'registry_sha256':sha256(registry_path), 'region_scene_files':regions, 'station_scene_files':stations,
            'required_scene_count':len(models), 'rigged_model_count':1+len(playable),
            'configured_rendering_method': 'mobile',
            'configured_android_driver': 'vulkan',
            'opengl_fallback_disabled': 'rendering_device/fallback_to_opengl3=false' in settings,
            'glb_models': glbs, 'texture_files': textures, 'shader_sha256': shader_hashes,
            'third_party_textures':third_party, 'notice_sha256':notices,
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
