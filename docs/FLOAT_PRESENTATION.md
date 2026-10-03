# 3D antenna float and readable waterline

The observation float is a modeled, shotted antenna float, built by `FishingStage3D._build_bobber()`. It has a shaped lacquered balsa body, carbon keel, upper/lower ferrules, whipping, a stainless lower line eye, a rounded antenna tip, and ten solid cylindrical paint bands. It is not an image, billboard, glowing marker, or set of scaled ball sprites.

## Physical scale and signal mapping

- Local y=0 is the neutral waterline. The sight tip reaches +0.114m; the balsa body occupies −0.089 to −0.018m; the carbon keel reaches −0.156m; the line eye is centered at −0.161m
- The fixed observation view uses the existing 43° reference vertical field of view and the existing cast-camera offset. At 720px viewport width, the neutral antenna projects to 53.458px. The 11.2mm painted sight tube projects to 3–4px width at 450px display width, a deliberate visibility accommodation. The same horizontal field of view gives the same scale at720×1280 and720×1584
- `float_lift` raises the float by up to 0.09m, revealing lower paint bands, the shoulder and part of the buoyant body
- `float_dip` lowers it by up to 0.18m. A full dip puts the entire tip more than 4cm under the current waterline
- `float_drag` and `float_current` move its water-plane position in meters. Travel turns the stem toward its direction and gradually tightens the real line. A small lit meniscus follows the actual shaft/surface intersection; a subtle wake follows measured lateral movement and stops when movement stops
- The line terminates at the lower modeled eye. A short leader continues from that eye to the anatomical mouth landmark during landing. The landing offset preserves clearance for the longer float and keeps the existing sturgeon snout guide

`float_lacquer.gdshader` gives paint and wood physically lit roughness, metal and clearcoat responses in the opaque depth-writing pipeline. Painted sections have no overlapping ivory core; this prevents transparent sorting from hiding their colors. The fine markings lose color contrast through 2–30mm of water and disappear below that, instead of remaining as a uniformly bright submerged silhouette through the existing transparent river. This is a narrow-object visibility approximation for the game, not a measured model of water turbidity. Cast and landing disable it and show the complete float.

## Determinism and camera contract

The stage consumes the session's continuous float values. There is no extra `_time`-based vertical drift or tilt. Water uses the authoritative `float_clock` while observing, and the float samples the exact analytic displacement function from `river_water.gdshader` at its current x/z location. The module's generic `float_water_height` is not added on top of that wave. As with the existing river, the actual water mesh rasterizes that analytic wave over its fixed grid.

WAITING, NIBBLE and BITE share exactly the same camera transform and field of view. No hidden state transition changes the angler animation, loads or reveals a fish, creates a ripple/splash, or produces a UI marker. The small cast ring remains a cast effect. Pausing freezes the observation.

## Verification

- `game/tests/float_observation_tests.gd`: 90/90 checks after the float material change. Covers exact observation-camera invariance, tip projection at both aspect ratios, real geometry, body below neutral waterline, lift/sink/lateral motion, submerged-tip attenuation, wave alignment, no presentation-clock wobble, no stationary wake, pause/resume, obsolete-fight-wave reset, hidden fish, minimum/maximum landing framing and anatomical leader endpoints
- `game/tests/camera_aspect_tests.gd`: 531/531 mathematical projection checks
- `tools/capture_float_presentation.gd` renders the real Main/Session/Stage with selected seeded common-carp encounters. It finds genuine lift, sink, lateral travel and soft-take sequences; captures quiet/wave/contact/held-motion views; records unchanged observation cameras; and can write 20fps sampled 450×990 frames with `--video`
- Rain-lighting images hold a genuine encounter snapshot and change only the stage weather to isolate readability. They are not rain-encounter balance tests

The initial native render in `build/float-presentation/` was a provisional visual checkpoint. It predates the underwater attenuation and the final core/angler integration; its source hash check correctly reported changes during capture. It must not be used as final release evidence. The corrected material smoke in `build/float-material-smoke/` completed with unchanged source hashes: native pixels show all paint bands, a fully disappeared sunk tip, intact character materials and ready water normals. The smoke uses explicit float geometry fixtures. The longer genuine-encounter movie is recorded separately after integration.

All native captures use actual Godot 4.6.3 Mobile rendering with Mesa lavapipe Vulkan on the desktop. They are not Android-device, phone frame-rate, heat, battery or touch-feel certification.

## Final native movie and fast recasts

The reviewed 27.1s float-only movie and selected full-resolution stills are preserved in `docs/evidence/1.2.0/float-presentation/`. Its four selected encounter excerpts are explicitly separated by cuts; no hidden-state label is drawn into the game. Each contact/take/return excerpt is continuous. The artifact manifest records dimensions,20fps sampling,542frames and SHA-256. The independent reviewer passed contact-versus-held-soft timing at native 450px width, including every 0.05s sample around the soft transition.

The initial combined movie revealed a real fast-recast framing defect: immediately dismissing a failed take or releasing a catch and charging for only 50–150ms retained the old close camera, hiding the angler during windup. `_begin_cast` now establishes the existing authored fishing camera at the explicit cast action. The water observation camera is unchanged. `fast_recast_camera_tests.gd` exercises actual Main dismissal/disposal actions, a genuine successful catch and short charging gestures: 12/12 pass. The 90-check float observation suite also passes after the fix. The float movie's original stage hash is deliberately kept as capture provenance; the later cast-only fix is disclosed in its manifest.
