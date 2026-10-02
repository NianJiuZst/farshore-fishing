# Northern marine fish: original 3D assets

This family owns nine original species, with head +X, Blender +Z / glTF +Y up, a centered one-metre resting length, a weighted armature, and `swim`, `struggle`, `breach`, `landed` clips. All geometry and pigment are authored procedurally in the species profiles. Reference photographs are for visual identification only, never textures or base meshes. No purchased assets or third-party modeling add-ons are used.

## Morphology evidence checked 2026-10-02

- **Atlantic cod / Gadus morhua:** three separate dorsal fins, two anal fins, single substantial chin barbel, upper jaw longer than lower, pale arched lateral line, broad belly and near-truncate tail. [VIMS / FAO account](https://www.vims.edu/research/units/programs/multispecies_fisheries_research/speciesofinterest/atlantic-cod.php), [MarLIN](https://www.marlin.ac.uk/species/detail/2095). DFO photograph viewed through [WoRMS](https://www.marinespecies.org/photogallery.php?album=745&pic=40141).
- **Atlantic wolffish / Anarhichas lupus:** rounded broad head, visible front canines and smaller crushing teeth, long continuous dorsal, broad rounded pectorals, no pelvic fins, tapered trunk and rounded tail, irregular slate-blue dark bars. [NOAA account and aquarium photograph](https://www.fisheries.noaa.gov/species/atlantic-wolffish), [NOAA anatomy factsheet](https://www.greateratlantic.fisheries.noaa.gov/public/public/web/NEROINET/prot_res/CandidateSpeciesProgram/atlanticwolffish_detailed.pdf).
- **Pollack / Pollachius pollachius:** lower jaw projects; no chin barbel; conspicuously large yellow eyes; sharply curved dark lateral line; first dorsal triangular, rear dorsals longer; slight tail fork. [Marine Biological Association / MarLIN](https://www.marlin.ac.uk/species/detail/9).
- **Saithe / Pollachius virens:** muscular streamlined trunk, nearly equal jaws, pronounced pale straight lateral line and forked tail. [Norwegian Institute of Marine Research](https://www.hi.no/en/hi/temasider/species/northeast-arctic-saithe).
- **Haddock / Melanogrammus aeglefinus:** high triangular first dorsal with concave trailing edge, smaller mouth and rounded snout, short barbel, dark continuous lateral line and shoulder blotch. [Marine Biological Association / MarLIN](https://www.marlin.ac.uk/species/detail/79).
- **Japanese horse mackerel / Trachurus japonicus:** pointed snout, adipose eye margins, two dorsal fins, deep fork, strong lateral-line scutes, upper gill-cover black spot, no finlets. The main scute line descends from the shoulder to the low posterior line; the accessory line follows the dorsal base. [Academia Sinica Taiwan Fish Database](https://fishdb.sinica.edu.tw/taxon/381555-fishdb).
- **Chub mackerel / Scomber japonicus:** Pacific population has an unspotted belly; first dorsal has 9–10 spines, gap to second dorsal shorter than first dorsal base. Five dorsal and five anal finlets, two small caudal keels on each side, no central keel. [FAO Scombrids of the World, pp.55–57](https://www.fao.org/4/ac478e/ac478e08.pdf). Historic FAO Atlantic taxonomic grouping is not used to add Atlantic-population belly markings to the Japanese catalog species.
- **Atlantic mackerel / Scomber scombrus:** narrower pointed spindle body with blue-green waved back and unmarked silver belly; larger gap between main dorsals than chub mackerel; five finlets above/below and paired minor caudal keels. [FAO pp.55,58](https://www.fao.org/4/ac478e/ac478e08.pdf), [NOAA](https://www.fisheries.noaa.gov/species/atlantic-mackerel).
- **Atlantic herring / Clupea harengus:** slender compressed silver body, single dorsal, slightly upturned mouth, forked tail and pelvic origins behind dorsal origin. Ventral scutes are subtle and do not create a strong sharp keel. [FAO clupeoid account](https://www.fao.org/4/ac482e/ac482e20.pdf), [MarLIN](https://www.marlin.ac.uk/species/detail/45), [NOAA](https://www.fisheries.noaa.gov/species/atlantic-herring).

## Quality gate

Representative cod and wolffish are built and visually checked before expanding the other seven. Every species has independent cross-sections, mouth geometry, fin position/shape, eye proportions and anatomy, with species-specific pigment. Shared rig/tooling is used only for export and deformation.

Evidence lives under `ownbuild/fish3d-catalog/<id>/`. All nine final models have passed the checks below, with eight actual rendered views each.

## Review corrections and structural checks

- Cod and wolffish hero, side, top and underside were inspected before the seven additional profiles were expanded. The wolffish's first preview used a convex dark mouth filler; review replaced this with a real concave oral cavity so the mouth reads as a recess. Its eight thick tapered front canines and smaller posterior teeth are original meshes.
- Wolffish dorsal attachment was additionally inspected in a magnified side crop. Rest fin roots lie 1.264–1.311 mm inside the authored body (pre-normalization). The visible narrow light line in the hero is a highlight, not visible background. This static result is explicitly separate from the dynamic gate.
- The shared animated-root checker added during production caught undersupported manually positioned pelvic/pectoral roots and caudal roots in provisional haddock/herring/chub exports. All nine profiles were then revised to seat paired-fin roots on their own body surface and give the caudal rootline 0.7 mm longitudinal overlap into the body cap. No tolerance overrides were introduced.
- Per-species `anatomy_contract.json` records independently executed profile calls. Gadoids have 3 dorsal / 2 anal fins; wolffish has no pelvic fins; each Scomber has 5 dorsal / 5 anal finlets; horse mackerel has 71 lateral scutes per flank and no finlets; herring has one dorsal and 33 low ventral scutes.
- `glb_file_audit.json` independently parses binary GLB chunks and accessor data, checking actual embedded images, skin joint/weight buffers, all four clip durations, zero exported root translation drift, centered one-metre rest length, and distinct position buffers. This does not substitute for rendered deformation or Android runtime QA.


## Final asset signoff, 2026-10-02 UTC

**Nine of nine species complete.** Every canonical GLB and editable Blender 4.3.2 master exists. All 72 final Cycles images (1200×800, 24 samples) were inspected: hero, side, top, underside, swim, struggle, breach and landed. Each `review_signoff.json` binds these images to the exact profile, master and GLB hashes. The family montage is `ownbuild/fish3d-catalog/atlantic_cod/northern_marine_hero_montage.jpg`.

All nine binary files have independently distinct position-buffer hashes, embedded original PBR images, normalized weights, centered 1m rest length, +X forward and glTF +Y up. Exported animation durations are swim 2.0s, struggle 1.2s, breach 1.4s and landed 3.0s, with zero root translation drift. The Blender deformation tests confirm real skin displacement and continuous loop endpoints. The attachment gate samples nine phases of every clip, 36 animated poses per species, and separately measures membrane and ray contacts against the deformed body. No tolerance override was used.

| Species ID | Triangles | Bones | GLB MiB | Max membrane distance mm | Max ray distance mm |
|---|---:|---:|---:|---:|---:|
| atlantic_cod | 38348 | 19 | 3.35 | 1.327 | 1.720 |
| pollack | 38762 | 19 | 5.11 | 1.323 | 1.668 |
| saithe | 38484 | 19 | 5.15 | 1.524 | 1.886 |
| haddock | 38072 | 19 | 5.09 | 1.342 | 1.727 |
| atlantic_wolffish | 42628 | 14 | 4.06 | 2.292 | 2.406 |
| japanese_horse_mackerel | 33910 | 17 | 4.51 | 1.131 | 1.553 |
| chub_mackerel | 33306 | 27 | 5.08 | 1.834 | 2.299 |
| atlantic_mackerel | 33474 | 27 | 5.08 | 1.687 | 2.164 |
| atlantic_herring | 29586 | 16 | 4.59 | 1.088 | 1.476 |

The three pelagic spiny first dorsals were additionally refined to eight raised rays for Japanese horse mackerel, ten for chub mackerel and twelve for Atlantic mackerel. The two mackerels differ in authored body depth/width, eye size, mouth, dorsal base/gap, and wave pattern; they are not palette swaps.

### Reproduction

Build one original model and run the full deformation/attachment gate:

```sh
blender -b -t 2 --python-exit-code 1 --python tools/art3d/fish_pipeline.py -- --species atlantic_cod --no-render
```

Revalidate a saved master without changing geometry:

```sh
blender -b -t 2 --python-exit-code 1 --python tools/art3d/fish_pipeline.py -- --species atlantic_cod --validate-existing
```

Render each view with the bounded two-slot helper (two threads per render):

```sh
for view in hero side top underside pose_swim pose_struggle pose_breach pose_landed; do
  tools/art3d/render_fish_view.sh atlantic_cod "$view" 24
done
```

Independent binary/anatomy QA scripts are preserved with the evidence under the cod representative folder. Visual evidence and reports are part of the outside-project, byte-verified family backup. Reference photographs were not included in game materials or the backup asset bundle.

### Verification boundary

These are Blender/rendered-anatomy, animated-contact, and native GLB-content checks. This family note does not claim Android-device frame rates, complete gameplay reachability, or the final aggregate Godot/Android acceptance pass. Those belong to the full 44-species integration and release QA.
