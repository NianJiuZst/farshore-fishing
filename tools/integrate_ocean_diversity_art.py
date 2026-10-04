#!/usr/bin/env python3
"""Integrate exactly37 new generated illustrations while retaining legacy74."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'art_masters/fish_photoreal_diversity'
LEGACY_COMMIT = '7b406cccaf57c9ca213693f75860443a118ed656'

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n')

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--finalize-import-audit',action='store_true',help='Sync final anatomical annotations while preserving proven Godot import hashes and exact legacy metadata')
    args = parser.parse_args()
    fragments = ['pacific_atlantic_manifest.json', 'indian_red_manifest.json', 'blue_whale_manifest.json']
    if args.finalize_import_audit:
        artist_path = BASE/'asset_manifest.json'
        artist = json.loads(artist_path.read_text())
        runtime_path = ROOT/'game/data/fish_art.json'
        runtime = json.loads(runtime_path.read_text())
        assert artist['complete'] and artist['asset_count'] == 37
        assert runtime['complete'] and runtime['asset_count'] == 111
        final_entries = {a['species_id']:a for name in fragments for a in json.loads((BASE/name).read_text())['assets']}
        assert set(final_entries) == {a['species_id'] for a in artist['assets']}
        for target in artist['assets']:
            entry = final_entries[target['species_id']]
            assert target['sha256'] == entry['sha256'] and target['thumb_sha256'] == entry['thumb_sha256']
            for key,value in entry.items():
                if key not in ['master','runtime','thumb','image_sha256','thumb_image_sha256'] and (key != 'fact_sources' or value):
                    target[key] = copy.deepcopy(value)
            actual = next(a for a in runtime['assets'] if a['species_id'] == target['species_id'])
            assert len(actual['image_sha256']) == len(actual['thumb_image_sha256']) == 64
            for key,value in target.items():
                if key not in ['master','runtime','thumb','image_sha256','thumb_image_sha256']:
                    actual[key] = copy.deepcopy(value)
        write(artist_path,artist)
        original = json.loads(subprocess.run(['git','show',LEGACY_COMMIT+':game/data/fish_art.json'],cwd=ROOT,check=True,capture_output=True,text=True).stdout)
        assert len(original['assets']) == 74
        for imported,legacy in zip(runtime['assets'][:74],original['assets']):
            assert imported['species_id'] == legacy['species_id']
            for key in ['sha256','thumb_sha256','image_sha256','thumb_image_sha256']:
                assert imported[key] == legacy[key], 'Legacy illustration/import changed'
        runtime['assets'][:74] = original['assets']
        for spec in runtime['source_manifests']:
            if spec['path'] == str(artist_path.relative_to(ROOT)):
                spec['sha256'] = sha(artist_path)
        runtime_path.write_text(json.dumps(runtime,ensure_ascii=False,indent='\t',sort_keys=True)+'\n')
        provenance_path = BASE/'art_provenance.json'
        provenance = json.loads(provenance_path.read_text())
        for fragment in provenance['source_fragments']:
            fragment['sha256'] = sha(BASE/fragment['path'])
        write(provenance_path,provenance)
        print('Final37 anatomical annotations synchronized; imported hashes preserved; legacy74 metadata exactly retained')
        return
    assets = []
    for name, expected in zip(fragments, [16,20,1]):
        data = json.loads((BASE/name).read_text())
        assert len(data['assets']) == expected
        if expected > 1:
            assert data.get('complete') is True, name
        assets.extend(copy.deepcopy(data['assets']))
    assert len({a['species_id'] for a in assets}) == len(assets) == 37
    catalogs = {f['species_id']: f for name in ['g','h','whale'] for f in json.loads((ROOT/f'game/data/fish_{name}.json').read_text())}
    assert set(catalogs) == {a['species_id'] for a in assets}
    whale_history = json.loads((ROOT/'game/data/encyclopedia_whale.json').read_text())['entries'][0]
    for entry in assets:
        sid = entry['species_id']
        species = catalogs[sid]
        assert entry['scientific_name'] == species['scientific_name'], sid
        runtime = ROOT/f'game/assets/fish/{sid}.png'
        thumb = ROOT/f'game/assets/fish/{sid}_thumb.png'
        assert sha(runtime) == entry['sha256'] and sha(thumb) == entry['thumb_sha256'], sid
        entry['original_fragment'] = next(name for name in fragments if any(v['species_id']==sid for v in json.loads((BASE/name).read_text())['assets']))
        entry['thumbnail_png_optimize'] = entry['original_fragment'] == 'pacific_atlantic_manifest.json'
        entry['master'] = f'masters/{sid}.png'
        entry['runtime'] = f'runtime/{sid}.png'
        entry['thumb'] = f'thumbs/{sid}_thumb.png'
        if sid == 'blue_whale':
            entry['fact_sources'] = [{'title': s['title'], 'url': s['url'], 'checked_on': s['accessed'], 'supports': '鲸体外形、分类和保护背景；不支持幻想挑战玩法。'} for s in whale_history['sources']]
            entry['prompt_summary'] = 'One complete adult blue whale, left-facing lateral scientific photoreal illustration on genuine transparent alpha; blue-gray mottling, U-shaped rostrum, paired blowholes, small posterior dorsal, long pectoral flippers, throat pleats and horizontal flukes; no bait, hook, text or scenery.'
        for field, src in [('master',runtime),('runtime',runtime),('thumb',thumb)]:
            dest = BASE/entry[field]
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src,dest)
    artist = {'format_version':1, 'complete':True, 'asset_count':37,
              'generated_on':'2026-10-04', 'generator':'OpenAI built-in image_gen',
              'purpose':'New naturalistic generated illustrations:36 fish and one blue-whale mammal. These are illustrations, not wildlife photographs.',
              'coordinate_system':'Canvas pixels, right/bottom exclusive alpha bounds; manually inspected anatomical nose and caudal landmarks.',
              'assets':assets}
    artist_path = BASE/'asset_manifest.json'
    write(artist_path, artist)
    provenance = {'format_version':1, 'generated_on':'2026-10-04', 'generator':'OpenAI built-in image_gen',
                  'scope':{'new_fish':36,'new_mammals':1,'reused_legacy_images':0},
                  'source_fragments':[{'path':name,'sha256':sha(BASE/name)} for name in fragments],
                  'processing':'Original PNGs retained; Pacific/Atlantic transparent canvas padding preserves all source pixels; only thumbnails use Lanczos resampling.',
                  'anatomy_review':'Each generated image inspected visually. Prompts, corrections, references and landmarks are retained in fragment/merged manifests.',
                  'disclaimer':'Photorealistic generated illustrations support game presentation; scientific facts are separately sourced in encyclopedia entries.',
                  'background':{'file':'red_sea_background.png','sha256':sha(BASE/'red_sea_background.png'),
                                'prompt_summary':'Warm Red Sea desert headlands surrounding a clear turquoise reef lagoon and small fishing jetty; premium naturalistic landscape illustration, no people or text.'}}
    write(BASE/'art_provenance.json',provenance)
    original = json.loads(subprocess.run(['git','show',LEGACY_COMMIT+':game/data/fish_art.json'],cwd=ROOT,check=True,capture_output=True,text=True).stdout)
    assert original['asset_count'] == len(original['assets']) == 74
    runtime_assets = []
    for entry in assets:
        target = copy.deepcopy(entry)
        sid = target['species_id']
        target['runtime'] = f'res://assets/fish/{sid}.png'
        target['thumb'] = f'res://assets/fish/{sid}_thumb.png'
        runtime_assets.append(target)
    original['assets'].extend(runtime_assets)
    original['asset_count'] = 111
    original['generated_on'] = '2026-10-04'
    original['integration_note'] = 'Retained74 illustration entries plus37 original diversity illustrations.110 fish and one mammal; imported RGBA8 hashes are filled by the strict Godot audit.'
    original['source_manifests'].append({'path':str(artist_path.relative_to(ROOT)),'sha256':sha(artist_path)})
    assert len(original['assets']) == len({a['species_id'] for a in original['assets']}) == 111
    write(ROOT/'game/data/fish_art.json',original)
    print(json.dumps({'new_fish':36,'new_mammals':1,'canonical_artworks':111,'artist_manifest':str(artist_path.relative_to(ROOT))}))

if __name__ == '__main__':
    main()
