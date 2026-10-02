# Recovered Android beta.2 packaging route

Preparation was rebuilt and tested after the 2026-10-02 executor replacement. It
does not establish a signed gameplay APK or an Android runtime pass. A final
runtime/source freeze and authorized signing identity/package remain separate
release gates. The original signing key is not included in source or these tools.

## Approved independent preview identity

The user approved a new dedicated signing identity and an independent preview app
after the original local signing key was lost in the executor replacement. The
prepared package is `org.farshore.fishing.preview`, launcher name **远岸钓记·试钓版**,
version1.2.0-beta.2/code4. It coexists with the prior `org.farshore.fishing` app and
starts separate local data; it is not an in-place update and does not inherit old
saves. Public metadata is in `ANDROID_PREVIEW_IDENTITY.json` and the frozen game's
`data/android_build_identity.json`. The private key/password are stored only in a
separate protected shared-workspace folder, never the repository or release ZIP.

The exact preview certificate SHA256 is
`e0c20cecffb3dc5af682bd16b3ce8b9da2f142b1bee8d59cc2fe70da232dc284`.
`android_identity.py` pins both this authorized identity and the historical one.
The verifier takes the exact expected package/launcher/certificate from the frozen
content manifest and retains the historical defaults when verifying old artifacts.
The export wrapper checks the protected key's public certificate before exporting.

Packaging/publication is currently held for the combined gameplay and44-species
encyclopedia-art freeze. No gameplay APK or source release ZIP was created during
this identity preparation.

## Fresh official toolchain

- Godot 4.6.3.stable.official.7d41c59c4 and its official SHA512-verified template bundle
- Temurin JDK21.0.12.1+1, SHA256-verified official archive
- Official Android command-line tools, build-tools36.1.0, platform36/revision2 and
  platform-tools37.0.1; archive sizes/checksums validated against Google's catalog
- SDK manager manifest downloads failed, so the same official package archives
  were fetched with curl, fully verified and extracted with path/mode checks
- NDK, emulator, system images and Gradle were not installed for this route

Fresh source URLs, checksums, template transformation, five regression groups and
minimal-export evidence are under
`evidence/1.2.0-beta.2/recovered/android-preparation/`.

## Isolated prebuilt route and exact changes

The primary `game/` tree is never exported. `android_prebuilt_build.py` requires a
commit-exact external source ZIP containing every current game and authoring hash
before copying anything. It copies source/imports without hardlinks into a
disposable project, keeps normal `res://android` metadata, excludes tests only in
the copy, and uses the inspected prebuilt template only there. Primary presets
remain ordinary Gradle presets.

The official template already targets API36 but defaults to minSdk24 and compressed
native libraries. `derive_android_template.py` accepts its pinned SHA256 only. It
changes exactly minSdk24→29 and extractNativeLibs true→false, omits unwanted ABIs,
and stores byte-identical ARM64 native libraries uncompressed. Every other retained
template member is checked unchanged. Independent aapt and native hashes confirm
the result. Godot then performs normal identity/version/permission export.

### Pinned upstream Vulkan attribute defect

The real minimal export exposed an upstream format defect: Godot4.6.3's
`_fix_manifest` in [the pinned exporter source](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp)
emits the generated Vulkan `required` and `version` attributes as TYPE_STRING.
Independent aapt rejects these attributes. This failure is retained as evidence;
the verifier has not been relaxed.

`normalize_android_features.py` therefore runs on the unsigned exported APK before
alignment/signing. It accepts exactly these generated values and requires both raw
and typed string indices to agree:

| Feature | Attribute | Unchanged meaning | Correct type |
|---|---|---|---|
| android.hardware.vulkan.level | required | false | boolean |
| android.hardware.vulkan.level | version | 1 | integer |
| android.hardware.vulkan.version | required | true | boolean |
| android.hardware.vulkan.version | version | 0x400003 | hexadecimal integer |

Unexpected names, duplicate features, types or values fail closed. Only declared
attribute offsets may change, reversing them must restore the original manifest,
and every other APK member is checked byte-identical. Unchanged compressed payloads
are copied directly. No feature, permission, renderer, model, texture or shader is
added, removed or weakened by this format correction. The actual normalized export
then passes unmodified aapt, required-Vulkan, native-byte and16KiB gates.

## Source ZIP and resource safety

`release_source_zip.py` enumerates a specific Git commit and requires each working
file to match its blob. It can reuse unchanged compressed members from a prior
verified source release, checking their CRC/SHA1/SHA256 first. Changed/added files
are included and deleted ones omitted. The entire result is streamed and checked
again for exact membership, modes, hashes and unchanged working sources. It never
overwrites a previous archive or includes credentials/toolchain caches.

The complete external ZIP serves as the game/authoring backup and is rechecked
after export. The pipeline then aligns16KiB, signs with an already-authorized key,
runs the full existing manifest/signature/44-species/54-scene/resource audit, and
verifies native bytes against the reviewed template. Native compression=false is
now an explicit hard gate. Only its own completed, verified disposable workspace
may be removed. Archives, keys and old releases are never cleanup targets.

`guard_release_command.py` monitors the owned process group at0.1-second intervals
and stops it below768MiB root space,512MiB tmpfs or1GiB available memory. The restored
workspace has ample disk; the recovered NDK-parking tool is included for continuity
but was not used in the replacement environment.

## Credential-free smoke and validation boundary

The minimal smoke is unsigned and uses non-runnable presets. A harmless existing
text marker suppresses Godot's automatic debug-key creation according to the pinned
exporter source; it is not a keystore and is never used for signing. The smoke
asserts that it created no keystore files. It uses an isolated minimal scene and
the existing icon; no gameplay source is exported or changed.

Its successful checks cover API29/36, versionCode4, VIBRATE-only, release mode,
backup disabled, required Vulkan, Mobile/no OpenGL fallback, portrait expand,
4×MSAA, identical uncompressed ARM64 native bytes and16KiB ZIP/ELF alignment.
Final application identity/signature and the full gameplay/content APK audit still
require the authorized final release. Desktop QA does not establish Android
installation, retained saves, Vulkan driver behavior or Snapdragon performance.
