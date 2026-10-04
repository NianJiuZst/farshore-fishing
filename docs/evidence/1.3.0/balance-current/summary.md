# Fishing skill balance evidence

Actual production GDScript, seeded RNG, isolated save environment. Python only aggregates results.

Scope: Quick 30fps grid

## Strategy outcomes

| Strategy | Runs | Catch rate | Catch duration p10 / p50 / p90 (s) |
|---|---:|---:|---:|
| always_pull | 877 | 0.0% | None / None / None |
| behavior_aware | 877 | 99.9% | 25.671 / 37.642 / 113.583 |
| metronome | 877 | 29.0% | 36.411 / 40.13 / 96.939 |
| never_pull | 877 | 0.0% | None / None / None |
| tension_only | 877 | 83.8% | 30.083 / 44.733 / 136.697 |

## Regression and balance gates

- PASS: all 74 species simulated
- PASS: observable reactive strategy wins at least 95%
- PASS: active reactive fights never receive premature wear warning
- PASS: never pulling cannot catch
- PASS: always pulling at least 35 percentage points worse than reactive
- PASS: blind metronome at least 20 percentage points worse than reactive
- PASS: median within-species max/min fight duration ratio at least 2
- PASS: continuous hard pull cannot land maximum-size giants
- Regression assertions: 70/70
- Frame-rate outcome disagreements: 0
- Maximum successful-duration spread across frames: 0 s
- Median same-species, same-gear maximum/minimum size duration ratio: 3.759
- Median same-species, same-gear maximum/middle size duration ratio: 2.998
- Visual-only hook trials: 0/0
- Organic stale-wear trials: {'runs': 16, 'warning_seconds_p10': 68.942, 'warning_seconds_p50': 69.025, 'warning_seconds_p90': 69.075, 'earliest_break_warning_lead': 29.567, 'break_within_30s_after_warning': 1, 'note': 'Observed seeded sample, not an estimated population probability; indefinite stalling accumulates risk.'}

## Interpretation and limits

The fight matrix deliberately hooks correctly before comparing fight policies, so blind-policy failure is not inflated by early strikes. Separate regressions exercise early/late strikes and held input. Boundary fixtures take a real generated record and deterministically select catalog min/mid/max sizes; random samples retain production EncounterGenerator sampling. All equipment combinations have a verified candidate route through the actual encounter filter. The reactive policy samples visible cues at15Hz and queues responses for170ms (about170–267ms total with frame quantization). Windup detection waits for visible warning amplitude0.15; active surge detection waits for amplitude0.08. The reactive policy reads only player-observable fight phase/tension; it cannot read the next phase, RNG, stamina target, or wear roll. Stamina, wear and RNG may be recorded for diagnostics but never drive that policy.

These are mechanics/control checks. They do not certify rendered visibility, Android behavior, localization legibility, or save settlement integration. Those require the separate integration and visual suites.

## Representative reactive failures

```json
[
  {
    "behavior": "steady",
    "caught": false,
    "failure": "浮漂恢复了原来的水线，鱼已松口离开。可以重新抛竿",
    "fight_seconds": 0.0,
    "fps": 30,
    "fraction": 0.810480876693985,
    "gear": 3,
    "max_tension": 0.34,
    "phase_count": 0,
    "sample": "random",
    "seed": 2674624750,
    "size": "random",
    "species": "cobia",
    "strategy": "behavior_aware",
    "terminal_events": 1,
    "warning_lead": -1.0,
    "warning_time": -1.0,
    "weight_g": 38711
  }
]
```
