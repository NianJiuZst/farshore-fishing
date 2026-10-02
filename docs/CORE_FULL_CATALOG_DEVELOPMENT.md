# Full-catalog development logic checkpoint

2026-10-02: `core_tests.gd -- --skip-ui` passed182,334/182,334 checks after extending the ordinary-fight benchmark to all five rods. The added heavy rod was adjusted from power1.58 to1.52 when the expanded test found a standard roach fight at9.83s; all five rods now satisfy the existing ordinary10–25.5s timing bounds without weakening that assertion.

The zero-currency, release-only progression simulation reached all44 species, six regions and all five purchased rods in100 actual generated/session-resolved catches, spending exactly3070 coins and retaining a nonnegative balance. Existing old-species attraction values and protected release-only settlement remain intact. `save_tests.gd` separately passed314/314, including10,000 catches and a real disk roundtrip.

This is explicitly **not the complete aggregate suite**. The old Main integration fixtures were run and failed while the full44-asset readiness gate correctly disabled entry; their remaining adaptation and full gameplay run must happen after all models exist. Partial-build UI has a separate test that checks disabled entry and safe browsing without bypassing the gate. Final release requires the complete unskipped core/UI/animation/render/build checks on the final frozen source.

Raw logs: `build/full-catalog-checkpoint/core_logic.log`, `save_tests.log`. These logs describe the current development checkpoint, not Android hardware certification.
