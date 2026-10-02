# 1.2.0-beta.1 full-world 3D controller and touchscreen navigation

This document describes the full-catalog controller. All 44 species-specific models have passed the frozen artifact/contact and eight-view visual gates. Final source, render, Android build and device acceptance are recorded separately in `3D_ACCEPTANCE.md` and `ANDROID_3D_BUILD.md`; a model pass alone is not a release pass. The earlier playable two-fish checkpoint is preserved in commit history.

## Native scene and flow

Main creates a real `FishingStage3D` / `Camera3D` behind a transparent 2D icon HUD. It passes the saved region/spot to `set_location` before the stage enters the tree, avoiding a redundant initial world load. Later location refreshes are idempotent. Stage owns the regional environment, authored station, angler, rod, line, float, fish animation and camera.

The real lobby has 开始钓鱼、行囊、图鉴、设置 and no visible cast action. Start leads to preparation, selected location, and five-rod/eight-bait loadout. Travel restores all six original regions and twelve original spots, with the existing discovery/currency unlock requirements. Optional temporary rod borrowing does not change ownership or the saved equipped rod.

Fishing now uses the ordinary `Encounter.generate` path with the actual selected spot, bait and effective gear. The temporary two-species target picker is removed. Old `river_trial` catch locations remain readable through the historical location formatter; new normal-world catches use the original catalog region/spot IDs. Unsupported saved location/gear IDs are preserved and block play instead of being silently rewritten.

The project explicitly uses Android Mobile/Vulkan, with OpenGL fallback disabled. Desktop llvmpipe images are software-render evidence, not Android hardware or frame-rate evidence.

## Complete-model readiness and truthful presentation

`Fish3DRegistry.validate_catalog(catalog, true)` must report zero errors before Main enables Start or the preparation entry action. Direct entry callbacks also enforce this gate. During partial development, saved statistics, settings, bag and the archive remain readable. Tests may inspect this disabled state; they must not set the readiness flag to pretend all 44 models exist.

The catalog loses the old two-only/historical distinction. While incomplete, entries accurately distinguish an available model from a model still being prepared. When all models exist, the temporary availability labels disappear. Normal cast eligibility still follows the original species/spot/salinity/depth/gear/time/weather logic and the documented bait balance.

Species detail, enlarged view and the primary catch showcase use one active `FishModelPreview` for the open page: a real species-specific model, weighted animation, transparent private SubViewport3D and its own lights/world. It captures no touch input and uses no ReflectionProbe. Missing models produce an explicit unavailable label, never another species or a flat image pretending to be a model. Atlas/favorites/pending-list thumbnails remain lightweight raster indexes.

The result ruler now accepts a general Control. Real previews provide projected normalized-rest-length endpoints through their current model transform and camera, scaled into global canvas coordinates. The drawn ruler follows those endpoints rather than measuring viewport width. They are rest-length landmarks, not instantaneous skinned-vertex extrema; the saved millimeter measurement remains the physical record. Historical TextureRect callers retain their original alpha-bound implementation.

## Transaction and presentation boundaries

1. Hold charges the authoritative FishingSession; release creates a real encounter and begins a save session. Effective rod reach clamps the charge used by the stage trajectory
2. Main holds Session stepping while the stage's full casting presentation is active, then resumes the existing state machine normally
3. Waiting, nibble, bite and fight remain Session states; stage visuals follow them
4. CAUGHT immediately enters the unchanged transactional settlement, recording the catch/reward/statistics and durable pending disposition before landing animation
5. Only the matching landing completion reveals the result; its disabled action says 起鱼中 during presentation
6. Back/background pauses session, stage and audio. A completed result cannot be re-armed by a duplicate terminal callback
7. Save failures expose the retry path. Exiting after a successful settlement leaves the existing recoverable pending catch. Sell/release commits before resetting the round

## Touch gesture ownership

Every page uses TouchScroll. It sees ScreenTouch/ScreenDrag before nested STOP-filter panels/buttons, uses a 14-logical-pixel directional threshold, directly advances scroll position, provides bounded inertia, and cancels taps after a swipe. Android-emulated mouse events are suppressed for owned gestures.

Native text/dropdown taps receive balanced GUI events only after a tap is recognized. Horizontal HSlider gestures receive balanced native press/motion/release; vertical swipes never press the slider or open a dropdown. Focus loss/page destruction clears a held gesture. The 31 actual generated raster icons retain transparent presentation and minimum 96-logical-pixel action targets.

## Verification layers

- Data/save/mechanics tests cover all five rods and eight baits; the original four bait weights remain unchanged across all 44 definitions
- Production touch tests inject real Viewport ScreenTouch/ScreenDrag events, including emulated-mouse duplicate suppression, native slider/dropdown conflicts and swiping through the real eight-bait list
- Full-world tests must use `--require-full`: no readiness override or partial-development skip can satisfy the release gate
- Preview/ruler tests check the actual 3D model factory and projected measurement endpoints, rather than inferring length from the viewport rectangle
- The exact final assertion counts, source hashes, aspect ratios and rendered diagnostics belong to `3D_ACCEPTANCE.md`, avoiding stale checkpoint totals here

Rendered production evidence labels its save recipe and renderer. Some captures use an isolated unlocked travel fixture; ordinary catches still come from Encounter and complete FishingSession/SaveStore. Historical seeded catch-detail captures verify presentation only. Neither kind is a user's real catch or Android hardware evidence.

### Historical partial-build review and resolved findings

The early `build/qa3d/full_catalog_preview/` captures were taken while 33 models were missing. They deliberately showed disabled Start and seeded a 718 mm / 3621 g flounder only for detail/result inspection. Those images are historical layout/ruler evidence, not final art or all44 gameplay proof.

Review caught and fixed dark angler front lighting and a doubled “大个体个体” caption. Actual software Vulkan retains the independently reproduced upstream seven-Texture-RID shutdown diagnostic documented in `3D_ACCEPTANCE.md`; it is not described as a warning-free exit.

The early animated flounder views exposed a real tail/root attachment defect missed by the static hero. The model was corrected, reimported, and rerendered through the same actual Main path at `build/qa3d/full_catalog_preview_corrected/`. Six transparent swim frames were also checked for disconnected opaque components. No UI mask or PNG substitution was used. All44 current models now have separate membrane/ray contact checks across36 sampled poses and hash-bound eight-view visual signoffs; `catalog_art_freeze.json` identifies the exact canonical art set.
