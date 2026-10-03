# 1.2.0 acceptance record

Source freeze acceptance on 2026-10-03. The tests below passed before export.
The release attachments separately record measured APK/source digests, signing,
export audits and publication; this source document does not predict those hashes.

## Change and preserved behavior

The float now reports a seeded fish/bait interaction: approach, optional touch,
mouth intake, held bait and movement, release, retreat, and possible return.
Hooking checks current bait possession and hook depth with a fresh input edge;
there is no mandatory elapsed WAIT/NIBBLE/BITE countdown or input-time win roll.
The internal compatibility states still drive the same hidden-water UI. The
button, camera, sound and vibration do not announce a take.

Brief contacts can overlap a small genuine take in amplitude. Their recovery
and duration distinguish them. A damped load drives the detailed antenna float,
while its waterline follows the same analytic waves as the river. Lateral
movement turns gradually against the line before leaving the fixed view. Old
fight-water impulses are cleared at the next cast. The player can open a short
reading guide from preparation or settings; it freezes and resumes the same
encounter and does not promise one universally successful indication.

The angler is replaced with a MakeHuman Community CC0 derivative with original
Farshore adaptation and fishing animation. The promoted asset retains a 4K
garment normal texture, 30 bones and five clips. Provenance and the distinction
between the GPL authoring tool and CC0 art are documented with the asset.

All 44 fish GLBs, original gameplay fish definitions, fish art and save-schema
inputs remain byte-identical to beta3. Four new offline encyclopedia data files
provide independently sourced natural-history facts without changing historical
species IDs or gameplay size ranges. Every one of the 44 entries includes family
and genus, current scientific-name display, qualified ordinary size, separate
maximum length and weight evidence, distribution, habitat, behavior, diet and a
source-backed natural-history story. A total of 140 per-species source entries
connect each field to its evidence. Unknown maxima remain null; regional upper
sizes and angling records retain their actual scope. Real-world facts, game size
settings and personal catch snapshots appear in separate sections.

The detail screen preserves first-screen fish artwork and personal count/length/
weight summary, and adds jump controls and explicit optional external-source
links. Reading facts remains offline. Opening a page does not increment catches.
Accepted taxonomic labels do not rewrite old saved IDs or record snapshots.

 Seven combat/terminal function bodies in FishingSession remain identical
to beta3: surge reset, fight start, phase selection, next phase, fight physics,
wear hazard and terminal settlement. The encounter RNG is now a separate stream;
therefore old exact seed traces are historical evidence, not current outcomes.
The save schema is unchanged. This release keeps the preview package and key so
beta2/beta3 can be updated without deliberately creating a new data namespace.

## Evidence requirements

- Float matrices distinguish fixed-time, first-motion, amplitude-only,
  observation-history and hidden-oracle controls. The oracle is a correctness
  check and never evidence that the visual signal is readable
- Retain failed intermediate matrices. The first strengthened-contact matrix
  exposed a queued-strike controller that committed even after motion recovered;
  its poor result is not a release pass. Independent seeds and multiple
  observation delays must check the revised visible-only decision rule
- Regressions cover fixed-step determinism, pause/input cancellation, repeated
  encounters, empty/late strikes, no-take departures and one-shot settlement
- Actual native captures cover normal/tall aspect ratios, calm/rain lighting,
  short contacts, soft/lift/sink/travel takes, rebound, detailed float geometry,
  new-character cast/reel/lift, the guide and detailed encyclopedia pages
- The complete aggregate runs after all production/test inputs are frozen
- Before export, create and verify an external commit-exact source archive.
  Export only from a copied isolated project, then reverify primary sources
- Signed APK checks include identity/version, permissions, Vulkan, exact art
  payloads, all four exact encyclopedia JSON files and their loader, required scripts/shader, native alignment and the existing public
  certificate. Publication requires remote main/tag and all artifact digests

## Source history and attribution

The user-authorized 2026-10-03 identity/date correction rewrote Git commit IDs
without changing source trees. The published beta3 baseline now resolves to
`86c383d61dbe3173313bdf9b7320161eed535a26`; its historical evidence names
`16376531830d462ae802b14c2cb06795f3c00be4`. Existing released APK/source bytes
and their original provenance were preserved. Historical capture documents can
therefore retain a pre-rewrite revision alongside measured file hashes; the
formal artifact manifest records its new frozen source revision. The 19 then
unpublished development commits and all uncommitted encyclopedia edits survived
the ref transplant with independently checked file hashes and unchanged index.
New commits use NianJiuZst for both author and committer.

## Device boundary

The target is Android 16 on the user's Snapdragon 8 Elite phone. Desktop
Mobile/Vulkan software rendering, Viewport-injected touch and static APK checks
do not establish Android installation, actual touchscreen mapping, retained
phone saves, driver behavior, frame rate, thermals or battery use. Those remain
physical-device acceptance. A 20fps exported demonstration describes capture
sampling, not measured phone performance.

## Final results

- The combined run passed all 25 suites and the independent 44-model binary audit,
  with the complete runtime/test input manifest unchanged. Raw logs and manifests
  are in [combined-headless](evidence/1.2.0/combined-headless/). It includes 314
  save checks, 182,417 core checks, 94 current float regressions, 360 fight cases,
  4,515 integrated 3D-flow checks (49 casts, 45 landings, 44 species, 12 spots),
  all44 bait reachability and actual Viewport touch/drag controls
- The original notebook suite remains 313/313. The new natural-history suite is
  948/948 headless; native runs at both 720×1280 and 720×1584 pass 969/969 with
  10 actual screenshots each. Sources are inspected and click callbacks intercepted;
  no test opens a browser. Native input tests retain the current paused page and
  separate catch snapshots through background/focus transitions. See
  [natural-history UI QA](NATURAL_HISTORY_UI_QA.md)
- All44 entries passed independent field/source-scope review with four substantive
  corrections retained in [the factual review](ENCYCLOPEDIA_INDEPENDENT_REVIEW.md).
  There are 140 per-species sources; ordinary-adult size gaps are disclosed rather
  than replaced by invented averages. Content review does not certify every
  historical record as a current world record
- The float/human native review passed within its selected desktop scope, including
  the repaired 50ms quick-recast framing. See [visual review](FORMAL_VISUAL_REVIEW.md)
  and [float validation](FLOAT_ENCOUNTER_VALIDATION.md). Earlier rejected captures
  and tests remain labeled as failures, never counted as the final pass
- All32 packaging regression groups pass, including new offline-data corruption,
  archive membership/export-byte gates and isolated staging ownership safeguards.
  The final exporter verifies the commit-exact external source ZIP before operating
  on an independent copied project. Actual final APK and remote results belong in
  the release's validation attachment, bound to the frozen commit and artifact hashes

This is a formal release classification with disclosed test scope. No physical
Android16 device, phone-update retention, measured phone FPS or thermal test is
claimed by these desktop and static checks.
