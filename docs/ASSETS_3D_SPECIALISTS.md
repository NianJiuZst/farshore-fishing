# Anatomical specialist 3D fish batch

Reviewed 2026-10-02 with Blender 4.3.2 and Godot 4.6.3. This is the first full-catalog expansion batch. The two original approved fish are preserved; this document does not claim all44 completion.

## Models and distinguishing anatomy

- `chinese_sturgeon`: full rounded gray body, flattened rostrum, bottom-facing mouth, exactly four rostral barbels, five longitudinal rows of low actual bony scute geometry, posterior dorsal/anal fins and an unmistakably longer upper tail lobe. 16-bone skin. This remains a protected virtual observation species; gameplay rules are owned by the runtime catalog.
- `olive_flounder`: adult left-eyed fish. Both eyes are on the upper ocular surface; anatomical dorsal edge is −Y in Blender after side rotation. Full thin body volume, asymmetrical large oblique jaw, smaller blind-side pectoral, olive mottling, dark small spots and continuous long margins. The blind underside is pale and eyeless. 18-bone skin with segmented margin controls and vertical body flex.
- `european_plaice`: adult right-eyed fish, with dorsal edge +Y. Independently authored broader/deeper oval profile, smaller terminal mouth, six low head knobs, round orange-red spots and rounded tail. Pale eyeless blind underside. 18-bone skin. It is not a palette-only copy of the flounder.

Output: `art_masters/3d/<id>.blend`, `game/assets/3d/<id>.glb`, `ownbuild/fish3d-catalog/<id>/`.

## Review corrections actually made

1. Confirmed flatfish ocular pigment in an unlit basecolor render. Broad specular highlights were washing out the top surface, so species-specific specular/coat/normal settings were added.
2. Replaced stretched cylindrical flatfish patterns with physical planar pigment coordinates and increased its cross-section/body resolution. Broad straight triangular pigment wedges were removed and plaice spots became round.
3. Welded coincident body-seam vertices while retaining per-loop UV seams, avoiding an artificial hard dorsal-normal ridge.
4. Matched solid tissue materials to the maps' sRGB palette convention. This removed chalk-white scute/rim/ray appearance and made anatomy materials read consistently with the body.
5. Replaced the flounder's angular jaw slab with a continuous closed asymmetric jaw loft. Both flatfish have independently positioned paired eyes, not mirrored bilateral eyes.
6. Added a review-only underside area light and hid the backdrop for underside views so ventral mouths, barbels and blind sides can actually be inspected.

## Rig/runtime contract

Nose +X, Blender up +Z, GLB/Godot up +Y. Static total X extent is exactly 1m, centered at the nose/tail range midpoint. Flatfish lie naturally with the ocular face up; they do not require a billboard or single-plane special case. Runtime can use the catalog's `asymmetric_flatfish` framing hint.

Each GLB includes `swim` (2.0s), `struggle` (1.2s), `breach` (1.4s), `landed` (3.0s). Root translation does not vary. Baked rest translations may exist on joints and are not root drift. Runtime owns world trajectories and enables LOOP_LINEAR. Bone count varies by anatomy; do not hardcode 16.

## Evidence and reproducibility

Per-species `manifest.json` records geometry counts, bones, sources, GLB bytes/SHA-256 and the actual shared pipeline hash used at generation. `validation.json` measures actual evaluated skin displacement and near-zero loop endpoint error. `godot_validation.json` verifies actual Godot Skeleton3D, AnimationPlayer, named clips, animated bones, skinned mesh coverage and 1m X bounds.

Hero/top/side/underside plus four posed renders are actual model renders. Diagnostic images are local review intermediates, not new art assets or extra species.

```sh
blender -b --python tools/art3d/fish_pipeline.py -- --species olive_flounder --no-render
blender -b --python tools/art3d/fish_pipeline.py -- --species olive_flounder --review-existing --views hero,top,underside,pose_struggle
# Direct GLTFDocument verification avoids duplicate imported texture/cache trees:
godot --headless --path ownbuild/fish3d-catalog --script validate_profiles.gd -- chinese_sturgeon olive_flounder european_plaice
```

Final anatomy references are the original catalog source records plus [NOAA Chinese sturgeon](https://www.fisheries.noaa.gov/species/chinese-sturgeon), [MarLIN plaice](https://www.marlin.ac.uk/species/detail/2172), [original olive-flounder eye-migration research](https://doi.org/10.1002/ar.a.10074), and the linked source URLs in each manifest. Existing PNGs were visually inspected for species grounding, never used as cutout planes or projected fish-image textures. Geometry, material maps and animation are original procedural authorship.

## Animated attachment regression and repair
Actual Main preview identified a caudal attachment gap that studio hero renders did not reliably expose. The new persistent-root BVH audit measured14.4mm at the old flounder tail root, while dorsal/anal root groups stayed at1–1.5mm. The caudal rootline was moved onto the actual posterior body cap and paired roots were surface-derived. Flounder now passes at2.41mm; plaice at2.46mm; sturgeon at2.68mm over rest plus36 animated samples. The production Main transparent SubViewport was recaptured across six swim phases by the runtime owner, showing one connected fish silhouette and a closed tail seam.

The same audit exposed root-placement errors in the two initial legacy models. Their exact originals were verified against retained backups before repair. Their body geometry, original palette/material identity, four clips and triangle counts remain unchanged; fin roots now follow the actual body surfaces/cap. Repaired carp/gar pass at2.14/2.19mm.

## Final source-art freeze

All three specialists and both repaired legacy models have current hash-bound eight-view `review_signoff.json` records, evaluated animated contact passes and native Godot import checks. Original carp/gar backups remain retained separately. The all-44 catalog gate now checks the exact canonical GLB and reviewed-image hashes before accepting final source art; this does not stand in for Android device or release verification.
