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

Current logs are under `build/qa3d/`. Final results and rendered review are recorded below when their runs complete.

### Real geometry and animation

- Actual production Main instantiates a Node3D world with active Camera3D, retained environment meshes and authored character
- Actor/fish instances contain real Skeleton3D, imported AnimationPlayer, Skin bind tables, vertex bone-index arrays and nonzero per-vertex skin weights
- Each advertised clip drives at least two actual live skeleton bone poses; key tracks alone are insufficient
- Character: idle/cast/wait/reel/lift. Both fish: swim/struggle/breach/landed
- Actual fishing rod follows the authored right-hand RodSocket; temporary socket fallback fails
- No Sprite3D/AnimatedSprite3D actor/fish substitution; ordinary UI/specimen illustrations remain legitimate 2D assets
- Live fish uses the correct species instance; its scale follows actual production `length_mm` measurements

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

### Regression fixes caught independently

- A duplicate already-presented completion re-armed Main's landing flag while Stage's duplicate guard refused playback, leaving no future completion signal. Main now ignores the already-owned catch identity before changing presentation state
- Stage attempted to resume an unassigned fish animation, generating `Animation not found`. Both animator resumes now require a valid assigned animation
- Stage originally read `length_cm`/`length`; the production record contains `length_mm`. The added scale regression requires actual measurement-driven mesh scaling

## Rendered visual review and device limits

Desktop rendered frames must identify renderer/device and capture time. Headless frames are not screenshot proof. Software-Vulkan/llvmpipe images can verify geometry, composition and state visibility; they cannot establish Snapdragon frame rate, Android touch latency, haptics, thermals, battery or long-session memory behavior.

Independent review has inspected authored Blender angler and both fish review images: the angler is fully modeled and rigged; common carp and alligator gar have visibly distinct silhouettes, scales, fins and heads. These asset renders are not misrepresented as final gameplay images. Final production lobby/prepare/cast/bite/fight/breach/lift/result images must also be reviewed before visual acceptance is marked complete.

No APK, emulator, physical-phone or published-source acceptance is claimed here.
