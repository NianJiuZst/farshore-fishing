# Ocean diversity: 36 new fish and a dedicated blue whale

Reviewed 2026-10-04 against the canonical GLBs with Godot 4.6.3, Mobile renderer and native Vulkan on Apple M5. These are original volumetric model assets and skeletal animations. The 37 additions bring the registry to 111 animals: 110 fish and one mammal. The original 74 manifest entries are retained exactly.

## Editable authorship

`tools/art3d/ocean_profiles.json` contains an explicitly authored profile for every new species: body cross sections, dorsal and ventral contours, eye and mouth placement, fins, pigments, distinctive anatomical features, motion style and scientific reference records. The original generator is `tools/art3d/build_ocean_diversity.py`. It reads no pre-existing fish model, image, texture or rig. No model is a rescaled or recolored old asset, and unknown profiles/pigment styles have no fallback.

The pipeline uses the Python standard library and Pillow. It constructs closed body volume from interpolated cross sections, cambered fin membranes with raised rays, thick rayless whale hydrofoils, sockets and individual anatomical details. Species pigments and microstructure are analytically authored. Each GLB embeds six original PBR maps: separate body/fin base color, normal and metallic/roughness triplets. This is procedural model art, not a photographic scan or third-party mesh conversion. Editable JSON profiles are the source masters for this batch; no Blender file is represented as having been created.

The 37 canonical GLBs total 96,573,432 bytes, 590,274 vertices and 1,009,930 triangles. Each contains 13–19 bones and 6–9 skinned material surfaces. The independent audit checks the actual binary arrays and records 37 distinct geometry fingerprints. Per-model file, geometry, source-profile and tooling hashes are bound in `ASSETS_3D_OCEAN_DIVERSITY_PROVENANCE.json`.

## Distinctive anatomical treatment

| Models | Authored treatment |
| --- | --- |
| Pacific halibut / turbot | Independent diamond / rounded thin body volumes; both eyes on the upper ocular surface; right / left eyed-side metadata; pale eyeless underside; horizontal tail and long marginal fins; turbot dermal tubercles. |
| Barreleye | A transparent volumetric cranial shield around two actual green upward tubular eyes; separate dark olfactory capsules on the front of the face. |
| Bluespotted ribbontail ray | Broad thin disk, upper eyes and spiracles, five paired ventral gill slits and ventral mouth, ribbon tail and actual sting geometry; no ordinary fish fan tail. |
| Giant moray | Long body and continuous dorsal/anal margins, lateral undulation, small gill openings, tubular nostrils and teeth; no pectoral fins. |
| Longhorn cowfish | Squared armored cross section, two frontal horns and two posterior armor spines, short posterior fins and exposed tail peduncle. |
| Russell's oarfish | Silver ribbon, full-length red dorsal, elongated red crown rays, streaming pelvic rays and small pectorals; no anal or caudal fin. |
| Bluespotted cornetfish | Long tubular snout and fine caudal thread; total length normalization includes the thread. |
| Atlantic flyingfish | Independently posed broad wing-like pectoral fins and a longer lower caudal lobe. |
| Stoplight parrotfish | Original terminal-phase pigment pattern and separate upper/lower fused ivory beak geometry. |
| Red Sea goatfish / grey gurnard | Paired sensory chin barbels / three free walking pectoral rays on each side. |
| Leaf scorpionfish / crocodile flathead | Tall leaf-like dorsal and dermal appendages / broad flattened bony head with high-set eyes and cranial ridges. |
| Angelfishes / bannerfish / batfish | Independently authored compressed body profiles, fins, masks and species pigment layouts; bannerfish elongated dorsal banner and batfish tall rounded outline. |
| Blue whale | Dedicated long blue-gray body, broad blunt head, small posterior dorsal, long solid chest flippers, thick horizontal twin flukes, paired blowholes, jaw lines and 31 ventral throat pleats. No fish gill or fin-ray geometry. Tail/spine pitch vertically; chest flippers and flukes have independent controls. |

The remaining reef, demersal and pelagic profiles retain their own authored shapes, pigment patterns and features rather than sharing a final mesh. All 37 are visible in the [native side/top contact sheet](evidence/ocean-diversity/models/all_37_side_top.png). Larger diagnostic sheets cover [flatfish and ray](evidence/ocean-diversity/models/flatfish_ray.png), [ribbon/eel/tube forms](evidence/ocean-diversity/models/ribbon_eel_tube.png), [eyes/horns/wings](evidence/ocean-diversity/models/eyes_horns_wings.png) and [the whale](evidence/ocean-diversity/models/blue_whale.png).

References are recorded per species in the editable profile and catalog. Particularly consequential morphology follows [MBARI's barreleye research](https://www.mbari.org/news/researchers-solve-mystery-of-deep-sea-fish-with-tubular-eyes-and-transparent-head/), [NOAA Pacific halibut](https://www.fisheries.noaa.gov/species/pacific-halibut), [MarLIN turbot](https://www.marlin.ac.uk/species/detail/1917), [Florida Museum bluespotted ribbontail ray](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/bluespotted-ribbontail-ray/), [Fishes of Australia longhorn cowfish](https://fishesofaustralia.net.au/home/species/837), [STRI oarfish morphology](https://biogeodb.stri.si.edu/sftep/en/thefishes/species/5806), and [NOAA blue whale](https://www.fisheries.noaa.gov/species/blue-whale). The black scabbardfish has a small forked caudal fin, consistent with its `Aphanopus carbo` profile, rather than the tail-less outline of a different hairtail species.

## Runtime and animation contract

Nose is +X and up is +Y. The rest X bounds are exactly −0.5 to +0.5 m, including appendages, and the rig and inverse bindings are normalized with the geometry. Runtime world scale remains controlled by `rest_length_m = 1.0`. `mouth_offset_normalized` comes from each authored profile. Runtime trajectories are not baked into root translation.

All 37 have real `swim`, `struggle`, `breach` and `landed` animation clips. New fish durations are 1.8 / 1.2 / 1.6 / 3.0 seconds; whale swim is 2.4 seconds. The old 74 clips keep their original duration contract. Each new clip has 49 sampled rotations per joint, meaningful motion on at least eight controls and continuous loop endpoints. Flatfish and whale axial motion uses vertical pitch; the ordinary fish/eel chain uses lateral yaw. Reef/box/ray amplitudes are reduced and fin controls move independently. The dedicated whale game stage uses aquatic swim; its `landed` compatibility clip is a surface glide and does not depict a beached catch.

## Validation and retained evidence

`tools/art3d/audit_ocean_models.py` reads the canonical GLB buffers and verifies header lengths, finite geometry, indices, unit normals, all skin weights, inverse bindings, centered length, PBR PNG payloads, named animations, actual animated tracks and required anatomy. All 37 pass. `tools/audit_fish_catalog_3d.py --require-all` verifies all 111 assets with the preserved legacy duration expectations; it reports zero missing models and zero failures.

The native studio imports checksum-identical asset copies in a disposable `/tmp` project. It never loads game classes or player saves. Its actual imported skeletons, skins, material surfaces and four animations pass for 37/37 models. The 222 actual GPU frames consist of four animation poses, a top view and an underside for every model. These local review intermediates remain in ignored `ownbuild/ocean-model-review/renders/`; only five overview PNGs, their exact pixel hashes and compact binary/import reports are retained under `docs/evidence/ocean-diversity/models/`. The temporary native process emits a shader-cache-directory diagnostic because it has no player user directory; rendering and capture complete successfully. This evidence confirms native Mobile/Vulkan model rendering on the development Mac and does not claim Android device performance or APK release validation.

Reproducible commands from the repository root:

```sh
# Regeneration edits the canonical new assets; use when authoring, before freeze.
python3 tools/art3d/build_ocean_diversity.py --species all --update-manifest
python3 tools/art3d/audit_ocean_models.py
python3 tools/audit_fish_catalog_3d.py --output ownbuild/ocean-model-review/all_111_binary_audit.json --require-all

# This check regenerates in /tmp and never replaces canonical assets.
python3 tools/art3d/check_ocean_reproducibility.py --species all --output ownbuild/ocean-model-review/reproducibility.json

# Supply the already installed Godot 4.6.3 executable.
python3 tools/art3d/run_ocean_model_review.py --godot /path/to/Godot --output ownbuild/ocean-model-review/renders
python3 tools/art3d/package_ocean_model_evidence.py
```
