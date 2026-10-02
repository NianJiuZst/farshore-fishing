# True-3D two-species vertical slice acceptance

## Scope

One fixed rigged angler, one coherent fictional managed river, and native animated common carp (`common_carp`) and alligator gar (`alligator_gar`). Required flow: lobby → preparation → charge/release → complete character cast → water-focused wait/bite/fight → fish breach/lift → result.

The production default is **Godot Mobile/Vulkan**, targeting the requested high-end Android 16 / Snapdragon 8 Elite device class. There is no compatibility-renderer downgrade in the project. Authoring uses Blender 4.3.2, engine Godot 4.6.3. No external gameplay/addon runtime is introduced. This acceptance is source, native scene and desktop/software-Vulkan evidence; it is **not** an APK build or phone-performance certification.

All 44 legacy species, six regions, twelve spots, save schema, discoveries, records, pending catches and favorites remain. Only two species and one managed river are playable in this native-3D slice. New trial catch records use the virtual trial location; the original saved selected region/spot is preserved. Temporary target selection does not become a saved unlock or replace that selection.

## Automated acceptance gates

Run every suite with fresh HOME/XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME directories under `/tmp/farshore-<suite>-*`. Texture/model imports must already exist. Do not run against a player's HOME.

```sh
D=$(mktemp -d /tmp/farshore-slice3d-XXXXXX)
mkdir -p "$D/home" "$D/data" "$D/config" "$D/cache"
HOME="$D/home" XDG_DATA_HOME="$D/data" XDG_CONFIG_HOME="$D/config" \
XDG_CACHE_HOME="$D/cache" godot --headless --audio-driver Dummy --path game \
  --script res://tests/slice3d_tests.gd
```

The slice script refuses non-isolated startup. Core, UI, save, trial-adapter and touch suite commands and evidence are documented separately. A full source acceptance requires all of them, clean exit plus no ERROR/WARNING output. Assertion totals are repeated checks, not independent gameplay scenarios.

Final six-suite run on **2026-10-02 at 12:34 UTC**, frozen production commit **`c931215`**, Godot **4.6.3.stable.official.7d41c59c4**:

| Gate | Passed | Exit / diagnostics |
| --- | ---: | --- |
| Full core with `--check-art`, actual Main included | 69,160 / 69,160 | 0; no ERROR/WARNING |
| Persistence/recovery/stress | 314 / 314 | 0; no ERROR/WARNING |
| Actual UI/style/assets | 10,839 / 10,839 | 0; no ERROR/WARNING; 28 routes, 215 button visits |
| Native 3D rig/presentation/interruptions | 270 / 270 | 0; no ERROR/WARNING |
| Managed-river adapter / retained content | 9,065 / 9,065 | 0; no ERROR/WARNING |
| Actual viewport touch, production pages included | 71 / 71 | 0; no ERROR/WARNING |

All **387** recorded game source/content/art files were byte-identical before/after these runs and through the final rendered capture. Logs: `build/qa3d/{core,save,ui_style,slice3d,trial_fishery,touch_scroll}.log`. Full SHA-256 snapshots: `build/qa3d/final_hashes_before.json` and `final_hashes_after_suites.json`; post-render snapshot `final_hashes_after_render.json`; summarized evidence and log/image digests `final_acceptance_manifest.json`. The snapshot excludes generated `.godot`, Android build and export directories; it includes the real scripts, tests, catalogs, icons, models, textures, shaders and project file.

Final imported weighted-vertex counts: angler **34,771**, carp **15,168**, gar **16,582**. All five character and all four clips on each fish move actual skeleton bones. These are real imported geometry counts, not triangle counts or performance guarantees.

### Real geometry and animation

- Actual production Main instantiates a Node3D world with active Camera3D, retained environment meshes and authored character
- Actor/fish instances contain real Skeleton3D, imported AnimationPlayer, Skin bind tables, vertex bone-index arrays and nonzero per-vertex skin weights
- Each advertised clip drives at least two actual live skeleton bone poses; key tracks alone are insufficient
- Character: idle/cast/wait/reel/lift. Both fish: swim/struggle/breach/landed
- Actual fishing rod follows the authored right-hand RodSocket; temporary socket fallback fails
- No Sprite3D/AnimatedSprite3D actor/fish substitution; ordinary UI/specimen illustrations remain legitimate 2D assets
- Live fish uses the correct species instance; its scale follows actual production `length_mm` measurements
- Whole lifted mesh bounds fit the portrait viewport at carp 180/900 mm and gar 650/2400 mm, as well as both generated catches
- Actual line geometry meets the animated rod tip within 1 cm; a separate actual Mobile/Vulkan post-draw check measured errors below 0.000001 m at cast release/air and breach/lift
- Production rain uses a bounded 256-particle native 3D system: clear weather hides/stops it, rainy clock state emits it, pause freezes its speed and world clock, and resume restores it

### Full production flow

The harness uses the real Main action callbacks, TrialFishery generation, FishingSession equations and SaveStore transactions. It does not reimplement the encounter or fighting algorithm.

- Lobby rejects cast input and hides fishing HUD; real Start opens preparation; real Enter reveals ready-to-cast controls
- Both selected target species are reachable through actual generated starter-gear encounters
- Cast clip length agrees with its 2.2-second presentation gate; lure stays hidden before the 1.2-second release, then follows real world trajectory/line
- Logical wait/bite progression stays held through the full cast presentation; completion is emitted once
- Water/bite camera changes actual Camera3D transform, not a texture or panel position
- Real balanced reeling completes each fight; canceled holds cannot cast or latch reeling
- Successful catch saves immediately and can be recovered from disk while landing is unfinished
- Fish geometry rises from beneath to above the water plane and is lifted toward the character; results wait for the full 3.35-second presentation
- Focus loss, Settings and repeated system Back during both cast and landing freeze stage clocks, world clock, camera, fish and session; resume continues the same identity/presentation
- Duplicate completion during landing and after result cannot re-arm a stuck animation or duplicate history/currency
- Repeated result Back preserves pending record; release restores play without subtracting history; restart preserves pending catches and rejects duplicate settlement

### Native touch acceptance

The 71-check input gate injects actual Viewport ScreenTouch/ScreenDrag plus Android-style `DEVICE_ID_EMULATION` MouseButton/MouseMotion events. Repeated gestures reach the true bottom of bag, catalog, settings and licenses; the final controls are visible, drag does not activate them, and reverse/inertial motion works. Bait is reached by actual swipe rather than `ensure_control_visible`.

The added native-control regression first reproduced unwanted volume edits and dropdown opening during vertical scroll. Final code defers native presses until gesture direction is known. Vertical HSlider/OptionButton swipes neither edit nor leave a held control/popup; genuine slider taps and horizontal drags persist once with balanced drag-start/end; OptionButton taps open; LineEdit taps focus. No input assertion was waived.

### Regression fixes caught independently

- A duplicate already-presented completion re-armed Main's landing flag while Stage's duplicate guard refused playback, leaving no future completion signal. Main now ignores the already-owned catch identity before changing presentation state
- Stage attempted to resume an unassigned fish animation, generating `Animation not found`. Both animator resumes now require a valid assigned animation
- Stage originally read `length_cm`/`length`; the production record contains `length_mm`. The added scale regression requires actual measurement-driven mesh scaling

## Rendered visual review and device limits

Desktop rendered frames must identify renderer/device and capture time. Headless frames are not screenshot proof. Software-Vulkan/llvmpipe images can verify geometry, composition and state visibility; they cannot establish Snapdragon frame rate, Android touch latency, haptics, thermals, battery or long-session memory behavior.

Independent review has inspected authored Blender angler and both fish review images: the angler is fully modeled and rigged; common carp and alligator gar have visibly distinct silhouettes, scales, fins and heads. These asset renders are not misrepresented as final gameplay images. The final production Main capture is in `build/qa3d/final_main/`: **26 actual 720×1280 images**, with native Mobile/Vulkan on Mesa llvmpipe (LLVM 19.1.7, Vulkan 1.4.305). The capture harness performs both production encounters rather than fabricating result pages: carp 31.1 cm / 470 g, gar 126.8 cm / 16.70 kg, each charged, cast, waited, hooked, fought with balanced reeling, saved and landed before its result. Capture metadata records real session/presentation states and persisted catch count. Bag and catalog bottoms are reached by actual ScreenTouch/ScreenDrag input. Rain is captured from the production clock/weather route.

Independent review checked the lobby/preparation, cast pose and tackle, close-water bite, shoulder-view fight, both whole lifted fish and result pages, bottom-of-list controls and rain. The final sky hemisphere/riverbed removes photographed panorama ground from the shore/water, and both species remain identifiable in their actual geometry. The fully rendered final controller/scene is reviewed as a two-species vertical slice, not a claim of all 44 native 3D species.

The first un-warmed lobby screenshot was underlit while the reflection atlas was incomplete. A controlled repeat with unchanged production code and 24 additional actual render frames produced the expected lighting. Final captures include that warmup; the earlier frame is not passed off as a steady-state scene. This is not a measurement of startup latency on Android.

Raw log: `build/qa3d/final_main_capture.log`. Per-image metadata: `build/qa3d/final_main/captures.json`. The only rendered diagnostic retained is the independently isolated upstream seven-texture shutdown warning described below. No rendered ERROR is accepted.

No APK, emulator, physical-phone or published-source acceptance is claimed here.

### Known Godot 4.6.3 Mobile shutdown diagnostic

Actual software-Vulkan captures emit `WARNING: 7 RIDs of type "Texture" were leaked` at engine shutdown. This is **not a clean rendered exit**, and the log is retained rather than filtered. Independent minimal reproduction with only camera, box, procedural sky and ReflectionProbe gives the same warning; removing only the probe gives a clean exit. The upstream [Godot reflection-atlas report #122498](https://github.com/godotengine/godot/issues/122498), checked 2026-10-02, describes the same 4.6/Mobile texture-view/buffer cleanup regression.

A bounded six-cycle create→render→free test in one viewport found **no observed growth**: every post-free sample reported 262,867,200 texture bytes, 279,686,032 video bytes, one resource, one node, and zero orphan nodes. Final shutdown still reported seven, not 42, texture RIDs. These are whole-renderer software-device counters, not a measurement of seven leaked textures' byte size or a long-session Android guarantee. Logs: `build/qa3d/shutdown_probe.log`, `shutdown_no-probe.log`, `shutdown_cycles.log`.

The production quality reflection probe remains enabled. No engine fork, warning suppression, or lower-quality renderer was introduced. This narrow known engine caveat is separate from the clean headless gameplay/data/input gates.
