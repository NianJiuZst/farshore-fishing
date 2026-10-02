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

During preparation, packaging/publication was held until the combined gameplay
and44-species encyclopedia-art freeze passed. No gameplay APK or source release
ZIP was created during the identity or photo-resource preparation probes. The
separate final-build verification manifests establish any later packaging result.

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

## Combined all44 photograph packaging contract

The photo preparation probe is separate from the final release. Its isolated
resource-only ZIP passed native import decoding and exact exported-byte checks for
44 full-resolution photographs and44 thumbnails. No signed gameplay APK, release
source ZIP, tag or upload was created by this probe. Its disposable source/cache
and ZIP were removed after the compact evidence was saved under
`evidence/1.2.0-beta.2/recovered/android-photo-preparation/`.

`content_fish_art_contract.py` requires the actual `data/fish_art.json` schema:
`complete=true`, `format_version=1`,44 unique canonical species, and88 canonical
PNG resources. The `sha256`/`thumb_sha256` fields bind raw PNG bytes; the
`image_sha256`/`thumb_image_sha256` fields bind the decoded, no-mipmap RGBA8 pixels
after Godot's transparent-border import processing. These are different hashes.
PNG dimensions, alpha bounds, source/import mappings and lossless import settings
must agree. The strict runtime photo gate and static view/main/ruler/shader/scene
sources are required and hashed in the frozen contract.

`inspect_imported_fish_art.gd` runs read-only inside the disposable imported game.
It invokes the native strict manifest validator, including anatomical landmarks,
alpha geometry, dimensions and all decoded image hashes, then records the exact
88 canonical `.ctex` target hashes. It never rewrites the manifest to bless changed
pixels. The runtime/import checks need only the staged game; authoring checks run
separately against the original repository root.

The measured4.6.3 resource export contains no original fish PNG files. Its stripped
`.png.import` mappings retain `[remap]` information but omit source/dependency/import
parameter sections. The APK gate therefore requires the canonical targets and
the exact audited `.ctex` bytes, not nonexistent PNGs or stripped source metadata.
If a raw fish PNG is also exported, its hash must still match. The exported
`data/fish_art.json` must be byte-identical to the frozen manifest. Native static UI
scripts must resolve to their matching `.gdc` resources, main scene to the exported
`.scn`, and the silhouette shader to byte-identical source. This is a resource and
source-integrity gate, not a claim to decompile and compare generated GDScript.

Both export routes run the new audit before exporting, and reject bad photo bytes
before signing. The final signed APK is checked again and its build manifest gains
a `photo_art` evidence section. Duplicate archive members are rejected. Existing
54-scene/44-rigged-fish/world-data, Mobile/Vulkan, API29/36, VIBRATE-only,
native-library byte identity,16KiB ZIP/ELF and exact preview certificate gates remain
active. These checks do not establish Android installation or phone performance.

The release source ZIP additionally requires135 photo-authoring files: the44
original masters,44 identical full-resolution runtime derivatives,44 thumbnails,
the exact artist manifest, derivative-generation script and provenance record.
The runtime manifest's `source_manifest_sha256` binds that artist manifest. Missing
or untracked required authoring members stop packaging even if the rest of the
selected commit could be archived. The existing3D editable masters/generators and
their frozen-source checks remain required too.

Regression coverage includes complete synthetic44 source/import/export fixtures;
partial, duplicate and retargeted catalogs; changed PNGs; missing decoded hashes;
wrong geometry/import hashes; stale/missing/swapped `.ctex`; missing static UI;
changed manifest/shader; and missing/corrupt authoring originals. The real exported
resource ZIP also rejected five injected stale/missing/retargeted payload cases.
All11 packaging test groups passed, including the retained official-template,
Vulkan-attribute, identity, archive and SDK-storage tests.

### Final commands after the coordinator approves the exact combined freeze

Do not execute this block during preparation. First commit the complete combined
runtime, all authoring files, tests, documentation and current evidence. The
selected source commit and every tracked working file must agree, and final
combined gameplay/visual tests must pass. These commands perform local packaging
only; they do not authorize a push, tag or Release.

```bash
FREEZE=$(git rev-parse HEAD)
OUT=/workspace/scratch/c16084497664/farshore-fishing-beta2-release
mkdir -p "$OUT" build/logs
python3 tools/test_release_packaging.py
python3 tools/guard_release_command.py \
  --log build/logs/beta2-source-zip.log \
  --proof build/logs/beta2-source-zip-resource-proof.json -- \
  python3 tools/release_source_zip.py --commit "$FREEZE" \
  --output "$OUT/farshore-fishing-1.2.0-beta.2-source.zip" \
  --prefix farshore-fishing-1.2.0-beta.2 \
  --manifest "$OUT/farshore-fishing-1.2.0-beta.2-source-manifest.json"
python3 tools/guard_release_command.py \
  --log build/logs/beta2-final-apk.log \
  --proof build/logs/beta2-final-apk-resource-proof.json -- \
  python3 tools/android_prebuilt_build.py \
  --source-zip "$OUT/farshore-fishing-1.2.0-beta.2-source.zip" \
  --source-manifest "$OUT/farshore-fishing-1.2.0-beta.2-source-manifest.json" \
  --template build/recovered-derived-android-release-arm64.apk \
  --output "$OUT/farshore-fishing-1.2.0-beta.2-arm64.apk"
```

The protected preview-key defaults are already handled by the build tool. Do not
copy a key/password into commands, logs, source, attachments or archives. Existing
outputs and audit directories are immutable; investigate a failed attempt rather
than overwriting them. Final static proof is written to
`build/audit/1.2.0-beta.2/arm64/`; inspect its photo/3D/import/build manifests,
signature and alignment logs before calling the APK statically verified.
