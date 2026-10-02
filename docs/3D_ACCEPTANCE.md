# 1.2.0-beta.1 full-catalog3D acceptance

## Accepted scope and evidence boundary

The frozen source supports **44 species-specific animated3D fish, six regions, twelve playable spots, five rods, eight baits and31 generated UI icons**, with a fixed rigged human angler. Normal play uses the original full-world Encounter rules. The obsolete two-species/trial-only restriction is removed; historical trial records remain readable.

The current gates below passed on2026-10-02 against runtime freeze **`f722b8f1c7446a6af209c8a5b4b67ad0ff74af26`**, Godot **4.6.3.stable.official.7d41c59c4**. Later documentation, build and QA-tool commits may be included in delivery only when the game input inventory remains identical.

This is source/art, headless native-scene/control integration and **actual desktop Mobile/Vulkan** acceptance. It does not certify APK installation, Android drivers, physical touch/safe areas, frame rate, thermal behavior, battery or a particular phone. The requested target remains the Android16/Snapdragon8Elite class; no phone model is inferred. Package/Android evidence is recorded separately in [ANDROID_3D_BUILD.md](ANDROID_3D_BUILD.md). Historical1.0/1.1 device results are not substituted for this beta.

## Shipped, independently checkable records

The compact [evidence index](evidence/1.2.0-beta.1/index.json) ships in Git and the source package. It contains hashes for every included log, summary, screenshot and source-art record. It links:

- [Complete1044-file runtime SHA256 inventory](evidence/1.2.0-beta.1/runtime_inputs_sha256.json)
- [Baseline full matrix](evidence/1.2.0-beta.1/baseline_summary.json) and [representative tall-layout matrix](evidence/1.2.0-beta.1/tall_summary.json)
- [Independent44-model binary audit](evidence/1.2.0-beta.1/binary_catalog_audit.json)
- [Frozen44-model art/master/review inventory](evidence/1.2.0-beta.1/catalog_art_freeze.json)
- Essential raw logs under `evidence/1.2.0-beta.1/logs/` and five actual Main screenshots with provenance under `screenshots/`

**All1044 runtime inputs were byte-identical before and after both matrices and in the final post-run tree check.** The shared manifest's SHA256 is `5ba36f3c68e4299a188cede2ed8d47c87c682cb6cbd06eb4a2d440c0e037cd53`. The inventory covers project settings, scripts/tests, scenes, catalogs, models, textures/import metadata, fonts, sounds and shaders; generated `.godot` caches and Android/export workspaces are excluded.

Key production hashes:

| Input | SHA256 |
| --- | --- |
| `game/project.godot` | `1f39c3c1de9312e5e0454160285d566a25dc03b76aad54167ba53fe1e65d0c73` |
| `game/scripts/fishing_stage_3d.gd` | `bec25c940ec5f28647f733811565456693b2100145071662049b780290aa265e` |
| `game/scripts/main.gd` | `4d3a635b8350cab87493ec3a77457b43e6145edcdc9cf6c7b151af147ec39ebe` |

## Frozen automated results

Every invocation uses an isolated HOME/XDG data directory. No test overrides Main's44-model readiness flag. Missing assets fail rather than being replaced by another fish. Assertion totals include repeated sample/vertex/control checks, not that many independent human scenarios.

| Headless/native-scene gate | Passed |
| --- | ---: |
| Camera projection, adaptive aspect and requested MSAA |531/531|
| Save/recovery/stress, including10,000 catches and disk roundtrip |314/314|
| Full core with actual Main integration, no `--skip-ui` |182,417/182,417|
| Five-rod/eight-bait data, mechanics and saves |557/557|
| Full-world bait balance/reachability |33,091/33,091|
| Registry with `--require-all` |98/98;44/44 imported|
| Actual3D preview component |25/25|
| Main travel transaction boundaries |24/24|
| All44 native3D rig/gameplay/landing/framing flows |4,405/4,405|
| Production UI/style, safe-inset stress and29 routes |11,950/11,950;253 button visits|
| Production touch with `--require-full` |132/132 baseline;130/130 tall|
| Historical trial adapter/record compatibility |38,082/38,082|
| Human anatomy, skin, grip and animation contract |3,705/3,705|
| Independent raw-GLB gate |44/44; no missing or duplicate geometry failures|

All headless runs exit0 without ERROR/WARNING output. The core's zero-start, release-only progression reaches all44 species and six regions in100 genuine generated/session-resolved catches, buying all rods and required unlocks for exactly3070 coins without a negative balance.

Actual renderer: **Forward Mobile, Vulkan1.4.305, desktop Mesa llvmpipe LLVM19.1.7**, native main-viewport **MSAA_4X**. Both matrices also execute the following with real rendering:

| Actual rendered gate |720×1280|720×1584|
| --- | ---: | ---: |
| Full44 gameplay/rig/landing/framing |4,405/4,405|4,405/4,405|
| UI/style/safe-inset coverage |11,950/11,950|11,950/11,950|
| Real Viewport ScreenTouch/ScreenDrag |132/132|130/130|

Every rendered run exits0 with no assertion or script errors. Each retains the known seven-Texture-RID shutdown warning described below; these are not described as warning-free exits.

## What the integration actually proves

- All44 imported actors contain real meshes, Skin weights, skeletons, required animation clips and live changing bone poses. Species changes instantiate the matching model; millimeter measurements control physical scale. No billboard fish or substitute species is accepted
- The real Main controls generate ordinary full-world encounters, charge and release, complete the2.2-second character cast, wait/nibble, hook, fight, save, breach/lift and show the result. Each matrix completes45 real casts/landings, reaches all44 species and visits all12 spots
- Every species' minimum and maximum catalog lengths pass projected landing mesh-bound checks. The live rod/line attachment is checked against the animated rod tip
- Catch settlement is durable before landing finishes. Reload, retry, repeated completion, repeated Back, background pause and disposition preserve identity/counts and cannot replay rewards. Chinese sturgeon remains observation/release-only; direct sale callbacks are rejected
- Scene rejection cannot persist a false destination. Save failure restores the previous Main/stage location. Landing and unresolved current catches block stale travel callbacks
- All pages retain borderless controls, minimum96-unit targets, contained captions and truthful3D previews. Long-page gestures reach the actual bottom without clicking nested controls. Slider/dropdown taps and horizontal gestures remain usable; vertical swipes do not accidentally edit them

### Edge-to-edge tall layout

Production uses `canvas_items` plus `stretch/aspect="expand"`; both tested physical sizes are also their logical sizes, with no letterboxing. The camera blends its original16:9 vertical angles, converts them to equivalent horizontal angles and uses KEEP_WIDTH. The original baseline projection remains unchanged; taller displays gain vertical space without cropping fish horizontally. See [ADAPTIVE_MOBILE_LAYOUT_QA.md](ADAPTIVE_MOBILE_LAYOUT_QA.md).

The720×1584 test represents a19.8:9 phone aspect, not a verified phone. Projection-only tests also cover1440×3168 and900×1200. Synthetic104px top/80px bottom insets stress layout; they are not real Android DisplayServer measurements. On the taller display, Settings and the unrecorded carp detail can genuinely fit without scrolling: the tests require full visibility and preserved gesture ownership rather than impossible motion. The baseline's overflowing drag requirements remain intact.

## Art and actual Main images

The source-art freeze contains44 GLBs,44 editable fish masters and **352 hash-bound reviewed views**. A separate final check verified all132 GLB/master/review-record hashes against that freeze. The canonical art-set digest is `bd84d91b7ba2fad848954d1add805a7140eb8acb86c8365292c4a211dc86545c`. Geometry uniqueness is only a duplicate guard; the per-species eight-view review and anatomical/contact checks provide the separate visual evidence. Studio renders are not presented as gameplay screenshots.

The shipped Main images are actual framebuffer captures, without image substitution or post-hoc scene masking:

1. [True first-run lake lobby,720×1584](evidence/1.2.0-beta.1/screenshots/first_run_lake_tall/01_first_run_lake_lobby.png): empty isolated save, default starter gear, no seeded unlocks/catches, enabled Start and no Cast action
2. [Norway lobby](evidence/1.2.0-beta.1/screenshots/norway_baseline/01_lobby_norway_start_enabled.png), [actual cast](evidence/1.2.0-beta.1/screenshots/norway_baseline/02_actual_cast_over_shoulder.png), [cod breach](evidence/1.2.0-beta.1/screenshots/norway_baseline/03_actual_cod_breach.png) and [3D result/ruler](evidence/1.2.0-beta.1/screenshots/norway_baseline/04_actual_cod_result_ruler.png),720×1280: explicitly seeded travel/rod ownership, then ordinary Encounter seed42 and a genuinely completed fight producing a612mm/2091g cod

Capture assertions pass5/5 and18/18 respectively. Each image group includes renderer, actual MSAA, physical/logical sizes, source hashes and save/encounter provenance. These fixture catches are not represented as a user's own catch. The ruler follows projected normalized-rest-length landmarks; its stored millimeter measurement is the physical record, not an instantaneous skinned-vertex measurement.

## Known engine diagnostic and remaining device boundary

Rendered tests report `WARNING: 7 RIDs of type "Texture" were leaked` at engine shutdown. The preserved minimal camera/box/sky/probe reproduction shows the same warning; removing the probe removes it. A six-cycle create/render/free probe showed no observed growth in its bounded desktop renderer counters, with zero orphan nodes. These results do not establish long-session Android memory behavior.

The symptom matches the open [Godot reflection-atlas cleanup report #122498](https://github.com/godotengine/godot/issues/122498), rechecked2026-10-02. The quality reflection probe remains enabled; no warning suppression, engine fork, OpenGL fallback or lower-resolution workaround is used. Verbose llvmpipe capture logs additionally show supported RGB8→RGBA8 texture conversion. The final captures have no ObjectDB/resource-in-use error: the capture helper explicitly releases its framebuffer Image before shutdown.

APK signing/ABI/permission/alignment checks, emulator behavior, physical Android safe areas, haptics, sound output and phone performance belong to their separate records. Desktop mouse or injected touch and software-Vulkan timing are not Android certification or an FPS promise.

## Reproduce

Run from the source root with the pinned official Godot and a fresh output directory. The runner supplies isolated per-suite user directories, refuses output reuse, records hashes before/after and fails on changed runtime inputs:

    python3 tools/run_full_catalog_qa.py --output build/qa-baseline --render
    python3 tools/run_full_catalog_qa.py --output build/qa-tall --skip-import --suites camera_aspect,slice3d,ui_style,touch --tall --render

Software-render suites allow a bounded1200-second budget so full44/MSAA/tall/license scrolling is not truncated. A timeout remains an incomplete failed run. Source exports must use isolated copies and separately verified backups; this test runner never exports or reads signing material.

The retired two-fish checkpoint is preserved solely as history in [HISTORICAL_TWO_FISH_ACCEPTANCE.md](HISTORICAL_TWO_FISH_ACCEPTANCE.md). Its old counts and images are not current full-catalog acceptance.
