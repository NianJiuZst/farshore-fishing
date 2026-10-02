# 1.2.0-beta.2 full-world 3D controller and native static-fish navigation

This document describes the combined full-catalog controller and photoreal static UI. The retained 44 species-specific inworld models have their frozen artifact/contact and eight-view evidence; the new static pages use separately generated illustrative artwork. Model and focused UI checks are not a combined release pass. Final aggregate source, render, Android build and device acceptance are recorded separately in `3D_ACCEPTANCE.md` and `ANDROID_3D_BUILD.md`. Earlier two-fish and static-3D-preview checkpoints are historical.

## Native scene and flow

Main creates a real `FishingStage3D` / `Camera3D` behind a transparent 2D icon HUD. It passes the saved region/spot to `set_location` before the stage enters the tree, avoiding a redundant initial world load. Later location refreshes are idempotent. Stage owns the regional environment, authored station, angler, rod, line, float, fish animation and camera.

The real lobby has 开始钓鱼、行囊、图鉴、设置 and no visible cast action. Start leads to preparation, selected location, and five-rod/eight-bait loadout. Travel restores all six original regions and twelve original spots, with the existing discovery/currency unlock requirements. Optional temporary rod borrowing does not change ownership or the saved equipped rod.

Fishing now uses the ordinary `Encounter.generate` path with the actual selected spot, bait and effective gear. The temporary two-species target picker is removed. Old `river_trial` catch locations remain readable through the historical location formatter; new normal-world catches use the original catalog region/spot IDs. Unsupported saved location/gear IDs are preserved and block play instead of being silently rewritten.

The project explicitly uses Android Mobile/Vulkan, with OpenGL fallback disabled. Desktop llvmpipe images are software-render evidence, not Android hardware or frame-rate evidence.

## Complete-model readiness and truthful presentation

`Fish3DRegistry.validate_catalog(catalog, true)` and `FishArtCatalog.load_all(catalog)` must both report success before Main enables Start or the preparation entry action. Direct entry callbacks also enforce content readiness. The final photoreal manifest is required: partial, missing, unknown, duplicate, invalid or hash-mismatched art blocks play. Tests must not set readiness flags or disable the final art requirement to pretend content is complete. The validation contract is documented in `FISH_PHOTO_UI.md`.

All 44 catalog species retain their original IDs and cast eligibility through the original species/spot/salinity/depth/gear/time/weather logic and documented bait balance. The six regions, twelve spots, five rods and eight baits are unchanged. This art update does not add catchable species or migrate data between Android package identities.

Catalog, favorites, species detail, enlarged view, pending-catch thumbnails and the primary catch settlement use `FishArtView`, a native static `TextureRect`/`AtlasTexture`. All 44 images are high-resolution generated photoreal illustrations, not wildlife photographs. Full PNGs remain byte-identical to the approved masters; artist-reviewed alpha bounds plus two pixels of padding crop the display without altering source pixels or body proportions. Views ignore touch input; page scrolling retains ownership. Undiscovered catalog thumbnails use a static silhouette. There is no active `FishModelPreview` on these static pages, no fake swim deformation, and no pinch gesture.

Actual inworld swimming, fighting, breach and lifting continue to use the existing species-specific 3D models and skeletal animation. The retained standalone `fish_preview_3d.gd` component is a historical test/preview utility, documented separately in `FISH_3D_PREVIEW.md`.

The result ruler accepts a general Control. Current `FishArtView.measurement_endpoints()` maps the manifest's reviewed anatomical nose and tail coordinates through the displayed cropped image into global canvas coordinates. Whisker extensions do not inflate length. Right-facing European plaice retains its orientation, with zero at the nose on the right. Image height follows the cropped aspect ratio so the ruler stays close to the fish. The illustration represents the species; the authoritative caught millimeter value remains the unchanged physical game record. Historical 3D-preview tests retain their projected-rest-landmark contract but do not describe the current static settlement.

## Transaction and presentation boundaries

1. Hold charges the authoritative FishingSession; release creates a real encounter and begins a save session. Effective rod reach clamps the charge used by the stage trajectory
2. Main holds Session stepping while the stage's full casting presentation is active, then resumes the existing state machine normally
3. Waiting, nibble, bite and fight remain Session states; stage visuals follow them. A genuine fresh BITE press may continue as held reeling; an input held before BITE cannot auto-hook. Pause during the hook transition clears held input and requires a new press after resume
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
- Current static-fish tests check all 44 catalog/detail/enlarged/catch paths, source/imported-image integrity, proportional crop geometry, anatomical ruler endpoints, right-facing anatomy, barbel exclusion and touch ownership
- The focused all 44 static UI suite passed 1182/1182 at each of 720×1280 and 720×1584; geometry/integrity passed 34/34. Selected seven-species desktop Mobile Vulkan capture passed 280/280 with a clean final exit. These preserved results are in `evidence/1.2.0-beta.2/fish-photoreal/` and do not replace combined regression or phone acceptance
- Retained historical preview/ruler tests still check the standalone 3D model factory and projected endpoints; they are not evidence that current static pages render 3D fish
- The exact final assertion counts, source hashes, aspect ratios and rendered diagnostics belong to `3D_ACCEPTANCE.md`, avoiding stale checkpoint totals here

Rendered production evidence labels its save recipe and renderer. Some captures use an isolated unlocked travel fixture; ordinary catches still come from Encounter and complete FishingSession/SaveStore. Historical seeded catch-detail captures verify presentation only. Neither kind is a user's real catch or Android hardware evidence.

### Historical partial-build review and resolved findings

The early `build/qa3d/full_catalog_preview/` captures were taken while 33 models were missing. They deliberately showed disabled Start and seeded a 718 mm / 3621 g flounder only for detail/result inspection. Those images are historical layout/ruler evidence, not final art or all 44 gameplay proof.

Review caught and fixed dark angler front lighting and a doubled “大个体个体” caption. Those historical software Vulkan inworld captures recorded the independently reproduced upstream seven-Texture-RID shutdown diagnostic documented in `3D_ACCEPTANCE.md`; those exits are not described as warning-free. The later selected-seven static-fish capture has a separate clean final log, with the hidden 3D background disabled during that focused render.

The early animated flounder views exposed a real tail/root attachment defect missed by the static hero. The model was corrected, reimported, and rerendered through the same actual Main path at `build/qa3d/full_catalog_preview_corrected/`. Six transparent swim frames were also checked for disconnected opaque components. No UI mask or PNG substitution was used. The retained inworld model set has separate membrane/ray contact checks across 36 sampled poses and hash-bound eight-view visual signoffs; `catalog_art_freeze.json` identifies that canonical 3D art set. These historical static-preview repairs and evidence remain valid within their original scope. The beta.2 static pages intentionally use the new all 44 generated illustrations, with their own manifest and evidence.
