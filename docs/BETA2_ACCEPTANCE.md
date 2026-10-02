# 1.2.0-beta.2 combined runtime acceptance

## What changed

This freeze combines observational float-reading and species-dependent fights with **44 new high-resolution generated fish illustrations** for the catalog, favorites, species details, zoom and catch settlement. In-water fish, struggles, breach/lift, the rigged angler and all six regions/twelve spots remain native3D. Five rods, eight baits, all44 species and the save schema remain available.

The cast completes before continuous water/float observation. WAIT/NIBBLE/BITE share the same camera, active reel control and non-revealing UI. Early strikes are empty casts; late strikes miss; a held early input cannot auto-hook. A legitimate fresh hook press may continue reeling. Fish/rod behavior signals upcoming surges. Giants have substantially higher stamina; continuous hard pulling loses, prolonged slack escapes, and prolonged stalemate wear cannot break before the visible warning grace.

## Current evidence

All19 headless suites plus the independent44-model binary audit passed at720×1280. The selected layout/gameplay/touch suites passed at720×1584, including actual desktop Mobile/Vulkan rendering. The complete **1070-file runtime inventory** was identical before/after and across both runs. [Combined evidence index](evidence/1.2.0-beta.2/combined/index.json) records every shipped proof file; input manifests bind the actual scripts, data, scenes and assets.

The separate [18,040-fight balance study](FISHING_SKILL_BALANCE.md) executes actual GDScript at16/30/60fps and verifies visible-cue control, blind strategies, giant durations, frame-independent hazards, pauses and unique terminal outcomes. Its final Session SHA256 is3957e67e25bf8fed7eeebc1bbe9e7055dd016ba4fd9fca406c4a3141a39da87a. Automated controller outcomes are not a promise of human success rate.

[Photoreal UI evidence](FISH_PHOTO_UI.md) covers all44 static page routes at both sizes and actual renderer captures. The perch catch sample reproduces the user reference's33.1cm/585g only as an isolated review fixture. Full-resolution runtime PNGs are unchanged from the reviewed image-generation masters; atlas views crop transparent margins without resampling, and ruler endpoints exclude barbels or reverse for right-facing plaice. These are generated near-photoreal illustrations, not wildlife photographs.

## Installation identity and save boundary

This is the explicitly approved independent test app `org.farshore.fishing.preview`, version1.2.0-beta.2/code4, displayed as远岸钓记·试钓版. It uses a new dedicated signing identity because the previous cloud environment's key was lost. **Keep the old app installed. This preview coexists and starts a separate new save; it does not automatically access the old app's private save.** The old package/release is not overwritten. The source contains only the public certificate fingerprint and no private signing credentials.

## Android and performance limits

This record is not Android runtime certification. The final release's separate APK verification report must bind the delivered bytes, package/version, ARM64 ABI, API29/36,16KiB alignment, signature, offline permissions, Mobile/Vulkan settings and all exported3D/photo resources to the frozen source archive. An unsigned minimal template smoke test is not substituted for that final game audit.

No current Android16 phone installation, physical touch/cutout, long-session memory, sound/haptic, battery, thermal or Snapdragon8Elite FPS claim is made here. The actual captures and native tests use desktop Mesa software Vulkan. Synthetic safe-area insets and a19.8:9 layout are stress tests, not a verified handset. The prior software emulator could not supply reliable installation/gameplay evidence; its historical failure is not reported as a pass.

Full-world native renderer shutdown retains the independently reproduced upstream seven-Texture-RID ReflectionProbe warning documented in the beta1 record. Static photo-only render validation exits cleanly. Neither warning suppression nor graphics-quality reduction was applied.

## Detailed results

| Run / suite | Actual summary |
|---|---|
| headless / camera_aspect | CAMERA_ASPECT_TESTS: 531/531 passed; failures=0; mathematical desktop projection, not device certification |
| headless / save | SAVE_TESTS: 314/314 passed; failures=0 |
| headless / core | CORE_TESTS: 182417/182417 passed; failures=0 |
| headless / session_observation | SESSION_OBSERVATION_TESTS: 124/124 passed; failures=0 |
| headless / hazard_boundary | FISHING_HAZARD_BOUNDARY_TESTS: 28/28; cases=7 |
| headless / guard_trace | FISHING_GUARD_TRACE_TESTS: old_new_differences=0 capture_mismatches=0 frames=382 substeps=764 max_wear=0.00892862787066 |
| headless / float_observation | FLOAT_OBSERVATION_TESTS: 46/46 passed; failures=0; presentation fixtures, not phone performance |
| headless / fish_art | FISH_ART_TESTS: 34/34 passed; prototype geometry and release gate, not 44 finished art or Android validation |
| headless / fish_art_ui | PHOTO_UI_SCOPE: canonical-photoreal-44; production native pages; no release gate override; not Android validation; FISH_ART_UI_TESTS: 1182/1182 passed; canonical-photoreal-44; (720, 1280) desktop layout |
| headless / tackle | TACKLE_TESTS: 557/557 passed; failures=0 |
| headless / bait_balance | BAIT_BALANCE_TESTS: 33091/33091; reachable_species=44/44 |
| headless / registry | FISH_3D_REGISTRY_TESTS: 98/98; imported models=44/44; release_gate=true |
| headless / fish_preview | FISH_PREVIEW_TESTS: 25/25 passed |
| headless / main_travel | MAIN_TRAVEL_TESTS: 24/24 passed; failures=0; boundary tests only, no readiness override |
| headless / slice3d | LAYOUT_SCOPE: physical=(720, 1280) logical=(720.0, 1280.0) aspect=expand; representative desktop layout only, not phone hardware; SLICE3D_TESTS: 4511/4511 passed; failures=0; cast events=47; landing events=45; species=44; spots=12 |
| headless / ui_style | LAYOUT_SCOPE: physical=(720, 1280) logical=(720.0, 1280.0) aspect=expand; representative desktop layout, not Android safe-area or hardware certification; SAFE_AREA_SCOPE: 104px top/80px bottom injected solely for layout testing; actual Android cutouts still require device testing; UI_STYLE_TESTS: 12575/12575 passed; failures=0; button visits=267; physical viewport=(720, 1280); logical viewport=(720.0, 1280.0) |
| headless / touch | LAYOUT_SCOPE: physical=(720, 1280) logical=(720.0, 1280.0) aspect=expand; representative desktop layout only; TOUCH_SCOPE: complete44 registry; full gameplay assertions enabled; TOUCH_SCROLL_TESTS: 132/132 passed; failures=0; actual Viewport ScreenTouch/ScreenDrag |
| headless / historical_trial | TRIAL_FISHERY_TESTS: 38082/38082 passed; failures=0 |
| headless / angler_anatomy | ANGLER_ANATOMY_TESTS: 3705/3705 passed; failures=0 |
| headless / binary_catalog | {"checked_models": 44, "missing": 0, "failures": [], "full_catalog_complete": true, "full_release_gate": true} |
| tall / fish_art_ui | PHOTO_UI_SCOPE: canonical-photoreal-44; production native pages; no release gate override; not Android validation; FISH_ART_UI_TESTS: 1182/1182 passed; canonical-photoreal-44; (720, 1584) desktop layout |
| tall / slice3d | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout only, not phone hardware; SLICE3D_TESTS: 4511/4511 passed; failures=0; cast events=47; landing events=45; species=44; spots=12 |
| tall / ui_style | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout, not Android safe-area or hardware certification; SAFE_AREA_SCOPE: 104px top/80px bottom injected solely for layout testing; actual Android cutouts still require device testing; UI_STYLE_TESTS: 12575/12575 passed; failures=0; button visits=267; physical viewport=(720, 1584); logical viewport=(720.0, 1584.0) |
| tall / touch | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout only; TOUCH_SCOPE: complete44 registry; full gameplay assertions enabled; TOUCH_SCROLL_TESTS: 130/130 passed; failures=0; actual Viewport ScreenTouch/ScreenDrag |
| tall / binary_catalog | {"checked_models": 44, "missing": 0, "failures": [], "full_catalog_complete": true, "full_release_gate": true} |
| tall / slice3d_vulkan | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout only, not phone hardware; SLICE3D_TESTS: 4511/4511 passed; failures=0; cast events=47; landing events=45; species=44; spots=12 |
| tall / ui_style_vulkan | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout, not Android safe-area or hardware certification; SAFE_AREA_SCOPE: 104px top/80px bottom injected solely for layout testing; actual Android cutouts still require device testing; UI_STYLE_TESTS: 12575/12575 passed; failures=0; button visits=267; physical viewport=(720, 1584); logical viewport=(720.0, 1584.0) |
| tall / touch_vulkan | LAYOUT_SCOPE: physical=(720, 1584) logical=(720.0, 1584.0) aspect=expand; representative desktop layout only; TOUCH_SCOPE: complete44 registry; full gameplay assertions enabled; TOUCH_SCROLL_TESTS: 130/130 passed; failures=0; actual Viewport ScreenTouch/ScreenDrag |

## Reproduce

Use official Godot4.6.3.stable.official.7d41c59c4 and isolated test data:

```sh
python3 tools/run_full_catalog_qa.py --output build/recheck-beta2
python3 tools/run_full_catalog_qa.py --output build/recheck-beta2-tall --skip-import --tall --suites fish_art_ui,slice3d,ui_style,touch --render
python3 tools/run_fishing_balance.py --output build/recheck-beta2-balance
```

Output directories must be new. Historical beta1/recovery logs remain labeled separately and do not replace this combined freeze.
