# Fishing skill balance verification: recovered historical report

## Recovery status

The local execution environment reset at approximately 18:51 UTC on 2026-10-02, after the original completed balance run and local commit. The original raw simulation rows, JSON summary, compressed evidence, and engine log were lost. This report reconstructs only aggregate observations retained in the completed task's working context. **It is historical evidence, not validation of the recovered source. The complete suite must be rerun on the recovered project before claiming the current build passes.** No raw rows or logs have been fabricated.

Original local test/report commit: `c3f6377`. Original stable session tuning checkpoint: `7ffb85a`. These identify the lost local work; they do not assert that those commits are present in the restored Git repository. The externally preserved source baseline was `c7b2b0b`.

The recovered controller is byte-for-byte verified against its original frozen SHA-256:
`1f24bb40dcd4343bd8fbd352d8d6bab66b4f2625d2cf85f9c69d824f475ff7cc`.
The full 360-line GDScript harness and Python launcher/aggregator were reconstructed from retained working context. They require fresh execution with the recovered production session.

## Previously observed run

The run completed on 2026-10-02 before the reset: **18,040 actual GDScript fights, 341/341 regression assertions and all nine balance gates passed**. The observed wall duration was 199.83 seconds, with no engine errors or simulation-input changes during that run. The frozen source inventory included the controller, test harness, session, encounter/catalog/definition scripts, all four fish data files, and world/gear definitions.

| Strategy | Fights | Caught | Catch rate | Catch time p10 / median / p90 |
|---|---:|---:|---:|---:|
| Always pull | 3,608 | 0 | 0% | — |
| Behavior-aware | 3,608 | 3,608 | 100% | 23.623 / 32.591 / 108.583 s |
| Blind one-second pull/release | 3,608 | 1,011 | 28.021% | 36.458 / 38.933 / 84.650 s |
| Never pull | 3,608 | 0 | 0% | — |
| Tension-only | 3,608 | 3,054 | 84.645% | 30.430 / 40.983 / 136.062 s |

The matrix gave every fight policy the same valid hook before comparing battle skill. This avoided inflating blind-policy losses with early strikes. Early/late strike behavior and visual detection were separate regressions.

The behavior-aware controller sampled current visible cues at 15Hz and queued each response for 170ms. Frame quantization made total cue-to-input latency approximately 170–267ms. It waited for surge-warning amplitude ≥0.15 or surge amplitude ≥0.08 rather than reacting to an invisible phase transition. It read current visible recovery pose and tension, never future phase timing, RNG, internal stamina targets, or wear rolls. Tension-only control used the same observation/reaction delay without fish/rod motion.

## Size results previously observed

| Boundary size | Reactive fights | Catch rate | Catch time p10 / median / p90 |
|---|---:|---:|---:|
| Minimum | 1,056 | 100% | 22.150 / 27.867 / 31.183 s |
| Middle | 1,056 | 100% | 27.150 / 32.737 / 38.217 s |
| Maximum | 1,056 | 100% | 96.471 / 104.329 / 114.188 s |

- Same-species, same-gear median maximum/minimum duration ratio: 3.874×
- Same-species, same-gear median maximum/middle duration ratio: 3.246×
- Longest behavior-aware fight: 128.533 seconds
- Tension-only maximum-size catch rate: 529/1,056 = 50.095%, versus 100% with visible-cue control
- Continuous hard pulling lost every maximum-size trial
- Active behavior-aware fights, including all maximum-size fights, had zero wear warnings or wear failures

Equipment used only real legal species/gear routes through encounter filters. Gear IDs differ in reach/depth limits and therefore contain different species mixtures.

## Frame-rate interpretation

Identical clock-aligned input replay previously produced exactly identical fight time, tension, distance, stamina, wear and RNG state at 16/30/60fps. The production model consumed elapsed time with fixed internal steps rather than discarding time at 16fps.

The realistic controller sampled at each external frame rate, so its actual input edges differed slightly. All behavior-aware outcomes remained wins. Its successful-duration spread across frame rates was median 0.637 seconds, p90 4.750 seconds, and maximum 10.283 seconds.

There were 52 borderline outcome disagreements: 34 tension-only cases and 18 metronome cases, with zero reactive disagreements. Among cases caught at all three frame rates, maximum successful-duration spread was 19.933 seconds for tension-only and 21.825 seconds for metronome. These do not justify a blanket claim that all adaptive controller outcomes are frame-invariant. The original individual disagreement rows were lost and must be regenerated.

## Float, input and lifecycle observations

- All 44 species × two seeds × 16/30/60fps: sustained dip/lift/drag observation, 100ms evidence accumulation, then 200ms delayed strike; 264/264 correct hooks and no nibble false positives
- WAITING and NIBBLE accepted an early reel press and terminated an empty cast; no later automatic hook from held input
- Missed strikes timed out without entering a fight
- No bite or nibble audio cue emitted by the session
- One hook edge per press, clean release, no duplicate terminal event or reused catch ID
- Pause froze tested timers, float observations, RNG and fight values; resume retained state and cleared held reel input
- Charge cancellation rejected a late release/cast; background-style cancellation cleared reel input; reset abandoned the round
- A real caught round remained immutable after repeated input and duplicate finish calls

Rendered visibility, fixed camera transform/FOV, button labels/colors and physical float transforms require the separate stage/UI suites. This matrix alone did not certify rendered evidence or Android behavior.

## Organic stale-fight wear observations

Sixteen seeded maximum-size carp fights on gear 4 were deliberately held at low pressure using actual input edges. No test injected wear or selected an RNG result. Control maintained enough line tension to avoid slack escape without completing the retrieve.

- Warning onset: 68.83–87.72 seconds; median 69.008 seconds
- Earliest warning-to-break interval: 23.95 seconds, exceeding the eight-second minimum warning guard
- Within 30 seconds after warning: 2/16 breaks; a seeded sample, not a population probability estimate
- Prolonged stalling eventually broke all 16 by the 500-second observation ceiling
- Four blind metronome trials also ended in wear failure; other blind failures were overload or prolonged slack

## Coverage and fresh reproduction

- 176 legal species/gear routes across all 44 catalog species
- 15,840 boundary fights: 176 routes × three sizes × two session seeds × three frame rates × five policies
- 2,200 randomized fights: 440 independently generated specimen/session seeds × five policies at 30fps
- Boundary specimens begin as real encounter records, then select catalog minimum/middle/maximum size with authoritative weight/difficulty formulas. Randomized specimens retain the production sampler unchanged.
- Godot executes the actual session. Python only launches, hashes inputs, and summarizes results; it contains no clone of fishing physics.

After the recovered files are integrated into the restored project, run:

```sh
python3 tools/run_fishing_balance.py --output /tmp/fishing-balance-recovered
```

Use `--quick` for the reduced 30fps grid or `--regressions-only` for lifecycle/float/wear checks. Each output directory must be new. HOME and XDG directories are isolated. Save the fresh raw output, source hashes, log and summary externally before another environment reset.

The historical aggregate results above should be replaced or supplemented by the newly measured results. Until then, current recovered-build validation remains pending.
