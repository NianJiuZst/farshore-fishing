# Android beta verification status

Preparation snapshot:2026-10-02 15:41 UTC. Target:1.2.0-beta.1/code3, ARM64 phone package and a separate x86_64 test package. Final export is awaiting the exact approved source/config freeze.

| Check | Current beta result |
|---|---|
| Source registry and GLB contract | Preparation probe passed44 distinct fish geometry fingerprints,45 rigs and54 required scenes |
| Imported scene structure | Preparation probe passed54/54; fresh isolated imports must be repeated for the release build |
| Editable source/provenance |45 Blender masters and48 Python authoring files identified; external archives are required before export |
| APK manifest/API/ABI/permissions/signature/16KiB alignment | Not yet run for this beta |
| Actual packaged Mobile/Vulkan/no-fallback settings | Not yet run for this beta |
| Android16 installation/start/rendering | Not yet run for this beta |
| Android gameplay, touch/scroll, Back, pause/resume, offline play | Not yet verified for this beta |
| Android saved-progress retention across update | Not yet verified |
| Physical ARM64/Snapdragon8 Elite behavior and performance | Not verified; no physical phone is attached |

Desktop/headless/Vulkan QA is recorded separately by the gameplay acceptance suite. It is not substituted for Android-device testing.

The earlier1.1.0 x86_64 package installed successfully on the persistent officialAPI36 software emulator, but was not launched before the requested stop. The older1.0.0 baseline rendered its Chinese home/scenery on ANGLE/swangle; SystemUI ANRs prevented reliable gameplay. Those historical outcomes do not validate this beta. Exact preserved reports are under `history/1.1.0/`.

The host has no KVM. Any resumed emulator run uses software TCG and records the actual rendering driver; a Vulkan limitation must be disclosed rather than changing the APK to Compatibility. SDK image/emulator binaries are temporarily parked in verified lossless local archives to make room for the builds. Both must be restored/hash-verified, and Gradle must stop, before runtime testing.
