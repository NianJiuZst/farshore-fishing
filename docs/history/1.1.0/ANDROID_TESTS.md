# Android verification record

Evidence snapshot:2026-10-02 10:24 UTC. This record distinguishes final1.1.0 binary audits, earlier1.0.0 runtime evidence, and physical-phone verification.

## Final signed APKs

| Artifact | ABI | Bytes | SHA256 |
|---|---|---:|---|
| farshore-fishing-1.1.0-arm64.apk | arm64-v8a |137793032|cc0a6e02885b8b0aedb0afa2e112638073109bba44c88e5d614ce72a44ac43f7|
| farshore-fishing-1.1.0-x86_64-test.apk | x86_64 |140692994|7a744da256808274d3ba71b6e50c926cec193162e5c686a2da134045f7f34a6f|

The ARM64 file is the phone package. The x86_64 file is only for emulator testing. Both use the frozen final generated-icon project, release mode, and the same dedicated release signing identity. Native libraries remain uncompressed.

## Completed binary checks

| Check | Result | Evidence |
|---|---|---|
| Official engine/templates | Passed | Godot4.6.3.stable.official.7d41c59c4; matching published template SHA512 verified |
| Application identity | Passed | org.farshore.fishing; version1.1.0, code2; label远岸钓记 |
| Android versions | Passed | Actual APK manifests: minimum29/Android10, target36/Android16, compile36 |
| ABI separation | Passed | ARM64 only in phone APK; x86_64 only in emulator APK |
| Release mode | Passed | Manifest is not debuggable; release native engine libraries; test harness absent |
| Permissions | Passed | VIBRATE only; no INTERNET/storage/camera/microphone/location/notification permission |
| APK signing | Passed | apksigner verifies; both v2/v3 blocks checked; same expected RSA4096 identity as1.0.0 |
|16KiB compatibility, static | Passed | zipalign-P16 validation and all ELF LOAD segments aligned16384 |
| Offline resources | Passed, static |44 unique fish across4 catalogs,6 regions/12 spots,88 fish art/thumbnail mappings,25 generated PNG UI-icon texture mappings, bundled Chinese font |
| Source preservation | Passed | External source archive read back and hash verified; original production hashes unchanged after both isolated exports |

`apksigner verify` normally validates v3 for this minSDK29 app and can report v2=false without evaluating the older scheme. The audit additionally verifies with a minimum verifier range of24 to check both signature blocks. This does not alter the manifest or claim the app installs belowAPI29.

Public machine-readable evidence: `APK_BUILD_MANIFEST.json`, `APK_EMULATOR_BUILD_MANIFEST.json`, and `SOURCE_BUILD_MANIFEST.json`. Raw reports: `build/audit/1.1.0/arm64/` and `build/audit/1.1.0/x86_64/`.

## Runtime evidence and current attempt

No physical phone is attached. The cloud host has no `/dev/kvm` or usable VMX/SVM acceleration, so testing uses official emulator37.2.12/build16428233 and official API36 default x86_64 image revision2 through software TCG.

Earlier1.0.0 baseline: the API36 guest booted, installed the signed APK, started its activity, and rendered the Chinese home/scenery plus local-save-created message on ANGLE/swangle. The initial legacy SwiftShader GLES backend had a261-uniform shader-link failure; ANGLE/swangle removed that failure without changing the APK. Android SystemUI/launcher ANRs prevented reliable gameplay, and the emulator later exited with signal9 during a memory-pressure period. The exit is verified; its exact cause is unconfirmed. Details and screenshot/log paths are in `ANDROID_BASELINE_RUNTIME.md`.

After both final1.1.0 exports completed, Gradle confirmed no running daemons. A separate smaller-screen persistent writable test device is prepared:480×854,213dpi,2560MiB,2 cores,6GiB data partition, official `-gpu swangle`, no hardware acceleration. Initial launch stopped at disk preflight before boot. The helper now handles spaced avdmanager config keys correctly; the installed emulator enforces minimum2560MiB RAM and6GiB data despite smaller requests. Completed-stage Android/import/Gradle caches were removed within the generated build tree after rechecking both APK and source-backup hashes, leaving7.7GiB for retry. Boot/install/gameplay/update checks remain pending; this edition has no runtime pass at this snapshot.

| Runtime check | Final1.1.0 status |
|---|---|
| API36 emulator setup | Prepared; disk preflight failed, retry prepared |
| Final APK installation/activity/rendering | Not yet verified |
| Full fishing loop/atlas/result disposition on Android | Not verified |
| Android touch/cancel/systemBack/safe area/Chinese layout | Not verified |
| Background pause and explicit resume | Not verified |
| Actual offline gameplay and save/restart on Android | Not verified; static package has no INTERNET permission |
| Same-signature version upgrade preserves actual Android save | Not verified |
|16KiB-page runtime device | Not verified; static alignment passed, earlier guest uses4KiB |
| Physical Android16 ARM64 installation | Not verified; no phone attached |
| Phone frame rate/heat/battery/memory | Not verified |

Desktop/core/save/UI tests are documented separately. Desktop mouse tests and x86_64 emulator results do not establish ARM64 phone performance or driver compatibility.

## Build recovery

An initial out-of-project Gradle path caused exporter cleanup to affect the source tree. That attempt was rejected. Production modules were recovered, artwork restored with matching hashes, other resources restored, and automated tests rerun. Every subsequent export uses an external, read-back-verified source archive plus a disposable project copy and standard in-project Gradle paths. See `EXPORT_SAFETY.md` for the source-level diagnosis and enforced assertions. Signing material remained outside the project and is excluded from source delivery.
