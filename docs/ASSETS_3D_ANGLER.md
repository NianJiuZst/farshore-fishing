# Realistic 3D angler: formal 1.2.0

## Deliverables and reproduction

- Runtime: `game/assets/3d/angler.glb`
- Editable, fully packed final model: `art_masters/3d/angler.blend`
- Fully packed human/clothing source and shape controls: `art_masters/3d/angler_human_source.blend`
- Runtime fitting/export: `tools/art3d/build_angler.py`
- Original Farshore rig and fishing performances: `tools/art3d/angler_motion.py`
- Optional upstream source rebuild: `tools/art3d/prepare_angler_human_source.py`
- Source/output license separation and reviewed alternatives: `ASSETS_3D_ANGLER_LICENSES.md`
- Exact selected-source and output hashes: `ASSETS_3D_ANGLER_PROVENANCE.json`
- Durable imported-GLB test: `game/tests/angler_anatomy_tests.gd`

Build with official Blender 4.3.2:

    blender --background --python tools/art3d/build_angler.py

`ANGLER_CANDIDATE=1` and an absolute `ANGLER_REVIEW_DIR` produce isolated `.blend`, `.glb`, statistics, and actual front/side/cast/release/reel/lift/grip-close renders without replacing the runtime model. `ANGLER_SAMPLES` controls review-render samples only. `ANGLER_SKIP_RENDERS=1` skips rendering when reproducing already-reviewed geometry and animation. The regular build needs neither MPFB installed nor a network connection.

## Visual changes

The old primitive-based face, disconnected-looking hands, mannequin clothing and oversized cap have been replaced by a continuous anatomically modeled adult human from the official CC0 MakeHuman assets. Natural head, eye, ear, nose, lip, neck, palm and finger topology, a fitted field jacket, a shirt, jeans and outdoor shoes provide the main improvement. The character has normal short hair and no cap.

The source male is configured with adult age, moderate muscle/weight and ordinary proportions. Its original skin and clothing maps are preserved at full resolution, including the 4096 px garment normal map. The runtime remains a single skinned mesh with six material surfaces.

The cast wind-up was moved forward and toward the center so the lower hand grips the rod butt ahead of the jacket. Both hands remain on the same rigid handle. Sleeve cuffs are shortened and follow the forearms rather than the finger bones; wrist skin remains underneath them. The body mask remains active under jeans to prevent skin showing through the knees.

The face and hands are genuine 3D meshes. Eyebrows and hair use their authored textured mesh surfaces. No image-plane limbs or character sprite replaces the model. Studio cameras, lights, floor and review rod are excluded from the GLB; actual equipment remains stage-owned.

## Runtime interface

- Meters; measured total height 1.74943 m, feet grounded at Godot Y=0
- Godot up +Y and front −Z
- One `AnglerRig/Skeleton3D` with the existing 30 deformation bone names
- One batched `Angler_Skinned_Mesh`, one skin and one AnimationPlayer
- A real bone-attached `RodSocket`, resolved recursively by name
- Socket local −Z points toward the rod tip; right grip at the origin
- Left lower grip is socket local +Z at 0.18 m during cast
- Keep the stage rod's identity attachment transform
- Equal upper arms of 30.5 cm and forearms of 27.0 cm

| Clip | Duration | Use |
| --- | ---: | --- |
| `idle` | 3.20 s | Breathing and ready stance |
| `cast` | 2.20 s | Wind-up, acceleration, release and recovery |
| `wait` | 4.00 s | Waiting with the rod |
| `reel` | 2.00 s | Right grip and left-hand crank motion |
| `lift` | 2.00 s | Raised rod and recovery |

Clips are baked at 30 fps. Cast timing is unchanged: wind-up peak 0.78 s, acceleration 1.00 s, release 1.20 s, follow-through 1.42 s and recovery 2.20 s. The reel clip frees the left hand for the existing 0.046 m crank circle at 1.5 revolutions/second.

## Measured release asset

- 57,380 triangles; 40,216 exported weighted vertices
- One mesh, six materials, one skin, 30 bones and five clips
- Seven embedded GLB image textures, with no external dependencies in the GLB itself
- Godot’s existing import setting extracts matching `game/assets/3d/angler_*.png` files; those images and their import settings are tracked and hashed in the provenance inventory
- 24,469,596 GLB bytes (23.34 MiB); exact SHA-256 in the provenance JSON
- Runtime GLB size increase over the preceding model: 22,999,644 bytes (about 21.93 MiB)
- 4096² garment normal; 2048² skin, garment color and hair color; 1024² eye and shoe color; 512² eyebrow texture

The full-quality source is retained for the user's high-end Android target. No texture or geometry reduction was applied merely for older-device compatibility.

## Verification and limits

    XDG_DATA_HOME=/tmp/angler-tests-data XDG_CACHE_HOME=/tmp/angler-tests-cache godot --headless --path game --script res://tests/angler_anatomy_tests.gd

Append `-- --model=/absolute/path/angler.glb` to inspect an isolated candidate.

The promoted release asset passed all 6,353 imported-GLB checks in official Godot 4.6.3, including all 67 cast frames, every clip duration, normalized skinning, actual vertex deformation, grounded feet and both hand/rod contacts:

- Maximum arm-segment error: 0.0000001121 m
- Maximum two-hand alignment error: 0.0000005940 m
- Foot translation during the cast: 0 m
- Maximum sampled cast vertex displacement: 0.46448 m
- Imported normalized-weight quantization error: 0.00004581

Actual reviewed studio images and logs are preserved under `docs/evidence/1.2.0/angler/` (working originals: `build/angler-realistic/final2/`). The subsequent promotion uses the same geometry hash and clip contract. Studio images demonstrate the model itself; native game and Android captures remain distinct integration evidence.

This is a game character with natural anatomy and textured clothing, not a scan-quality or film face. Very close hand views can show minor retargeting faceting, and an extreme cast close-up shows a small dark armpit fold/seam. The cuff/finger intersections and knee skin breakthrough found in interim candidates were corrected. There is no facial performance or independent finger animation in this fixed angler.
