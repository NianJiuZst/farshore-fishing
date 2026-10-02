# 44-species full 3D production plan

The catalog contains exactly 44 unique stable species IDs. The full-catalog request supersedes the two-species release scope, but the approved common-carp/alligator-gar body and material identities are preserved; original files are retained in verified backups before animated-contact repairs. A reusable authoring/rig/export library is shared; silhouettes, mouths, fins, eyes, armor, barbels and pigment are authored per species. A family relationship never permits palette-only duplicates.

## Batches and review gates

1. Preserved approved assets (2): `common_carp`, `alligator_gar`
2. Anatomical specialists (3): `olive_flounder`, `european_plaice`, `chinese_sturgeon`
   - Lead-owned: opposite flatfish laterality, actual thin volume and pale blind sides, independent jaw/outline/spot layouts; sturgeon five scute rows, four ventral barbels, bottom mouth and heterocercal tail
3. Catfish and elongate freshwater soft-fin fish (6): `channel_catfish`, `flathead_catfish`, `southern_catfish`, `longsnout_catfish`, `bowfin`, `northern_snakehead`
   - Representative gates: channel catfish and northern snakehead; adipose lobes must be rayless; species-specific barbel counts, tail and dorsal/anal forms
4. Cod family and wolffish (5): `atlantic_cod`, `pollack`, `saithe`, `haddock`, `atlantic_wolffish`
   - Representative gates: Atlantic cod and wolffish; cod has three dorsal/two anal fins; wolffish continuous dorsal, canine teeth and no pelvic fins
5. Long-snouted/fast freshwater predators (3): `northern_pike`, `longnose_gar`, `yellowcheek`
   - Representative gate: pike; duckbill vs needle snout vs pointed cyprinid jaw, different armor, fin positions and caudal outline
6. Cyprinid body plans (5): `crucian_carp`, `roach`, `rudd`, `common_bream`, `tench`
   - Distinct body depth, mouth angle/barbels, anal length, dorsal origin, tail fork and scales
7. Perch/bass/rockfish forms (4): `european_perch`, `largemouth_bass`, `mandarin_fish`, `marbled_rockfish`
   - Distinct spiny/soft dorsal structure, mouth/gape, body depth, pelvic location and species marking
8. Pelagic streamlined fish (4): `japanese_horse_mackerel`, `chub_mackerel`, `atlantic_mackerel`, `atlantic_herring`
   - Mackerel finlets vs horse-mackerel lateral-line scutes vs herring single dorsal; tail keels/forks and correct back patterns
9. Coastal perciforms/sparids/mullet (12): `red_seabream`, `black_seabream`, `japanese_seabass`, `japanese_whiting`, `european_seabass`, `gilthead_seabream`, `saddled_seabream`, `white_seabream`, `annular_seabream`, `red_mullet`, `painted_comber`, `common_pandora`
   - Independent profile/fin topology with specific forehead/jaw shape, dorsal separation, tail markings, chin barbels and body patterns

Total: 2 + 3 + 6 + 5 + 3 + 5 + 4 + 4 + 12 = 44.

## Shared verification gates

- Real closed volumetric fish body; meaningful width/thickness shown in top/underside/side renders
- Species anatomy reviewed against catalog sources and actual existing reference pixels
- Surface-seated eyes, natural jaw/lip boundaries, no floating fin roots or angular rigid barbels
- PBR color spaces matched: ordinary sRGB palette values for maps and solid tissues
- GLB weighted skin, normalized 1m rest X length, zero varying root translation and all four named clips
- Actual evaluated skinned vertex displacement and identical loop endpoints, followed by Godot Skeleton3D/AnimationPlayer playback
- Actual rendered hero/top/underside and animated poses, not a source illustration presented as model proof
- Scoped Git checkpoint and one per-species external backup after a reviewed batch
- No publication or claims of all44 completion until the final catalog coverage and runtime checks pass

See `FISH_3D_PIPELINE.md` for the profile API and output contract. The runtime owner maintains `game/data/fish_3d.json`; missing models stay explicitly missing rather than silently substituting carp.
