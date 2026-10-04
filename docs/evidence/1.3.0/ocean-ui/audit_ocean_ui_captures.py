#!/usr/bin/env python3
"""Validate native ocean UI evidence; no game execution, edits or Android claim.

The four HUD foreground masks were visually reviewed at 720 px width. They bind
this fresh1500-currency fixture, its fixed font and current HUD arrangement. A
future intended layout/font change needs a new reviewed reference, not a looser
comparison. Native screenshots remain unchanged; Pillow only reads RGB pixels.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = next(parent for parent in Path(__file__).resolve().parents if (parent / "game/project.godot").is_file())
REGIONS = {
    "wallet_text": ((513, 60, 580, 99), "light", "f30a92fd796b9105a338f3757ac77928e9638239cffb9844021ccee8ad5191d7"),
    "coin_icon": ((478, 59, 514, 98), "gold", "9f5351b3fc32b67e43512e714077f72786d9972129f6704060a81299be0ca204"),
    "pause_caption": ((616, 94, 672, 126), "light", "770343c9d00fa2c1d83c439ae1dd6ebd84c9e49dbd368868c1d3fa8d7614aac5"),
    "pause_icon": ((618, 37, 669, 93), "gold", "ac1b9a50e228007fe63bfd99705e1d576db5b0673b6f2b16430756eb5da14930"),
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("evidence_root", type=Path, help="Directory containing native-720x1280 and native-720x1584")
    options = parser.parse_args()
    base = options.evidence_root.resolve()
    errors: list[str] = []
    captures: list[dict] = []
    checks = 0

    def check(ok: bool, description: str) -> None:
        nonlocal checks
        checks += 1
        if not ok:
            errors.append(description)

    for height in (1280, 1584):
        folder = base / f"native-720x{height}"
        manifest_path = folder / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        check(not manifest["failures"] and manifest["passed"] == manifest["checks"] and manifest["checks"] >= 902, f"{height}: native suite passed all assertions")
        check(manifest["physical_size"] == [720, height], f"{height}: physical size")
        check(manifest["rendering_method"] == "mobile" and manifest["rendering_driver"] == "vulkan", f"{height}: production renderer")
        check(len(manifest["captures"]) == 27, f"{height}: exact27 expected frames")
        for source, expected in manifest["source_sha256"].items():
            relative = Path(source.removeprefix("res://"))
            safe = source.startswith("res://") and not relative.is_absolute() and ".." not in relative.parts
            check(safe, f"{height}: project-relative source")
            if not safe:
                continue
            actual = ROOT / "game" / relative
            check(actual.is_file() and digest(actual.read_bytes()) == expected, f"{height}: final source unchanged {source}")
        world_count = 0
        for entry in manifest["captures"]:
            safe = Path(entry["path"]).name == entry["path"]
            check(safe, f"{height}: direct capture filename")
            if not safe:
                continue
            path = folder / entry["path"]
            check(path.is_file(), f"{height}: saved capture exists {entry['label']}")
            if not path.is_file():
                continue
            actual_hash = digest(path.read_bytes())
            check(actual_hash == entry["sha256"], f"{height}: PNG matches capture manifest {entry['label']}")
            with Image.open(path) as source:
                pixels = source.convert("RGB")
            check(pixels.size == (720, height), f"{height}: exact original PNG size {entry['label']}")
            row = {"run": folder.name, "label": entry["label"], "sha256": actual_hash, "hud_regions": {}}
            if entry["label"].startswith("fishing_"):
                world_count += 1
                check(entry["main_viewport_3d_disabled"] is False, f"{height}: actual world renderer restored {entry['label']}")
                for name, (bounds, kind, expected_hash) in REGIONS.items():
                    raw = pixels.crop(bounds).tobytes()
                    mask = bytearray()
                    for i in range(0, len(raw), 3):
                        r, g, b = raw[i:i + 3]
                        active = min(r, g, b) > 178 if kind == "light" else r > 115 and g > 56 and b < 77 and r > b * 1.6
                        mask.append(255 if active else 0)
                    mask_hash = digest(mask)
                    foreground = sum(value != 0 for value in mask)
                    check(foreground > 0 and mask_hash == expected_hash, f"{height}: reviewed {name} foreground present and intact {entry['label']}")
                    row["hud_regions"][name] = {"bounds": bounds, "mask": kind, "pixels": foreground, "sha256": mask_hash}
            captures.append(row)
        check(world_count == 10, f"{height}: four giant-bait and six ocean world frames")
    result = {"scope": "exact unchanged PNG/native-source audit; no Android or FPS claim", "checks": checks, "passed": checks - len(errors), "failures": errors, "captures": captures}
    output = base / "capture_audit.json"
    output.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({"checks": checks, "passed": result["passed"], "failures": errors, "report": str(output)}, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
