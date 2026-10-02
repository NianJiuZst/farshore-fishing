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
- Real triangulated water surface uses analytic crossing/phase-warped waves, generated seamless micro-normal textures, Fresnel opacity, sky/local-probe PBR reflection, shoreline foam, and impact wave uniforms
- Fixed pools of 12 soft, irregular mesh wavefronts and 30 ballistic spray droplets bound effect node/allocation growth. Existing rain conditions enable 256 native GPU rain streaks in a camera-local emission volume; pause freezes particle speed and clear weather hides emission.
- A CC0 Poly Haven HDR environment supplies native sky/IBL; CC0 scanned timber albedo/normal/roughness textures supply physically scaled dock detail. Ground and foliage detail remain original procedural shaders. Original branches, leaves, terrain and dock are actual geometry, not backdrop images

No Halyard, Verlet Rope addon, custom SSR plugin, downloaded world mesh, billboard forest/background PNG, account, or network gameplay dependency is included. CC0 texture provenance and hashes are in `docs/ASSETS_3D_ENVIRONMENT_CC0.json`.

## Rendering and verification boundaries

The production renderer is Godot 4.6.3 **Mobile / Vulkan**, with MSAA and native shadows, aligned with the requested high-end Android target. The shaders also compile in Compatibility for diagnostics; that is not the production quality acceptance target. Native Mobile has no built-in SSR or SSAO, and this implementation does not claim otherwise. Reflections come from sky radiance and one local ReflectionProbe, not screen-space reflection.

Desktop captures use the intended Mobile renderer on Mesa lavapipe software Vulkan via `tools/render_godot.py`. They prove the actual rendering path and composition, not Android driver behavior, Snapdragon frame rate, thermal behavior, battery life, or touch feel on the user's phone. No physical-device FPS claim is made.

Independent automated QA checks loaded skeletons, weighted geometry, all advertised clip tracks and movement, timing, exact fish-size conversion, and pause/reset/Back lifecycle. Final visual evidence and current mesh counts are recorded alongside the captures and `game/assets/3d/environment/manifest.json`.

## Rebuild

    blender -b --python tools/art3d/build_environment.py
    godot --headless --path game --editor --import --quit
    python3 tools/render_godot.py --timeout 240 -- --path game --audio-driver Dummy --rendering-method mobile --rendering-driver vulkan --script ../build/stage3d/capture_final.gd

The capture harness is a diagnostic build artifact. The production scene is `game/scenes/fishing_stage_3d.tscn` and its script is `game/scripts/fishing_stage_3d.gd`.

## Known native-engine shutdown warning

Godot 4.6.3 Mobile prints `7 RIDs of type Texture were leaked` after a rendered ReflectionProbe has existed. Independent probe/no-probe tests reproduced 7 versus 0, and six scene create/render/free cycles had stable texture/video memory and no orphan nodes. This matches [Godot issue 122498](https://github.com/godotengine/godot/issues/122498), a reflection-atlas color-view/buffer cleanup defect in the engine. The single persistent stage retains its probe for visual quality. This warning is disclosed, not described as a clean shutdown or an observed per-catch memory leak.

The current authored environment is 1,420,035 triangles in 21 material-group mesh nodes; root-viewport Mobile captures render roughly 4.3–4.5M primitives including shadow/probe passes. These are desktop render counters, not a measured Snapdragon throughput claim.

Final visual captures use only the sky hemisphere of the 2K CC0 HDR panorama for sky radiance and reflection; a native sky shader masks photographed horizon/terrain, and a real3D channel bed sits below the transparent water. `fog_sky_affect=0.08` keeps distance haze from erasing the sky. Native camera flow is 3/4-front lobby → full-body cast → near-shoulder waiting/reeling → surface approach with live underwater fish → size-aware breach/lift. Tackle is synchronized after skeleton updates in `RenderingServer.frame_pre_draw`; an independent rendered test measured line-to-tip error below 0.000001m across casting and lifting.

## Frozen visual evidence

The final stage-only 720×1280 Mobile/Vulkan frames are in `build/stage3d/release_candidate_01_lobby.png` through `release_candidate_10_rain.png` (cast, shoulder wait/reel, underwater approach, full-size gar breach/lift, rain). These are actual native renders, not painted mockups. The dedicated release-candidate log is `build/stage3d/approved_capture.log`; that diagnostic filename is not a claim of user acceptance. Native Main UI captures and the independent six-suite gate are coordinated separately before packaging.
