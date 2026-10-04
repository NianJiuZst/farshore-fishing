# Exact JSON readback regression and repair

## Confirmed failure

The release's actual zero-start growth test failed on iteration 103 after 103 successfully paid catches and 59 discovered species. The landed fish was `oceanic_whitetip_shark`, caught using `large_surface_lure` with gear 4, at 1,440 mm and 13,332 g. Its protected-observation metadata was valid. `SaveStore` rejected the next settlement with:

> 临时存档内容校验失败（内容不一致）；原存档未替换。

The source, temporary file and validation result demonstrated a false mismatch after a byte-perfect write, not an invalid catch, resource gate, oversized fish, missing bait or failed fishing session.

The exact generated `size_fraction` has IEEE-754 bytes `e888ea65d715963f` (little endian). On the tested official Godot 4.6.3 engine:

| Stage | Serialized decimal | IEEE-754 bytes |
| --- | --- | --- |
| Original runtime value | 0.021567693324535592 | e888ea65d715963f |
| Parse once | 0.021567693324535588 | e788ea65d715963f |
| Serialize and parse again | 0.02156769332453558 | e588ea65d715963f |

The first decimal parse moves one ULP lower. A second parse moves another two ULPs lower. The former comparison reserialized both the expected state and the already-parsed readback, effectively comparing the first parse with the second parse. Since this parser is not idempotent for every finite double, that comparison rejected some correct writes.

The regression constructs the float from its exact bytes. A decimal GDScript literal would itself be parsed and could hide the failing original value. The original captured record and diagnostic output are retained in `build/ocean-fresh-profile-validation/growth-first-failure.log` and `float-exact-diagnosis.log`.

## Narrow production repair

Exactly three readback comparison sites now call `_matches_persisted_state(readback, expected)`:

1. The verified pre-import snapshot
2. The verified final primary file
3. The verified temporary JSON file

The actual readback already passed through the production JSON parser and state normalizer. The new helper applies the identical single serialize/parse/normalize sequence to the expected state, then compares the two resulting Dictionaries exactly. It does **not** serialize or parse the actual readback again.

No approximate numeric comparison or epsilon is used. A one-ULP modification to normalized float metadata is rejected, as are one-unit changes to coins, revisions, gear, historical catch count, integer length and weight, altered IDs, booleans, and unknown fields. The existing byte-for-byte temporary-file check is unchanged; even appended JSON whitespace, with identical semantic content, remains a rejected write.

Save schema, checksum format, RNG, catch rewards, release protection, revision guards, backup/rollback behavior and gameplay values are unchanged. Integer measurements and progress remain exact. Informational floating-point metadata follows the engine's canonical JSON roundtrip; this is not a promise that an original in-memory double retains identical bits through this engine's JSON parser.

## Dedicated regression coverage

`game/tests/ocean_float_save_tests.gd` uses production SaveStore, Catalog and EncounterGenerator against unique `/tmp/farshore-*` directories, with isolated HOME/XDG/TMPDIR.

- Exact first-failing generated fish: settlement, duplicate rejection, primary-byte verification, pre-import snapshot, replacement import, undo, restart, protected-sale rejection and ordinary release
- Direct strict readback tests covering one-ULP and meaningful float mutations, coins, gear, revisions, history counts, integer dimensions, IDs, booleans and unknown fields
- Real temporary-file corruption, including semantically equivalent whitespace, changed float metadata and changed integer currency; each rejection preserves exact prior committed state and bytes, and allows the original catch to retry exactly once
- All 12 bait options × all 74 fish species × three genuinely RNG-generated size cases: small ordinary, large ordinary and extended-tail fish
- Each of the 2,664 generated records includes production depth/rig/affinity metadata, settles to disk, restarts, verifies full canonical state and exact integer/identity/protection fields, releases, then restarts again
- Three repeated catch/save/reload/release/reload cycles in each of 888 fresh fixture profiles verify bounded progression without compensation or reward replay
- Two generated matrix records exercise floats that the former double-parse comparison would falsely reject

## Results

Official Godot `4.6.3.stable.official.7d41c59c4`, headless Linux, 2026-10-04. Final results and SHA-256 manifest are in `build/ocean-float-save-validation/`.

The new float suite passes 41,790 assertions, including all 2,664 generated records. Fresh-profile policy remains 423/423 and the original persistence suite remains 314/314, including its 10,000-catch stress test. The unchanged literal-old44 compatibility suite also passes 1,154/1,154 against the same production fix. A focused rerun of the real growth route reaches all 74 species and nine regions in 148 caught/released fish, spending exactly 4,870 coins and retaining 14, with no failed fishing attempts. Its historical final `_same_json()` test comparison had the same double-parse flaw. A focused diagnostic using one expected parse passes the complete route and restart assertion with exit 0; `growth-one-pass-final.log` records that result. The aggregate core suite owns its independent equivalent one-pass expectation. No Android device-install, same-signature update or hardware filesystem guarantees are implied.

## Reproduce

```sh
sandbox="$(mktemp -d /tmp/farshore-float-save-validation.XXXXXX)"
mkdir -p "$sandbox"/{home,config,data,cache,tmp}
export HOME="$sandbox/home" XDG_CONFIG_HOME="$sandbox/config"
export XDG_DATA_HOME="$sandbox/data" XDG_CACHE_HOME="$sandbox/cache" TMPDIR="$sandbox/tmp"
godot --headless --path game --script res://tests/ocean_float_save_tests.gd --check-only
godot --headless --path game --script res://tests/ocean_float_save_tests.gd
godot --headless --path game --script res://tests/ocean_fresh_profile_tests.gd
godot --headless --path game --script res://tests/save_tests.gd
godot --headless --path game --script res://tests/ocean_save_tests.gd
```

Final regression logs and SHA256SUMS are archived in `docs/evidence/1.3.0/float-save/`. The diagnostic failing growth log is historical evidence; the focused fixed-growth result and final aggregate are separate.
