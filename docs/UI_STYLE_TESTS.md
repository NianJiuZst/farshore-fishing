# Native-3D lobby and borderless UI integration gate

## Full-catalog status

The current suite requires all44 imported species-specific models and Main's real content gate before testing playable pages; it never overrides readiness. It has been adapted to31 generated icons, eight baits, exactly one active biome/station after actual travel, and real species-specific detail/zoom/result previews. Borderless styles,96-unit minimum targets, caption containment, all page controls and interruption checks remain mandatory.

During development, the31-icon source/alpha/binding checks passed, but the production-page run correctly failed at the missing imported-model dependency (`509/510`; full pages **NOT RUN**). Log: `build/full-catalog-checkpoint/ui_style_full_gate.log`. This is not a full pass. Rerun the entire suite after final44 imports and freeze.

## Historical two-fish verified result

On **2026-10-02 at 12:34 UTC**, the actual production `res://scenes/main.tscn` passed **10,839 / 10,839 assertions**, **28 routes**, **215 button visits**, exit 0, with no ERROR/WARNING output. The logical viewport is **720 × 1280**. Log: `build/qa3d/ui_style.log`. This final pass used frozen production commit `c931215`; all 387 recorded game source/content/art files were unchanged during the six-suite run.

This is production source/control integration, not a replica screen. It is headless and does not certify Android, Vulkan rendering, actual screenshot appearance, device performance, physical target size or accessibility. Rendered evidence belongs in `3D_ACCEPTANCE.md`; real synthesized touchscreen gestures belong in `touch_scroll_tests.gd`.

The historical painted-2D checkpoint was 10,267/10,267, 26 routes and 220 button visits on commit `334d594a99bd86fed030a344a48125d6c5a0c56f`. Its frozen evidence remains in `UI_REGRESSION_MANIFEST.json`. It is not presented as a test of this 3D revision.

## Reproduce safely

After importing assets in Godot 4.6.3, run from the repository root:

```sh
D=$(mktemp -d /tmp/farshore-ui-style-XXXXXX)
mkdir -p "$D/home" "$D/data" "$D/config" "$D/cache"
HOME="$D/home" XDG_DATA_HOME="$D/data" XDG_CONFIG_HOME="$D/config" \
XDG_CACHE_HOME="$D/cache" godot --headless --audio-driver Dummy --path game \
  --script res://tests/ui_style_tests.gd > "$D/output.log" 2>&1
R=$?
cat "$D/output.log"
printf 'Saved log: %s/output.log\n' "$D"
exit "$R"
```

The script refuses non-isolated HOME/XDG_DATA_HOME. Main initializes `user://` before its SaveStore fixture is installed, so each run needs a fresh directory. The fixture uses real disk transactions and production-generated 44-species observations. It settles/releases those observations, unlocks the retained legacy collection, and installs six favorites. Fixed production RNG seeds stabilize record banners and totals. Counts include repeated assertions and button visits, not that many independent scenarios.

## Preserved control and asset contracts

- All31 required HD RGBA icon sources exist and have distinct bytes, at least 512×512 dimensions, transparent cutout space/corners, painted pixels, and antialiased alpha edges
- The production resolver loads the exact icon PNG and retains alpha; actual bindings, condition/bait icons, and generated OptionButton arrows are checked
- The icon renderer uses texture drawing without primitive/vector or SVG substitutes; measurement marks remain valid functional geometry
- All inspected Button/OptionButton states, including hover_pressed, remain transparent; opaque card centers, visible borders/shadows, and dark rectangular backplates fail
- All buttons, search fields and the actual settings volume slider have targets at least 96×96 logical units
- Live production IconAction controls have matching, contained visible captions with outline/shadow; icon/caption children do not steal input
- Fish catalog buttons may use their adjacent specimen illustration. Current action controls use real icons; no text-only exception was introduced
- Disabled controls change caption/icon opacity. Native viewport mouse input on Settings Back checks hover, held feedback, transparency and its navigation callback
- Retired decorative branding/poetic captions fail; functional title, source/legal credits and conservation instructions remain allowed

## Native-3D contract adaptations

The startup route is now a real lobby with no visible cast action. The suite inspects that lobby and its preparation page before using `_enter_fishery()` to exercise fishing controls. Navigation later re-enters through the same production route instead of bypassing the lobby by mutating mode.

The retired `SceneryView.shore_support`/twelve painted-background assertions were replaced with actual Node3D/Camera3D/retained-MeshInstance3D checks. Every populated active mesh has a valid rendering RID. Static meshes remain owned across ordinary frames; animated rod/line retain stable nodes and valid current meshes while their intended curved geometry is rebuilt at frame_pre_draw; only currently hidden, lazily generated geometry may omit a mesh. Actual travel then replaces the current biome/station, leaving exactly one of each and no old hidden region. Presentation-only scene calls cannot overwrite the stored location. Detail, zoom and result each require one real animated species-specific3D preview that does not steal touches. Sprite3D/AnimatedSprite3D actor substitutes fail. Full skin-weight, bone-pose, animation and moving-camera evidence is in `slice3d_tests.gd`.

The primary fishing action retains its bottom-right geometry across charge/bite/fight and changes rod→hook→reel. Compact top HUD and right-edge secondary navigation remain checked. Navigation hides during fight, including after pause/settings/resume.

## Actual controls and interruptions

- All eight live bait actions update/persist selection and bind the matching HUD bitmap
- Day/dusk/rain updates choose the correct real condition asset
- Repeated idle system Back opens/closes pause without stale overlays
- Cast/wait/nibble/bite/fight each visit pause→Settings→real sound/vibration/volume callbacks→visible Back; exact encounter identity and progress survive, clocks stay frozen and held reel input clears
- Actual catalog search, region/discovery filters, sorting, species detail, zoom and Back preserve state; exact scientific-name search and empty-result guidance are checked
- Actual ordinary and protected catch signals save first, leave the result hidden during landing, then show it after the real stage clock completes
- Repeated result Back preserves pending record/count/currency; actual release controls remain inside the viewport and settle through production callbacks
- Protected result copy contains no sale instruction and explicitly states `放归后保留图鉴与纪录`

Controls' production signals are used for most callbacks. Only the identified Settings Back feedback test injects native mouse input here. This suite does not claim to verify ScreenTouch/ScreenDrag, inertia, gesture cancellation or bottom-of-list reachability; the separate production touch suite is mandatory for those.

## Routes

Lobby, preparation, fishing; starter home/pause/travel/gear/catalog/favorites/settings/licenses/empty-pending; undiscovered protected species; discovered travel/gear/catalog/favorites; discovered species and zoom; active filtered catalog; ordinary/protected result and pending; charge/bite/fight/escape.

No failed functional style assertion was waived to obtain the 3D pass. Current changes replace obsolete two-fish/retained-world assumptions with actual full-world routing and one loaded region, retaining lobby/preparation routes and all active control, layout, caption, input and persistence checks. Historical passing counts above must not be used as current full44 acceptance.
