#!/usr/bin/env python3
"""Preserve built-in generated art bytes and derive thumbnails/metadata only."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art_masters/fish_photoreal_diversity"
RECORDS = OUT / "indian_red_source_records.json"

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def alpha_bounds(image: Image.Image) -> list[int]:
    return list(image.getchannel("A").point(lambda v: 255 if v >= 24 else 0).getbbox())

def main() -> None:
    records = json.loads(RECORDS.read_text())
    ids = [record["species_id"] for record in records]
    assert len(ids) == len(set(ids)), "duplicate species"
    assets = []
    for record in records:
        sid = record["species_id"]
        source = Path(record["source_path"])
        master = OUT / f"{sid}.png"
        runtime = ROOT / f"game/assets/fish/{sid}.png"
        thumb_path = ROOT / f"game/assets/fish/{sid}_thumb.png"
        for dest in (master, runtime):
            if dest.exists():
                assert digest(source) == digest(dest), f"unexpected existing asset: {dest}"
            else:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, dest)
        image = Image.open(runtime).convert("RGBA")
        assert image.getchannel("A").getextrema()[0] == 0, f"no transparency: {sid}"
        bbox = alpha_bounds(image)
        width, height = image.size
        assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < width and bbox[3] < height, f"clipped canvas: {sid}"
        thumb = image.copy()
        thumb.thumbnail((512, 512), Image.Resampling.LANCZOS)
        thumb.save(thumb_path)
        nose = record["nose_px"]
        tail = record["tail_px"]
        for point in (nose, tail):
            assert bbox[0] <= point[0] < bbox[2] and bbox[1] <= point[1] < bbox[3], f"ruler endpoint outside: {sid}: {point} {bbox}"
            assert image.getchannel("A").getpixel(tuple(point)) >= 24, f"ruler endpoint off silhouette: {sid}: {point}"
        assets.append({
            **{k: v for k, v in record.items() if k not in ("details", "source_path", "nose_px", "tail_px")},
            "generator": "OpenAI built-in image_gen",
            "generated_source_file": source.name,
            "master": str(master.relative_to(ROOT)),
            "runtime": f"res://assets/fish/{sid}.png",
            "thumb": f"res://assets/fish/{sid}_thumb.png",
            "width": width, "height": height,
            "thumb_width": thumb.width, "thumb_height": thumb.height,
            "subject_bbox_px": bbox,
            "subject_bbox_normalized": [bbox[0]/width,bbox[1]/height,bbox[2]/width,bbox[3]/height],
            "thumb_subject_bbox_px": alpha_bounds(thumb),
            "nose_normalized": [nose[0]/width,nose[1]/height],
            "tail_normalized": [tail[0]/width,tail[1]/height],
            "ruler_extent_normalized": [nose[0]/width,tail[0]/width],
            "alpha_threshold_for_bbox": 24,
            "sha256": digest(runtime), "thumb_sha256": digest(thumb_path),
            "source_rgba8_sha256": hashlib.sha256(image.tobytes()).hexdigest(),
            "source_thumb_rgba8_sha256": hashlib.sha256(thumb.tobytes()).hexdigest(),
            "transparent_fraction": image.getchannel("A").histogram()[0] / (width*height),
            "reviewed_full_body": True,
            "ruler_endpoints_on_alpha24_silhouette": True,
            "decoded_hash_note": "Import with Godot lossless texture settings then populate image_sha256/thumb_image_sha256 from Godot RGBA8; transparent RGB repair may differ from source pixels.",
        })
    result = {
        "format_version": 1,
        "asset_count": len(assets),
        "complete": len(assets) == 20,
        "generated_on": "2026-10-04",
        "generator": "OpenAI built-in image_gen",
        "purpose": "Photorealistic illustrative encyclopedia and catch-card art, not wild photographs or diagnostic scientific plates.",
        "variant_note": "Original generated PNG bytes copied unchanged to master and runtime; Pillow only makes 512px Lanczos thumbnails and measures alpha/hash metadata.",
        "coordinate_system": "Full original canvas; bbox right and bottom exclusive; nose and tail points manually inspected. Ray intentionally dorsal view with nose left/tail right.",
        "assets": assets,
    }
    target = OUT / "indian_red_manifest.json"
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n")
    print(json.dumps({"manifest": str(target), "assets": len(assets), "complete": result["complete"]}))

if __name__ == "__main__":
    main()
