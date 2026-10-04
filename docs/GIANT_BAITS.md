# Giant-target bait expansion

This is fictional game balance, not a real-world feeding model or fishing guide. The changes append four free, unlimited baits to the existing eight. They do not change natural-history data, species IDs, rod prices, region unlocks, spot geography, hook input, or fight rules.

## Appended choices

| Stable ID / icon ID | Chinese name | Authored target emphasis | Ordinary size exponent | Theoretical same-species giant share |
|---|---|---|---:|---:|
| `large_fish_chunk` | 大块鱼肉 | Freshwater catfish and gar; giant grouper | 0.88 | 15.2503% |
| `whole_mackerel` | 整尾鲭鱼 | Large ocean predators, especially sharks, wahoo and barracuda | 0.84 | 15.8345% |
| `large_squid` | 大只鱿鱼 | Swordfish, bigeye tuna, opah and other deeper pelagic targets | 0.80 | 16.4725% |
| `large_surface_lure` | 巨物波扒 | Tuna, giant trevally, marlin and sailfish | 0.92 | 14.7133% |

Names fit the existing four-character HUD budget. The last hint explicitly identifies the bait as a 大型水面拟饵. Every hint labels its claims as 游戏设定 and explains either the lack of a guaranteed hook/landing or the continuing rod/depth restrictions.

The existing order and full definitions of `worm`, `grain`, `shrimp`, `lure`, `sweetcorn`, `dough`, `cut_fish`, and `spinner` are unchanged. All 12 have price zero. Inventory/save selection continues to use actual stable bait IDs; no new currency or consumable system is introduced.

## Two separate effects

1. **Which species appears:** explicit `species_weights` in `world.json` apply only to listed targets. Other species retain their category preference multiplied by the new bait's `fallback_weight_scale` (0.14, 0.10, 0.12, 0.10 respectively). Existing baits omit that field and keep a multiplier of exactly 1.0. Positive fallback weights preserve legal reachability rather than silently deleting species from the catalog. Normalized catch composition also depends on the other eligible fish, rod, cast, time and weather; the weights are not probabilities.
2. **How large that species is:** the new bait's `size_exponent` reshapes its ordinary `u^exponent` size draw. The 2% extended branch, `u^2.6` tail, normal upper bound, game maximum, weight model, relative size classes and difficulty calculation all remain intact. This is a conditional individual-size effect, not a chance of successfully landing a fish on every cast.

For the existing 74 species, giant means relative size fraction greater than 0.88; extended-branch specimens are also giants. Its theoretical probability is:

`0.02 + 0.98 × (1 − 0.88^(1 / size_exponent))`

The original eight baits retain exponent 1.55 and the existing 9.7581% giant share. The new baits increase same-species giant frequency to roughly 14.7–16.5%, leaving plenty of ordinary and small specimens. They do not enlarge the extreme-tail chance or any species' maximum.

## Configuration and integration

- `game/data/world.json` is the sole source for target weights, fallback scale and size exponent
- `ContentCatalog.bait_size_exponent` indexes the data once, refreshes on a successful catalog load, and lazily reads the same file for direct specimen-generation callers that have no catalog argument
- `EncounterGenerator.make_individual` performs no additional random draw; both normal and extended branches preserve the legacy draw sequence
- `ContentCatalog` rejects nonnumeric, nonfinite or out-of-range tuning: fallback scale 0–1, size exponent 0.75–2.0. The shipped new bait values additionally have hard tests requiring their theoretical giant probability to remain between 14% and 18%
- Real `generate()` uses the same weighting and size lookup as direct tools/tests. Preparation still uses the ordinary salinity, gear, cast and depth gates. The new surface lure receives the suspended presentation rather than the bottom-feeder soft-bait presentation
- Existing `FloatEncounter` possession/strike logic and `FishingSession` fight mechanics are unmodified. Bait affinity still flows through their existing bounded handling. A large bait is neither an automatic hook nor an automatic landing

## Verification

The focused suite uses real Catalog, EncounterGenerator and FishingSession code, isolated HOME/XDG directories, and an explicit report path. It performs no editor import, export, signing, installation or publication.

The golden fixture was captured before the change from the production logic at `c89ba4503104c449c97072867dbdd8baf63c5e67`. It contains the full original-eight bait definitions, exact 74×8 attraction values, seeded record/RNG hashes and source hashes. This is an immutable regression fixture, not a second production tuning source.

The final suite passed **7,187,621/7,187,621 assertions** with zero failures. Results are recorded in `docs/evidence/1.3.0/giant-baits/giant_bait_report.json` and `giant_bait_tests.log`:

- 37,888 original-eight seeded records match every field other than wall-clock timestamp, plus the final RNG state
- All original eight bait definitions and 592 original attraction values remain exact
- All six fish JSON and six encyclopedia JSON files are byte-identical; all world content other than baits remains semantically identical
- All 888 bait/species pairs have a legal real candidate route and are actually produced by real weighted generation; 15,244 total draws, longest individual search 1,094 draws
- Seven matched-route selectivity comparisons use 12,000 actual generated encounters per bait, 168,000 encounters total
- 2,368,000 generated individual draws cover all four new baits and all 74 species, 8,000 per pair; every specimen respects game length/weight caps and the unchanged size-based difficulty formula
- Paired legacy/new samples preserve the RNG sequence, never reduce size/difficulty, and keep extended-tail specimens exactly equal
- Every new bait still generates small specimens and has a rare, reachable extreme tail
- Early striking fails for each new bait. In four generated giant sessions, constant pulling and no pulling fail; the existing delayed visible-cue controller lands the fish in 96.4–113.9 seconds. These are deterministic logic fixtures, not a promise of real-player success

Observed aggregate same-species giant shares:

| Bait | Samples | Observed giant share | Observed small share |
|---|---:|---:|---:|
| 大块鱼肉 | 592,000 | 15.1709% | 13.8500% |
| 整尾鲭鱼 | 592,000 | 15.7777% | 12.6329% |
| 大只鱿鱼 | 592,000 | 16.3988% | 11.4049% |
| 巨物波扒 | 592,000 | 14.6361% | 15.0958% |

The same per-species seeds are intentionally reused across bait comparisons. The strictly-above-normal measured share is 1.8274%; this differs from the 2% branch probability because the extended draw can round to the ordinary maximum in integer millimetres. The branch itself is unchanged.

Example actual matched-route encounter counts (12,000 draws per column):

| Target | Intended bait | Target encounters | Comparison bait | Target encounters |
|---|---|---:|---|---:|
| Alligator gar | 大块鱼肉 | 1,554 | 整尾鲭鱼 | 438 |
| Giant grouper | 大块鱼肉 | 9,200 | 巨物波扒 | 123 |
| Great white shark | 整尾鲭鱼 | 739 | 巨物波扒 | 25 |
| Swordfish | 大只鱿鱼 | 1,417 | 整尾鲭鱼 | 40 |
| Opah | 大只鱿鱼 | 1,818 | 巨物波扒 | 48 |
| Giant trevally | 巨物波扒 | 11,808 | 大只鱿鱼 | 4,169 |
| Indo-Pacific sailfish | 巨物波扒 | 1,506 | 整尾鲭鱼 | 136 |

These are deliberately chosen legal test routes; they are not universal species probabilities. Full UI touch/scroll/icon, save progression and native rendering acceptance remain separate integration checks.

## Reproduce

```sh
run_root="$(mktemp -d /tmp/farshore-giant-baits.XXXXXX)"
mkdir -p "$run_root"/{home,data,config,cache} build/giant-baits
HOME="$run_root/home" \
XDG_DATA_HOME="$run_root/data" \
XDG_CONFIG_HOME="$run_root/config" \
XDG_CACHE_HOME="$run_root/cache" \
FARSHORE_GIANT_BAIT_REPORT="$PWD/build/giant-baits/giant_bait_report.json" \
godot --headless --path game --script res://tests/giant_bait_tests.gd
```
