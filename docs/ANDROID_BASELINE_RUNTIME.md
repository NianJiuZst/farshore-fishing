# Android16 baseline runtime investigation

Evidence snapshot:2026-10-02 09:30UTC. This concerns the original1.0.0/code1 x86_64 APK, not the upcoming redesigned edition.

## Confirmed milestones

- Official API36 x86_64 guest booted through software TCG; no KVM acceleration available
- Guest reports Android16/API36,720×1280,320dpi,4096-byte pages
- Signed x86_64 APK installed successfully. Package manager confirms org.farshore.fishing, versionCode1, min29/target36
- Exported launcher alias successfully started the activity. Android `am start-W` returned Status:ok and LaunchState:COLD
- Cold-launch timing was17577ms in software emulation; this is not representative of a phone

## Rendering failure observed

The old SwiftShader GLES backend logged shader-link failures for both Godot SceneShaderGLES3 and CanvasShaderGLES3: active fragment uniforms exceeded its limit at261. The game process remained present, but a usable game frame was not established. The emulator launcher and system UI also displayed ANR dialogs, so these dialogs are recorded separately from any game-process crash.

This must not be counted as a full game-start or gameplay pass. Catch/save/back/pause/offline/update-retention remain unverified.

## Official-source diagnosis

An existing [Godot issue109550](https://github.com/godotengine/godot/issues/109550) reports the identical261-uniform Scene/Canvas failure on SwiftShader, including a2D game. It is evidence of a known renderer interaction, not proof that every physical ARM64 device is unaffected.

In official4.6.3:

- [Canvas shader specialization](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/shaders/canvas.glsl) defaults to lighting disabled
- [Canvas rasterizer](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L2825-L2829) hard-codes the global shader uniform array size at256
- [Uniform declaration](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/shaders/canvas_uniforms_inc.glsl#L31-L33) includes that array unconditionally
- The configurable global buffer size controls allocation, while this shader define is fixed. Reducing the3D maximum-lights setting is not a demonstrated fix for the Canvas failure

No production project setting was changed on that assumption.

## Second verification route

The installed official emulator documents `-gpu swangle`: ANGLE with SwiftShader backend for GLES and SwiftShader for Vulkan. The second attempt used this option with the unchanged game APK; its result is recorded below. A real rendered frame alone does not establish a gameplay pass.

## Raw evidence

- `build/android-control/results/010-install-baseline.json`: install success
- `build/android-control/results/011-install-state.json`: installed package metadata
- `build/android-control/results/013-launch-baseline.json`: cold activity launch
- `build/android-control/results/017-godot-errors.json`: renderer failures and earlier Android-system exceptions
- `build/android/screenshots/03-game-home.png`, `04-game-home-loaded.png`, `05-game-visible.png`: emulator ANR/dialog evidence
- `build/logs/emulator-run-swiftshader.log`: first renderer/backend log
- `build/logs/emulator-gpu-help.txt`: supported emulator GPU modes

The emulator test uses no real account or phone. Release signing and adb test credentials remain private and outside source delivery.

## ANGLE/swangle result and termination

The second official emulator run used ANGLE2.1 over SwiftShader Vulkan. The same unchanged x86_64 APK installed successfully. The261-uniform link errors disappeared, and an actual game home screen rendered the Chinese text, lake illustration, and local-save-created message. Evidence: `build/android/screenshots/10-swangle-uncovered.png`, plus empty Godot error output in `build/android-control/results/033-swangle-late-errors.json`.

Android Quickstep/SystemUI ANR dialogs still overlaid the game, preventing reliable input/playthrough verification. During concurrent Gradle export, available host RAM fell to about1GiB and the emulator eventually exited with signal9. The exit is verified; memory pressure is correlated, but the exact kill cause is not proven. This is not evidence of a game-process crash. The current test session is terminated.

Catch, disposition, restart statistics, pause/back, offline play, and version-update save retention remain unverified. Later tests should use a persistent writable test AVD, and run separately from Gradle exports to reduce memory contention. The upcoming redesigned build needs its own validation.
