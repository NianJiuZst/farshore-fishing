# 1.3.0 ocean source acceptance

## Final product boundary

This source builds the separately authorized `org.farshore.fishing.ocean`, version1.3.0/code7, launcher“远岸钓鱼·海洋”. It preserves the user's `1afda37` work and appends exactly30 species:74 fish,9 regions,18 spots,5 rods,12 baits and35 generated interface icons. Original44 species identifiers, natural-history text, portraits and3D source assets are retained. New species have individual rigged models/four animations, generated photoreal illustrations, source-backed encyclopedia entries and actual playable routes.

A new profile receives1500 coins and travel unlocks through all six original regions. Rod/depth restrictions remain; purchase suitable equipment with those coins. No caught fish or collection records are fabricated, and the three oceans keep their discovery/currency unlocks. Existing or imported saves remain authoritative. This separate package does not overwrite the installed preview app or automatically migrate its private data.

The owner generated and separately backed up the new signing key on their Mac. Only its public certificate SHA256 is in source: `a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716`. Private material and passwords are never uploaded. APK export, owner-local signing and final signed-byte verification are recorded separately in the release's build/validation files.

## Complete suite and explicitly isolated rerun

Final source/control acceptance is [machine-readable here](evidence/1.3.0/final-qa/acceptance.json). It contains results for all32 suites plus the full74 binary-model audit. This is **combined acceptance**, not a claim that the first full batch passed unchanged:

1. The complete batch ran against1703 stable game input files. All production/assets and tests were unchanged throughout it.31 suites and the binary audit passed
2. The sole failure was the UI style harness's obsolete31-icon list: the four newly authorized bait icons made nine allowlist/count assertions fail. The actual35 assets were loaded and the independent new UI/visual suites already passed
3. Only that test's expected icon IDs, count and printed denominator changed from31 to35. No production code, assets, style geometry, interaction assertions or other tests changed
4. The full style suite then passed28,762/28,762 at both720×1280 and720×1584,376 button visits each. Both reruns had unchanged inputs and passed the binary audit again
5. `tools/assemble_ocean_qa_acceptance.py` checks the exact inverse of that one test edit against the original hash, the precise nine original failure messages, all unchanged production/other-test hashes and both complete reruns. It retains the original failed batch rather than rewriting its result

The original and replacement logs, manifests and checksums are retained in [final-qa evidence](evidence/1.3.0/final-qa/). All current tests are included in this source and may be rerun as a fresh full batch.

## Key independent results

| Area | Verified result |
|---|---|
| Original persistence / old44 compatibility / fresh compensation |314 /1154 /423 assertions pass|
| Exact JSON readback repair |41,790 assertions;2664 genuine generated records across12baits×74fish×3size bands, each reloaded twice; no numerical tolerance|
| New large baits |888/888 actual bait/species generation routes,2,368,000 size draws; original8 bait definitions/seeded records preserved|
| General size balance |1,480,000 draws;144,632 giants (9.7724%); bounded fictional extension with real records kept separate|
| Growth / production Main |368,247 assertions;148 genuinely landed catches reach all74 species/all9regions from a zero-currency/lake-only challenge,4870 spent,14 remaining|
| Full actual3D catch flow |8047 assertions;74 species,18 spots,78 cast events and75 landing events; ordinary/protected disposition, pending restart and min/max framing|
| Additional extreme geometry |921 assertions;74species×minimum/maximum×two portrait aspects, exact scale and alongside-boat giants|
| Final two-aspect native UI |902 assertions and27 screenshots per aspect;836 headless UI assertions;462 exact source/image/HUD audit checks|
| Fight strategies |4385 actual seeded30fps simulations,70 regressions and8 balance gates pass; controller results are not player success rates|
| Float observation |20,736 simulations,864 passive traces,16/30/60fps,5631 assertions and7 gates pass; current input hashes stable|
| Build safety |34 packaging/identity/source-guard tests,11 unsigned-handoff safety tests and14 mocked acceptance-guard regressions pass|

The report-writing variants of the bait and general-size suites include one extra successful report-output assertion; the aggregate variants intentionally omit that file-write check. Counts are repeated assertions/samples, not millions of independent UI scenarios.

## Visual and scientific evidence

- [UI report](OCEAN_UI_VALIDATION.md) and [four source-bundled sample screens](evidence/1.3.0/ocean-ui/README.md); all54 final images are preserved in the full release validation archive
- [Ocean scenery](OCEAN_WORLD_VISUAL_QA.md), [species sources](OCEAN_SPECIES_SOURCES.md), [independent factual review](OCEAN_SPECIES_INDEPENDENT_REVIEW.md)
- All74 mesh-binary audits and148 portrait import/pixel audits pass;87 imported3D scenes include74fish, angler,9regions and3stations
- [Large-bait balance](GIANT_BAITS.md), [save precision repair](OCEAN_FLOAT_SAVE_VALIDATION.md), [fresh profiles](OCEAN_FRESH_PROFILE_VALIDATION.md)

## Honest limitations

No physical Android device installation, input/safe-area certification, GPU frame-rate, heat/battery,16KiB-page runtime or old-app update was performed. Native imagery uses Godot4.6.3 Mobile/Vulkan on a software llvmpipe renderer, not a Snapdragon benchmark. The two native UI runs exit successfully but each reports seven Texture RIDs at renderer shutdown; the same warning occurs in the standalone scene baseline without the UI optimization. Its cause is unresolved and it is not hidden as a clean-warning run.

The preserved upstream gold focus ring has approximately1.81:1 contrast on its pale surface, below a3:1 nontext target; current geometry is tested but accessibility compliance is not claimed. Source QA is also not APK-signature verification: the signed release has its own exact certificate/package, content, ZIP/ELF alignment and checksum audit after owner-local signing.
