#!/usr/bin/env python3
"""Rebuild canonical derivatives from retained masters; no raster invention."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    manifest = json.loads((BASE/'asset_manifest.json').read_text())
    assert manifest['complete'] and manifest['asset_count'] == len(manifest['assets']) == 37
    for entry in manifest['assets']:
        master = BASE/entry['master']
        assert digest(master) == entry['sha256']
        image = Image.open(master).convert('RGBA')
        assert image.size == (entry['width'],entry['height'])
        thumb = image.copy()
        thumb.thumbnail((512,512),Image.Resampling.LANCZOS)
        assert thumb.size == (entry['thumb_width'],entry['thumb_height'])
        dest = BASE/entry['thumb']
        thumb.save(dest,optimize=bool(entry.get('thumbnail_png_optimize',False)))
        assert digest(dest) == entry['thumb_sha256'], 'Thumbnail derivation differs: '+entry['species_id']
        shutil.copy2(master,BASE/entry['runtime'])
        shutil.copy2(master,ROOT/f"game/assets/fish/{entry['species_id']}.png")
        shutil.copy2(dest,ROOT/f"game/assets/fish/{entry['species_id']}_thumb.png")
    print('37 master/runtime/thumbnail variants regenerated and hash-verified')
if __name__ == '__main__':
    main()
