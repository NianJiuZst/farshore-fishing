#!/usr/bin/env python3
"""Package a small, reproducible selection of native GPU model evidence.

The 222 original frames stay in ownbuild/. Contact sheets use their exact pixels,
resized with Pillow, and never substitute generated illustrations for 3D renders.
"""
import argparse
import datetime
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font(size):
    for path in ("/System/Library/Fonts/Menlo.ttc", "/System/Library/Fonts/Helvetica.ttc"):
        if Path(path).is_file():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def sheet(ids, views, cols, width, frames, output, title):
    # Native frame aspect ratio is 3:2. The label belongs to the sheet only.
    image_width = width // len(views)
    image_height = round(image_width * 2 / 3)
    tile_height = image_height + 42
    margin = 42
    result = Image.new("RGB", (cols * width, margin + math.ceil(len(ids) / cols) * tile_height), (9, 17, 23))
    draw = ImageDraw.Draw(result)
    draw.text((14, 12), title, fill=(216, 230, 234), font=font(18))
    for i, sid in enumerate(ids):
        x, y = i % cols * width, margin + i // cols * tile_height
        draw.text((x + 8, y + 5), sid, fill=(216, 230, 234), font=font(14))
        for j, view in enumerate(views):
            with Image.open(frames / (sid + "_" + view + ".png")) as source:
                result.paste(source.convert("RGB").resize((image_width, image_height), Image.Resampling.LANCZOS), (x + j * image_width, y + 25))
            draw.text((x + j * image_width + 7, y + 26), view, fill=(178, 202, 209), font=font(11))
    result.save(output, optimize=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames", type=Path, default=ROOT / "ownbuild/ocean-model-review/renders")
    parser.add_argument("--output", type=Path, default=ROOT / "docs/evidence/ocean-diversity/models")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    profiles = json.loads((ROOT / "tools/art3d/ocean_profiles.json").read_text())["species"]
    ids = [row["id"] for row in profiles]
    report = json.loads((args.frames / "godot_model_studio.json").read_text())
    assert len(ids) == 37 and report["model_count"] == 37 and not report["errors"]
    frame_names = [sid + "_" + view + ".png" for sid in ids for view in ("swim", "struggle", "breach", "landed", "top", "underside")]
    assert all((args.frames / name).is_file() for name in frame_names)
    sheet(ids, ["swim", "top"], 4, 480, args.frames, args.output / "all_37_side_top.png", "37 original models / native Godot 4.6.3 Mobile Vulkan / side and top")
    # Anatomy views at a larger size for the exceptional silhouettes.
    groups = [
        ("flatfish_ray", ["pacific_halibut", "turbot", "bluespotted_ribbontail_ray"]),
        ("ribbon_eel_tube", ["russells_oarfish", "giant_moray", "bluespotted_cornetfish"]),
        ("eyes_horns_wings", ["barreleye", "longhorn_cowfish", "atlantic_flyingfish"]),
        ("blue_whale", ["blue_whale"]),
    ]
    for name, group in groups:
        sheet(group, ["swim", "top", "underside"], 1, 1728, args.frames, args.output / (name + ".png"), "Imported anatomy / " + name.replace("_", " "))
    for name in ("binary_audit.json", "all_111_binary_audit.json"):
        (args.output / name).write_bytes((ROOT / "ownbuild/ocean-model-review" / name).read_bytes())
    reproducibility = ROOT / "ownbuild/ocean-model-review/reproducibility.json"
    rebuild_report = json.loads(reproducibility.read_text())
    assert rebuild_report["checked"] == 37 and not rebuild_report["failures"], "Complete source rebuild evidence required"
    (args.output / "reproducibility.json").write_bytes(reproducibility.read_bytes())
    (args.output / "native_run.json").write_bytes((args.frames / "run.json").read_bytes())
    (args.output / "native_gpu_stdout.txt").write_bytes((args.frames / "gpu.log").read_bytes())
    # Preserve the actual imported structure but use repository-relative paths.
    for sid, model in report["models"].items():
        model["frames"] = ["ownbuild/ocean-model-review/renders/" + Path(p).name for p in model["frames"]]
    (args.output / "godot_model_studio.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    evidence = {"scope": "Exact native GPU frames; only resized and labeled for contact sheets", "native_frames": [{"path": "ownbuild/ocean-model-review/renders/" + name, "sha256": sha(args.frames / name)} for name in frame_names], "contact_sheets": [{"path": p.relative_to(ROOT).as_posix(), "sha256": sha(p)} for p in sorted(args.output.glob("*.png"))]}
    (args.output / "capture_sha256.json").write_text(json.dumps(evidence, indent=2) + "\n")
    binary = json.loads((args.output / "binary_audit.json").read_text())
    assert len(binary["models"]) == 37 and not binary["errors"]
    assert binary["source_profile_file_sha256"] == sha(ROOT / binary["source_profile_file"])
    assert binary["generator_file_sha256"] == sha(ROOT / binary["generator_file"])
    tooling = ["tools/art3d/ocean_profiles.json", "tools/art3d/build_ocean_diversity.py", "tools/art3d/audit_ocean_models.py", "tools/art3d/capture_ocean_models.gd", "tools/art3d/run_ocean_model_review.py", "tools/art3d/check_ocean_reproducibility.py", "tools/art3d/package_ocean_model_evidence.py", "tools/audit_fish_catalog_3d.py"]
    entries = []
    for model in binary["models"]:
        sid = model["species_id"]
        path = "game/assets/3d/" + sid + ".glb"
        profile = next(p for p in profiles if p["id"] == sid)
        assert sha(ROOT / path) == model["glb_sha256"], "Canonical asset differs from actual binary audit"
        entries.append({**model, "path": path, "authoring_source": "tools/art3d/ocean_profiles.json", "profile_id": sid, "generator_source": "tools/art3d/build_ocean_diversity.py", "morphology_reference": profile["morphology_reference"], "sources": profile["sources"], "actual_native_review_frames": report["models"][sid]["frames"]})
    provenance = {"schema_version": 1, "reviewed_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "asset_origin": "Original Farshore procedural authorship; no third-party mesh, inherited fish geometry, old texture sampling, or fallback model", "source_master_format": "Editable per-species JSON profiles plus original Python generator; no Blender master claimed for these additions", "model_count": 37, "new_fish_count": 36, "new_mammal_count": 1, "retained_legacy_manifest_entries": 74, "full_registry_animals": 111, "full_registry_fish": 110, "normalized_coordinate_contract": {"nose": "+X", "up": "+Y", "rest_x_bounds": [-0.5, 0.5]}, "native_review": {"engine": report["engine"], "rendering_method": report["rendering_method"], "rendering_driver": report["rendering_driver"], "gpu": "Apple M5 / Vulkan 1.2.283", "imported_rigs": 37, "actual_gpu_frames": 222, "android_device_claim": False, "save_or_signing_key_access": False, "nonblocking_diagnostic": "Disposable user:// shader-cache directory unavailable; native rendering completed"}, "tooling": [{"path": p, "sha256": sha(ROOT / p)} for p in tooling], "execution_commands": ["python3 tools/art3d/audit_ocean_models.py", "python3 tools/audit_fish_catalog_3d.py --output ownbuild/ocean-model-review/all_111_binary_audit.json --require-all", "python3 tools/art3d/check_ocean_reproducibility.py --species all --output ownbuild/ocean-model-review/reproducibility.json", "python3 tools/art3d/run_ocean_model_review.py --godot ../toolchain/Godot.app/Contents/MacOS/Godot --output ownbuild/ocean-model-review/renders", "python3 tools/art3d/package_ocean_model_evidence.py"], "evidence_files": [{"path": p.relative_to(ROOT).as_posix(), "sha256": sha(p)} for p in sorted(args.output.iterdir()) if p.is_file()], "models": entries}
    (ROOT / "docs/ASSETS_3D_OCEAN_DIVERSITY_PROVENANCE.json").write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + "\n")
    print("OCEAN_EVIDENCE: 222 native frames / 5 durable contact sheets / 37 imported rigs")


if __name__ == "__main__":
    main()
