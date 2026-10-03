# 1.2.0-beta.3 UI acceptance

This release fixes the actual fish-image tap target, replaces the empty fullscreen failure page with a compact scene-backed dialog, and improves the full menu/navigation hierarchy. The visual system retains transparent illustrated actions, a warmer paper surface, darker readable text, and safe-area-aware layouts.

## Delivered behavior

- Empty casts, escaped fish and line breaks use one compact modal over the3D scene. Terminal HUD is hidden. Retry/Back waits for held/emulated input to drain; it returns to an idle cast-ready state without auto-casting or rewards. Duplicate terminal events cannot replace the modal
- Lobby exit uses the same input shield and a compact confirmation. A failed selection-save keeps the game open with retry instead of silently quitting
- Each of all44 fish tiles is one real native Button, including its image/name/whitespace. Vertical/horizontal drags cancel activation. Details and zoom preserve catalog filters/scroll, favorites origin, and pending-result origin
- Species details put high-resolution art and real catch count/longest/heaviest summaries first. Full records retain independent original individuals, first/latest catches and regional counts. Zero-catch states show dashes rather than invented records; browsing cannot increment data
- Preparation groups destination, tackle and available species. Travel keeps destination imagery and nearby spot decisions together. Gear has direct rod/bait positioning, clickable bait illustrations, concise comparison rows, and retained scroll after choosing
- Empty favorites has one invitation instead of six repeated placeholders. Catch results keep the fish, measurements, information and actions together. Settings separates controls/save guidance from About/licenses, displays volume, and retains pause context through toggles/About
- Lobby progression values have bounded nonwrapping layout. Paper text no longer has a pale halo. Overlay/HUD/modal actions account for all four safe-area sides

## Tests and honest evidence boundaries

The final [complete22-suite headless run](evidence/1.2.0-beta.3/headless/summary.json) passes with every recorded runtime input unchanged. It includes all44 ordinary encounter/3D cast/landing flows, data/save fault cases, touch conflicts, the photograph gate, schema-2 beta2-save reading, and the new UI journeys. The full3D suite passes4515/4515 and still visits44 species/12 spots; the core suite passes182417/182417. These assertion counts describe coverage, not a player-experience score.

The dedicated notebook suite passes313/313 and checks actual Viewport taps on all44 images. The production journey suite passes82/82 at720×1280 and720×1584 and under actual desktop Mobile/Vulkan. The standalone input-shield suite passes37/37. The final tall UI matrix also passes with unchanged inputs. No Android physical-touch or phone performance claim is inferred from these events.

The native screenshot pass produced25 real framebuffer captures, including home, gear/bait, catalog, details, result/protection/save-error states, failure and exit dialogs. The independent review found and corrected home-counter wrapping and stale terminal HUD. Before/after examples and renderer logs ship in the [evidence index](evidence/1.2.0-beta.3/index.json). All catch/progression data shown in review images are isolated test fixtures, not user records. Save-error images demonstrate presentation; actual fault injection is covered separately by the save/core tests.

The native runner's original whole-tree summary conservatively reports a stability failure because two **unexecuted headless-test files** were updated during its run. Both native jobs themselves passed. Its retained [executed-input proof](evidence/1.2.0-beta.3/native/executed-input-proof.json) checks that every production input, the actual native test, and all other recorded inputs remained identical before/after and at the final freeze. Neither native harness loads the two changed files. Their corrected complete headless rerun passed. The raw summary was not rewritten into a pass.

An earlier core assertion also used a simulated timer to wait for a wall-clock input drain after a long CPU-heavy matrix frame. It was corrected to wait for the actual modal dismissal with a bounded real-time deadline; the complete current run passes. No production input guard was removed to satisfy that test.

The known upstream seven-Texture-RID ReflectionProbe shutdown warning remains in world-backed desktop renders. Focused photo-only/component renders have their separate logs. The application was not installed/run on an Android16 device during this iteration. Phone Vulkan drivers, OS touch mapping/cutouts, sound/haptics, sustained frame rate and thermals remain user acceptance checks.

## Update and scope

Version1.2.0-beta.3/code5 uses **org.farshore.fishing.preview** and the exact same approved certificate as beta2. It is intended as an in-place beta2 update retaining its private save; do not uninstall beta2 first. It remains separate from the earlier org.farshore.fishing package. Literal beta2-schema data loads without reset; final APK identity/signature gates verify update prerequisites. This is not a claimed physical-device upgrade test.

FishingSession, FishingStage3D, SaveStore, the44 fish definitions, world/equipment/bait data, and all3D/fish image assets are unchanged from beta2. Its previously recorded fight-balance study remains physics evidence; this UI iteration does not rebalance fishing. Same-user public GitHub source/release publication is authorized, while signing private keys/passwords are excluded.

Final source/Android commands are in [BETA3_BUILD.md](BETA3_BUILD.md); the release's APK/source verification attachments must match the frozen source. This acceptance document records the pre-export runtime gate, not an assertion that a future artifact already passed.

## Research and reproduction

[UI research and independent review](BETA3_UI_RESEARCH.md) records six primary references and actual inspected official game screenshots. External screenshots were not copied into product assets. It distinguishes publisher marketing images from interaction evidence.

```sh
python3 tools/run_full_catalog_qa.py --output build/recheck-beta3
python3 tools/run_full_catalog_qa.py --output build/recheck-beta3-tall --skip-import --tall --suites fish_art_ui,failure_modal,notebook_ui,ui_iteration,ui_style,touch
```

Use official Godot4.6.3.stable.official.7d41c59c4. The runner isolates HOME/XDG saves and refuses output reuse. Native reproduction additionally uses tools/render_godot.py and the shipped capture/test harnesses with isolated test data.
