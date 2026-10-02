# 1.2.0 full-world 3D controller and touchscreen navigation

This document describes the full-catalog integration in progress. Release remains blocked until all 44 species-specific models and the complete acceptance checks are ready. The earlier playable two-fish checkpoint is preserved in commit history; it is not the full-catalog release.

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

## Verification state

- The bounded five-rod/eight-bait checkpoint passed 381/381 focused data/save/mechanics tests and 120/120 production touch/controller checks, including actual casts
- Full-world bait overrides subsequently pass 557/557 focused data/save/mechanics checks. Original four bait weights remain unchanged across all 44 definitions
- The restored full-world Main currently passes 120/120 **partial-development** UI/touch checks, including disabled entry, no gate override, and archive/bag/travel browsing. Full gameplay assertions are intentionally deferred until all 44 resources exist
- Main's actual 3D preview factory plus the projected ruler passes 17/17 component/touch assertions
- Logs are under `build/qa3d/full_catalog_touch_partial.log`, `preview_ruler_integration.log`, and `build/tackle_expansion/full_world_tackle_tests.log`

Final release testing must run the production touch suite with `--require-full`; that mode fails while any model is missing. A partial check is not a full gameplay pass. Rendered production UI evidence uses an isolated, explicitly seeded historical save and does not override the Start gate; the seed and actual renderer are printed in its log.

### Production partial-build image review

`build/qa3d/full_catalog_preview/` contains three actual 720×1280 Mobile/Vulkan 1.4.305 desktop llvmpipe images: the revised-angler lobby with disabled Start, a reviewed olive-flounder detail page, and its 3D catch-result/ruler page. The latter two use an explicitly seeded isolated historical test record (718 mm / 3621 g, Japan reef); they are not a claim that a user caught that fish or that full44 gameplay is ready. The readiness gate stayed false with 33 missing models, and disposition cleared the seeded pending record normally. Detail/result fit and the ruler follows projected specimen endpoints.

The review identified dark face/front lighting in the lake lobby; this was sent to the stage owner for a bounded lighting pass. It also caught the pre-existing doubled “大个体个体” result caption, corrected in Main by removing an existing suffix before appending it. The image predates that text-only correction. The capture completed without script/ReflectionProbe errors but emitted seven Texture RID warnings at process exit; retain this explicit cleanup caveat for final QA rather than calling the run warning-free.

The parent review subsequently found animated fin/body gaps in the seeded olive-flounder detail/result (dorsal and tail seams), despite the static hero having passed. Those exact fish screenshots are withheld from user delivery and are **layout/ruler evidence only**, not approved final fish-art evidence. The model pipeline owner is correcting attachment weights. Keep `build/qa3d/capture_partial_catalog_ui.gd` unchanged for a like-for-like rerender after the corrected GLB is imported; no UI mask or PNG fallback was added.
