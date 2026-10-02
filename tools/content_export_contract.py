"""Read the authoritative catalog list from the frozen project's content loader."""
from pathlib import Path
import json
import re
from content_3d_contract import three_d_contract
from android_identity import project_identity
from content_fish_art_contract import photo_art_contract

def content_contract(project: Path, check_art: bool = True):
    settings = (project/'project.godot').read_text()
    version = re.search(r'^config/version="([^"]+)"', settings, re.M).group(1)
    presets = (project/'export_presets.cfg').read_text()
    codes = {int(v) for v in re.findall(r'^version/code=(\d+)', presets, re.M)}
    names = set(re.findall(r'^version/name="([^"]+)"', presets, re.M))
    assert len(codes) == 1 and names == {version}, 'Android presets must match the frozen application version'
    code = next(iter(codes))
    android_identity = project_identity(project, presets, version, code)
    loader = (project/'scripts/catalog.gd').read_text()
    files = list(dict.fromkeys(re.findall(r'"(fish_[a-z0-9_]+\.json)"', loader)))
    assert files, 'No authoritative fish catalog files found in ContentCatalog'
    entries = []
    for filename in files:
        value = json.loads((project/'data'/filename).read_text())
        assert isinstance(value, list), f'Catalog is not a JSON array: {filename}'
        entries.extend(value)
    ids = [e['species_id'] for e in entries]
    assert len(ids) == len(set(ids)) and ids, 'Empty or duplicate fish IDs'
    if check_art:
        for entry in entries:
            for field in ['art', 'thumb']:
                resource = entry[field]
                assert resource.startswith('res://assets/fish/'), f'Unexpected artwork path: {resource}'
                path = project/resource.removeprefix('res://')
                assert path.resolve().is_relative_to(project.resolve())
                assert path.is_file() and path.stat().st_size > 0, f'Missing artwork: {resource}'
    world = json.loads((project/'data/world.json').read_text())
    return {
        'application_version':version, 'android_version_code':code, 'android_identity':android_identity,
        'catalog_files': files,
        'species_ids': sorted(ids), 'species_count':len(ids),
        'region_ids': sorted(r['region_id'] for r in world['regions']),
        'region_count':len(world['regions']), 'spot_count':len(world['spots']),
        'gear_count':len(world['gear']), 'bait_count':len(world['baits']),
        'ui_icon_files':sorted(str(p.relative_to(project)) for p in (project/'assets/ui/icons').glob('*.png')),
        'photo_art':photo_art_contract(project, entries),
        'three_d':three_d_contract(project, ids),
    }
