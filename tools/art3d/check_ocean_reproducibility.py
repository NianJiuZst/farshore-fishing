#!/usr/bin/env python3
"""Rebuild selected/all new GLBs in /tmp and compare canonical file hashes.

This never replaces a game asset or edits the model manifest.
"""
import argparse
import hashlib
import json
import tempfile
from pathlib import Path

from build_ocean_diversity import Animal, GLB, PROFILE_FILE, ROOT


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--species", default="all")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    profiles = json.loads(PROFILE_FILE.read_text())["species"]
    wanted = {p["id"] for p in profiles} if args.species == "all" else set(args.species.split(","))
    assert wanted <= {p["id"] for p in profiles}, "Unknown species; no fallback exists"
    results = []
    with tempfile.TemporaryDirectory(prefix="farshore-model-rebuild-", dir="/tmp") as directory:
        for profile in profiles:
            if profile["id"] not in wanted:
                continue
            sid = profile["id"]
            candidate = Path(directory) / (sid + ".glb")
            raw = GLB().model(Animal(profile).build()).save(candidate)
            actual = ROOT / "game/assets/3d" / candidate.name
            source_sha = hashlib.sha256(raw).hexdigest()
            actual_sha = hashlib.sha256(actual.read_bytes()).hexdigest()
            results.append({"species_id": sid, "rebuilt_sha256": source_sha, "canonical_sha256": actual_sha, "identical": source_sha == actual_sha})
            print("REPRODUCIBLE_MODEL", sid, "identical=" + str(source_sha == actual_sha), flush=True)
    report = {"scope": "Canonical-byte reproducibility from current editable profiles and generator in disposable /tmp", "models": results, "checked": len(results), "failures": [r["species_id"] for r in results if not r["identical"]]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    raise SystemExit(1 if report["failures"] else 0)


if __name__ == "__main__":
    main()
