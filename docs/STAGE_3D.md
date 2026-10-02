# Authored 3D stage: Riverbend managed fishery

This is a fixed-location 3D vertical slice. The location is a fictitious managed Mississippi oxbow fishery, displayed in the game as 河湾试钓场. It is not an assertion that alligator gar occur naturally in Asia. Biological IDs remain `common_carp` and `alligator_gar`.

## Public interface

`FishingStage3D` is a `Node3D`, attached behind the native Control HUD in the root viewport. It exposes `camera`, `presentation_state`, `cast_in_progress`, `weather`, and `time_of_day`.

- `bind_session(FishingSession)` subscribes to state changes; stage never settles a catch or edits persistent state
- `set_mode("lobby"|"fishing")` selects the presentation; lobby smoothly turns the same grounded rig toward the camera and fishing turns toward the river
- `set_region(region, spot)` is a compatibility no-op: there is only one authored scene in this slice
- `set_weather(String)` and `set_time_of_day(String)` change wind and physical sky/light/fog color
- `suspend(bool)` freezes scene time, animation, effects and camera
- `play_landing(record)` starts one 3.35-second landing beat per catch ID
- `cancel_landing()` clears the pending landing beat without emitting its completion signal
- `debug_snapshot()` exposes presentation state and render counters for QA
- Signals: `cast_presentation_finished()` and `landing_finished(record: Dictionary)`

## Timing and lifecycle

The character has a 2.20-second cast clip; line/bobber release is at 1.20 seconds. Native controller gates Session.step while `cast_in_progress`, then resumes core mechanics. Presentation uses real elapsed time, matching AnimationPlayer rather than artificially stretching the visuals on slow frames. Session can independently clamp its game simulation.

Landing is presentation only. The controller settles the catch once immediately, then defers result UI until `landing_finished`. Pause/resume never creates another reward. Closing/back/reset cancels pending presentation. A maximum-size 2.4m gar has a size-aware pulled-back landing camera. Runtime fish scale is the record's `length_mm / 1000`; imported fish are 1m long at rest.

## Real geometry and shaders

- Original deterministic Blender environment source: `tools/art3d/build_environment.py`
- Authored bevelled dock planks, inset grains, nails, bearer beams, submerged pilings, round mooring ropes, open bucket, tackle crate, a fishery sign, alluvial banks, branch-built trees, individual curved leaf geometry, reeds/cattails and shoreline stones
- Character GLB has native Skeleton3D, skinned geometry, five clips, and a hand bone-attached RodSocket
- Rod is a tapered dynamic 3D tube with cork grip and metallic reel; line is a light curved tube, not a screen-space stroke
- Both fish are actual bone-animated GLBs, used underwater and in the breach/lift beat
- Real triangulated water surface uses analytic crossing/phase-warped waves, normal derivatives, Fresnel opacity, sky/local-probe PBR reflection, shoreline foam, and impact wave uniforms
- Fixed pools of 12 mesh ripples and 30 ballistic spray droplets bound effect node/allocation growth
- Original procedural wood, ground and foliage shaders add material detail without imported photograph backdrops

No Halyard, Verlet Rope addon, custom SSR plugin, downloaded scene assets, billboard forest/background PNG, account, or network gameplay dependency is included.

## Rendering and verification boundaries

The production renderer is Godot 4.6.3 **Mobile / Vulkan**, with MSAA and native shadows, aligned with the requested high-end Android target. The shaders also compile in Compatibility for diagnostics; that is not the production quality acceptance target. Native Mobile has no built-in SSR or SSAO, and this implementation does not claim otherwise. Reflections come from sky radiance and one local ReflectionProbe, not screen-space reflection.

Desktop captures use the intended Mobile renderer on Mesa lavapipe software Vulkan via `tools/render_godot.py`. They prove the actual rendering path and composition, not Android driver behavior, Snapdragon frame rate, thermal behavior, battery life, or touch feel on the user's phone. No physical-device FPS claim is made.

Independent automated QA checks loaded skeletons, weighted geometry, all advertised clip tracks and movement, timing, exact fish-size conversion, and pause/reset/Back lifecycle. Final visual evidence and current mesh counts are recorded alongside the captures and `game/assets/3d/environment/manifest.json`.

## Rebuild

    blender -b --python tools/art3d/build_environment.py
    godot --headless --path game --editor --import --quit
    python3 tools/render_godot.py --timeout 240 -- --path game --audio-driver Dummy --rendering-method mobile --rendering-driver vulkan --script ../build/stage3d/capture_final.gd

The capture harness is a diagnostic build artifact. The production scene is `game/scenes/fishing_stage_3d.tscn` and its script is `game/scripts/fishing_stage_3d.gd`.
