# Android build: 远岸钓记

Build snapshot:2026-10-02 17:03 UTC. **1.2.0-beta.1 / versionCode3** is signed and statically verified for ARM64 and the separate x86_64 test ABI. The final frozen game and all 54 imported 3D scene payloads match the audited snapshots. Android runtime evidence is tracked separately in `ANDROID_TESTS.md`. Verified 1.1.0 artifacts and their original records remain under `history/1.1.0/`.

## Locked toolchain and package

- Godot **4.6.3.stable.official.7d41c59c4**, with matching official export templates whose published SHA512 was verified
- Eclipse Temurin **JDK21.0.12.1+1**, official archive with published SHA256 verified
- Official source template: Gradle8.11.1, Android Gradle Plugin8.6.1, Kotlin2.1.21, compileSDK36, build-tools36.1.0, NDK29.0.14206865
- Native Godot Mobile renderer, Android Vulkan explicitly selected, automatic OpenGL fallback disabled; no WebView wrapper
- Package `org.farshore.fishing`, display name远岸钓记, version1.2.0-beta.1, code3
- MinimumAPI29/Android10, targetAPI36/Android16; Vulkan-capable hardware is required. The OS minimum is not a promise that every Android10 GPU is suitable
- Phone package: ARM64 only. Separate x86_64 package: software-emulator testing only
- Permission allowlist: VIBRATE only. No INTERNET, external-storage, camera, microphone, location or notification permissions
- Android automatic backup disabled; local app data and the existing release signing identity are retained through in-place updates

The acceptance target is the user's Snapdragon8 Elite Android16 phone. Physical-device performance/driver compatibility remain separate from desktop tests and x86_64 emulator evidence. Native library compression remains disabled; no APK/art quality reduction is part of this build.

## Content and audit contract

`game/data/fish_3d.json` is authoritative for all44 distinct fish models. The build additionally requires the fixed rigged angler, six regional environment GLBs and three station GLBs:54 required imported scenes,45 required rigs,6 regions and12 spots. Five rods, eight baits and31 generated PNG UI icons are checked against the frozen source. The old managed-oxbow asset may remain as unused legacy content.

The pre-export contract records actual geometry fingerprints, skins/weights, each fish's four clips, the angler's five clips and bone-attached RodSocket, texture imports, shaders, original editable masters/generators and CC0 environment provenance. The imported-scene audit verifies genuine Skeleton3D/AnimationPlayer/weighted-mesh structures without imposing one fixed bone count on every species. Final APK inspection matches the exact inspected imported-scene bytes, all texture payloads, the runtime registry, catalog/world JSON, notices and bundled Chinese font.

The signed-APK audit also checks package/version/API/ABI, release mode, permissions, expected certificate, v2/v3 signatures and16KiB ZIP/ELF alignment. It decodes `project.binary` and requires Mobile/Vulkan with OpenGL fallback disabled. Structural and static binary checks do not establish rendered gameplay or a physical-phone pass.

## Protected build workflow

Never export the primary `game/` tree. `tools/android_build.sh` first creates external source and authoring archives, reads them back against per-file SHA256 inventories, and copies the game into a fresh disposable `build/android-workspaces/` project. The Gradle directory is always that copy's normal `res://android`. All recursive cleanup targets must resolve inside the disposable copy and outside the primary source. Original game/authoring hashes are rechecked after export.

The default backup location is the sibling `farshore-fishing-checkpoints/`, configurable through `FARSHORE_BACKUP_DIR`; it must resolve outside the project tree. All45 editable Blender masters and current shared/profile generators are included in the authoring backup. Mutable source is never hardlinked into an export workspace. The original out-of-project Gradle cleanup incident and source recovery are documented in `EXPORT_SAFETY.md`.

The wrapper requires4GiB free for an ordinary cold build, or3.5GiB for the measured retry with fully reverified existing backups and scoped tmpfs caches and stops only its owned build process group if available space falls below768MiB. After unsigned-export CRC and source checks, completed Gradle/asset copies are cleared before alignment/signing. Final audits must pass before removing the remaining disposable workspace. Finish and clean one ABI's verified workspace before preparing the next; do not run the emulator alongside Gradle. The final source ZIP is created separately after build/runtime documentation freezes and enough disk space is available.

## Rebuild and install

On a fresh Linux x86_64 machine with Python3, curl, unzip and shell tools, fetch the pinned official dependencies. The SDK setup command requires acceptance of the Android SDK license. Restore the existing authorized signing identity securely; these scripts never generate a key.

```sh
python3 tools/fetch_export_dependencies.py
./tools/setup_android_toolchain.sh --accept-sdk-license
./tools/android_build.sh arm64
# Verify the result and clean only its completed disposable workspace before the next ABI.
./tools/android_build.sh x86_64
adb install -r build/farshore-fishing-1.2.0-beta.1-arm64.apk
```

`-r` performs an in-place update. Do not uninstall or clear app data when retaining saves. Android installation permission is controlled by the phone's owner. Future updates must retain the package and signing key and increase versionCode.

Supported build paths include `FARSHORE_BACKUP_DIR`, `JAVA_HOME`, `ANDROID_HOME`, `GODOT`, `FARSHORE_SIGNING_DIR`, `FARSHORE_KEYSTORE`, `FARSHORE_PASSWORD_FILE` and `FARSHORE_KEY_ALIAS`. Signing material stays outside the repository/source archives. Passwords are consumed from protected files, never command-line literals or logs. Presets intentionally disable built-in signing; the pipeline aligns the unsigned release and signs separately with apksigner. Its isolated editor settings suppress creation of a second debug identity, and one-click deployment is disabled.

## Workspace SDK storage and evidence

Matching `android_source.zip` under `tools/godot-templates/4.6.3.stable/` is the source template used by each isolated copy. The old out-of-project `tools/android-gradle/` copy has been retired; its nonstandard metadata was archived before removal. Installed tools and caches are excluded from source delivery.

To manage this workspace's disk limit, the stopped official API36 base image and emulator binaries are temporarily archived losslessly under ignored `build/toolchain-storage/`. Every file hash was verified before removing the redundant installed copies. AVD userdata/authentication files are untouched. Restore both exact components before any emulator launch:

```sh
python3 tools/android_image_storage.py restore image
python3 tools/android_image_storage.py restore emulator
```

The runner refuses to start until both restore manifests confirm verification. The manifests/archives are local tool caches, not release assets. See `ANDROID_3D_BUILD.md` for detailed gates and `ANDROID_TESTS.md` for current verification status. New beta manifests replace the clearly marked pending records only after actual APK verification.

## Official references

- [Godot4.6.3 and matching templates](https://godotengine.org/download/archive/4.6.3-stable/)
- [Godot Android export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html)
- [Godot project/renderer settings](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)
- [Android SDK and license](https://developer.android.com/studio)
- [Android application signing](https://developer.android.com/studio/publish/app-signing)
- [Android16KiB support](https://developer.android.com/guide/practices/page-sizes)
- [Android ZIP alignment](https://developer.android.com/tools/zipalign)
- [Temurin JDK21](https://adoptium.net/temurin/releases?version=21)

Existing game/authoring archives are reused only when the complete current member/hash inventories match and the archives are fully reread and verified again. A changed inventory creates a new archive in ordinary mode; constrained-space retries refuse to proceed without an exact verified reusable backup. Historical archives are never renamed/deleted on a failed copy. The archive regression probes cover reuse, changed/added members, corruption, duplicate entries, and source drift.

The current retry keeps only regenerable Gradle caches and unsigned/aligned APK intermediates in task-scoped `/tmp` directories. The isolated source tree and final signed APK remain on the workspace filesystem. The guard preserves a768MiB root-disk floor,1GiB available-memory floor and512MiB tmpfs floor. APK configuration auditing additionally requires portrait `expand` and4×MSAA.

## Completed beta artifacts

| Artifact | Bytes | SHA256 |
|---|---:|---|
| ARM64 player APK | 570512995 | `a1c3896e07fa0367957137c2df75b04232dab922fe5890e641d764852c0911bb` |
| x86_64 test APK | 573412957 | `7142db0cf68ebdf56caa8b7c77ad6203ff8ed9b25d7d7b13cd84b3a0aa48be2a` |

Both packages use the existing release certificate, v2/v3 signatures, 16 KiB ZIP/ELF alignment, API29 minimum/API36 target, release/non-debuggable mode, and VIBRATE as the only permission. The ARM64 APK is the downloadable phone artifact. The x86_64 APK is validation-only. See `APK_BUILD_MANIFEST.json`, `APK_EMULATOR_BUILD_MANIFEST.json`, and `evidence/1.2.0-beta.1/android/`.

### Retained-stage low-space recovery

The initial full-stage export hit its resource guard before producing an APK. Recovery reused that exact source snapshot and imported scene audit rather than copying/importing again. All 2,553 generated Gradle-output files (1,427,554,304 allocated bytes) were hash-verified while moving to a unique scoped tmpfs directory. Only the disposable copy's `build.gradle` generated `buildDir` was overridden, before task configuration; Godot's source directory remained the normal in-project `res://android`. No symlink or source-cleanup-root change was used.

The official `assembleStandardRelease` and then `copyAndRenameBinary` tasks ran with explicit package, version, API, ABI, unsigned release, and uncompressed-native-library properties. The copy task must be a separate invocation, as in Godot's exporter, because it has no assemble dependency. Offline cached Gradle dependencies and at most two workers were used. Root/tmpfs/available-memory floors stayed 768 MiB/512 MiB/1 GiB. ARM64 assembly completed in 28 seconds.

After unsigned CRC and source/authoring checks, both external archives were fully reread and their exact members/hashes revalidated. Generated Gradle/asset copies were cleared before alignment and signing. x86_64 reused the identical 1,012 Godot asset files from the signed ARM64 package, excluding only Gradle-generated dexopt baseline profiles; those profiles were regenerated for the second ABI. Its initial duplicate-profile packaging failure was fixed only in that disposable input, then packaging succeeded. Both signed APK audits passed before the remaining disposable workspace and finished regenerable Gradle cache were removed. No primary game or authoring files were deleted or modified.

The static verifier trims aapt's indented feature lines before requiring the Vulkan feature. The packaged binary manifest independently confirms `android.hardware.vulkan.version` is required with version 0x400003. This parser correction changed no APK bytes.
