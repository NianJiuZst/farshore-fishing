# Authored 3D world, fish and equipment presentation

The current approved scope restores all 44 existing catalog fish, the existing 6 regions / 12 spots, five rods and eight baits. Publication waits for every species-specific model and the full runtime acceptance gate; a registry entry is not proof that its model exists. The former two-fish managed-river slice remains in Git/backup history, not a limit on the current runtime.

A shared original Blender world builder creates separate lake, Japanese coast, Norwegian fjord, Mediterranean coast, Mississippi river/wetland and Yangtze river packs. Only the selected region and one appropriate native dock, rock ledge or closed-hull boat are instantiated. Place IDs, ecological routing and restrictions remain the existing catalog's source of truth. No fish is silently replaced by a carp or another species.

## Public interface

`FishingStage3D` is a `Node3D`, attached behind the native Control HUD in the root viewport. It exposes `camera`, `presentation_state`, `cast_in_progress`, `weather`, and `time_of_day`.

- `bind_session(FishingSession)` subscribes to state changes; stage never settles a catch or edits persistent state
- `set_mode("lobby"|"fishing")` selects the presentation; lobby smoothly turns the same grounded rig toward the camera and fishing turns toward the river
- `set_location(region_id, spot_id) -> bool` validates the existing catalog pair and both required packs, works before `_ready`, is idempotent for the current location and refuses travel during active/pause-active fishing or landing
- `set_region(region_dictionary, spot_dictionary)` is a compatibility wrapper around `set_location`
- `location_changed` and `location_error` report selected-location transitions; `location_rebuild_count` makes redundant rebuilds testable
- `set_weather(String)` and `set_time_of_day(String)` change wind, rain emission, sky illumination, light and fog color
- `suspend(bool)` freezes scene time, animation, effects and camera
- `play_landing(record)` starts one 3.35-second landing beat per catch ID
- `cancel_landing()` clears the pending landing beat without emitting its completion signal
- `debug_snapshot()` exposes presentation state and render counters for QA
- Signals: `cast_presentation_finished()` and `landing_finished(record: Dictionary)`

## Timing and lifecycle

The character has a 2.20-second cast clip; line/bobber release is at 1.20 seconds. Native controller gates Session.step while `cast_in_progress`, then resumes core mechanics. Presentation uses real elapsed time, matching AnimationPlayer rather than artificially stretching the visuals on slow frames. Session can independently clamp its game simulation.

Landing is presentation only. The controller settles the catch once immediately, then defers result UI until `landing_finished`. Pause/resume never creates another reward. Closing/back/reset cancels pending presentation. A maximum-size 2.4 m gar has a size-aware pulled-back landing camera. Runtime fish scale is the record's `length_mm / 1000`; imported fish are 1 m long at rest.

## Real geometry and shaders

- Original deterministic Blender environment source: `tools/art3d/build_environment.py`
- Authored bevelled dock planks, inset grains, nails, bearer beams, submerged pilings, round mooring ropes, open bucket, tackle crate, a fishery sign, alluvial banks, branch-built trees, individual curved leaf geometry, reeds/cattails and shoreline stones
- Character GLB has native Skeleton3D, skinned geometry, five clips, and a hand bone-attached RodSocket
- Rod is a tapered dynamic 3D tube with cork grip and metallic reel; line is a light curved tube, not a screen-space stroke
- Fish are species-specific bone-animated GLBs selected through `Fish3DRegistry`, used underwater and in the breach/lift beat; unavailable/invalid IDs produce a visible error and `model_error`, never a substitute fish
- Real triangulated water surface uses analytic crossing/phase-warped waves, generated seamless micro-normal textures, Fresnel opacity, sky/local-probe PBR reflection, shoreline foam, and impact wave uniforms
- Fixed pools of 12 soft, irregular mesh wavefronts and 30 ballistic spray droplets bound effect node/allocation growth. Existing rain conditions enable 256 native GPU rain streaks in a camera-local emission volume; pause freezes particle speed and clear weather hides emission.
- A CC0 Poly Haven HDR environment supplies native sky/IBL; CC0 scanned timber albedo/normal/roughness textures supply physically scaled dock detail. Ground and foliage detail remain original procedural shaders. Original branches, leaves, terrain and dock are actual geometry, not backdrop images

No Halyard, Verlet Rope addon, custom SSR plugin, downloaded world mesh, billboard forest/background PNG, account, or network gameplay dependency is included. CC0 texture provenance and hashes are in `docs/ASSETS_3D_ENVIRONMENT_CC0.json`.

## Rendering and verification boundaries

The production renderer is Godot 4.6.3 **Mobile / Vulkan**, with MSAA and native shadows, aligned with the requested high-end Android target. The original slice was also compiled in Compatibility for diagnostics. The expanded regional shaders are accepted against Mobile / Vulkan; Compatibility is not the current production quality target. Native Mobile has no built-in SSR or SSAO, and this implementation does not claim otherwise. Reflections come from sky radiance and one local ReflectionProbe, not screen-space reflection.

Desktop captures use the intended Mobile renderer on Mesa lavapipe software Vulkan via `tools/render_godot.py`. They prove the actual rendering path and composition, not Android driver behavior, Snapdragon frame rate, thermal behavior, battery life, or touch feel on the user's phone. No physical-device FPS claim is made.

Independent automated QA checks loaded skeletons, weighted geometry, all advertised clip tracks and movement, timing, exact fish-size conversion, and pause/reset/Back lifecycle. Final visual evidence and current mesh counts are recorded alongside the captures and each regional GLB's adjacent JSON manifest.

## Rebuild

    blender -b -t 2 --python tools/art3d/build_environment.py -- --region norway
    blender -b -t 2 --python tools/art3d/build_environment.py -- --station boat
    godot --headless --path game --editor --import --quit
    python3 tools/render_godot.py --timeout 240 -- --path game --audio-driver Dummy --rendering-method mobile --rendering-driver vulkan --script ../build/stage3d/capture_final.gd

The capture harness is a diagnostic build artifact. The production scene is `game/scenes/fishing_stage_3d.tscn` and its script is `game/scripts/fishing_stage_3d.gd`.

## Known native-engine shutdown warning

Godot 4.6.3 Mobile prints `7 RIDs of type Texture were leaked` after a rendered ReflectionProbe has existed. Independent probe/no-probe tests reproduced 7 versus 0, and six scene create/render/free cycles had stable texture/video memory and no orphan nodes. This matches [Godot issue 122498](https://github.com/godotengine/godot/issues/122498), a reflection-atlas color-view/buffer cleanup defect in the engine. The single persistent stage retains its probe for visual quality. This warning is disclosed, not described as a clean shutdown or an observed per-catch memory leak.

Active authored biome geometry after the bounded foliage and cabin pass: lake 1,016,781 triangles; Japan 959,342; Norway 1,084,196; Mediterranean 685,762; bayou 1,353,458; Yangtze 857,632. Dock/rock/boat stations are separate small packs. Original-build manifests are beside each GLB. Sampled Mobile captures rendered roughly 2.2–4.3 million primitives including passes, with 29–52 draw calls depending on location. These are desktop counters, not measured Snapdragon throughput.

Final visual captures use only the sky hemisphere of the 2K CC0 HDR panorama for sky radiance and reflection; a native sky shader masks photographed horizon/terrain, and a real 3D channel bed sits below the transparent water. `fog_sky_affect=0.08` keeps distance haze from erasing the sky. Native camera flow is 3/4-front lobby → full-body cast → a fixed surface-float view through waiting, exploratory taps and committed bites → player-initiated hook/shoulder fight → size-aware breach/lift. Pre-hook camera/FOV, angler wait pose and HUD are identical; species geometry stays hidden until the player hooks. The physical7cm float projects about33.5px high at720px portrait width. Cast landing creates one small thin ripple without oversized spray; post-hook windup visibly loads the rod before a surge. Tackle is synchronized after skeleton updates in `RenderingServer.frame_pre_draw`; an independent rendered test measured line-to-tip error below 0.000001 m across casting and lifting.

## Historical two-fish visual baseline

The earlier stage-only 720×1280 Mobile/Vulkan frames are in `build/stage3d/release_candidate_01_lobby.png` through `release_candidate_10_rain.png` (cast, shoulder wait/reel, underwater approach, full-size gar breach/lift, rain). These are actual native renders, not painted mockups. The dedicated release-candidate log is `build/stage3d/approved_capture.log`; that diagnostic filename is not a claim of user acceptance. Native Main UI captures and the independent six-suite gate are coordinated separately before packaging.

## Five equipment visuals

`set_gear_profile(gear: Dictionary)` accepts the selected catalog gear row, including optional `rod_length` (forward blank meters), `rod_radius` (base radius meters), `rod_color`, `reel_color`, and `grip_color` (HTML colors). It also works before the stage enters the tree. The stable ID supplies a default for every omitted visual field. Power, tolerance, reach, price, and saved gear IDs are never changed by this presentation API.

IDs 0–4 are individually recognizable: original forest/silver, travel blue/brass, deep-water graphite/ice, light-spinning blue/silver/cork, and heavy-casting burgundy/brass/dark grip. The last two colors follow the actual generated equipment icons and catalog overrides. Forward lengths are 2.04, 2.22, 2.42, 1.86 and 2.58 m; base radii are 13, 14, 16, 10.5 and 18 mm. Tapers and trim bindings follow each blank's bend. Right-hand socket, rear grip center `(0,0,0.08)`, rear grip length 0.34 m, and reel center `(0,-0.075,0.05)` stay fixed for all five.

The native Mobile/Vulkan gear gate in `build/stage3d/gear/render_gear_profiles.gd` checks actual mesh lengths, five colors/profile IDs, invariant grips, both hands at cast/reel/lift poses, and frame-post-draw line/tip coincidence. The first geometry gate passed 68/68 with maximum line endpoint error below 0.000001 m. The repeated gate with the final natural-proportion character and actual catalog color overrides also passed 68/68. Its log is `build/stage3d/gear/adult_render.log`; lobby images for all five rods and cast/reel/lift images for rods 3 and 4 are in `build/stage3d/gear/adult_final/`.

## Full-region and size-aware acceptance

`build/stage3d/regions/polished/` contains actual 720×1280 Mobile/Vulkan lobby and fishing views for every existing spot. The final world gate passed 86/86: valid pre-ready selection, all 12 locations, exact biome identity, idempotent refresh, active-cast travel rejection, and capture success. Visual review additionally caught and fixed a reef camera intersecting its lighthouse and a reversed boat-deck winding; structural test totals alone were not treated as visual acceptance.

The stage uses catalog `length_mm` at actual physical scale, divided by the registry's declared model rest length. Wide asymmetric flatfish receive a dorsal-view tilt during landing. Fish below 45 cm get a late optical push-in; their model scales and stored measurements remain unchanged. The separate detail viewport may normalize its display independently. The existing 2.2 s cast / 1.2 s release and 3.35 s landing timing and frame-pre-draw tackle synchronization remain in force.

Shared builder commands, one selected export per invocation:

    blender -b -t 2 --python tools/art3d/build_environment.py -- --region norway
    blender -b -t 2 --python tools/art3d/build_environment.py -- --station boat

The regional terrain, trees, lighthouse, red harbor houses, stone wall, alluvial sandbar and station geometry are original. Native triplanar CC0 rock maps use approximately 2.7 m tiling for individual rocks and 2.1 m for cliffs and regional tint; there is no whole-landscape image backdrop. The HDR shader excludes photographed horizon/ground, and water has a real submerged bed.


The bounded final scenery pass enlarged and densified actual curved leaf/frond geometry, added timber grain, eaves and window/door trim to Norway's cabins, and tightened world-space cliff tiling. A restrained portrait fill affects only the character, preserving world shadow contrast. Rock stations omit the incidental tackle crate and suppress only reed geometry intersecting the near ledge. The final Yangtze cleanup is visible in `build/stage3d/regions/cleared/yangtze_river_{lobby,fishing}.png`; `regions/final/` preserves the before images.

### Atomic travel and exact-size camera checks

- `build/stage3d/regions/atomic_travel_tests.gd`: 12/12 passed. Missing scene paths and instantiated non-Node3D roots are injected deliberately. Rejected transitions preserve the old IDs, definitions, live root identities and rebuild count. Both candidate scenes are validated off-tree before committing a swap.
- `build/stage3d/regions/registry_checks.gd`: 30/30 passed. The exact species registry is used, invalid species produce a visible error, valid loads clear that error, and five rod bindings remain thin local-axis wraps.
- `build/stage3d/regions/render_size_cases.gd`: 38/38 passed in actual Mobile / Vulkan. Physical-scale examples include 180 mm carp and plaice, 850 mm olive flounder, and 2,400 mm gar and Chinese sturgeon. Wide flatfish and both large fish fit the portrait frame. A separate synthetic 100 mm carp fixture tested only camera mathematics and was never presented as whiting evidence.
- `build/stage3d/regions/render_whiting_100mm.gd`: 6/6 passed with the genuine Japanese whiting model at exactly 0.1 m world scale. Its complete model bounds project about 113 pixels wide in the 720-pixel portrait frame. Source SHA-256: `2e69b6b7a03640b5e2d4205d8c3bf6d04e9db87127477e9357e9872071051f31`. Image and JSON report: `build/stage3d/whiting_100mm/`.

The final tackle rerender (`build/stage3d/regions/render_final_tackle.gd`) passed 27/27 with genuine 100 mm whiting, 2,400 mm gar and 2,400 mm sturgeon. Rendered line-to-rod errors were below 0.000001 m and terminal leader errors were below 0.000001 m; all three complete fish bounds remained inside the portrait frame. The final curved sturgeon leader is captured separately by `render_sturgeon_leader.gd`. Images are in `build/stage3d/final_tackle/`. The known seven-texture engine shutdown warning is still disclosed.

The minimum-size pixel review exposed the original oversized float. The final native float is a slender approximately 7 cm body/antenna assembly, with a short explicit leader to the actual-size fish's mouth during landing. Float-eye and leader endpoints use transformed geometry offsets, replacing the old hard-coded line end. The camera close-up retains real physical fish scale. Three measured normalized landmarks cover the two asymmetric flatfish and Chinese sturgeon's ventral mouth (`Vector3(0.321118, -0.025555, 0)`, behind the rostrum). The sturgeon leader passes around the snout rather than through the head; all anatomical offsets scale and rotate with the actual fish. The source-rig measurements are recorded in `ownbuild/fish3d-catalog/mouth_landmarks.json`.

These are stage-specific results, not a claim that all 44 fish models or the complete game have passed publication acceptance. Full-catalog model, ecology, gameplay, input, save and packaging gates are maintained separately by the project owner.
