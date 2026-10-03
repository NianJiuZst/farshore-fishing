# Android beta3 packaging and update contract

This is the packaging handoff for `1.2.0-beta.3` / versionCode `5`. Preparation
checks passed on 2026-10-03. A signed beta3 APK, source ZIP, release tag, or upload
is not established by this document; use the final build evidence for those
results. Freeze the complete UI iteration and pass its combined gameplay and
visual checks before running the release commands below.

## Installation identity and saves

- Package: `org.farshore.fishing.preview`
- Launcher name: **远岸钓记·试钓版**
- Version: `1.2.0-beta.3`, Android versionCode `5`
- Existing preview certificate SHA256:
  `e0c20cecffb3dc5af682bd16b3ce8b9da2f142b1bee8d59cc2fe70da232dc284`

Beta3 keeps the same package and authorized signing identity as beta2/code4, so
it is an in-place update of that preview installation. Android's normal update
preserves its private app data; do not uninstall beta2 or clear its app data to
install beta3. Save loading and the actual update must still be checked on the
target phone. This preview package remains separate from the earlier
`org.farshore.fishing` app, whose progress does not automatically migrate across
the package boundary.

Public metadata is in [ANDROID_PREVIEW_IDENTITY.json](ANDROID_PREVIEW_IDENTITY.json)
and `game/data/android_build_identity.json`. `tools/android_identity.py` pins the
certificate. Preparation checked only the existing signing files' existence,
non-symlink status, and protected directory/file modes; it did not read their
contents or create credentials. During the authorized final build, the exporter
checks the existing key's public certificate before signing. Never copy private
key material or passwords into source, logs, archives, or command arguments.

## Required beta3 UI resources

`tools/content_fish_art_contract.py` now requires these three native UI scripts
alongside the original photo catalog/view, ruler, main script/scene, and shader:

- `game/scripts/fish_notebook_ui.gd`
- `game/scripts/fishing_menu_pages.gd`
- `game/scripts/fishing_failure_modal.gd`

All nine UI resources are hashed in the frozen source contract and required in
the source ZIP. For each GDScript in the exported APK, the check requires either
byte-identical source or one exact remap to its matching `.gdc` file with a valid
compiled-script header. A missing payload, missing/duplicate remap, retargeted
script, invalid bytecode header, or changed exported source fails the build. The
final photo-art evidence includes both `static_ui_resources` and
`static_ui_payload_sha256`, recording every exported UI target and its SHA256.
This proves resource presence and records payload bytes; it does not decompile
GDScript to assert equivalence with its source or establish runtime behavior.

The existing photo gates remain active: 44 canonical species, 44 full images,
44 thumbnails, exact raw PNG hashes, decoded RGBA8 hashes and geometry, 88
distinct lossless imported payloads, and exact exported `.ctex` bytes. The source
archive must also contain all 135 photograph authoring inputs. The full 54-scene
3D audit, rig/animation checks, editable 3D masters and generators, and frozen
catalog/world data remain required.

## Retained Android gates

The existing official prebuilt template route is documented in
[ANDROID_BETA2_BUILD.md](ANDROID_BETA2_BUILD.md). Reuse its installed Godot
4.6.3, JDK21, Android SDK36/build-tools36.1.0, and audited ARM64 template; this
iteration does not require an SDK reinstall, emulator, NDK, Gradle download, new
key, or debug-key creation.

The final verifier still requires API29 minimum/API36 target, the exact version
and preview identity, VIBRATE-only permissions, offline packaging, release mode,
backup disabled, Mobile Vulkan without OpenGL fallback, portrait expand and
4×MSAA, APK v2/v3 signatures, 16KiB ZIP/ELF alignment, uncompressed ARM64 native
libraries, and native bytes identical to the reviewed official template. The
existing narrow Vulkan manifest type normalization is unchanged.

Android installation, retained beta2 saves, touch input, pause/Back behavior,
actual Vulkan rendering, Snapdragon performance, and physical 16KiB-page runtime
remain separate device acceptance. Source/desktop and static APK checks must not
be described as a physical Android pass.

## Preparation verification

`python3 tools/test_release_packaging.py` passed all **13 tests**, with no skips,
on 2026-10-03. This includes the verified official-template check; identity and
Vulkan-manifest regressions; source archive corruption, member reuse, mode and
hash checks; and the existing complete synthetic 44-species photo fixtures.
Added regressions require each beta3 script in source and source-archive inputs,
reject all six missing/corrupt/retargeted export cases for each new script, and
check each exported UI payload digest. The fixture's success is preparation
evidence, not a beta3 gameplay export.

The historical beta2 finalization records source commit
`8bd027433c705ecdf26e105b1286864a6366caa3` and the 611,979,449-byte ARM64 APK with
SHA256 `272e1e3c87077a35bd0c17d749ce34c4e27505eedd592d73f07517ad312b2d7a`.
Those historical results do not certify beta3. The existing beta2 source ZIP and
manifest can supply unchanged compressed members, which are revalidated before
reuse and again in the final archive.

## Final local commands after the combined freeze

Run only after the coordinator freezes the complete, tested UI iteration in one
specific commit. Every tracked working file must match that commit, and all new
required files must be tracked. The output source ZIP is outside the repository
and must be fully verified before starting any Godot export. These commands do
not push, tag, publish a release, or change repository visibility.

```bash
set -euo pipefail
FREEZE=$(git rev-parse HEAD)
OUT=/workspace/scratch/c16084497664/farshore-fishing-beta3-release
BASE=/workspace/scratch/c16084497664/farshore-fishing-beta2-release
mkdir -p "$OUT" build/logs
python3 tools/test_release_packaging.py
python3 tools/guard_release_command.py \
  --log build/logs/beta3-source-zip.log \
  --proof build/logs/beta3-source-zip-resource-proof.json -- \
  python3 tools/release_source_zip.py --commit "$FREEZE" \
  --output "$OUT/farshore-fishing-1.2.0-beta.3-source.zip" \
  --prefix farshore-fishing-1.2.0-beta.3 \
  --manifest "$OUT/farshore-fishing-1.2.0-beta.3-source-manifest.json" \
  --base-zip "$BASE/farshore-fishing-1.2.0-beta.2-source.zip" \
  --base-manifest "$BASE/farshore-fishing-1.2.0-beta.2-source-manifest.json"
python3 tools/guard_release_command.py \
  --log build/logs/beta3-final-apk.log \
  --proof build/logs/beta3-final-apk-resource-proof.json -- \
  python3 tools/android_prebuilt_build.py \
  --source-zip "$OUT/farshore-fishing-1.2.0-beta.3-source.zip" \
  --source-manifest "$OUT/farshore-fishing-1.2.0-beta.3-source-manifest.json" \
  --template build/recovered-derived-android-release-arm64.apk \
  --output "$OUT/farshore-fishing-1.2.0-beta.3-arm64.apk"
```

The exporter copies source/imports into its own disposable project, verifies
there are no hardlinks, and changes presets/removes tests only in that copy. It
rechecks primary game/authoring hashes and the external archive after export.
Do not export, clean, or delete the primary `game/` tree. Existing releases,
archives, and signing files are never cleanup targets. The resource guard stops
the owned process below its existing disk/tmpfs/memory thresholds.

Before calling the resulting APK statically verified, inspect
`build/audit/1.2.0-beta.3/arm64/`: the frozen source manifest, imported photograph
and 3D audits, final APK manifest (including all three beta3 UI payloads),
signature/alignment logs, and `prebuilt-finalization.json`. Existing final
outputs and audit directories are immutable; diagnose any failure before choosing
a fresh attempt location. Publication and physical-device results belong in the
final release/acceptance record after they actually occur.
