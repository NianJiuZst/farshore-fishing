# Android 1.2.0 packaging and update contract

This is the preparation handoff for **1.2.0 / versionCode 6**. Preparation on
2026-10-03 does not establish a formal APK, source ZIP, release tag, upload, or
Android device pass. Freeze and validate the complete float-encounter, character,
and interface iteration in one commit before running the final commands below.

## Installation identity and save boundary

- Package: `org.farshore.fishing.preview`
- Launcher name: **远岸钓记**
- Version: `1.2.0`, Android versionCode `6`
- Existing certificate SHA256:
  `e0c20cecffb3dc5af682bd16b3ce8b9da2f142b1bee8d59cc2fe70da232dc284`

The launcher name changes, while the existing preview package and signing identity
remain unchanged. This preserves the Android app-data namespace for updates from
beta2/code4 and beta3/code5. Install as an update; do not uninstall the existing
preview or clear its data. Actual update installation and save loading still need
device acceptance. The historical `org.farshore.fishing` app remains a separate
installation, and its progress does not automatically cross the package boundary.

The launcher/project-name change does not select a new Android `user://` folder.
The official Godot 4.6.3 source delegates
[`OS_Android::get_user_data_dir`](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/platform/android/os_android.cpp#L707)
to the
[`GodotIOJavaWrapper`](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/platform/android/java_godot_io_wrapper.cpp#L121),
which ignores `p_user_dir` and calls Java `getDataDir()` without parameters.
[`GodotIO.java`](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/platform/android/java/lib/src/main/java/org/godotengine/godot/GodotIO.java#L162)
returns `getContext().getFilesDir().getAbsolutePath()` directly. Android documents
this as the application's persistent internal-files directory
([storage guide](https://developer.android.com/training/data-storage/app-specific#internal),
[`Context.getFilesDir`](https://developer.android.com/reference/android/content/Context#getFilesDir())).
Therefore the same-package update keeps the same logical save namespace regardless
of `config/name` or launcher label. The game continues to initialize `SaveStore`
with `user://`; no label-derived path was added. This is source/API verification,
not an installed-device update or retained-save test. Do not hardcode an absolute
Android storage path, which the OS may relocate.

The retained derived template was also inspected directly with the existing
Android `dexdump` tool. Its `GodotIO.getDataDir()` bytecode invokes only
`getContext()`, `Context.getFilesDir()`, and `File.getAbsolutePath()`, then returns
that value. The inspected `classes.dex` SHA256 is
`ec8642c15e59f680e6867334acec546b72f16066a7af3cde4b6bd568f22edd90`, matching
the retained official-template transformation proof. Source links above pin the
current official `4.6.3-stable` tag commit `35e80b3a8822a9df9be390814b62f44c0a9c69e8`.
The local engine's reported suffix `7d41c59c4` was not resolvable through GitHub's
commit endpoint, so this check does not claim source-commit equivalence for that
suffix; the retained-template bytecode supplies the direct Java-side evidence.

The 1,255,918,323-byte retained template bundle was rehashed: its SHA512 matches
the existing `toolchain-proof.json`, and SHA256
`3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8` matches the
current asset digest returned by the
[official 4.6.3 release API](https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.6.3-stable).
The original APK, derived APK, and all 114 unchanged members (including DEX and
both ARM64 libraries) match the retained transformation proof. No template hash
mismatch was found. The retained toolchain proof records the editor version but
no editor-binary/archive checksum, so this check does not independently certify
the installed desktop editor binary against an official download. No engine or
template was replaced.

`game/data/android_build_identity.json` and `ANDROID_PREVIEW_IDENTITY.json` are
identical public metadata. The latter keeps its filename to document the package
lineage. `tools/android_identity.py` pins the exact formal launcher/version/code
and existing certificate; historical preview and legacy identities remain
verifiable. Both export presets and the project version match the formal identity.

Preparation checks only signing-file existence, non-symlink status, and protected
modes. The existing key directory is `0700` and its key/password files are `0600`.
No signing contents were read, copied, replaced, or logged. The authorized final
exporter checks the existing key's public certificate before export and signing.
Never include keys or passwords in source, archives, logs, or command arguments.

## Required source and exported resources

`tools/content_fish_art_contract.py` now requires
`game/scripts/float_encounter.gd` and
`game/assets/shaders3d/float_lacquer.gdshader` alongside all nine existing UI
resources. The
historical `ui_resource_sha256`, `static_ui_resources`, and
`static_ui_payload_sha256` evidence fields retain their names and cover all eleven
resources, including the float encounter module and lacquer shader.

Every required resource is hashed in the frozen source contract and required in
the source ZIP. Exported GDScripts must be byte-identical source or have one exact
remap to the matching `.gdc` file with the compiled-script header. Missing source,
missing remap or payload, retargeted/duplicate remaps, invalid bytecode, or changed
exported source fail the gates. Evidence records every exported target and its
payload SHA256. The lacquer shader must export byte-identical source; a missing,
changed, or remapped replacement fails the gate. These checks prove resource
presence and payload bytes; they do
not decompile GDScript or establish gameplay correctness.

All existing art requirements remain active:

- 44 canonical species, 44 full photos and 44 thumbnails; exact PNG and decoded
  RGBA8 hashes/geometry; 88 distinct lossless imported textures; exact exported
  `.ctex` bytes; all 135 photo authoring inputs in the source archive
- All 54 required 3D scenes, 45 rigged models, species-specific geometry, angler
  idle/cast/wait/reel/lift clips, fish animation clips, editable Blender masters,
  generators, asset documentation, and frozen catalog/world data

The revised angler must retain the existing scene, master, and animation contract.
New authoring inputs must be tracked and included before freezing the release.

## Retained toolchain and static Android gates

Use the retained official route described in [ANDROID_BETA2_BUILD.md](ANDROID_BETA2_BUILD.md):
Godot `4.6.3.stable.official.7d41c59c4`, Temurin JDK `21.0.12.1+1`, Android
SDK36/build-tools36.1.0, and `build/recovered-derived-android-release-arm64.apk`.
The verified official template and transformation proof are retained. This build
does not need new dependencies, an SDK reinstall, Gradle/NDK/emulator downloads,
new signing credentials, or a debug key.

The final APK gates still require API29 minimum/API36 target, the exact formal
version and package identity, VIBRATE-only permissions, offline release packaging,
backup disabled, Mobile Vulkan with OpenGL fallback disabled, portrait expand,
4x MSAA, v2/v3 signatures, 16 KiB ZIP/ELF alignment, uncompressed ARM64 native
libraries, and native bytes matching the audited official template. The existing
narrow Vulkan manifest type normalization remains unchanged.

Installation, beta save retention, touch input, pause/Back behavior, actual Vulkan
rendering, Snapdragon performance, and physical 16 KiB-page runtime remain device
acceptance items. Desktop and static APK checks cannot certify those results.

## Preparation evidence

`python3 tools/test_release_packaging.py` passed **17 tests with no skips** on
2026-10-03. New regressions cover formal identity/package/certificate boundaries,
the required float source, six invalid float export cases, strict lacquer-shader
source/export hashes, and source-archive membership. The retained
official-template, source archive reuse/corruption,
Vulkan normalization, beta3 UI, and synthetic complete 44-species photo tests pass.
This is preparation evidence, not a formal gameplay export.

GitHub CLI authentication was verified with
`GH_CONFIG_DIR=/workspace/shared/.github-cli` without printing credentials. About
16 GiB was free at preparation time; the command guard remeasures disk, tmpfs,
and memory at build time. All 2,393 members of the retained 1,657,724,227-byte
beta3 source ZIP were reverified against commit
`16376531830d462ae802b14c2cb06795f3c00be4`; its SHA256 is
`b818099ac8c61a176e572b24d0838bf6a50ffdd438b65a4244c8ea57c6ba04b7`.
The retained derived template matches its transformation proof at SHA256
`27dcf3ecf8dbf48725d8fc5a9c8d807385c9586d8a6c2d00a69ad7833e7c5eca`.
Unchanged beta3 compressed source members may be reused; every reused member and
the complete final archive are revalidated against the frozen commit. No prior
release is a cleanup target.

## Final local commands after the combined freeze

Run from the repository root only after the coordinator has frozen and tested
all changes. The worktree must be clean, all required new files must be tracked,
and the release output and audit paths must not already exist. These commands
create local release artifacts; they do not push, tag, publish, or change access.

```bash
set -euo pipefail
test -z "$(git status --porcelain --untracked-files=all)"
FREEZE=$(git rev-parse HEAD)
OUT=/workspace/scratch/c16084497664/farshore-fishing-1.2.0-release
BASE=/workspace/scratch/c16084497664/farshore-fishing-beta3-release
test ! -e "$OUT/farshore-fishing-1.2.0-source.zip"
test ! -e "$OUT/farshore-fishing-1.2.0-source-manifest.json"
test ! -e "$OUT/farshore-fishing-1.2.0-arm64.apk"
test ! -e build/audit/1.2.0/arm64
mkdir -p "$OUT" build/logs
python3 tools/test_release_packaging.py
python3 tools/guard_release_command.py \
  --log build/logs/formal-1.2.0-source-zip.log \
  --proof build/logs/formal-1.2.0-source-zip-resource-proof.json -- \
  python3 tools/release_source_zip.py --commit "$FREEZE" \
  --output "$OUT/farshore-fishing-1.2.0-source.zip" \
  --prefix farshore-fishing-1.2.0 \
  --manifest "$OUT/farshore-fishing-1.2.0-source-manifest.json" \
  --base-zip "$BASE/farshore-fishing-1.2.0-beta.3-source.zip" \
  --base-manifest "$BASE/farshore-fishing-1.2.0-beta.3-source-manifest.json"
python3 tools/guard_release_command.py \
  --log build/logs/formal-1.2.0-final-apk.log \
  --proof build/logs/formal-1.2.0-final-apk-resource-proof.json -- \
  python3 tools/android_prebuilt_build.py \
  --source-zip "$OUT/farshore-fishing-1.2.0-source.zip" \
  --source-manifest "$OUT/farshore-fishing-1.2.0-source-manifest.json" \
  --template build/recovered-derived-android-release-arm64.apk \
  --output "$OUT/farshore-fishing-1.2.0-arm64.apk"
```

The archive fixes membership and source bytes to `FREEZE`; final archive/APK
digests are measured, not predicted. The complete external source ZIP is verified
before any export. The exporter makes a disposable independent project copy,
rejects hardlinks, adjusts only copied presets, omits tests only from that copy,
and rechecks primary source/authoring hashes and the external archive afterward.
Never export, clean, or delete the primary `game/` tree.

Before describing the APK as statically verified, inspect
`build/audit/1.2.0/arm64/`: frozen source manifest, imported photo and 3D audits,
final APK manifest including `scripts/float_encounter.gd` and
`assets/shaders3d/float_lacquer.gdshader`, signature/alignment
logs, and `prebuilt-finalization.json`. Existing output and audit paths are
immutable. Diagnose a failed attempt before selecting a fresh output/audit
location; do not overwrite evidence. Record publication and physical-device
results separately only after they actually occur.
