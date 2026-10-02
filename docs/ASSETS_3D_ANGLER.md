# Original 3D angler asset

## Files and reproduction

- Runtime: `game/assets/3d/angler.glb`
- Editable source: `art_masters/3d/angler.blend`
- Reproducible authoring: `tools/art3d/build_angler.py`
- Render and verification evidence: `build/angler-review/`

Rebuild with the installed official Blender 4.3.2:

    /usr/bin/blender --background --python tools/art3d/build_angler.py

The source preserves individually editable tailored clothing, cap, face, hands, boot details, a named armature, and animation actions. The runtime export batches those objects into one skinned mesh with shared material surfaces. The review-only studio lights, ground, camera, and hand-contact test rod are excluded from the GLB. No runtime PNG billboard, sprite, normal-map impostor, or external model is used.

## Coordinate and attachment contract

- Meter scale; approximately 1.75 m including cap
- Feet aligned to Godot's Y=0 ground plane
- Front faces Godot −Z; +Y is up; +X is the character's right-hand side
- Runtime skeleton: `AnglerRig/Skeleton3D`, with 30 deformation bones
- Skeleton bone names retain dots (`hand.R`, `hand.L`); the imported attachment node is sanitized to `hand_R`
- Socket: `AnglerRig/Skeleton3D/hand_R/RodSocket`
- Resolve `RodSocket` recursively by name so root renaming is safe
- `RodSocket` is under an imported `BoneAttachment3D`; it follows the right-hand grip position and rotation
- Rod-tip direction is socket local −Z
- Right grip is socket origin; left lower grip is 0.18 m toward socket +Z
- A compatible handle extends about 0.22–0.25 m along +Z behind the forward grip
- Attach the rod as a child with an identity transform. Do not apply an additional −90° axis correction

The reel animation releases the left support grip for a crank motion while the right hand holds the rod. The crank circle is 0.046 m radius and 1.5 revolutions/second; its center is about 0.08 m to character left and 0.085 m behind the right grip. A separate stage-owned rod/reel provides the runtime equipment and line.

## Baked skeletal animation clips

All clips are authored and baked at 30 frames/second on the actual deformation skeleton. No procedural actor translation replaces the skeletal motion.

| Clip | Duration | Intended playback |
| --- | ---: | --- |
| `idle` | 3.20 s | Loop; subtle breathing and upper-body weight movement |
| `cast` | 2.20 s | Once; clear backswing, acceleration, forward release, recovery |
| `wait` | 4.00 s | Loop; relaxed rod hold and small body movement |
| `reel` | 2.00 s | Loop; left-hand crank, right-hand hold, torso effort |
| `lift` | 2.00 s | Once; raised rod and lean-back catch reaction, recovery |

Cast synchronization in seconds from the clip start:

- 0.00: neutral ready grip
- 0.34: gather and raise
- 0.78: backswing peak
- 1.00: acceleration begins
- 1.20: forward line-release cue
- 1.42: follow-through peak
- 2.20: recovered neutral grip

Set `idle`, `wait`, and `reel` to loop in the stage's animation library. `cast` and `lift` should remain non-looping. Explicit loop configuration in Godot is intentional rather than inferred from clip names.

## Art construction

The original cozy, stylized angler has a teal, pocketed fishing vest; sandstone cloth sleeves and rolled cuffs; continuous sculpted umber canvas trousers; reinforced knees; leather boots with soles, lace eyelets and laces; a stitched teal cap; dimensional face, hazel eyes, ears, nose, lips and brows; and individually modeled curled fingers and opposing thumbs. The vest includes sewn binding, pocket flaps, brass snaps, center zipper, and a small original fishing fly. Clothing proportions and large forms were reviewed as real renders, including front/back and casting keyframes.

Materials are embedded Principled PBR base-color/roughness/metalness materials. There are no texture downloads, paid assets, accounts, add-ons, or third-party art dependencies. All geometry and performances were authored specifically for this project in the generator. Project use, modification, bundling, and distribution are unrestricted by any third-party asset license. This does not claim exclusive intellectual-property rights over generic shapes or designs.

## Verification

Godot 4.6.3 official was used to import the GLB directly through `GLTFDocument`. Checks cover an actual `Skeleton3D`, actual weighted `MeshInstance3D`, all five `AnimationPlayer` clips at their exact lengths, and the animated hand socket through windup, release, follow-through, and recovery. The import requires normal process-frame updates for `BoneAttachment3D`; querying immediately after `seek()` without processing frames can show a stale socket.

The Blender review images are real path-traced scene renders of the generated mesh and rig, not concept art. A review-only handle/shaft is visible in final contact-review renders; the gameplay rod is supplied by the stage.

### Completed build measurements

- Runtime GLB: 2,135,512 bytes (about 2.04 MiB)
- Runtime geometry: 67,298 triangles; 34,771 weighted export vertices
- Runtime batching: one mesh, 20 material surfaces, one skin, 30 bones
- Grounded height: 1.7489 m
- Maximum skin-weight sum error: 2.98 × 10⁻⁸
- CPU deformation comparison, idle to backswing: 0.63968 m maximum displacement over 2,686 sampled vertices
- Godot socket-to-hand position check: within 0.00001 m at all five sampled cast phases
- Both-hand grip consistency across all 67 cast frames: maximum error 0.000000659 m from the shared handle axis
- The exported clips have lengths 3.20, 2.20, 4.00, 2.00, and 2.00 seconds for idle, cast, wait, reel, and lift respectively
- All sampled skinned vertex positions are finite; all exported weights are nonnegative and normalized
- Final GLB SHA-256: `19775a036d4fe72edd877e4208f1f805be4325524855b15a47febf21506c072b`

The initial shoulder-panel/cheek forms were simplified after rendered review; the trouser pelvis and legs were fused and reweighted into a continuous surface; fingers were reshaped to visibly close around the handle; the unneeded cap badge was removed; and the undershirt shoulder volume was reduced to stop cloth intersection with the vest. Final polished review images use the `final-` prefix in `build/angler-review/`.

The Blender build logs include a missing optional Draco library diagnostic from Blender's exporter. Draco compression is not enabled or required: the uncompressed GLB was exported successfully and then independently imported and tested in Godot. No render-only material, camera, light, or contact-review rod enters the runtime asset.
