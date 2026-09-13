# Gameplay and UI integration verification

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

**Recovery verification pending:** the pre-recovery run passed **42,012 / 42,012 assertions**, art checks enabled, exit code **0**, with no warnings or errors on **2026-10-02**. The test has been reconstructed after an export-directory deletion; current restored production files must pass a new run before this result is considered current. Raw output is written locally to `build/core-tests.log` during development.

## What runs against production code

### Content and encounter generation

- Loads `ContentCatalog`, `FishDefinition`, and both production JSON catalogs
- Confirms 32 unique species and scientific names, four regions, eight spots, three gear tiers, and four free bait choices
- Confirms at least eight fish per region, text/provenance presence, supported behavior IDs, and valid spot/region membership
- Enumerates **5,520 legal combinations** of spot, available gear, cast power, bait, day/dusk, and clear/rain
- Confirms every fish is reachable in at least one combination and every spot has real candidates
- Finds **32 empty combinations**, which are permitted configurations rather than fabricated out-of-region fallbacks; minimum starter cast remains playable
- Confirms bait, time, and weather actually change encounter weights; unknown spots return an empty encounter
- Art-enabled mode validates all **64 fish art and thumbnail references** through the production catalog

### Seeds, size, weight, and difficulty

- Compares 150 paired, same-seed real encounter sequences, excluding only the system wall-clock `caught_at` field
- Checks selection, length, weight, size class, behavior, and difficulty are reproduced
- Generates **5,120 real individuals**, 160 per species
- Verifies integer length/weight bounds, species-specific cubic length-weight anchors and bounded condition variation, uncommon giant individuals, and greater weight/difficulty for larger individuals
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
- Reaches **all 32 species, all four regions, and gear tier 2 in 57 successful catches**, with **281 coins** remaining
- This is an existence proof of an unlocked resource path: the harness deliberately chooses a new reachable species when possible. It is not a prediction of random-player collection time or rarity pacing

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
- Rejecting a gear downgrade below the current spot's requirement

Regressions found during review were fixed in production by the integrator and are retained in this suite: escape Back soft-lock, unprotected exit with an unsaved result, selection mutation before a failed commit, duplicate-retry UI failure, stale-result UI takeover, under-equipped deep-spot selection, and terminal-state Pause/Continue soft-locks.

## Scope limits

- This is headless logic/control integration, **not** Android emulator or physical-device validation
- Main runs with automatic processing disabled; explicit virtual steps drive gameplay. This does not measure frame pacing, GPU performance, battery use, memory stability over hours, or real input latency
- Audio output and vibration are disabled in the Main virtual-time fixture. Cue emission is tested separately, but audible quality, platform suspension, and haptic behavior require runtime/device testing
- Background behavior is invoked through the actual notification handler, not by Android task switching or process kill
- Resource references are checked; this suite does not certify illustration morphology, visual layout, clipping, contrast, or touch-target usability
- The separate `save_tests.gd` suite owns corruption recovery, schema migration, higher-version protection, bounded event data, and 10,000-catch persistence stress
