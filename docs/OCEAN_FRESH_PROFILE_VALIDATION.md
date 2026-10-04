# Separate ocean app: compensated fresh profiles

## Requested profile policy

A genuinely new local profile receives exactly:

- 1,500 coins
- The six original regions, in original order: `lake`, `japan`, `norway`, `med`, `bayou`, `yangtze`
- The original starter rod only: `gear: 0`, `owned_gear: [0]`
- Zero discovered species, catches, pending fish, favorites, settled catch IDs, playtime or fabricated transactions
- The unchanged lake-shore/worm starting selection and unchanged settings

The six region unlocks cover the twelve original spot listings. The new Pacific, Atlantic and Indian Ocean regions remain locked. Their respective discovery/cost requirements remain 20/450, 28/600 and 36/750. This change does not edit world content, equipment, bait, encounter probabilities or UI.

**Equipment access is separate from region unlocks.** Existing `Main._can_use_spot()` still checks rod tier and minimum depth. With starter rod 0, some spots in the unlocked original regions still require purchasing/selecting an appropriate rod. These persistence tests verify region unlocks and spot bindings; they do not claim all twelve spots are immediately fishable with rod 0.

## Implementation boundary

`SaveStore.default_state()` remains the historical schema-normalization baseline: 120 coins and lake-only unlocks. Required source currency is still validated, so this default does not fabricate currency for an incomplete save. Missing optional unlock fields retain the historical lake-only meaning.

`SaveStore.fresh_state()` changes only the currency and original region list. The initializer calls it only after proving there is no primary or rolling backup. Existing saves, schema 1 migration, imported raw JSON/checksummed envelopes, rollback recovery and undo/redo continue through the historical normalizer. There is no compensation flag, replayable grant or schema/version change.

Fresh initialization now publishes the new profile and enables writes only after persistence succeeds. A failed initial write cannot export or commit the unverified in-memory profile. A later initialization may safely recover a verified initial backup or create the fresh profile if no committed primary/backup was produced.

The previously repaired import/undo rollback behavior is unchanged. Existing/imported currency, region unlocks and catches remain authoritative, including zero balances and explicit subsets of region unlocks.

## Automated validation

Official Godot `4.6.3.stable.official.7d41c59c4`, headless Linux, 2026-10-04:

- `ocean_fresh_profile_tests.gd`: **423/423 passed**, exit 0
- Literal old-44-species `ocean_save_tests.gd`: **1,154/1,154 passed**, exit 0; no changes to this suite
- Existing `save_tests.gd`: **314/314 passed**, exit 0; eight fresh-balance assertions use an independent literal 1,500-coin expectation instead of the superseded 120-coin start; no historical fixtures or reward amounts were changed
- The 10,000-catch/10,000-disposition test retains exact one-time economics, bounded state, real-disk final persistence and restart; serialized final state was 5,436 bytes
- `--check-only` succeeds for the new profile suite and adjusted original save suite
- `git diff --check` succeeds for these edits

The dedicated suite covers fresh creation and independent nested defaults; exact primary and initial backup content; zero fabricated progress; all original region/spot bindings; unchanged ocean unlock gates; repeated restarts after spending the full 1,500 coins; schema 1, schema 2 and omitted-version saves with missing optional fields; zero old balances; every original region's existing selection; import preview/import/restart/undo/redo without compensation replay; explicit selected-region unlock subsets, including later earned ocean progress; and portable checksum preservation.

Six real-filesystem initial-creation faults are injected: primary temporary write, temporary validation, backup temporary write, backup replacement, primary replacement and final primary validation. Each verifies failed initialization cannot publish/write/export a fresh profile, then exercises safe retry, persistence and restart. Existing zero-balance backup recovery, corrupt files, future primary/backup schemas and unresolved import rollback protection are also covered.

The old compatibility suite emits its documented expected `Failed to open ...does-not-exist` line for the deliberate rollback-copy failure case. This is separate from parser/runtime failures; its assertions pass.

Before the eight expected-balance updates, the original suite reported 297/314 because 17 assertions still assumed the old fresh 120-coin profile. No unrelated failures were observed. All 314 pass after aligning those fresh-only expectations.

## Reproduction

From the repository root:

```sh
sandbox="$(mktemp -d /tmp/farshore-fresh-validation.XXXXXX)"
mkdir -p "$sandbox"/{home,config,data,cache,tmp}
export HOME="$sandbox/home" XDG_CONFIG_HOME="$sandbox/config"
export XDG_DATA_HOME="$sandbox/data" XDG_CACHE_HOME="$sandbox/cache" TMPDIR="$sandbox/tmp"
godot --headless --path game --script res://tests/ocean_fresh_profile_tests.gd --check-only
godot --headless --path game --script res://tests/ocean_fresh_profile_tests.gd
godot --headless --path game --script res://tests/ocean_save_tests.gd
godot --headless --path game --script res://tests/save_tests.gd --check-only
godot --headless --path game --script res://tests/save_tests.gd
```

Every suite creates additional unique `/tmp/farshore-*` fixture directories and never reads player `user://` data. Raw logs for this run are in `build/ocean-fresh-profile-validation/`. These are filesystem/logic tests, not Android device installation, signing, upgrade or touch/UI validation. The release now uses the separately approved coexisting app identity; previous same-package signing statements in earlier validation reports describe the earlier upgrade plan, not this new-profile policy.
