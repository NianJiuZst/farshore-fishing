"""Inspect original GLBs and the explicitly bounded two-species trial."""
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
            'skins': len(skins), 'bones': sum(len(s['joints']) for s in skins),
            'weighted_primitives': weighted, 'required_clips': clips,
            'animations': sorted(animations), 'embedded_images': len(doc.get('images', []))}


def three_d_contract(project):
    adapter = project/'scripts/trial_fishery.gd'
    if not adapter.exists():
        return None
    declaration = re.search(r'const PLAYABLE_SPECIES[^=]*=\s*\[([^]]+)\]', adapter.read_text())
    assert declaration, 'Missing authoritative trial species declaration'
    playable = re.findall(r'"([a-z0-9_]+)"', declaration.group(1))
    assert set(playable) == {'common_carp', 'alligator_gar'} and len(playable) == 2
    settings = (project/'project.godot').read_text()
    assert 'renderer/rendering_method="mobile"' in settings
    assert 'renderer/rendering_method.mobile="mobile"' in settings
    assert 'rendering_device/driver.android="vulkan"' in settings, 'Vulkan must be explicit for this trial'
    assert 'rendering_device/fallback_to_opengl3=false' in settings, 'Silent OpenGL fallback is not allowed for this trial'
    models = {'assets/3d/angler.glb': ['idle','cast','wait','reel','lift'],
              **{f'assets/3d/{species}.glb': ['swim','struggle','breach','landed'] for species in playable},
              'assets/3d/environment/managed_oxbow.glb': []}
    glbs = {name: glb_contract(project/name, clips) for name, clips in models.items()}
    textures = sorted(str(p.relative_to(project)) for p in (project/'assets/3d').rglob('*.png'))
    assert len(textures) >= 12, 'Expected fish base-color, normal and roughness texture imports'
    shaders = sorted(str(p.relative_to(project)) for p in (project/'assets/shaders3d').glob('*.gdshader'))
    assert len(shaders) >= 5, 'Missing water/foliage/ripple/wood/riverbank shaders'
    shader_hashes = {p: sha256(project/p) for p in shaders}
    root = project.parent
    authoring = [f'art_masters/3d/{name}.blend' for name in ['angler', *playable]]
    authoring += ['tools/art3d/build_angler.py','tools/art3d/build_fish.py','tools/art3d/build_environment.py',
                  'docs/ASSETS_3D_ANGLER.md','docs/ASSETS_3D_FISH.md']
    for name in authoring:
        path = root/name
        assert path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(root.resolve()), f'Missing original authoring source: {name}'
        if path.suffix == '.blend':
            with path.open('rb') as stream:
                assert stream.read(7) == b'BLENDER', f'Invalid Blender master: {name}'
    return {'playable_species': playable, 'playable_species_count': 2, 'playable_locations': 1,
            'legacy_catalog_is_not_all_3d': True,
            'configured_rendering_method': 'mobile',
            'configured_android_driver': 'vulkan',
            'opengl_fallback_disabled': 'rendering_device/fallback_to_opengl3=false' in settings,
            'glb_models': glbs, 'texture_files': textures, 'shader_sha256': shader_hashes,
            'authoring_files_sha256': {p: sha256(root/p) for p in authoring},
            'provenance_scope': 'Editable Blender masters, original generators, and asset documentation with exact file hashes'}


if __name__ == '__main__':
    import sys
    project, report_path = Path(sys.argv[1]), Path(sys.argv[2])
    report = json.loads(report_path.read_text())
    assert not report['failures'] and len(report['models']) == 4
    resources = {}
    for model in report['models']:
        mapping = (project/(model+'.import')).read_text()
        target = re.search(r'^path="(res://[^"]+)"', mapping, re.M).group(1)
        path = project/target.removeprefix('res://')
        assert path.resolve().is_relative_to(project.resolve()) and path.is_file()
        resources[target.removeprefix('res://')] = sha256(path)
    report['imported_scene_sha256'] = resources
    report_path.write_text(json.dumps(report,indent=2)+'\n')
