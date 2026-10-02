# Freshwater 3D expansion batch

Nine independently authored species following review of the flatfish/sturgeon representatives. Original project PNGs were visually inspected as morphology references; they are not runtime cutouts or body textures. Palette values are sRGB and maps are original analytic PBR textures.

## Distinct anatomy and geometry

| Species | Triangles | Bones | Distinguishing anatomy |
|---|---:|---:|---|
| crucian_carp | 29406 | 16 | Short high laterally compressed bronze body; No mouth barbels; Long dorsal with convex upper contour |
| roach | 27810 | 16 | Slender laterally compressed silver body; Red iris and orange-red lower fins; Terminal small mouth, no barbels |
| rudd | 27978 | 16 | Deeper golden-silver body than roach; Upturned small mouth and forward lower lip; Dorsal starts clearly behind pelvic origin |
| european_perch | 33616 | 17 | Seven dark vertical flank bars on yellow-green body; Two separated dorsal fins, tall hard-spined front dorsal; Single dark spot toward rear of first dorsal |
| northern_pike | 32058 | 16 | Elongate torpedo body with broad flat duckbill snout; Large long mouth and slightly projecting lower jaw; Dorsal and anal fins both far back near forked tail |
| common_bream | 29574 | 16 | Very deep and thin laterally compressed bronze-silver body; Small downturned protrusible mouth and small head; Long anal-fin base with dark gray membrane |
| tench | 30154 | 16 | Thick olive-green rounded body and minute embedded scales; Small red eyes, thick lips and one short barbel pair; Rounded dorsal/paired/anal fins and near-square shallowly concave tail |
| longnose_gar | 28610 | 16 | Needle-narrow snout more than twice remaining head length; Thin elongate armored body with fine diamond-shaped scales; Dark side and tail spots, rear dorsal and anal |
| yellowcheek | 29550 | 16 | Long pointed head and large terminal predatory mouth; No barbels; pale yellow cheeks and lower fins; Small dorsal beginning behind pelvic fins |

The shared `_freshwater.py` file contains surface-anchoring and mouth/fin authoring helpers, not a complete recolorable fish. Each profile supplies separate body cross-sections, fin outlines, eye/mouth positions, diagnostic morphology and pigment logic. Pike, gar and yellowcheek use independently authored jaw lofts and different snout proportions; bream/crucian have much deeper outlines than roach, while tench has a robust body, rounded tail and a short barbel pair.

## Runtime and verification

- Nose +X, Godot up +Y, 1m normalized rest length; four clips swim/struggle/breach/landed and no varying root translation
- Dense paired/median fin roots come from the actual body surface; caudal roots match the posterior cap instead of being placed behind it
- Persistent membrane/ray roots are sampled in rest plus nine phases of every clip; all nine pass without tolerance overrides
- `ownbuild/fish3d-catalog/<id>/validation.json` is the actual contact/loop report; `godot_validation.json` checks native Godot skeleton/player/skin/clip import
- `tools/art3d/audit_fish_catalog.py` checks current canonical hashes, all44 expected IDs, weighted skins, clip names, root-motion constancy, normalized bounds and distinct exact geometry signatures
- Hero sheets and later full-view review remain separate from numerical acceptance; a model is not called final merely because a generator ran

## Art references

- Existing `FISH_A_SOURCES.md`, `FISH_C_SOURCES.md`, `FISH_D_SOURCES.md` and catalog morphology records
- Northern pike: https://home.nps.gov/miss/learn/nature/northern-pike.htm
- Longnose gar: https://www.nps.gov/miss/learn/nature/long-nosed-gar-lepisosteus-osseus.htm
- Yellowcheek: https://dfz.jl.gov.cn/jltc/201805/t20180502_5217576.html
- Other original per-species sources are retained in each Python profile and model manifest

No third-party model/photo reuse, paid assets, new accounts or undocumented licensing assumptions. Canonical promotion is atomic; scoped source/assets are checkpointed and a bounded per-species external backup is maintained.
