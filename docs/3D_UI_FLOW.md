# 1.2.0 native 3D controller and touch navigation

## Scope and actual scene

The production `main.tscn` controller creates a `FishingStage3D` (`Node3D`) directly in the root viewport before its transparent 2D HUD. The stage owns a real `Camera3D`, rigged angler/fish assets, environment, line, float, and presentation animation. Main does not use `SceneryView` or a painted background as the fishing scene. The project selects Godot Mobile/Vulkan rendering for the high-end Android target. A headless test is logic coverage, not proof of Vulkan image quality or device frame rate.

The launch screen is an actual lobby over the 3D world, with four clear routes: 开始钓鱼、行囊、图鉴、设置. The cast button is hidden there. Start opens the preparation page; that page contains a single managed fictional river location, current equipment/bait, and an explicit temporary trial target (mixed, common carp, or alligator gar). Entering the location reveals the fishing HUD. The original 25 raster icons, their transparent presentation, and minimum 96-logical-pixel controls remain in use.

The playable scope is two 3D fish and one location. The original 44-species catalog remains readable, with clear “3D 可体验” indicators on the two playable entries and “历史图鉴” on other entries. Existing region unlocks, old location selection, records, and favorites remain untouched. The pure TrialFishery adapter is the only trial content source. Its virtual location is stored on new catch records, never written over the player's old selected region/spot. The target selector is ephemeral, not an unlock or migration.

## State and presentation boundaries

1. Lobby → preparation/loadout → enter location
2. Press and hold charges the real FishingSession; release creates a real TrialFishery encounter and begins a save session
3. FishingStage3D starts its casting presentation. Main holds `Session.step` while `cast_in_progress` is true; the existing session state machine advances normally after the stage signals completion
4. Waiting/nibble/bite/fight remain authoritative FishingSession states; the 3D stage changes cameras and animations from those states
5. On CAUGHT, Main immediately calls the unchanged transactional SaveStore settlement. This records the catch, statistics/reward, and durable pending disposition before animation starts
6. Only successful settlement starts the landing presentation. The result overlay waits for the matching `landing_finished(record)` catch ID
7. Back/background pauses the session and stage, preserving the pending presentation. Resume continues it. Exit after a successful settlement leaves the catch in the existing recoverable pending-catches page
8. Failed saving opens the retry path immediately; no catch is silently dropped. Duplicate settlement is guarded both by Main's committed ID and the unchanged store's idempotency
9. Sell/release resolves the existing pending catch transaction before resetting the round

Navigation cannot start another encounter while an existing round or catch is unresolved. Landing hides incidental travel/bait controls; Back opens a pause page rather than skipping to a result. Native focus loss suspends the stage as well as session/audio. The page router preserves lobby/prepare/fishing return context.

## Actual touchscreen fix

All production page ScrollContainers are `TouchScroll`, not only the bag. It observes `InputEventScreenTouch` and `InputEventScreenDrag` in `_input` before descendant `PanelContainer` and `Button` STOP filtering can prevent a drag. A 14-logical-pixel directional threshold distinguishes taps from scrolling. A completed drag moves the scroll position directly, coasts with bounded exponentially decaying velocity, and never dispatches the captured button's action. A tap is dispatched once after the input event finishes, allowing callbacks to rebuild a page safely. Emulated mouse events are suppressed for owned gestures to avoid a second click. Focus loss/page destruction clears held gestures and inertia. Native text, range, and option controls preserve their built-in touch route; wheel and scrollbar interaction remain supported.

This fixes gesture ownership, not just scrollbar width or viewport size. Hardware-specific Android touch behavior still requires device validation; synthesized viewport events alone are not labeled a real-device result.

## Verification

Run with isolated HOME, XDG_DATA_HOME, XDG_CACHE_HOME, and XDG_CONFIG_HOME under `/tmp/farshore-*`:

```
godot --headless --path game --script res://tests/touch_scroll_tests.gd
godot --headless --path game --script res://tests/touch_scroll_tests.gd -- --production
```

The standalone suite injects ScreenTouch/ScreenDrag through the actual Viewport, with overflowing nested STOP panels and buttons: threshold, scroll distance, button-tap activation, post-drag cancellation, horizontal-swipe tap cancellation, emulated-mouse duplicate suppression, inertia, reverse direction, and Android canceled touch. The production extension drives actual Main page trees and the real session/store pipeline: lobby, prepare, temporary target, bag/catalog/settings/licenses drags, real bait drag/tap, cast gate, landing pause/resume, immediate durable catch, result gate, idempotent settlement, and preserved legacy selection.

2026-10-02 verification: standalone 12/12 and production-inclusive 45/45 passed on Godot 4.6.3, headless. Actual production ScreenDrag offsets: bag 315 px, catalog 315 px, settings 91 px (the full available overflow), licenses 315 px. The production suite also passed the real bait tap/drag and session/store lifecycle assertions described above, including duplicate terminal callbacks that must not re-arm a completed landing. Rendered validation is recorded separately; headless success is not rendered-image evidence. No desktop/software renderer FPS is a Snapdragon 8 Elite performance claim.
