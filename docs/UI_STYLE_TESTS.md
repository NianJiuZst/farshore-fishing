# Borderless UI integration gate

## Verified result

On 2026-10-02 at 09:41 UTC, Godot 4.6.3 ran the actual production scene at a **720 × 1280 logical viewport** against UI source commit `8465dde`:

```text
UI_STYLE_TESTS: 3817/3817 passed; failures=0; button visits=208; logical viewport=720x1280
```

The 208 visits are controls across 25 route/state inspections, not 208 unique buttons. The test builds the real `res://scenes/main.tscn`, inspects its live production children, and calls production navigation/session/store code. It does not substitute mock interface controls or screenshot-only replicas.

This gate checks the requested floating icon-and-label interface. It is not an Android emulator, APK, physical-phone, accessibility, or full gameplay certification. The existing core and save suites remain separate requirements.

## Reproduce safely

From the repository root, with the project assets already imported by Godot:

```sh
D=$(mktemp -d /tmp/farshore-ui-style-XXXXXX)
mkdir -p "$D/home" "$D/data" "$D/config"
HOME="$D/home" XDG_DATA_HOME="$D/data" XDG_CONFIG_HOME="$D/config" \
  godot --headless --audio-driver Dummy --path game \
  --script res://tests/ui_style_tests.gd > "$D/output.log" 2>&1
R=$?
cat "$D/output.log"
printf 'Saved log: %s/output.log\n' "$D"
exit "$R"
```

The script refuses to instantiate Main unless HOME and XDG_DATA_HOME are under `/tmp/farshore-ui-style-…`, and Godot's resolved user-data directory is beneath that XDG directory. This matters because Main initializes `user://` during `_ready()` before a test fixture can be installed. Every run needs a **fresh** directory. No player's save is used or modified.

The fixture is a real SaveStore with validated disk persistence. Discovery records are produced by the real encounter generator, settled, and released before the fixture unlocks all areas/equipment and seeds favorites. Normal and protected result pages are reached through the production FishingSession's cast/finish signals and Main's settlement path. Sound and vibration are disabled; production audio also skips resource playback with the headless display driver.

## Contract covered

- Every built Button and OptionButton in inspected subtrees has transparent `normal`, `hover`, `pressed`, `hover_pressed`, `focus`, and `disabled` style boxes. An empty style passes; a flat style must have no opaque center, visible border, or visible shadow. Textured/unrecognized style boxes fail conservatively
- Laid-out targets are at least **96 × 96 logical units**. This is a design-coordinate check, not a claim about physical millimeters or Android density
- Buttons have text and use the production IconAction implementation; its caption matches the real action text and stays within its hit target with sufficient vertical space
- Button captions use an outline or shadow for readability; icon/caption children ignore pointer input so they cannot steal taps
- Actions have visible vector icons. Catalog species-name actions may use their own adjacent fish artwork instead of a redundant second pictogram. OptionButtons use the native visible dropdown chevron
- Disabled controls change icon/caption opacity instead of drawing a plate
- Native viewport mouse motion, press, and release on the real Settings Back control verify hover feedback through icon/text, a transparent held-hover style, and its real callback
- PanelContainer card styles are transparent; large dark ColorRect backplates are rejected
- The actual editable catalog search has a transparent background and a 96-unit minimum target. A functional underline is allowed
- Repeated opening and Back dismissal of Settings does not leave stale overlays
- Real ordinary and protected catch settlement/release flows remain operable

Functional progress-bar fills/tracks, slider tracks, measurement rulers, scenery/specimen artwork, and a light full-screen menu surface are intentionally allowed. These are not filled button/backplate regressions. The editable search is tested in its real normal/focus states; an unused read-only state is not claimed to be covered. Text legibility still needs visual inspection because geometry cannot prove contrast against an illustration.

## Routes inspected

1. Fishing idle, charging, bite, fight, escape
2. Starter home, pause, travel, gear, catalog, favorites, settings, licenses, empty pending catches
3. Undiscovered protected-species detail
4. Fully discovered/unlocked travel, gear, catalog, favorites
5. Discovered species detail and enlarged specimen view
6. Common carp result and pending-catch views
7. Chinese sturgeon protected result and pending-catch views

## Regressions caught and repaired

The first gate found an **88 × 96** discovery-filter target, a cast caption extending **7 logical pixels** beyond its hit target, and inherited non-transparent `hover_pressed` styles. The UI implementation was repaired to use a minimum 96-unit filter width, a 180-unit cast target height, and explicit transparent held-hover styles. The complete gate was rerun successfully after these fixes.

## Pixel inspection

The actual rendered PNGs in `docs/screenshots/` were visually inspected, including lake gameplay, gear, travel, normal catch, catalog, and protected-sturgeon catch. The first four were inspected at their 09:32 UTC generation; gameplay, catalog, and protected catch were inspected again from 09:37:12–21 UTC captures after the outline/contrast update in `1c864f1`.

Observed: floating icon-plus-label navigation/actions, no filled action rectangles or dark card backplates, clear short cast text, readable gear/travel/catch labels without obvious unwanted wrapping, a working ruler, and release-only treatment for the protected species. The last structural fixes in `8465dde` are verified by this runtime gate; the 09:37 screenshots predate those small target/style-state fixes.

These PNGs are native desktop game renders at **450 × 800 output pixels**, not device screenshots. Their filename or capture method does not prove Android behavior. Scroll-page content continuing below the viewport is expected and is not itself clipping.
