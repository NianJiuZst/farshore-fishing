# Android verification record

## Environment observed

2026-10-02 UTC: Linux x86_64 cloud container, about10GiB RAM, no `/dev/kvm`, no hardware GPU node observed, no preinstalled Android SDK/adb/emulator. No physical phone is attached to this task.

The lack of KVM means accelerated Android virtual machines cannot currently be used. The official emulator supports `-accel off`; a software-emulation attempt is planned after SDK license approval. Software emulation is not valid evidence for real-phone frame rate, battery use, thermal behavior, or arm64-driver compatibility.

## Evidence levels

| Check | Status | Evidence |
|---|---|---|
| Godot official version and template match | Passed | 4.6.3.stable.official.7d41c59c4, official SHA512 comparison |
| Dedicated release signing identity | Passed | RSA4096, password/key not included in deliverables |
| Android16 target/API36, minAPI29 | Not yet verified in APK | Export configuration prepared; final manifest audit required |
| APK ABI/permissions/resources | Not yet verified | Final APK audit script prepared |
| Signature and16KiB ZIP/ELF alignment | Not yet verified | Final APK audit script prepared |
| Android16 emulator installation/launch | Not yet verified | SDK terms approval and emulator setup pending |
| Native Android touch/back/pause/restart | Not yet verified | Requires runtime execution |
| Same-signature in-place update keeps save | Not yet verified | Requires Android installation and a saved catch |
| Offline play | Not yet verified | No INTERNET permission configured; actual offline runtime check pending |
| Physical Android16 ARM64 installation/performance | Not yet verified | User phone acceptance required |

Do not substitute desktop mouse testing for Android touch-device verification. Build success, emulator success, and physical phone success are separate results.

## Planned software-emulator route

- Official API36 x86_64 system image and official Android Emulator
- AVD assets/settings located under `build/`; no persistent changes to the host machine
- No KVM or OS-security settings changed
- Software rendering and `-accel off`, portrait device matching720×1280 logical design
- Install the separate x86_64 release-mode build, inspect adb logs and screenshots
- Test cold start, full fishing loop, atlas, result disposition, settings, background/resume, system Back, force-stop/restart, offline mode, and in-place APK update where practical

If software emulation cannot boot or render reliably, record the exact failure and leave Android runtime checks **not verified**, rather than reporting them passed.

## Build recovery safeguard

The first Gradle attempt used an out-of-project `res://../tools/android-gradle` path. Godot's asset-cleanup phase affected the project source tree and the export failed. No APK from that attempt is eligible for delivery. Source recovery and all functional tests must be repeated before rebuilding. The build script was changed to make a full source archive with SHA256 inventory, verify an isolated copied project, and invoke export only within that disposable project's standard `res://android` directory. Direct export of the primary `game/` tree is no longer used.

## Installed Android tools after approval

SDK license acceptance was authorized2026-10-02. Installed: command-line tools22.0/build15859902, platform-tools37.0.1, build-tools36.1.0, platform/API36 revision2, NDK29.0.14206865, emulator37.2.12/build16428233, API36 default x86_64 image revision2. KVM acceleration check returned unavailable. The emulator is running via software TCG/SwiftShader in a private workspace test session; boot and application tests remain pending at this checkpoint.
