# Android verification record

Evidence snapshot:2026-10-02 10:03 UTC (baseline1.0.0; redesigned edition requires new verification). Build success, emulator success, and physical-phone success are separate results.

## Signed APKs

| Artifact | ABI | Bytes | SHA256 |
|---|---|---:|---|
| farshore-fishing-1.0.0-arm64.apk | arm64-v8a |119737722|dc415e4c78d4c291f94dd6b412588bdbbef11db3cf42a6bac502e812d703b337|
| farshore-fishing-1.0.0-x86_64-test.apk | x86_64 |122637684|b3b17b4e2369dce06ef628db45f494563812c7f6cfb9109edcec4e1aadfe766a|

The ARM64 file is the preserved baseline phone package; the redesigned1.1.0 release is awaiting its final build. The separate x86_64 file is only for emulator testing. Both use the same production code and dedicated release signing identity, with no debug flag or development harness.

## Completed binary checks

| Check | Result | Evidence |
|---|---|---|
| Official engine/templates | Passed | Godot4.6.3.stable.official.7d41c59c4; matching published template SHA512 verified |
| Application identity | Passed | org.farshore.fishing; version1.0.0, code1; label远岸钓记 |
| Android versions | Passed | Actual APK manifests: minimum29/Android10, target36/Android16, compile36 |
| ABI separation | Passed | ARM64 only in phone APK; x86_64 only in emulator APK |
| Release mode | Passed | Manifest is not debuggable; release native engine libraries; test harness absent |
| Permissions | Passed | VIBRATE only; no INTERNET/storage/camera/microphone/location/notification permission |
| APK signing | Passed | apksigner verifies; both v2/v3 blocks checked; expected RSA4096 identity matched |
|16KiB compatibility, static | Passed | zipalign-P16 validation and all ELF LOAD segments in libc++/Godot libraries aligned16384 |
| Offline resources | Passed, static |32 unique fish JSON entries; all64 art/thumbnail mappings and texture payloads; bundled Chinese font |
| Original source preservation | Passed after replacement workflow | Source SHA256 inventory unchanged after staged full-game exports |

`apksigner verify` normally validates v3 for this minSDK29 app and can report v2=false without evaluating the older scheme. The audit additionally verifies with a minimum verifier range of24 to check both signature blocks. This does not alter the manifest or claim the app installs belowAPI29.

Machine-readable proof and raw tool output are under `build/audit/arm64/` and `build/audit/x86_64/`.

## Android runtime attempt and current limitation

The cloud host has no `/dev/kvm` or usable VMX/SVM acceleration. Official emulator37.2.12/build16428233 with the official API36 default x86_64 image revision2 was launched using software TCG and SwiftShader,720×1280,320dpi,2GiB RAM. The guest reports Android16/API36 and4096-byte runtime pages. adb and Android package/activity services respond. The current software-emulator run reached `sys.boot_completed=1` at2026-10-02 08:48:37 UTC. Earlier screenshots during boot were black.

After the guest booted, the signed baseline x86_64 APK installed successfully. Package manager confirmed versionCode1/min29/target36, and Android cold-started its activity with Status:ok. However, the legacy SwiftShader GLES backend failed Godot Canvas/Scene shader linking at261 active fragment uniforms, so a usable game frame and gameplay are not yet proven. Android launcher/system ANR dialogs were also observed separately from the game.

The unchanged APK also installed on the official emulator's `swangle` backend (ANGLE over SwiftShader Vulkan). It rendered real Chinese UI/scenery and the initial local-save message without the previous shader errors. System/launcher ANR overlays prevented reliable gameplay checks, and the emulator later terminated with signal9 during a memory-pressure period. Testing will resume separately from builds. See `ANDROID_BASELINE_RUNTIME.md` for logs, screenshots, exact error, and source diagnosis. This is baseline evidence, not validation of the upcoming redesigned edition.

| Runtime check | Status |
|---|---|
| API36 emulator installed and adb accessible | Passed |
| Android guest fully booted | Passed; sys.boot_completed=1,2026-10-02 08:48:37UTC |
| Baseline APK installation | Passed on API36 x86_64 |
| Baseline activity and rendering | Installed and activity started; real home/Chinese/scenery rendered on swangle; system ANRs prevented reliable interaction |
| Full fishing loop/atlas/result disposition on Android | Not verified |
| Android touch/cancel/systemBack/safe area/Chinese layout | Not verified |
| Background pause and explicit resume | Not verified |
| Actual offline gameplay and save/restart on Android | Not verified; static package has no INTERNET permission |
| Same-signature version upgrade preserves actual Android save | Not verified |
|16KiB-page runtime device | Not verified; static alignment passed, guest uses4KiB |
| Physical Android16 ARM64 installation | Not verified; no phone attached |
| Phone frame rate/heat/battery/memory | Not verified |

Desktop/core/save tests are documented separately. Desktop mouse tests are not substituted for Android touch/device evidence. No physical-device or universal performance claim is made.

## Build recovery

An initial out-of-project Gradle path caused the exporter cleanup to affect the source tree. That attempt was rejected. Production modules were recovered from live Godot memory, fish/scenery art restored with matching hashes, other resources restored, and automated tests rerun. Subsequent successful builds used protected source archives plus isolated project copies and standard in-project Gradle paths. See `EXPORT_SAFETY.md` for the official source-level diagnosis and enforced assertions.

Signing material remained outside the project and was unaffected; it is not part of either APK or the source archive.
