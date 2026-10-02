# Five rods and eight baits: bounded loadout checkpoint

This checkpoint expands loadout choices without resetting the existing game data. The later 44-species 3D conversion is a separate, unfinished release gate; this document does not claim that conversion is complete.

## Appended options

The original gear IDs 0/1/2 and their entire dictionaries, including prices 0/180/480, remain unchanged. Gear 3 is 轻岚 · 灵敏纺车竿: price 100 existing travel coins, retrieve power 1.24, tension tolerance 1.08, reach 90%, depth 25 m. Gear 4 is 重潮 · 巨物枪柄竿: price 320 existing travel coins, power 1.58, tolerance 1.75, reach 92%, depth 90 m. The original deep rod retains its greater 100% reach and 180 m depth.

These are tradeoffs, not five labels for identical stats. Session uses the selected rod's power/tolerance; Main clamps actual casting charge and the stage's cast trajectory to its reach. With the same controlled test fish and reeling policy, simulation fight times differ. The light rod retrieves faster while held but raises tension faster; it is not promised to finish every fight faster than the more forgiving travel rod.

Stage `set_gear_profile` receives real blank length, taper radius and material colors. New rod 3 has a short/thin blue blank, silver reel and pale cork grip; rod 4 has a longer/thicker burgundy blank, brass reel and dark grip, aligned with the generated UI icons. Hand/reel attachment positions remain fixed. These are geometry/material variants of the real 3D rod, not a 2D overlay.

Baits retain worm/grain/shrimp/lure in their original order. Appended choices are sweetcorn (甜玉米), dough (面团饵), cut_fish (鱼肉块), and spinner (旋转亮片). All eight are free unlimited refills. No currency type, consumable purchase or payment was added.

The two-species trial has explicit species-dependent game-balance weights owned by `trial_fishery.gd`. For the unchanged 44 historical fish definitions, Catalog maps the additions to grain/grain/shrimp/lure categories. Encounter consumes those category weights while recording the actual selected new bait ID. The four old bait weights and all fish JSON definitions remain unchanged. These are game balance choices, not measured feeding probabilities.

## Temporary trial borrowing

Unowned rods expose a transparent “试钓借用” action. Borrowing is stored only as Main's runtime override; it does not spend coins, add ownership, change the saved equipped rod, or fake an unlock. Real encounters and fight mechanics use the borrowed rod. Preparation names the borrowed rod and offers “使用已装备钓竿” to restore the saved one. Restarting the app drops the temporary choice. An explicit existing purchase/equip action still commits normally and clears borrowing.

The bag shows all rods' retrieve/tolerance/reach/depth values. Bait and rod actions retain at least 96 logical-pixel touch targets and generated transparent icons. The original 25 raster icons are retained; six independently generated 1024×1024 RGBA assets are added: sweetcorn, dough, cut_fish, spinner, rod_spinning, rod_heavy. Asset provenance and small-size checks are in `ASSETS_ICONS_EXTRA_TACKLE.json`.

## Save compatibility

SaveStore already validates gear IDs as nonnegative bounded integers and requires the selected gear to appear in owned_gear. It has no maximum-2 restriction. Bait IDs use the existing safe-ID validator. No SaveStore/schema changes were necessary. The extension preserves the first three gear dictionaries and all six regions/twelve spots.

The focused save test seeds and releases all 44 species, sets old gear/selection/unlocks/favorites, reloads it, adds IDs 3/4 and spinner, and reloads again. The original archive survives semantically intact. New catches preserve equipment 4 and all eight actual bait IDs, adding eight catches to the existing archive rather than resetting it.

## Verification

- `res://tests/tackle_tests.gd`: 381/381 data, category weighting, real Session mechanics, and save-roundtrip assertions
- `res://tests/touch_scroll_tests.gd -- --production`: 120/120 actual Viewport ScreenTouch/ScreenDrag/controller assertions
- Expanded bag reaches 2393/2393 logical pixels through real touch gestures
- Every one of the eight bait buttons is reached with repeated touch swipes, tapped, and persisted exactly once, including Android-emulated mouse events
- All five temporary rods drive real casts, reach clamps, fight parameters and 3D profile IDs while the saved ownership/equipped rod/currency remain unchanged
- Existing native slider/dropdown gesture cancellation, landing settlement idempotency and menu navigation assertions remain included

Run under isolated `/tmp/farshore-*` HOME/XDG paths. Logs are `build/tackle_expansion/tackle_tests.log` and `touch_expanded.log`. These are logic/input checks, not Android device or frame-rate claims. Release remains held for the separately authorized character and full-44-species work.
