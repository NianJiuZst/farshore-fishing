# Full-world Main travel transaction checkpoint

2026-10-02. This checkpoint addresses stale travel and save/scene agreement. Its24/24 boundary assertions also pass in the final full-catalog matrix; current frozen results are in [3D_ACCEPTANCE.md](3D_ACCEPTANCE.md). The partial-asset aggregate run below remains historical development evidence.

## Controller guarantees

- Main checks the boolean scene-load result before saving a destination or updating its labels
- Scene rejection preserves the existing saved selection, Main selection, HUD labels and travel retry page
- If the scene accepted a destination but the save failed, Main restores its previous selection and asks the stage to restore that exact prior region/spot; no destination labels are published
- If rollback itself fails, gameplay is blocked and the user receives a restart message rather than being allowed to cast in an inconsistent location
- Initial location failure disables entry; entering a fishery also rechecks the actual location before changing mode
- Queued travel callbacks cannot interrupt a landing or any unresolved current catch, including CAUGHT and a stale IDLE state with an unresolved record
- The stage owner separately made rejected scene loads atomic, preserving IDs, definitions and live roots until both replacement Node3D scenes validate

## Focused evidence

`game/tests/main_travel_tests.gd` passed **24/24** headless controller-boundary assertions. It uses actual Main, actual saved-state writes/reload and actual regional scene travel. The explicit rejecting-scene double tests only scene-failure propagation. Synthetic unresolved records are identified as boundary fixtures, never settled, and the test asserts zero earned catches. The real44 readiness flag is checked against Registry and never overridden.

Log: `build/full-catalog-checkpoint/main_travel.log`. Use an isolated `/tmp/farshore-...` HOME/XDG_DATA_HOME and run `godot --headless --audio-driver Dummy --path game --script res://tests/main_travel_tests.gd`.

## Aggregate fixture adaptation

`core_tests.gd` now requires the actual44-model registry before Main gameplay. Missing resources are one explicit failing dependency assertion with the complete missing list, disabled-entry assertions and a `full gameplay checks NOT RUN` marker; it no longer cascades into impossible trial-fixture casts. The no-UI logic option remains explicitly incomplete.

Full-world expectations now check ordinary Encounter location eligibility, real expanded spot buttons and their equipment/depth restrictions, real biome agreement and the deep-water entry gate. Existing settlement failure/retry, terminal idempotence, Back/background, stale completion, protected-observation sale refusal, release retry and reloaded pending-record assertions remain in place.

The adapted aggregate was run while18 imported fish resources were missing: **182,341/182,342 assertions passed; overall FAILED** solely at the required44 asset dependency. This is not full gameplay verification. Rerun unskipped after all44 assets are imported and again on the final frozen source.
