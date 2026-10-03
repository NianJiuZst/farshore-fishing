# Compact fishing failure modal

`game/scripts/fishing_failure_modal.gd` replaces the visual treatment of the non-catch result with one small paper panel over the visible fishing scene. The component itself does not pause, reset, cast, save, reward, change bait, or mutate the fishing session. Main owns those transitions.

The supplied beta3 reference (`build/beta3-user-reference/1000049902.jpg`) was inspected as actual pixels. It showed a full-screen pale result page, a small block of text at its top, and a large empty area. This component retains the surrounding 3D scenery and the existing transparent illustrated action style.

## Integration contract

1. Construct `FishingFailureModal.new()` and connect `retry_requested` and `dismiss_requested` before adding it under Main.
2. Call `configure(reason, safe_insets)` before adding it. Insets are `Vector4(left, top, right, bottom)` in the same logical coordinates as Main, defaulting to `(20, 22, 20, 20)`. The component inherits Main's Theme and its Noto Sans CJK font.
3. Main should cancel held fishing input, pause the completed session/scenery/sound as appropriate, and retain the fishing HUD behind this overlay. Keep Main's overlay guard active until the component's signal arrives.
4. Route Back and any other requested exit through `request_dismiss()`; do not free the overlay immediately while a finger is down. Route explicit retry through `request_retry()`.
5. On either signal, remove/free the component and return to the ready fishing state. “再试一竿” is an explicit reset/readiness action: the component never casts automatically. A new cast still needs a fresh press and release on the fishing control.
6. Forward safe-area changes with `set_safe_insets(insets)`. Construct a fresh component for a new result rather than recycling an already-completed instance.

The two zero-argument signals each occur at most once per instance. Requests latch the first choice. They wait until all fingers are released and 160 ms have passed after touch/emulated-mouse activity. This keeps the full-viewport input shield in place while Android's touch-generated mouse events drain. It is a short input safeguard, not a timed toast or automatic dismissal.

Application focus loss/pause cancels held gestures and pending choices. Resume leaves the modal open, awaiting a fresh user action. Freeing/replacing the component kills its 140 ms opacity-only opening tween; the tween cannot trigger actions or navigation. Set `animate_open = false` before adding it for stable snapshots or reduced-motion use.

## Layout and copy

- One panel, maximum width 596 logical pixels, centered inside all four safe insets, with content-sized height
- Cream `#f5f0e3`, ink `#244449`, muted `#587872`, gold `#ab742b`, 24 px corner radius, a restrained shadow, and a 28% dark teal scrim
- Existing `ui_art.gd` illustrations and `icon_action.gd` transparent icon/text buttons, without filled button plates
- 96 logical-pixel action heights, matching the existing app target convention (48 dp at its 2× design scale); physical device density and safe-area behavior still require Android validation
- Short distinct copy for empty cast, missed bite, slack line, overload break, wear break, and generic escape
- No scrolling, decorative branding, catch preview, full-screen page heading, or large blank panel region
- Background taps consume input but leave the result open; only the two named actions or Back dismiss it
- Keyboard/controller focus cycles between the two actions

The modal is the single intentional opaque card exception to the earlier application-wide no-card style audit. The actions themselves remain `StyleBoxEmpty` in every state, using the existing IconAction treatment. General-purpose pages and unrelated cards are outside this component.

## Stable test API

- `get_panel_rect()` returns the global panel bounds
- `get_test_handles()` exposes `panel`, `scrim`, `title`, `body`, `note`, `retry`, `dismiss`, and `art`
- Stable nodes: `FishingFailureModal`, `FailureScrim`, `FailurePanel`, `OutcomeTitle`, `OutcomeBody`, `OutcomeNote`, `OutcomeArt`, `RetryAction`, `DismissAction`
- `copy_for_reason(reason)` selects presentation copy without mutating game state

## Verification

Run the standalone component suite in an isolated user-data directory:

```sh
mkdir -p /tmp/farshore-failure-home /tmp/farshore-failure-data /tmp/farshore-failure-cache /tmp/farshore-failure-config
env HOME=/tmp/farshore-failure-home XDG_DATA_HOME=/tmp/farshore-failure-data XDG_CACHE_HOME=/tmp/farshore-failure-cache XDG_CONFIG_HOME=/tmp/farshore-failure-config godot --headless --path game --script res://tests/fishing_failure_modal_tests.gd
env HOME=/tmp/farshore-failure-home XDG_DATA_HOME=/tmp/farshore-failure-data XDG_CACHE_HOME=/tmp/farshore-failure-cache XDG_CONFIG_HOME=/tmp/farshore-failure-config godot --headless --path game --script res://tests/fishing_failure_modal_tests.gd -- --tall
```

The suite sends actual `Viewport.push_input()` ScreenTouch, ScreenDrag, canceled touches, native mouse and emulated mouse events. It checks both touch indices 0/1, duplicate suppression, background/pause interruption, Back while a second finger is held, repeated replacement, inherited font, borderless actions, compact bounds, and asymmetric synthetic safe insets. It does not substitute `Button.pressed.emit()` for pointer interaction.

Native pixel previews use the project's scoped X/Mesa runner:

```sh
python3 tools/render_godot.py --timeout 1200 -- --path game --rendering-method mobile --rendering-driver vulkan --script res://tests/fishing_failure_modal_preview.gd
python3 tools/render_godot.py --timeout 1200 -- --path game --rendering-method mobile --rendering-driver vulkan --script res://tests/fishing_failure_modal_preview.gd -- --tall
```

The preview creates the actual Main/3D scenery on an isolated first-run save, enters the fishery, and adds the component over it. These images validate component pixels and scenery retention; they are not evidence that Main's completed-session route was exercised. Main integration, session/persistence regression, APK packaging, and Android hardware behavior require separate verification.

### Component verification on 2026-10-03

- Final focused suite: **37/37** at headless 720×1280, **37/37** at headless 720×1584, and **37/37** under native Mobile/Vulkan at 720×1280; all three exited 0 without script errors or resource warnings
- Logs: `build/beta3-modal-headless-1280.log`, `build/beta3-modal-headless-1584.log`, and `build/beta3-modal-native-tests.log`
- Ten native PNGs: five outcome previews each in `build/beta3-modal-preview-1280/` and `build/beta3-modal-preview-1584/`; empty-cast and line-break pixels were inspected directly, including the tall empty-cast layout
- Actual panel bounds: 596×364 at `(62,459)` in 720×1280 and `(62,611)` in 720×1584; no clipping or overlapping modal actions observed
- Both actual-Main preview runs saved all five PNGs and exited 0, but emitted seven Texture RID warnings during renderer shutdown. These preview-only shutdown warnings are disclosed and have not been established as a component defect; the standalone native component suite shuts down cleanly

The interaction suite includes removal of the modal from its dismissal signal, with an emulated click delivered one frame after the original touch release. The underlying cast fixture remains untouched. Native desktop rendering and synthetic viewport input are not Android hardware evidence.
