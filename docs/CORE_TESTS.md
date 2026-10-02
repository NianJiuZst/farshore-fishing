# Gameplay and UI integration verification

## Current native-3D slice checkpoint

On **2026-10-02 at 11:33 UTC**, the real current Main and all legacy production classes passed **69,160 / 69,160 assertions**, `--check-art` enabled, exit 0, with no ERROR/WARNING output. Log: `build/qa3d/core.log`. This supersedes the historical UI baselines below; the numeric total is unchanged because the same four retired-destination assertions were replaced one-for-one with explicit archived-destination assertions.

The Main fixture now enters through `_show_prepare()` → `_enter_fishery()` rather than trying to close the startup lobby into fishing. Successful protected-observation fixtures advance the actual stage's landing clock before expecting a result overlay. Legacy travel destinations remain in the catalog/save, but are not advertised as playable 3D locations. Starter gear is valid in the managed trial while the archived deep-water selection remains unchanged. Pure encounter reachability, all 44 species, progression, conservation and transactional persistence assertions remain intact; the old 44-species progression is a retained-data compatibility test, not a claim that 44 native 3D fish are playable.

`slice3d_tests.gd` independently covers the full presentation-bound production Main route, actual skinned meshes and animations, both playable species, camera changes, interrupted casting/landing, immediate durable saves, deferred results and duplicate callbacks. `touch_scroll_tests.gd` separately owns actual viewport touch gestures. See `3D_ACCEPTANCE.md`.

## Result and reproducible command

Engine: **Godot 4.6.3.stable.official.7d41c59c4**. Tests use the shipped GDScript classes, current JSON content, real scene controls, and real SaveStore disk transactions. No fishing, encounter, or settlement algorithm is reimplemented in the test harness.

From the project root:

```sh
run_root="$(mktemp -d /tmp/farshore-core-home.XXXXXX)"
mkdir -p "$run_root/home" "$run_root/data" "$run_root/config" "$run_root/cache"
HOME="$run_root/home" \
XDG_DATA_HOME="$run_root/data" \
XDG_CONFIG_HOME="$run_root/config" \
XDG_CACHE_HOME="$run_root/cache" \
godot --headless --path game --script res://tests/core_tests.gd -- --check-art
```

An imported Godot project is required for texture/font loading; open the project in the locked editor, or perform an editor import first when testing a freshly unpacked project. `--check-art` makes missing fish art/thumb references fail. Without that flag, catalog checks can run during content production, although the Main integration test still uses the application’s own startup validation.

Every SaveStore fixture uses a newly created `/tmp/farshore-core-*` directory. The separate HOME and XDG directories isolate the Main startup path from a player's real save. Tests print the fixture path. Failures produce `FAIL:` lines and a nonzero process exit. The numeric assertion count includes repeated candidate/sample checks and is not a count of independent scenarios.

**Expanded-content verification: 69,160 / 69,160 assertions passed**, art checks enabled, exit code **0**, with no warnings or errors. A fresh editor import, Godot process, and isolated HOME/XDG directories tested the full 44-species project and redesigned Main on **2026-10-02 at 09:10 UTC**. Current raw output: `build/core-tests-expanded.log`; import output: `build/import-expanded-test.log`. The separate persistence suite passed **314 / 314** assertions, including all existing recovery/stress tests and 113 new conservation/compatibility checks.

The earlier 32-species post-recovery baseline passed 42,012 / 42,012 assertions at 08:35 UTC after checkpoint `31fdf64c64f665508533f04c707abafe1a329b06` (`build/core-tests-recovered.log`). Existing session, save-failure, navigation, and terminal-state regressions are retained in the expanded suite. A semantic empty-search hint check replaces an obsolete exact child-layout assumption; it still requires the actual visible explanatory text.

During content production only, `-- --skip-ui` explicitly omits Main integration and prints that omission. The 69,093 / 69,093 preliminary logic-only pass is recorded in `build/core-tests-expanded-logic.log`; it is not used as the full-suite result. The final command above uses no skip flag.

## Painted-icon regression checkpoint

On 2026-10-02 during 10:12–10:14 UTC, the final full `--check-art` suite (including actual Main, with no `--skip-ui`) passed **69,160 / 69,160**, exit 0, on frozen production UI commit `334d594a99bd86fed030a344a48125d6c5a0c56f`. The raw output is `build/core-tests-painted-icons.log`. The first run exposed orphan result labels at exit despite passing the behavioral assertions; the UI owner repaired conditional label allocation, and this subsequent run contained **no ERROR, WARNING, or leaked-resource output**. This distinction is important: behavioral assertion success alone was not called a clean runtime pass.

The expanded painted-interface suite is documented in `UI_STYLE_TESTS.md`; it separately checks all 25 HD raster assets, actual runtime bindings, transparent control states, compact HUD, active catalog/settings/catch controls, and interruption routes. All 41 recorded production/test/scene/project/icon file hashes stayed unchanged during the final full runs; exact evidence is in `UI_REGRESSION_MANIFEST.json`.

## What runs against production code

### Content and encounter generation

- Loads `ContentCatalog`, `FishDefinition`, and all four production JSON catalogs
- Confirms exactly 44 unique species and scientific names, six regions, twelve spots, three gear tiers, and four free bait choices
- Confirms at least eight fish per region in both content membership and actual reachable candidate sets, text/provenance presence, supported behavior IDs, and valid spot/region membership
- Enumerates **7,440 legal combinations** of spot, available gear, cast power, bait, day/dusk, and clear/rain
- Confirms every fish is reachable in at least one combination and every spot has real candidates
- Finds **64 empty combinations**, which are permitted configurations rather than fabricated out-of-region fallbacks; minimum starter cast remains playable
- Confirms bait, time, and weather actually change encounter weights; unknown spots return an empty encounter
- Art-enabled mode validates all **88 fish art and thumbnail references** through the production catalog

### Seeds, size, weight, and difficulty

- Compares 150 paired, same-seed real encounter sequences, excluding only the system wall-clock `caught_at` field
- Checks selection, length, weight, size class, behavior, and difficulty are reproduced
- Generates **7,040 real individuals**, 160 per species
- Verifies integer length/weight bounds, species-specific cubic length-weight anchors and bounded condition variation, uncommon giant individuals, and greater weight/difficulty for larger individuals
- Every sample preserves the exact boolean conservation flag and conservation note; protected observations always have a zero sale value, while ordinary fish retain their existing sale economics
- The tests validate the game model; they do not establish scientific accuracy of its tuning coefficients

### Fishing sessions and interruptions

- Exercises the real input/state order: charge → cast → wait → nibble → bite → fight → caught
- Verifies the cast, nibble, bite, and hook cue signals occur distinctly and once
- Checks charge saturation, duplicate casts, detached input records, empty encounters, missed bites, excessive tension, and extended slack
- Pauses each of casting, waiting, nibble, bite, and fighting for 1,000 virtual steps
- Verifies elapsed time, charge, tension, progress, fight time, slack/overload timers, wait duration, RNG state, session identity, and exact individual are frozen
- Repeated pause/resume and canceled touch/held input do not leave reeling latched
- Compares otherwise identical interrupted/uninterrupted sessions through actual completion, including exact fish and fight duration
- Repeated terminal callbacks cannot duplicate success, turn success into failure, or turn failure into success

### Behavior and timing

The scripted player uses the real `press`, `release`, and `step` methods, reeling below 46% tension and releasing above 58%. The benchmark uses actual generated **standard-size** individuals at within-species size fraction 0.267; large fish are not mislabeled as ordinary fish.

| Actual representative | Behavior | Starter gear | Travel gear | Deep gear |
| --- | --- | ---: | ---: | ---: |
| Common bream | Continuous pull | 24.47 s | 17.65 s | 13.98 s |
| Rudd | Short bursts | 23.30 s | 17.30 s | 13.53 s |
| Roach | Pull/rest intervals | 20.32 s | 15.35 s | 12.58 s |

All nine combinations succeed. Continuous pull has one phase; burst and rest each expose two distinct production phases. These measurements cover the **12.58–24.47 second** ordinary benchmark, rather than claiming every species, size, player strategy, or frame rate has that duration. Larger tested individuals can take approximately 27–29 seconds on starter gear.

### Real catch accounting and growth

- Drives three real successful sessions of one species through `SaveStore.settle_catch`, disposal, and disk reload
- Injects an actual FileAccess open failure in one settlement; failed writes publish no count/reward, and exact-record retry counts once
- Checks bite-only activity, escaped/abandoned rounds, and duplicate callbacks do not count
- Confirms sale and release preserve historical catches and unique discovery totals
- Starts progression with **zero currency**, uses only currently reachable candidates, plays every encounter through the actual session, and uses only the ordinary catch reward plus release bonus
- Pays actual configured gear and travel prices while respecting discovery gates
- Reaches **all 44 species, all six regions, and gear tier 2 in 87 completed encounters**, with **221 coins** remaining
- Verifies every journey follows unlocked-region and spot-equipment gates, every round earns exactly 25 + 8 coins, every purchase spends earned currency, and the seven required purchases total exactly **2,650 coins**
- Verifies the new discovery/currency thresholds remain Mississippi **20 / 450** and Yangtze **28 / 600**, with no added gear beyond tier 2; the full earned collection and unlock state survives a real disk restart
- This is an existence proof of an unlocked resource path: the harness deliberately chooses a new reachable species when possible. It is not a prediction of random-player collection time or rarity pacing

### Protected conservation observation

- Confirms exactly one protected species, stable ID `chinese_sturgeon`, with an explicit conservation explanation
- Drives its real generated individual through the production session, settlement, direct sale rejection, JSON reload, and successful release
- Confirms sale rejection changes neither state nor currency; release preserves the complete observation history and discovery count and grants only the ordinary release bonus once
- This is an explicitly virtual field-guide observation, not a claim about lawful real-world capture
- Detailed four-boundary settlement/release I/O failures, exact retries, forged nonzero sale values, and legacy schema-2 compatibility are covered by `save_tests.gd` and documented in `SAVE_TESTS.md`

### Main integration and regressions

The tests instantiate the real `main.gd` Control and operate its actual methods, signals, and visible Back button. They cover:

- Action buttons creating the round and catalog navigation preserving the exact encounter
- Application focus loss opening a paused overlay rather than advancing the round
- Missed bite opening an escape page without a historical count
- Visible escape Back returning to a playable idle state
- Failed catch save staying on its result page; Back preserving identity; attempted exit protecting the unsaved result
- Save retry, a second queued retry, result reopening, and disposition without double-counting
- Window-close, Pause, and Continue from caught/escaped terminal states retaining the result or returning to playable idle
- Old completion callbacks failing to replace a newer cast or its UI
- Catalog/favorite views referencing existing history without creating catches
- Empty search results displaying a helpful hint
- Failed destination and bait writes rolling live selections back
- Equipping starter gear in the managed trial while preserving an archived deep-water selection
- Rejecting both new-region unlocks below their discovery or currency threshold; failed writes and duplicate callbacks cannot spend the unlock cost twice
- Verifying four archived destinations retain data but have no false playable-3D travel controls; a permitted legacy selection still persists through the existing compatibility method
- Running a protected compatibility session through Main immediately saves its observation, then opens a result after the actual landing timer, with guidance and no sale button
- Direct protected result and pending-page sale callbacks are blocked by the actual transaction layer
- Actual release controls recover from injected disk failures, return to playable idle or clear the pending entry, and preserve all historical records without duplicate income
- Reopening the protected pending page after a real disk reload preserves its release-only controls

Regressions found during review were fixed in production by the integrator and are retained in this suite: escape Back soft-lock, unprotected exit with an unsaved result, selection mutation before a failed commit, duplicate-retry UI failure, stale-result UI takeover, under-equipped deep-spot selection, and terminal-state Pause/Continue soft-locks.

## Scope limits

- This is headless logic/control integration, **not** Android emulator or physical-device validation
- Main runs with automatic processing disabled; explicit virtual steps drive gameplay. This does not measure frame pacing, GPU performance, battery use, memory stability over hours, or real input latency
- Audio output and vibration are disabled in the Main virtual-time fixture. Cue emission is tested separately, but audible quality, platform suspension, and haptic behavior require runtime/device testing
- Background behavior is invoked through the actual notification handler, not by Android task switching or process kill
- Resource references are checked; this suite does not certify illustration morphology, visual layout, clipping, contrast, or touch-target usability
- The separate `save_tests.gd` suite owns corruption recovery, schema migration, higher-version protection, bounded event data, and 10,000-catch persistence stress
