# Formal-release float encounter validation

Checked 2026-10-03 against the production `FloatEncounter`, `FishingSession`, and `EncounterGenerator`. **The final simulation acceptance passes.** This is headless gameplay evidence, not a claim about mobile frame rate, pixel visibility, Android input latency, or completed device acceptance. The separate visual review remains necessary.

## Final result

[Release matrix summary](evidence/1.2.0/float/release-matrix/summary.json), [raw cases](evidence/1.2.0/float/release-matrix/raw.json), [run status](evidence/1.2.0/float/release-matrix/status.json), and [source hashes](evidence/1.2.0/float/release-matrix/before_sha256.json) record:

- 44 species; 129 legal species/equipment routes covering all five rods; two preferred baits per route across eight paired seeds; clear/rain; 16, 30, and 60 rendered observations per second
- 24,768 complete cast/fight simulations, 1,032 uninterrupted passive traces, and a separate 512-seed encounter sweep
- 6,273/6,273 invariant assertions and 7/7 quantitative gameplay acceptance gates
- Identical production and harness hashes before/after the run; no timeouts

Each strategy has 3,096 casts. Every successful hook uses the same unchanged fight controller, which observes the existing visible fight cues. Hooking and landing are recorded separately; both happen to match in this sample.

| Pre-hook controller | Hooks | Landed catches | Catch rate |
| --- | ---: | ---: | ---: |
| Surface history, 0.35 s confirmation and recovery cancellation | 3,096 | 3,096 | 100.00% |
| Hidden possession oracle, validation control only | 3,096 | 3,096 | 100.00% |
| Blind strike at 5 s after cast | 0 | 0 | 0.00% |
| Blind strike at 8 s | 504 | 504 | 16.28% |
| Blind strike at 11 s | 1,098 | 1,098 | 35.47% |
| Blind strike at 14 s | 495 | 495 | 15.99% |
| First amplitude of at least 0.22, no history | 402 | 402 | 12.98% |
| Earliest small motion, then a 0.18 s reaction | 0 | 0 | 0.00% |

The surface-history controller succeeds on every sampled species/equipment route at all three observation rates. Median strike time is 11.335 s after cast; median latency from the first **sampled** hittable possession is 1.233 s, p90 1.433 s. This latency includes the subtle mouth-seating lead before a developed take; it is not the configured human reaction delay. The configured reaction delay is 0.18 s after recognizing a sustained signal.

All-fish landed fight duration is median 31.396 s, p90 82.892 s, maximum 127.192 s for this controller. These are simulation durations under a consistent skilled control policy, not measured human completion times.

## What the controller can see

`SurfaceReader.update()` receives only `dip`, `lift`, `drag`, `tilt`, and the observation interval. It stores a 0.30 s history, recognizes vertical displacement or directed travel, requires sustained evidence, and applies a 0.18 s reaction delay. A return to baseline cancels a queued strike. It receives no species, state enum, RNG, mouth depth, remaining hold time, session elapsed time, or future action schedule. Its own elapsed clock only timestamps observations and the response delay.

The harness reads hidden state separately to diagnose results, measure possession intervals, and run the explicitly named oracle. Those values never enter `SurfaceReader`. Fixed-time, earliest-motion, and amplitude-only controls are intentionally weak comparison policies. A successful oracle is evidence of available opportunities, not evidence of readable animation.

The quantitative gates require at least 95% of oracle-available opportunities overall and at each frame rate, a 35-percentage-point advantage over the best tested fixed strike, a 15-point advantage over amplitude alone, and no timeout. Invariant checks alone do not establish gameplay acceptance: an earlier matrix passed its invariants but failed the reading comparison below.

## Signals, possession, and repeats

The passive traces contain 3,096 takes: 315 lifts, 1,122 sinks, 1,272 lateral carries, and 387 soft takes. They include 516 direct approach-to-mouth transitions, 1,419 rejected contacts, repeated returns, release, and eventual departure. First hittable take time has p10/median/p90 of 4.925/9.233/16.017 s after the float begins its surface simulation. This excludes the cast animation and differs from the cast-relative controller clock.

Actual damped contact amplitude reaches 0.482; soft takes peak at 0.24. Amplitude therefore cannot universally distinguish contact from possession. Above 0.20, contact pulses last median 0.192 s, p90 0.300 s, maximum 0.317 s. A developed held take remains above 0.22 for median 1.933 s; the shortest sampled interval, including soft takes, is 1.083 s. A player can read continuity and recovery instead of waiting for the largest motion.

Possession is deliberately not identical to a visible displacement threshold. Among passive samples with amplitude 0.22–0.45, 73.23% are hittable; above 0.45, 91.68% are hittable. Strong residual displacement can remain while the float recovers after the bait is released. A late strike must fail there. Tests strike during the actual empty-mouth, contact, carry, spit, and return phases and verify that only held, seated bait hooks; an empty strike cannot later turn into a catch.

The 512-seed supplemental sweep finds 76 direct first takes, 436 exploratory starts, and one complete contact-only departure (seed 1034792). The main eight-seed matrix has no contact-only whole casts, so that matrix alone would not establish this branch. Every ignored sampled encounter eventually departs.

Maximum lateral displacement is 0.424 m. Largest single fixed-tick changes in the main passive matrix are 0.0298 normalized vertical displacement, 0.00146 m lateral displacement, and 0.0149 rad tilt. The float remains inside the tested 0.60 m tether envelope, with no position teleport or tilt sign snap.

## Independent observer robustness

[Independent reader robustness](evidence/1.2.0/float/independent-reader-robustness/summary.json) tests a different seed family from the eight-seed matrix: 128 seeds, carp/horse mackerel/wolffish presentations, 16/30/60 fps, and three confirmation periods (0.25, 0.35, 0.45 s), totaling 3,456 trials. The [tested probe](evidence/1.2.0/float/independent-reader-robustness/probe.gd) and [hash status](evidence/1.2.0/float/independent-reader-robustness/status.json) are retained.

Every confirmation-period/frame-rate group has 381 hooks from 384 casts, zero empty strikes, and zero missed available takes. The three remaining casts contain no hittable take, and the observer correctly does not strike. Thus the result is not dependent on one exact confirmation duration or a single render rate. A separate 256-seed/three-presentation check of the default reader also found zero false strikes; its only three non-hooks were contact-only casts ([evidence](evidence/1.2.0/float/independent-seed-reader/summary.json)).

This robustness is conditional on these tested surfaces and seed samples. It does not establish a human success rate or validate recognition from screen pixels.

## Problems found and retained negative evidence

The rejected runs remain intact; none was relabeled as acceptance.

1. **False confidence from a separated amplitude threshold.** The [first observation matrix](evidence/1.2.0/float/observation-first/summary.json) gave 100% to the history reader. A [threshold audit](evidence/1.2.0/float/threshold-audit/summary.json) then found that a single amplitude threshold also hooked 258/258: damped contact peaked at only 0.109, below every soft take. The same audit found 57 tilt discontinuity failures, maximum 0.285 rad per tick. Production was changed to permit stronger brief contacts and remove the signed tilt flip.
2. **A narrow quick check was insufficient.** The [two-seed retest](evidence/1.2.0/float/threshold-retest/summary.json) showed history 100%, amplitude-only 51.94%, and clean continuity. The expanded run named [full-final](evidence/1.2.0/float/full-final/summary.json) is nevertheless a **failed gameplay candidate**: its original reader committed after only 0.12 s and did not cancel a queued strike after recovery. History achieved only 25.48%, below the 35.47% blind 11 s control. The wider sample exposed contact pulses lasting up to 0.317 s. Its 6,273 passing invariant checks do not change that failure.
3. **Reader correction, followed by independent verification.** The final reader waits for sustained visible evidence and cancels when the float recovers. Its default confirmation is 0.35 s. No production change was made to force the eight-seed result after this failure. The different-seed, three-duration test above was completed before the final acceptance claim. No hidden-state information was added to the observer.

The initial fixed-time diagnostic used ordinary floating-point comparisons, which could delay an integer-second strike by one observation frame. The final harness uses a small numerical tolerance so the fixed policies strike at the same scheduled time across frame rates. Initial and final fixed-time percentages should therefore be read from their own recorded timestamps, not treated as a controlled before/after effect of contact strength alone.

## Lifecycle and unchanged combat

Pause/resume snapshots include the encounter's own RNG, phase, age, mouth depth, possession, hook readiness, float values, and fixed-step remainder. Tests cover fresh edges, a press held through casting, repeated press, input cancellation, pause within the hook transition, reset, distinct session IDs, stale callbacks, and exactly one terminal settlement. Equal elapsed-time pre-hook trajectories are identical at 16/30/60 fps; a long frame consumes all 120 Hz ticks. Existing settlement and protected-observation assertions remain strict.

The full core test passed 182,417/182,417, session observation 126/126, and hazard boundaries 28/28 on stable source ([integration evidence](evidence/1.2.0/float/integration-final/summary.json)). That integration run also truthfully records the old guard test's failure: it required the entire session to match a historical pre-guard source, which the deliberate float rewrite cannot satisfy.

The replacement default `fishing_guard_trace_tests.gd` checks seven exact reviewed combat/settlement function hashes from commit `1637653`, then runs 360 current fight-only cases. It passes 1,305/1,305 including output verification; the [formal combat report](evidence/1.2.0/float/formal-combat/summary.json) preserves results. Its provenance does **not** claim unchanged RNG draws before the fight or unchanged beta2 video timing. `--historical-video` retains the original strict historical source/capture audit; it is not weakened to accept the new float model.

| Fight control | Ordinary 0.35-size fixtures | Giant 0.95-size fixtures |
| --- | ---: | ---: |
| Behavior-aware | 36/36; median 28.49 s | 36/36; median 80.56 s |
| Tension only | 36/36; median 35.16 s | 23/36; median 100.44 s among catches |
| Fixed metronome | 12/36 | 0/36 |
| Always pull | 0/36 | 0/36 |
| Never pull | 0/36 | 0/36 |

These fixtures cover the existing rest/burst/steady fight families, starter/heavy rods, two seeds, and 16/30/60 fps. Every completed case checks single settlement and rejection of a late opposite result. The main release matrix additionally exercises all 44 fish and all five rods through real hooks.

## Reproduction and limits

From the repository root, with the installed Godot 4.6.3 executable:

```sh
python3 tools/run_float_encounter_matrix.py --output build/float-encounter-release
```

The runner creates isolated HOME/XDG directories, executes the real GDScript, records source hashes before/after, and applies both invariant and gameplay gates. Python aggregates results; it does not clone the fishing simulation. `--skip-fights` measures hooking only and must not be described as a catch test. `--quick` uses only 30 fps and omits the 512-seed sweep. `--regressions-only` is appropriate for the ordinary full-catalog suite; it does not replace this matrix.

The matrix selects the minimum legal rod, strongest legal rod, and spinning rod when legal. It does not exhaust every possible species/gear/bait/spot/depth combination. The eight session seeds are intentionally reused across species and equipment for paired comparisons; 24,768 is a case count, not that many independent random encounters. Bait and weather are varied across seeds rather than fully factorial, so their grouped rates cannot establish causal bait/weather effects. The fixed-time benchmark covers four specific times, not every conceivable blind schedule.

The model remains a deliberately simplified float abstraction across deep water and artificial lures. No test validates universal real-world feeding behavior or a natural-history claim for each fish. Float pixel readability, waterline contrast, screen edges, full-submersion presentation, absence of secondary UI/audio/haptic giveaways, Android input cancellation, and device performance require their dedicated visual/device checks. The research and wording boundaries remain in [FLOAT_BITE_RESEARCH.md](FLOAT_BITE_RESEARCH.md).
