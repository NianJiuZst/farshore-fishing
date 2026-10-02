# Android build: 远岸钓记

Evidence snapshot:2026-10-02 10:20 UTC. Final generated-icon1.1.0/code2 ARM64 and x86_64 builds have passed binary audits. API36 runtime testing is in progress on a separate software emulator. Physical Android16 ARM64 testing has not been performed.

## Locked toolchain

- Godot **4.6.3.stable.official.7d41c59c4**, official Linux x86_64 editor
- Matching official standard export templates: 4.6.3.stable, published SHA512 verified
- Eclipse Temurin **JDK 21.0.12.1+1**, official Linux x64 archive, published SHA256 verified
- Official Godot Gradle source template, **Gradle 8.11.1**, **Android Gradle Plugin 8.6.1**, **Kotlin 2.1.21**
- Template compile SDK **36**, build-tools **36.1.0**; official Android SDK installed after explicit user acceptance on2026-10-02 UTC
- Native Godot engine + GDScript, Compatibility/OpenGL ES renderer. No WebView game wrapper

The exact 4.6.3 downloaded source template is authoritative for build dependencies. The general Godot 4.6 export page listed older SDK35 dependencies when consulted. The template itself uses API36/build-tools36.1.0 and NDK29.0.14206865 metadata. This project uses the precompiled official engine libraries, not a custom native-engine compilation.

## Application identity

- Display name: 远岸钓记
- Package: `org.farshore.fishing`
- Current release: `1.1.0`, versionCode `2`; preserved audited baseline: `1.0.0`, versionCode `1`
- Minimum Android: **10 / API29**
- Target Android: **16 / API36**
- Player APK: **arm64-v8a only**
- Separate emulator APK: **x86_64 only**, same project/release mode/signing identity
- Requested permission: **VIBRATE only**. No INTERNET, storage, camera, microphone, location, or notification permissions are allowed by the validation script
- Android automatic backup is disabled. Saves are local, inside the app sandbox

The Gradle export is required so minSdk29 is actually applied. Merely setting minSdk in a non-Gradle Godot export preset does not change the prebuilt template's minimum API.

## Local directories

- `game/`: portable Godot project and shipped data/assets
- `tools/android_build.sh`: release pipeline
- `tools/verify_android_apk.py`: signed-APK audit
- `tools/prepare_android_environment.py`: isolated editor/build environment
- `tools/godot-templates/4.6.3.stable/`: verified official export templates
- `tools/android-gradle/build/`: original extracted official Gradle source template (not used as an out-of-project Gradle target)
- Sibling `farshore-fishing-checkpoints/`: default pre-export source archives and SHA256 inventories, outside the project tree; configurable with `FARSHORE_BACKUP_DIR`
- Existing early `build/source-snapshots/` archives are retained for historical evidence; future exports always use an external backup directory
- `build/android-workspaces/`: isolated disposable projects with standard in-project `android/build/` directories
- `tools/android-gradle/.build_version`: template version identity
- `tools/android-sdk/`, `tools/jdk/`: local tools; do not redistribute in the source archive
- `build/`: outputs, local caches, isolated settings, raw logs, audit evidence

Signing material is stored **outside the project tree**. It must not be copied into the source archive, Library uploads, screenshots, chat, or build logs. Losing the original key prevents normal updates to an installed package. The archive must exclude caches and credentials.

## Rebuilding after tool setup

On a fresh Linux x86_64 machine with Python3, curl, unzip and basic shell tools, first fetch the pinned official dependencies. Read and accept the Android SDK license before running the second command. No signing identity is generated automatically; restore the authorized original key through a secure local mechanism.

```sh
python3 tools/fetch_export_dependencies.py
./tools/setup_android_toolchain.sh --accept-sdk-license
./tools/android_build.sh arm64
./tools/android_build.sh x86_64
```

The script supports `FARSHORE_BACKUP_DIR` (must resolve outside the project tree), `JAVA_HOME`, `ANDROID_HOME`, `GODOT`, `FARSHORE_SIGNING_DIR`, `FARSHORE_KEYSTORE`, `FARSHORE_PASSWORD_FILE`, and `FARSHORE_KEY_ALIAS`. The password is consumed through a protected file; do not place it on the command line or in project files. The user must provide/restore the already-authorized signing identity on a new machine. This script does not create keys.

The export presets intentionally set `package/signed=false`: Godot/Gradle first produce an unsigned release, then the script applies **16KiB ZIP alignment** and signs using Android's `apksigner` with v2/v3 enabled. The final output, not the intermediate file, is the deliverable.

Before every export the script archives all source files into the external sibling checkpoint directory (or `FARSHORE_BACKUP_DIR`) and reads the archive back to verify every file hash, records the archive SHA256, and checks the inventory against both the original and a separate disposable project copy. It exports only this copy with a standard in-project `res://android` directory. Never configure a Gradle build directory with `res://../`: the initial export attempt with that path caused recursive cleanup to affect the source tree. The original tree was taken out of the export route, and recovery/revalidation is recorded in the task.

The script uses isolated editor settings and points Godot's automatic debug-keystore check at the existing release file to prevent creation of a second, unauthorized identity. It never exports a debug variant and does not send signing passwords to Godot or Gradle. Both export presets have one-click device deployment disabled (`runnable=false`), so Godot does not automatically launch adb/device discovery during builds. Emulator adb setup is a separate test step.

`verify_android_apk.py` rejects wrong package/API/ABI, a debuggable build, any unapproved permission, missing v2/v3 signature, invalid ZIP alignment, native ELF LOAD alignment below16KiB, absent catalogs/font, duplicate fish IDs or any fish/region/spot inventory mismatch against the frozen staged content. The catalog filenames come from the authoritative ContentCatalog loader, supporting both the32-fish baseline and expanded editions. Generated PNG UI icons and their exported texture payloads are also checked against the frozen source inventory. Both Android launcher presets use the generated `assets/ui/icons/badge.png`. Binary inspection alone does not prove runtime or physical-device compatibility.

## Install and update

```sh
adb install -r build/farshore-fishing-1.1.0-arm64.apk
```

Alternatively, copy the ARM64 APK to the phone and open it in the phone's file manager. Android may ask to allow installation from that particular file source. The user controls that security decision. Keep the same package and release signing key for every future update; increase versionCode. Use an in-place update, not uninstall/reinstall, to preserve the app's local data. Uninstalling or clearing app data can erase the save.

## Official sources

- Godot release and matching templates: https://godotengine.org/download/archive/4.6.3-stable/
- Godot Android export: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
- Godot Android export options: https://docs.godotengine.org/en/4.6/classes/class_editorexportplatformandroid.html
- Android SDK and license: https://developer.android.com/studio
- Android signing: https://developer.android.com/studio/publish/app-signing
- Android 16KiB support: https://developer.android.com/guide/practices/page-sizes
- Android ZIP alignment: https://developer.android.com/tools/zipalign
- Temurin JDK: https://adoptium.net/temurin/releases?version=21

## Current verification status

Both final generated-icon release-mode APKs were built from frozen source commit `366790826b98fb79c2e1764c47087ce4062e5a8d` and signed successfully. Actual manifests, ABI, VIBRATE-only permission list, signing identity, v2/v3 signatures,16KiB ZIP/ELF alignment,44 fish and their88 texture mappings,25 generated UI-icon textures, Chinese font, and absence of development tests passed the audit. Native libraries remain uncompressed. The original production-source SHA256 inventory was unchanged after both staged exports.

Phone deliverable: `build/farshore-fishing-1.1.0-arm64.apk`,137793032 bytes, SHA256 `cc0a6e02885b8b0aedb0afa2e112638073109bba44c88e5d614ce72a44ac43f7`.

Separate emulator package: `build/farshore-fishing-1.1.0-x86_64-test.apk`,140692994 bytes, SHA256 `7a744da256808274d3ba71b6e50c926cec193162e5c686a2da134045f7f34a6f`.

The public `APK_BUILD_MANIFEST.json` and `SOURCE_BUILD_MANIFEST.json` record the exact phone binary, frozen source inventory, and read-back-verified external source archive. Raw binary audits are under `build/audit/1.1.0/arm64/` and `build/audit/1.1.0/x86_64/`.

The earlier1.0.0 baseline installed and rendered real Chinese home/scenery on an API36 x86_64 software emulator using ANGLE/swangle. System ANRs prevented reliable gameplay, and that emulator later exited with signal9; the exact cause is unconfirmed. After both final exports completed, Gradle reported no running daemons and a smaller persistent API36/swangle test device was started independently. Final Android gameplay/pause/update-retention and physical-phone checks remain unverified at this snapshot. See `ANDROID_TESTS.md` for the matrix and `ANDROID_BASELINE_RUNTIME.md` for the earlier attempt.
