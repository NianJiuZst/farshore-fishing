# Five-rod/eight-bait full-world balance checks

The four original baits retain their exact per-species attraction weights. New bait definitions can carry explicit `species_weights` for known species and a `legacy_category` fallback for others. `ContentCatalog.bait_weight` is used by the real full-world `EncounterGenerator`, so the additions are not limited to the superseded two-fish trial.

Sweetcorn and dough differ among carp/bream and other cyprinids; cut fish and spinner differ among gar, pike, catfish and perch-like predators. These are authored game-balance values, not measured feeding probabilities or advice about real-world fishing.

`tests/bait_balance_tests.gd` passed33,091/33,091 checks on 2026-10-02: all old attraction values unchanged, all new values finite/nonnegative, explicit new-bait differences, and every one of44 species remains reachable across its actual existing spot, gear depth/reach, cast, time and weather conditions. This is content/encounter logic coverage; it is not evidence that all44 3D models or Android runtime are finished.
