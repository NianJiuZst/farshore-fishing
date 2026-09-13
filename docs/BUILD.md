# Android build: 远岸钓记

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
- Version: `1.0.0`, versionCode `1`
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
- `build/source-snapshots/`: pre-export source archives and SHA256 inventories
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

The script supports `JAVA_HOME`, `ANDROID_HOME`, `GODOT`, `FARSHORE_SIGNING_DIR`, `FARSHORE_KEYSTORE`, `FARSHORE_PASSWORD_FILE`, and `FARSHORE_KEY_ALIAS`. The password is consumed through a protected file; do not place it on the command line or in project files. The user must provide/restore the already-authorized signing identity on a new machine. This script does not create keys.

The export presets intentionally set `package/signed=false`: Godot/Gradle first produce an unsigned release, then the script applies **16KiB ZIP alignment** and signs using Android's `apksigner` with v2/v3 enabled. The final output, not the intermediate file, is the deliverable.

Before every export the script archives all source files and checks the SHA256 inventory against both the original and a separate disposable project copy. It exports only this copy with a standard in-project `res://android` directory. Never configure a Gradle build directory with `res://../`: the initial export attempt with that path caused recursive cleanup to affect the source tree. The original tree was taken out of the export route, and recovery/revalidation is recorded in the task.

The script uses isolated editor settings and points Godot's automatic debug-keystore check at the existing release file to prevent creation of a second, unauthorized identity. It never exports a debug variant and does not send signing passwords to Godot or Gradle. Both export presets have one-click device deployment disabled (`runnable=false`), so Godot does not automatically launch adb/device discovery during builds. Emulator adb setup is a separate test step.

`verify_android_apk.py` rejects wrong package/API/ABI, a debuggable build, any unapproved permission, missing v2/v3 signature, invalid ZIP alignment, native ELF LOAD alignment below16KiB, absent catalogs/font, and a final fish count other than32. Binary inspection alone does not prove runtime or physical-device compatibility.

## Install and update

```sh
adb install -r build/farshore-fishing-1.0.0-arm64.apk
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

Tool download and checksums: passed. Release key generation: passed under explicit user approval. APK build/installation tests: pending while SDK license approval and project implementation are in progress. See `ANDROID_TESTS.md` for runtime evidence and limitations; do not present this checkpoint as a final APK result.
