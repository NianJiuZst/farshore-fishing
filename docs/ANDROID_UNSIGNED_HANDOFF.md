# Ocean 1.3.0 internal unsigned signing handoff

This workflow prepares an **UNSIGNED-INTERNAL** artifact for the owner's local
signing step. It is not an installable release, and does not authorize uploading,
publishing, signing, or installing anything. The existing signed builder,
`verify_android_apk.py`, and release safety helpers remain unchanged.

## Final identity and custody boundary

- Package: `org.farshore.fishing.ocean`
- Launcher: `远岸钓鱼·海洋`
- Version: `1.3.0`, Android versionCode `7`
- Owner-generated public certificate SHA256:
  `a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716`
- Private key and password stay on the owner's Mac and owner-controlled backup
- Old packages/signers are not substitutes; this app coexists with earlier apps

The unsigned helper still calls the strict `expected_identity()` gate. It rejects
pending/null/boolean/NUL/mismatched fingerprints and both previous signers. The
public pin must match the frozen source identity and the explicit command input.
An unsigned build does not establish possession of the private key; final signed
verification must independently prove the same certificate.

## Preconditions

1. Finish combined source/native UI QA, commit the entire final source including
   both handoff helpers and their tests, then freeze one exact current HEAD
2. Create the complete source ZIP outside the repository using
   `release_source_zip.py`; every tracked working file must match the freeze
3. Retain the source ZIP and its manifest; inspect its actual byte size before
   selecting any transfer route. No valid c89ba45 baseline ZIP was produced: its
   retained full source archive is a verified TAR
4. Restore official Godot 4.6.3, Java21 and Android SDK/build-tools36.1.0 plus
   official platform-tools. Do not run adb or create device-authentication keys
5. Use the reviewed ARM64 template and pinned official exporter source listed
   below. No shader/GPU/device runtime claim follows from this headless export

The helper requires the final 74-species, 12-bait, 35-icon content contract. Full
source membership, bytes, authoring inputs, photo resources and natural-history
resources are verified before the editor runs and rechecked after export.

## Source-backed credential and device safeguards

Official exporter source:
[Godot 4.6.3 Android exporter](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp)

- Exporter source SHA256:
  `9bb2416174a1e262a4282baaf346b118be921d4e3d78755743e1b1a6cb21bfd4`
- Reviewed official-derived ARM64 template SHA256:
  `27dcf3ecf8dbf48725d8fc5a9c8d807385c9586d8a6c2d00a69ad7833e7c5eca`

The pinned exporter returns before debug-key generation when its configured
file already exists. An isolated, clearly labelled inert text file satisfies
that existence check; it contains no credential and is never used for signing.
Both presets must be non-runnable, preventing the exporter's gated adb polling,
and `package/signed=false` prevents the signing path. Settings/environment are
isolated. Presets are parsed per section, with duplicate, noncanonical,
credential-bearing, signed and runnable settings rejected.

The container blocks ptrace. Evidence therefore consists of reviewed pinned
source, fail-closed settings, unchanged inert-file bytes, exhaustive isolated
credential-file checks and unsigned-APK rejection; it is not a syscall trace.
Both new Python entry points explicitly refuse `-O`, `-OO` and optimized
`PYTHONOPTIMIZE` execution, and child Python optimization inheritance is removed.

## Commands after final freeze approval

The directories below are examples for this workspace. Source, artifact, audit
and disposable staging directories must be outside the repository, with no
symlinked ancestors. Existing artifacts and audit directories are immutable.

```bash
set -euo pipefail
ROOT=/workspace/scratch/c16084497664/farshore-fishing-ocean
OUT=/workspace/scratch/c16084497664/farshore-ocean-1.3.0-internal
UPSTREAM=/workspace/scratch/c16084497664/farshore-ocean-internal-unsigned-c89ba45/audit/official-export-plugin.cpp
cd "$ROOT"
FREEZE=$(git rev-parse HEAD)
mkdir -p "$OUT" build/logs
python3 tools/test_release_packaging.py
python3 tools/test_unsigned_handoff.py
python3 tools/guard_release_command.py \
  --log build/logs/ocean-final-source-zip.log \
  --proof build/logs/ocean-final-source-zip-resource-proof.json -- \
  python3 tools/release_source_zip.py --commit "$FREEZE" \
  --output "$OUT/farshore-fishing-1.3.0-source.zip" \
  --prefix farshore-fishing-1.3.0 \
  --manifest "$OUT/farshore-fishing-1.3.0-source-manifest.json"
python3 tools/guard_release_command.py \
  --log build/logs/ocean-unsigned-handoff.log \
  --proof build/logs/ocean-unsigned-handoff-resource-proof.json -- \
  python3 tools/android_unsigned_handoff.py \
  --source-zip "$OUT/farshore-fishing-1.3.0-source.zip" \
  --source-manifest "$OUT/farshore-fishing-1.3.0-source-manifest.json" \
  --template "$ROOT/tools/godot-templates/4.6.3.stable/android_release_arm64_aligned.apk" \
  --upstream-source "$UPSTREAM" \
  --expected-certificate-sha256 a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716 \
  --output "$OUT/farshore-fishing-1.3.0-UNSIGNED-INTERNAL-arm64.apk" \
  --audit "$OUT/unsigned-audit" \
  --staging-parent /workspace/scratch/c16084497664/farshore-unsigned-workspaces
```

Successful output has normalized Vulkan manifest types and 16KiB ZIP/ELF
alignment. The separate unsigned verifier retains all non-signature static APK
gates, verifies the pinned future identity, and instead requires apksigner to
reject the unsigned file and no APK signing block or v1 signature material.
Exact exported photos, imported 3D scenes, native-library bytes, natural-history
JSON/module, catalogs, world, icons and runtime UI payloads remain audited.

Only a fully verified candidate is copied to the explicit handoff output. The
newly owned disposable workspace is removed after success; failures preserve
it and their logs. No primary `game/` export or cleanup occurs.

## Required completion evidence

Inspect `unsigned-audit/unsigned-handoff-finalization.json`, `build-manifest.json`,
source snapshot, imported photo/3D reports, natural-history verification,
unsigned-signature rejection, normalization and alignment logs, cleanup proof,
and resource-floor proof. Record the exact unsigned SHA256 before any separately
authorized transfer.

On the Mac, verify the received unsigned SHA256 before using the owner's signing
key. Verify the chosen local build-tools36.0.0 commands and produced artifact,
rather than assuming equivalence to cloud36.1.0. After signing, verify the exact
public certificate, both APK v2 and v3 schemes, API29/36 and 16KiB alignment, and
rerun the unchanged full signed verifier against the frozen snapshot. Signing
adds metadata; all payload members must remain byte-identical to the audited
unsigned candidate. No signing commands containing private data are supplied
by this document.

Physical Android installation, touch/Back/pause behavior, saved data, Vulkan
rendering, performance and 16KiB-page runtime remain separate acceptance.
