# Ocean expansion save-compatibility validation

## Scope and provenance

- Installed-release reference: commit `7df14ff`, Farshore Fishing 1.2.0, save schema 2
- Integration base: the user's newer commit `1afda37`, including portable backup, preview/import, undo, and unknown-field preservation
- Historical fixture identifiers, locations, anchor sizes, region IDs, and gear indices were read with `git show 7df14ff:game/data/{fish_a,fish_b,fish_c,fish_d,world}.json`. The 44 identities are literal constants in `game/tests/ocean_save_tests.gd`; they are not inferred from the expanded catalog
- Progress is deterministic synthetic test data, not a copied player save. Separate snapshots represent first catch, last catch, longest fish, and heaviest fish. Compatible extension fields are explicitly synthetic sentinels
- New-catch data uses the expanded catalog with `load_all(false)`. This exercises real catalog and SaveStore code without loading `Main`, visual resources, or model manifests
- All persistence uses newly created `/tmp/farshore-ocean-save-*` directories. Runs isolate `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `TMPDIR`; no player `user://` data is read or written

## Coverage

1. Schema 2, explicit schema 1, and schema-1-with-omitted-version migration preserve all 44 old species. Loading/migration does not rewrite primary or backup bytes. First migration commit retains the exact legacy bytes in the rolling backup
2. Checks retain 1,254 historical catches, full first/last snapshots, independent length/weight records, regional subcounts, currency, twelve pending catches, six favorites, owned/selected equipment, region unlocks, selection, game clock, settings, and nested compatible extension fields
3. Thirty new ocean catches and three region unlocks append alongside old progress. The result has 74 discoveries, 1,284 catches, 42 pending catches, and exact one-time rewards. Every historical species entry remains semantically identical. Duplicate callbacks and restarts add neither counters nor rewards
4. Historical pending fish remain actionable. Selling a historical carp and releasing the protected sturgeon grant exactly the original disposition amounts; protected sale and repeated disposition are rejected without changing history
5. Portable export retains the complete payload and produces its SHA-256 checksum. Preview reports exact totals, preserves extension fields, accepts surrounding whitespace/BOM, and cannot mutate live state or files. Import uses the local revision, retains the prior save, restarts exactly, and supports undo/redo and schema-1 raw JSON without incorrectly claiming a checksum
6. Invalid JSON, wrong format, absent/changed checksums, future and malformed versions, incomplete save objects, invalid settings/counters/pending entries/favorites, and oversized input are rejected without changing live state or committed save bytes
7. Active rounds, pending save retries, stale confirmations, maximum revisions, and future files block import. Corrupt primary recovery keeps original corrupt bytes and valid backup; two corrupt files and unknown future schemas fail closed
8. Real filesystem errors are injected through production `FileAccess` and `DirAccess` operations, plus actual temporary-file corruption. Snapshot write/validation/replacement, primary write/validation, rolling-backup replacement, primary replacement, rollback-copy failure, and rollback-rename failure are covered. Successful retries must restore the intended target, not merely return success

The `Main._backup_content_error()` restrictions were read before fixture design: current fish/region/spot/gear/bait identities and unlocked selected regions must match the catalog. This suite validates catalog bindings and Store semantics, but does not execute the backup UI or its interaction guards. UI/device testing is separate

## Pre-existing failed-undo bug and narrow repair

The unmodified `1afda37` SaveStore reproduced eight failures in the new suite: 1,129/1,137 checks passed. Its source SHA-256 was `046b7983e64f52452d135fe49562641e50f4738664136610d0a77d77976ffc9b`

After a successful import, `restore_previous_save()` read the old snapshot, then `_preserve_before_import()` replaced that snapshot with current progress before the primary commit completed. If primary write, temporary validation, rolling-backup replacement, or primary replacement failed, live state and primary remained correct, but the original undo target was lost. Retrying undo reported success while restoring the wrong progress

The repair preserves a verified byte-for-byte rollback copy of an existing pre-import snapshot until import/undo commits successfully. Any failure restores the original snapshot by rename, including its original formatting. This keeps the schema, public API, checksum format, revision behavior, all backup functionality, and user changes intact

If the rollback rename itself fails, the exact target remains in a uniquely named recovery file, further writes are blocked, and startup protects the unresolved recovery file rather than silently using the wrong undo target. Cleanup after a successful import is best-effort; an unresolved leftover recovery copy causes conservative protection on restart. This is not a claim of multi-file atomicity or power-loss durability

## Reproduction commands

From the repository root, using official Godot `4.6.3.stable.official.7d41c59c4`:

```sh
sandbox="$(mktemp -d /tmp/farshore-save-validation.XXXXXX)"
mkdir -p "$sandbox/home" "$sandbox/config" "$sandbox/data" "$sandbox/cache" "$sandbox/tmp"
export HOME="$sandbox/home" XDG_CONFIG_HOME="$sandbox/config"
export XDG_DATA_HOME="$sandbox/data" XDG_CACHE_HOME="$sandbox/cache" TMPDIR="$sandbox/tmp"
godot --headless --path game --script res://tests/ocean_save_tests.gd
godot --headless --path game --script res://tests/save_tests.gd
```

## Results and limits

On 2026-10-04, official Godot `4.6.3.stable.official.7d41c59c4` returned exit code 0 for both post-repair runs:

- `ocean_save_tests.gd`: **1,154/1,154 passed**, zero failed assertions
- Existing `save_tests.gd`: **314/314 passed**, including 10,000 settlements/dispositions and final real-disk roundtrip (5,395-byte serialized state)
- `git diff --check`: passed for the SaveStore edit

The new suite deliberately calls the production copy operation with a nonexistent source in its rollback-copy failure test. Godot prints one expected `Failed to open ...does-not-exist` error/backtrace for that injected case; the assertion verifies failure, unchanged bytes/progress, and correct subsequent recovery. This is distinct from an unexpected parser/runtime failure

These are real GDScript/headless filesystem tests, not Android-device upgrade tests. No Android device or emulator update was run here. The original release signing key is unavailable, so same-signature APK replacement and installed-device save retention remain unverified; this report must not be used to claim a successful device update. The app identity must remain `org.farshore.fishing.preview`, and preserving that identifier alone does not prove signing compatibility. No user should uninstall or clear application data to bypass the missing-key blocker
