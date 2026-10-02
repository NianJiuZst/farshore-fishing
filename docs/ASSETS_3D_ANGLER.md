# Original 3D angler: anatomical revision

## Deliverables and reproduction

- Runtime: `game/assets/3d/angler.glb`
- Editable source: `art_masters/3d/angler.blend`
- Generator: `tools/art3d/build_angler.py`
- Durable Godot tests: `game/tests/angler_anatomy_tests.gd`
- Revised model renders and logs: `build/angler-review/teal-final/`
- Front/side/cast contact sheet: `build/angler-review/teal-final/character-contact-sheet.png`

Rebuild using official Blender 4.3.2:

    blender --background --python tools/art3d/build_angler.py

For an isolated candidate, set `ANGLER_CANDIDATE=1` and `ANGLER_REVIEW_DIR` to an absolute writable review directory. This produces the candidate `.blend`, `.glb`, actual rendered front/side A-poses and fishing keyframes without replacing the runtime asset. `ANGLER_SAMPLES` controls the studio-render sample count only.

All runtime body parts are genuine 3D mesh volumes, with bone weights and baked skeletal clips. There are no image-plane limbs, billboards, sprites or external character assets. Studio lights, cameras, ground, A-pose reviews and the contact-review rod are excluded from the GLB.

## What changed after the anatomy review

The review prioritized normal human limb proportions and normal clothing fit, not additional wrinkles or surface decorations.

| Measure | Previous model | Revised model |
| --- | ---: | ---: |
| Upper-arm length, each side | 28.73 cm | 30.50 cm |
| Right forearm | 34.30 cm | 27.00 cm |
| Left forearm | 44.84 cm | 27.00 cm |
| Shoulder-joint spacing | 47.0 cm | 39.0 cm |
| Forearm / upper-arm ratio | 1.19 right, 1.56 left | 0.885 both sides |
| Runtime triangles | 67,298 | 43,912 |

- The former asymmetric, overlong forearms were rebuilt with equal bilateral segment lengths. Arm placement and animation are solved from those lengths.
- The torso, shoulder saddle, armpits, deltoid area, elbows and forearms now belong to one connected, branching quad garment surface. There are no separate capped sleeve cylinders or overlapping shoulder balls.
- The entire connected jacket and sleeves use one consistent teal textile material, with restrained dark cuffs and a zipper. Shared shoulder vertices eliminate floating armhole plates; uniform fabric avoids irregular two-tone color islands during windup.
- The pelvis and trouser legs use one shared crotch saddle and connected quad topology. The old box-like seat/leg assembly and voxel-union construction were removed.
- Thigh, knee, calf and hem profiles are continuous. Separate oval knee pads and superficial crease/seam rods were removed.
- Boots have narrower, normal-width soles and shafts; trouser hems overlap the boot shafts naturally. Hands, faces, cap and individual fingers remain dimensional.
- Raised pockets, flaps and unnecessary decorative pieces were removed after cast-pose inspection showed residual arm intersections. The resulting simple zip jacket keeps a clean, normal clothing silhouette.

Unobscured front and side A-pose renders were inspected before reviewing the casting poses. Those are model-review poses, not extra runtime animation clips.

## Coordinate and rod contract

- Meters; grounded total height approximately 1.75 m (measured 1.7518 m including cap)
- Feet at Godot Y=0; up +Y; front −Z
- Skeleton: `AnglerRig/Skeleton3D`; 30 deformation bones
- Skeleton names retain dots: `hand.R`, `hand.L`, `upper_arm.R`, etc.
- Imported attachment node: `AnglerRig/Skeleton3D/hand_R/RodSocket`
- Resolve `RodSocket` recursively by name so root renaming is safe
- The socket is under a genuine `BoneAttachment3D` and follows the right-hand grip
- Socket local −Z points toward the rod tip; right grip at its origin
- Left lower grip stays on socket local +Z at 0.18 m
- A compatible handle extends about 0.22–0.25 m behind the forward grip
- Attach the stage rod with an identity transform; do not add an axis correction

The reel clip frees the left hand for a crank circle: radius 0.046 m, 1.5 revolutions/second, centered approximately 0.08 m to character left and 0.085 m behind the right grip. Runtime equipment and fishing line remain stage-owned.

## Baked animation clips

All clips are authored at 30 fps and baked onto the deformation skeleton. Existing names, durations, hand trajectories and attachment conventions are preserved.

| Clip | Duration | Use |
| --- | ---: | --- |
| `idle` | 3.20 s | Breathing and small upper-body weight movement |
| `cast` | 2.20 s | Backswing, acceleration, forward release and recovery |
| `wait` | 4.00 s | Relaxed hold |
| `reel` | 2.00 s | Left-hand crank, right-hand hold and body effort |
| `lift` | 2.00 s | Rod high, backward lean, recovery |

Cast cues remain: backswing peak 0.78 s; acceleration 1.00 s; release 1.20 s; follow-through peak 1.42 s; recovery complete 2.20 s. Stage code should loop idle/wait/reel and leave cast/lift non-looping.

## Verification and measured runtime data

Run with isolated user data:

    XDG_DATA_HOME=/tmp/angler-tests-data XDG_CACHE_HOME=/tmp/angler-tests-cache godot --headless --path game --script res://tests/angler_anatomy_tests.gd

For candidates, append `-- --model=/absolute/path/angler.glb`.

The revised GLB passed 3,705/3,705 checks in official Godot 4.6.3. These checks import the actual GLB using `GLTFDocument`, verify one real skinned mesh and skeleton, check all five exact clip lengths, evaluate both arms and hand contacts on every one of the 67 cast frames, and calculate actual skinned vertex positions.

- Runtime: 1,469,952 bytes (about 1.40 MiB)
- Geometry: 43,912 triangles; 22,937 weighted export vertices
- Batching: one mesh; 16 material surfaces; one skin; 30 bones
- Maximum arm-segment length error over the full cast: 0.000000112 m
- Maximum both-hand grip alignment error: 0.000000571 m
- Foot motion during cast: 0 m
- Maximum sampled vertex deformation between ready and backswing: 0.63968 m
- Original GLB skin-weight sum error: at most 5.96 × 10⁻⁸; all weights finite and nonnegative
- Godot's normalized 16-bit imported weights show at most 0.00003052 quantization error; tests account for that representation
- GLB SHA-256: `93444c28ff3b0650661bb571de752fe323e64f717b0d9f2ef692ba5913bc06ec`

`BoneAttachment3D` needs normal process-frame updates after an animation seek. Immediate queries before processing can return the preceding socket transform.

The images in the review directory are actual Blender path-traced model renders. They verify model form and posed hand/handle contact. Headless Godot tests verify imported geometry, skinning and contracts; integrated game-render and Android checks are separate stages and must not be inferred from the studio renders.

## Provenance

All character geometry, clothing topology, materials and performances were authored specifically for this project in the generator. Materials are embedded PBR base-color/roughness/metalness materials. No paid model, downloaded base mesh, unrecognized add-on, account, texture download or third-party art license is required. Project use, modification, bundling and distribution have no third-party asset-license dependency; this does not claim exclusive rights over generic designs.

Blender may log that its optional Draco library is absent. Compression is not enabled or required; the uncompressed GLB exports and imports successfully.
