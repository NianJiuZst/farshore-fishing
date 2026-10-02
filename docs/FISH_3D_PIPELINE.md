# Full-catalog 3D fish pipeline contract (v1)

Owner of shared code: fish-pipeline lead. Other workers own only assigned `tools/art3d/fish_profiles/<species_id>.py`, their `.blend` / `.glb`, species review directory and assigned family notes. Do not edit `fish_pipeline.py` or legacy `build_fish.py`; request shared API changes from the lead. Existing carp/gar assets are preserved.

## Output and CLI

`blender -b --python tools/art3d/fish_pipeline.py -- --species olive_flounder`

Preview only: append `--views hero,top,underside`. Render a saved master without rebuilding: `--review-existing --views hero,pose_struggle --samples 48`. `--no-render` exports and validates without any rendering. Default produces all eight views.

- `art_masters/3d/<species_id>.blend`
- `game/assets/3d/<species_id>.glb`
- `ownbuild/fish3d-catalog/<species_id>/`: `hero.png`, `top.png`, `side.png`, `underside.png`, `pose_swim.png`, `pose_struggle.png`, `manifest.json`, `validation.json`
- No wildcard all-species generation until representatives pass actual render review
- Default model nose +X, Blender up +Z, GLB/Godot up +Y, centered normalized 1m total X extent, root motion zero
- Same four exported baked loop endpoints: `swim` 2s, `struggle` 1.2s, `breach` 1.4s, `landed` 3s
- Stage enables LOOP_LINEAR and owns world trajectories; no dependency on fixed bone count

## Profile module API

Each profile declares `PROFILE = {...}` and `def anatomy(f): ...`.

Required PROFILE keys:
- `id`: stable catalog species_id
- `sections`: increasing X tuples `(x, half_width_Y, dorsal_height_Z, ventral_depth_Z, center_Z)`; actual authored species outline, not one common outline
- `skin`: dict with `back`, `side`, `belly` RGB triples; `pattern` one of `scales`, `fine_scales`, `diamond`, `smooth`, `mottle`, `spots`, `bars`, `waves`, `flatfish`; optional pattern parameters
- `morphology`: list of concrete distinguishing features
- `sources`: verified URLs supporting morphology
Optional: `flatfish=True`, `ocular_side='left'/'right'`, `mirror_y=True` (mirrors anatomy and bones while preserving +Z ocular surface), `specular`, `coat`, `normal_strength`, `bend_axis='vertical'`, `swim_amplitude`, `fin_color`, `fin_pattern`, `head_start`, `head_end`, `roughness`, `custom_skin` callback (API and numpy grids, returns color/height/roughness arrays)

A closed smoothed body is made from `sections` before `anatomy(f)`.

Available f methods:
- `surface(x, theta, inflate=0)` → body surface point, theta=0 dorsal midline, +pi/2 positive Y flank
- `fin(name, roots, edge, bone=None, parent='spine_mid', rays=20, material=None)` → curved real-thickness fin with raised rays; registers and animates its own fin bone; additional fin names are permitted
- `eye(name, center, normal, radius=.01, iris=(.45,.32,.12))` → surface-seated physical eye, normal points away from body; flatfish can use `(0,0,1)` twice on the ocular side only
- `tube(name, points, radius, material=None, weight='spine', rings=7)` → curved volumetric lips/barbels/lateral-line details; radius may be scalar or one value per point
- `ellipsoid(name, center, scale, material=None, weight='head')`
- `mesh(name, vertices, faces, material=None, uv=None, weight='spine')`
- `material(name, color, roughness=.45, metallic=0, color_space='srgb')`
- `bone(name, head, tail, parent='head')`
- `gill(name, points, width=.001, parent='head')` → narrow independently animated gill edge
- `scute(name, x, theta, length=.025, width=.017, height=.008)` → genuine raised armored plate following body surface and spine weights
- `mats`: `skin`, `fin`, `ray`, `edge`, `dark`, `lip`, `tooth`
- `sections`, `profile`, `species` are readable

`anatomy` must author species-correct fins, mouth/jaw, eyes and distinguishing anatomy. Workers may add original custom meshes using the above methods. No PNG cutouts, no duplicated species meshes with only palette changes, no automatic symmetric eyes on flatfish, no default belly fins on wolffish, no generic scaly material on naked catfish.

Shared runner handles normals, skin weights, material consolidation, normalization, animation, GLB export, master saving, actual mesh-deformation/loop tests and rendered evidence. Profile anatomy can add bones, including dorsal/anal segments or asymmetrical controls. Raise API issues rather than modifying shared code in parallel.

## Flatfish anatomical orientation
With head +X and ocular face +Z in Blender, a left-eyed flatfish has the anatomical dorsal margin on −Y; a right-eyed flatfish has it on +Y. The body remains genuinely thick and the blind underside has no eyes. The runner supports mirror_y for authoring parity, but each species must retain its own head/outline/mouth/fin differences.

## Color convention
All profile palette values and f.material RGB triples are ordinary sRGB values. The shared pipeline converts solid-material colors to Blender linear values, matching the sampled sRGB basecolor maps. Pass color_space="linear" only for values already converted. Do not double-convert solid tissues. This prevents pale adipose lobes, white scute rivets, and chalky orbital rings.

## Atomic promotion
The runner exports to `ownbuild/fish3d-catalog/<id>/staging/<id>.glb`, verifies the complete GLB header, all four animations and weighted mesh skin bindings, and saves the packed editable master beside it. Only complete candidates are promoted with same-filesystem `os.replace` into canonical master and runtime paths. Concurrent Godot readers see either the previous complete model or the next complete model, never a partially written stream.
