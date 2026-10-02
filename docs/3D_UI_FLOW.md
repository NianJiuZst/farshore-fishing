# 1.2.0 native 3D controller and touch navigation

## Scope and actual scene

The production `main.tscn` controller creates a `FishingStage3D` (`Node3D`) directly in the root viewport before its transparent 2D HUD. The stage owns a real `Camera3D`, rigged angler/fish assets, environment, line, float, and presentation animation. Main does not use `SceneryView` or a painted background as the fishing scene. The project selects Godot Mobile/Vulkan rendering for the high-end Android target, explicitly chooses Vulkan on Android, and disables fallback to OpenGL3. This slice requires a Vulkan-capable device; there is no silent quality downgrade. A headless test is logic coverage, not proof of Vulkan image quality or device frame rate.

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

All production page ScrollContainers are `TouchScroll`, not only the bag. It observes `InputEventScreenTouch` and `InputEventScreenDrag` in `_input` before descendant `PanelContainer` and `Button` STOP filtering can prevent a drag. A 14-logical-pixel directional threshold distinguishes taps from scrolling. A completed drag moves the scroll position directly, coasts with bounded exponentially decaying velocity, and never dispatches the captured button's action. A tap is dispatched once after the input event finishes, allowing callbacks to rebuild a page safely. Emulated mouse events are suppressed for owned gestures to avoid a second click. Focus loss/page destruction clears held gestures and inertia. Native text fields and option controls receive a balanced native GUI click only after a tap is recognized. Horizontal slider gestures receive a balanced native press/motion/release after horizontal intent is clear. Vertical swipes never send a native press, preventing the observed premature dropdown opening and slider grab. Wheel and scrollbar interaction remain supported.

This fixes gesture ownership, not just scrollbar width or viewport size. Hardware-specific Android touch behavior still requires device validation; synthesized viewport events alone are not labeled a real-device result.

## Verification

Run with isolated HOME, XDG_DATA_HOME, XDG_CACHE_HOME, and XDG_CONFIG_HOME under `/tmp/farshore-*`:

```
godot --headless --path game --script res://tests/touch_scroll_tests.gd
godot --headless --path game --script res://tests/touch_scroll_tests.gd -- --production
```

The standalone suite injects ScreenTouch/ScreenDrag through the actual Viewport, with overflowing nested STOP panels and buttons: threshold, scroll distance, button-tap activation, post-drag cancellation, horizontal-swipe tap cancellation, emulated-mouse duplicate suppression, inertia, reverse direction, and Android canceled touch. The production extension drives actual Main page trees and the real session/store pipeline: lobby, prepare, temporary target, bag/catalog/settings/licenses drags, real bait drag/tap, cast gate, landing pause/resume, immediate durable catch, result gate, idempotent settlement, and preserved legacy selection.

2026-10-02 verification: standalone 12/12 and production-inclusive 71/71 passed on Godot 4.6.3, headless. Repeated actual production ScreenTouch/ScreenDrag gestures reached the true bottom: bag 504/504 px, catalog 7335/7335 px, settings 91/91 px, licenses 100905/100905 px. Final buttons were visible, no child control was accidentally activated, and reverse swipes moved back up. The bait choice was reached through real touch drags rather than a programmatic scroll-to shortcut. The production suite also passed Android-style emulated MouseButton/MouseMotion after touch/drag, vertical gestures over actual Main HSlider and OptionButton controls, preserved horizontal slider editing, exactly balanced slider drag signals, native dropdown tap, search-field focus, and the real bait tap/drag plus session/store lifecycle assertions described above. Duplicate terminal callbacks cannot re-arm a completed landing. The native-control reproducer first failed 2 of 65 checks before the arbitration fix; the expanded final suite passes 71 of 71. Actual production Main screenshots `build/ui3d/screenshots/01_lobby.png` and `02_prepare.png` were captured and visually inspected at 720×1280 using Mobile/Vulkan 1.4.305 on desktop llvmpipe. The lobby shows the rigged angler/world and four routes with no cast button or filled backplates; the preparation page fits its labels, icons, target choices, and entry action. A shorter real Mobile/Vulkan run also captured and visually checked `03_bag_top.png`, `04_bag_touch_scrolled.png`, `12_atlas_touch_bottom.png`, and `05_fishing_ready.png`; bag/atlas bottom images follow actual ScreenTouch/ScreenDrag events (504/504 and 7335/7335 px). The fishing HUD capture snaps the diagnostic camera to the production ready pose, without changing the app camera code or quality. These layout screenshots predate the final environment art upgrade and are not final-world-art evidence. Headless success is not rendered-image evidence. No desktop/software renderer FPS is a Snapdragon 8 Elite performance claim.
