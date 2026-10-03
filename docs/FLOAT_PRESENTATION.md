# 3D antenna float and readable waterline

The observation float is a modeled, shotted antenna float, built by `FishingStage3D._build_bobber()`. It has a shaped lacquered balsa body, carbon keel, upper/lower ferrules, whipping, a stainless lower line eye, a rounded antenna tip, and ten solid cylindrical paint bands. It is not an image, billboard, glowing marker, or set of scaled ball sprites.

## Physical scale and signal mapping

- Local y=0 is the neutral waterline. The sight tip reaches +0.114m; the balsa body occupies −0.089 to −0.018m; the carbon keel reaches −0.156m; the line eye is centered at −0.161m
- The fixed observation view uses the existing43° reference vertical field of view and the existing cast-camera offset. At720px viewport width, the neutral antenna projects to53.458px. The same horizontal field of view gives the same scale at720×1280 and720×1584
- `float_lift` raises the float by up to0.09m, revealing lower paint bands, the shoulder and part of the buoyant body
- `float_dip` lowers it by up to0.18m. A full dip puts the entire tip more than4cm under the current waterline
- `float_drag` and `float_current` move its water-plane position in meters. Travel turns the stem toward its direction and gradually tightens the real line. A small lit meniscus follows the actual shaft/surface intersection; a subtle wake follows measured lateral movement and stops when movement stops
- The line terminates at the lower modeled eye. A short leader continues from that eye to the anatomical mouth landmark during landing. The landing offset preserves clearance for the longer float and keeps the existing sturgeon snout guide

`float_lacquer.gdshader` gives paint and wood physically lit roughness, metal and clearcoat responses. The fine markings fade through2–30mm of water and disappear below that, instead of remaining as a uniformly bright submerged silhouette through the existing transparent river. This is a narrow-object visibility approximation for the game, not a measured model of water turbidity. Cast and landing disable it and show the complete float.

## Determinism and camera contract

The stage consumes the session's continuous float values. There is no extra `_time`-based vertical drift or tilt. Water uses the authoritative `float_clock` while observing, and the float samples the exact analytic displacement function from `river_water.gdshader` at its current x/z location. The module's generic `float_water_height` is not added on top of that wave. As with the existing river, the actual water mesh rasterizes that analytic wave over its fixed grid.

WAITING, NIBBLE and BITE share exactly the same camera transform and field of view. No hidden state transition changes the angler animation, loads or reveals a fish, creates a ripple/splash, or produces a UI marker. The small cast ring remains a cast effect. Pausing freezes the observation.

## Verification

- `game/tests/float_observation_tests.gd`:86/86 checks after the float material change. Covers exact observation-camera invariance, tip projection at both aspect ratios, real geometry, body below neutral waterline, lift/sink/lateral motion, submerged-tip attenuation, wave alignment, no presentation-clock wobble, no stationary wake, pause/resume, hidden fish, minimum/maximum landing framing and anatomical leader endpoints
- `game/tests/camera_aspect_tests.gd`:531/531 mathematical projection checks
- `tools/capture_float_presentation.gd` renders the real Main/Session/Stage with selected seeded common-carp encounters. It finds genuine lift, sink, lateral travel and soft-take sequences; captures quiet/wave/contact/held-motion views; records unchanged observation cameras; and can write8fps sampled frames with `--video`
- Rain-lighting images hold a genuine encounter snapshot and change only the stage weather to isolate readability. They are not rain-encounter balance tests

The initial native render in `build/float-presentation/` was a provisional visual checkpoint. It predates the underwater attenuation and the final core/angler integration; its source hash check correctly reported changes during capture. It must not be used as final release evidence. Final native evidence is recorded separately after integration.

All native captures use actual Godot4.6.3 Mobile rendering with Mesa lavapipe Vulkan on the desktop. They are not Android-device, phone frame-rate, heat, battery or touch-feel certification.
