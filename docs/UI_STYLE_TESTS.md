# Painted, borderless UI integration gate

## Verified result

The current gate instantiates the actual production `res://scenes/main.tscn` at a **720 × 1280 logical viewport**. It loads the shipped content, textures, controls, navigation, session, and SaveStore. No replica interface or replacement gameplay algorithm is used.

On **2026-10-02, 10:12–10:14 UTC**, frozen production commit `334d594a99bd86fed030a344a48125d6c5a0c56f` passed **10,267 / 10,267 assertions**, **26 style routes**, and **220 button visits**, exit 0, with no ERROR/WARNING output. All 25 distinct HD RGBA icon files and twelve spots' retained support textures were checked. The full core suite simultaneously passed **69,160 / 69,160** with `--check-art` and real Main; save passed **314 / 314**. All 41 recorded production/test/scene/project/icon hashes were identical before and after all runs. See `UI_REGRESSION_MANIFEST.json` for exact hashes and log digests. Raw output: `build/ui-style-painted-icons.log`.

 The previous borderless-only baseline was 3,817 assertions / 208 button visits; it did not establish generated-raster completeness or cover the Settings slider target. The expanded gate retains its transparent-style, caption, target, and route checks and adds the raster, compact-HUD, interruption, and active-control contracts below.

This gate is headless source/runtime-control integration. It is **not Android APK, emulator, physical-phone, GPU/rendering, visual-quality, or accessibility certification**. Core gameplay and save suites remain independent requirements.

## Reproduce safely

Run from the repository root after importing assets with the documented Godot 4.6.3 editor:

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

The script refuses to instantiate Main unless HOME and XDG_DATA_HOME are under `/tmp/farshore-ui-style-…`, and Godot's resolved user-data directory is beneath that XDG directory. Main initializes `user://` in `_ready()` before a fixture can be substituted, so every run must use a **fresh** isolation directory. No player's save is read or modified.

The separate fixture uses real SaveStore disk transactions. Its 44 discovery records come from the production encounter generator and are settled/released before all areas, equipment, and six favorites are unlocked. The encounter RNG uses a fixed seed so record-banner visibility and assertion totals are reproducible. Ordinary/protected result pages are reached through actual FishingSession cast/finish signals and Main settlement. Dummy/headless audio prevents device output.

## Generated-raster contract

- Exactly 25 named production icons are required: rod, reel, hook, bag, compass, book, heart, coin, badge, pause, settings, sound, back, arrow, sort, search, release, worm, grain, shrimp, lure, sun, dusk, rain, ruler
- Each actual runtime PNG exists, has distinct source bytes, decodes as RGBA8, and is at least 512 × 512 pixels. It must have >10% transparent space, >2% opaque painted subject, antialiased alpha edges, and transparent corners. These checks reject absent, empty, flattened, or duplicated placeholder files
- The production resolver must return the exact `res://assets/ui/icons/<kind>.png`; the imported texture must retain alpha. `validate_assets()` must accept the complete set
- Runtime ExpeditionArt children must reference a supported, actually loaded PNG. The icon renderer must draw a texture and contain no primitive/vector or SVG fallback. The functional measurement ruler remains allowed to draw actual measurement marks; those marks are not an icon fallback
- OptionButton's live dropdown arrow must be the production scaled/rotated generated-arrow texture, rather than an inherited vector icon
- The unused badge/ruler files remain part of the complete asset set; the decorative badge is forbidden in inspected UI routes. Availability is not misrepresented as every asset being simultaneously displayed
- Selecting each of the four real bait controls changes and persists the selection and updates the HUD to that bait's actual bitmap. Day/dusk/rain changes select the corresponding real condition bitmap
- Pixel/format tests do not prove aesthetic quality or image-generation provenance. Generation prompts, masters, and source SHA-256 evidence are in the three `ASSETS_ICONS_*.json` manifests; visual inspection is separate

## Transparent controls and compact HUD

- Every inspected Button/OptionButton has transparent normal, hover, pressed, hover_pressed, focus, and disabled style boxes. Filled centers, visible borders, visible shadows, and unrecognized textured style boxes fail
- Buttons, editable search, and the volume slider have laid-out targets of at least **96 × 96 logical units**. This is not a claim about physical millimeters or Android density; native popup-menu item dimensions are not certified
- Actions use the production IconAction implementation with a matching visible caption, contained text geometry, and outline/shadow. Icon/caption children ignore pointer input. Catalog species actions may use their own adjacent fish illustration instead of a redundant pictogram
- Disabled actions change icon/caption opacity. Actual viewport mouse movement, press, and release on Settings Back exercise hover/held feedback and the actual navigation callback
- PanelContainer styles stay transparent; large dark ColorRect backplates are rejected. Search may have a functional underline
- The main action stays at the safe bottom-right edge without moving across idle, charging, bite, and fight. Its bitmap changes rod → hook → reel. Secondary navigation occupies the right edge and hides during fight, including after pause/settings/resume. Location/weather stay compact at the top
- Retired English branding and decorative/poetic captions are rejected in every inspected label. Functional game title, legal/source credits, conservation guidance, and concise control explanations remain allowed

Progress bars/sliders, measurement marks, scenery/specimen artwork, and light full-screen menu surfaces remain legitimate functional elements. No broad rule suppresses errors or bypasses a failed style assertion.

## Actual control and interruption coverage

- Repeated system Back opens/closes pause from idle without a stale overlay
- Casting, waiting, nibble, bite, and fight each pass through pause → real Settings action → real sound/vibration toggle and volume completion callbacks → real visible Back. Paused Main updates cannot advance encounter state or world time. Exact encounter identity/individual are retained, and held reel input is released
- Catalog search, region/discovery selection, sort, species detail, zoom, and Back use their live production controls/signals. Search filters an exact scientific name; empty results show the real hint; region counts match the production catalog; discovery filters and sorting survive rebuilding; nested Back preserves the query
- Repeated result Back retains the exact pending record and cannot duplicate historical counts/currency. Real ordinary/protected release controls remain in the viewport and settle through their production callbacks
- Protected result text has no misleading sale instructions, and its footer explicitly says `放归后保留图鉴与纪录`

The catalog OptionButton selection tests emit the actual controls' selection signals after setting their value; they do not claim native popup-pointer coverage. The settings and catch tests emit real controls' callbacks; only the explicitly identified Settings Back test uses native viewport mouse input.

## Route inspections

The style walker visits 26 route/state combinations: fishing idle; starter home/pause/travel/gear/catalog/favorites/settings/licenses/empty-pending; undiscovered protected species; fully discovered travel/gear/catalog/favorites; discovered species and zoom; active filtered catalog; ordinary/protected result and pending pages; charging/bite/fight/escape. There are 220 button visits, not 220 unique controls or independent scenarios. Repeated per-label/per-asset/per-state assertions must not be presented as independent scenarios.

## Regressions found during this revision

- Replaced the old hardcoded lure expectation with the selected production bait and exercised all four real selection controls
- Core's actual Main integration exposed orphan result Labels when there was no new-record ribbon. The UI owner changed allocation to happen only when attached; the full core rerun then exited cleanly
- The old gate did not inspect HSlider target size. The expanded gate caught the 70-unit volume target; the UI owner increased it to 96, and the full gate passed without reducing the assertion
- A rendered review found white support rectangles from draw-local texture lifetimes. Production retains `shore_support`; all twelve real spots now retain the intended PNG across redraw frames with a valid RID. Appearance still relies on the separate rendered review
- Earlier baseline repairs remain covered: 88-unit discovery-filter width, a cast caption extending outside its target, and inherited opaque hover_pressed styles

Actual screenshots and scenic/contact-plane inspection are documented separately by the UI author. Headless results are not screenshot evidence and do not imply Android compatibility.
