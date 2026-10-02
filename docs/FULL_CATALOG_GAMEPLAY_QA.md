# Full44 native3D gameplay verification

This supersedes the **test fixture assumptions** of the earlier two-fish slice. The original historical trial data remains readable. The file name `slice3d_tests.gd` is retained so existing QA commands use the extended suite.

## Strict dependencies and test honesty

The suite constructs real Main, checks the production44-model Registry and Main's actual content gate, then requires all44 imported resources before any gameplay assertions. It never overrides `_models_complete` or `_content_ok`. Missing assets fail the run and print `full44 gameplay NOT RUN`; partial availability is not acceptance.

Only the isolated fixture's equipment ownership and six region unlocks are seeded. Production Encounter, FishingSession, Main, actual stage and durable SaveStore perform the catches below. Progression purchase/discovery gates remain separately tested by the unskipped core suite's real100-catch progression simulation.

## Preserved and extended coverage

- Actual native Mobile configuration with OpenGL fallback disabled
- Forty-four real imported fish actors, nonzero vertex skinning, substantial mesh geometry, required clips, live bone-pose changes and physical length scaling
- Authored human skeleton, hand/rod socket, cast duration and retained environment meshes
- Real lobby and preparation before the fishing HUD; cancelled hold never accidentally casts
- Reproducible ordinary Encounter seeds for every species; no trial target picker, fish replacement or post-generation species rewrite
- All44 species and all12 original spots in all6 regions finish actual charge, animated cast, wait, nibble, hook, balanced fight, settlement, animated breach/lift and disposition
- Long casting presentation gates the Session timer; rod/lure/line release timing and camera movement are checked
- Cast and landing focus loss, Settings/Back and repeated Back preserve the same specimen and freeze stage, Session, game clock and input
- Catch save is durable before presentation completes; a second actual SaveStore reload confirms the pending specimen
- Duplicate terminal callbacks and dispositions cannot replay counts or currency; repeated result Back preserves unresolved catches
- Protected Chinese sturgeon sale refusal and ordinary release/sale paths
- Actual animated rod-tip/line attachment and portrait landing bounds
- Minimum and maximum catalog length framing for all44 species without altering saved catches
- A final real unresolved catch survives restart and cannot be settled twice

The recipe search accounts for each rod's actual reach and depth. In particular, Atlantic wolffish requires the original180m deep rod; the90m heavy rod is not treated as an unconditional upgrade.

## Commands

Headless logic/native-scene integration (not visual or phone evidence): create fresh isolated directories under `/tmp/farshore-...`, set HOME, XDG_DATA_HOME and XDG_CACHE_HOME to them, then run:

    godot --headless --audio-driver Dummy --path game --script res://tests/slice3d_tests.gd

Actual desktop software rendering through the private-display harness:

    python3 tools/render_godot.py --timeout 600 -- --path game --rendering-method mobile --rendering-driver vulkan --script res://tests/slice3d_tests.gd

The harness supplies isolated HOME/XDG directories and prints the actual renderer. llvmpipe/lavapipe evidence is not Android16 Snapdragon8Elite hardware certification or a frame-rate guarantee.

Final companion gates remain unskipped core, production touch with `--require-full`, Registry with `--require-all`, independent `audit_fish_catalog_3d.py --require-all`, full image/model review, build verification and device evidence. Run the final acceptance against frozen source and exported isolated copies, not an in-progress producer checkout.

## Development checkpoint, 2026-10-02

- The extended suite parses and explicitly fails at the still-missing asset dependency; full gameplay is not yet run
- A standalone pure recipe-planning check passed101/101 across all44 species and all12 spots, using production Encounter; this is not gameplay verification
- Separate Main travel transaction boundaries passed24/24 both headless and actual desktop Mobile/Vulkan, without overriding model readiness or fabricating catches
- Raw development logs: `build/full-catalog-checkpoint/slice3d_full_gate.log`, `full44_recipe_planning.log`, `main_travel.log`, `main_travel_vulkan.log`

Final all44 result counts and limitations must replace this pending status only after actual completion.

## Coordinated aggregate runner

After the producers declare stable raw assets, run:

    python3 tools/run_full_catalog_qa.py --output build/full-catalog-development-RUN_ID --render

The output directory must be new. The runner imports with isolated user directories, runs twelve suites plus the independent binary gate, and optionally reruns slice3d/UI/touch through the actual Mobile/Vulkan private software display. It stores separate logs and JSON hashes before import, before testing and after testing. Any runtime input changes during testing fail the stability gate. Importer metadata/extracted-texture regeneration is reported separately; raw GLB/script/scene/data changes during import fail stability. `--skip-import` is available when the coordinated import already completed. This runner never exports or reads signing files.

The full45-catch actual software-render integration and repeated real scrolling of the101k-pixel license page exceed the earlier two-fish180-second harness budget. The aggregate runner therefore allows600 seconds per rendered suite, configurable with `--render-timeout`. No assertion or scenario is dropped. A timeout remains an incomplete failed run.
