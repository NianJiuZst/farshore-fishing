# Ocean expansion production UI validation


## Final corrected-source result

**The requested desktop UI checks pass.** Final headless Main UI: **836/836**, from `build/ocean-final-fixed-qa/ocean_ui.log`. Final native Mobile/Vulkan runs: **902/902 at 720×1280** and **902/902 at 720×1584**, 27 captures each. The exact-source/54-PNG/HUD-foreground audit passes **462/462**. Production source hashes remain unchanged through both runs and the post-run audit.

- [Compact final evidence, logs, manifests and four representative images](evidence/1.3.0/ocean-ui/README.md)
- [Read-only reproducible audit tool](../tools/audit_ocean_ui_captures.py)
- Full 54-frame validation collection: `build/ocean-ui-final`, retained for the separate release-validation ZIP
- Final SaveStore SHA256: `900a7ae2f9b5d30f7b32737c14b9411c588947bba12dd7ff67d91dae08f43660`
- Native adapter: Mesa `llvmpipe (LLVM 19.1.7, 256 bits)`; Godot 4.6.3 Mobile/Vulkan

Both native runs retain a seven-Texture-RID shutdown warning, also present in the independent earlier Stage-only renderer. Exact cause is unresolved and recorded separately. This is **not Android/device/FPS or overall release acceptance**. The broader aggregate/release checks are owned by the release report.

## Scope

The new `game/tests/ocean_ui_tests.gd` drives the actual `main.tscn`, unchanged production readiness checks, imported fish portraits and models, travel scenes, native UI controls and SaveStore. It never substitutes models, changes `_content_ok`/`_models_complete`, or fabricates catches. Only an isolated test fixture owns all rods and unlocks nine regions to exercise travel. Both `HOME` and XDG data must live beneath a fresh `/tmp/farshore-*` directory before Main may initialize.

This is desktop source/UI regression evidence. Native captures use Godot 4.6.3 Mobile/Vulkan through the scoped Mesa lavapipe/Xvfb harness. They do not validate an Android device, safe-area values, touch hardware, installation/upgrade, GPU frame rate, thermal behavior or battery use. The UI test harness does not change signing or package settings.

## Coverage

- Genuine fresh-profile policy: 1500 currency, six earlier regions/twelve earlier spots, unchanged starter gear, zero catches and all three oceans still locked
- Full 9-region / 18-spot / 74-species catalog, all thumbnail tiles and all nine region choices
- Real ScreenTouch catalog entry and zoom/Back paths for great white shark, both hammerheads, Atlantic and Pacific bluefin, yellowfin, bigeye, albacore, skipjack and dogtooth tuna
- Correct accepted scientific names, full natural-history paragraphs, honest zero-catch summary and explicitly separate fictional game-size ranges
- Real ScreenDrag over long catalog/detail/gear pages; scroll-end bounds and source-action reachability
- Full-resolution portrait cache limited to four entries, with an actual currently displayed original surviving cache eviction, plus separate thumbnail retention
- All twelve bait controls: distinct names/icons/hints, real touch selection, selected-state rebuild, scroll-end reachability and durable save reload; no change to unrelated progress. All four new giant baits additionally enter the visible fishing HUD with exact selected names and caption-within-button geometry checks
- Actual 90 m giant-rod preparation shows the 100 m wolffish blocker; the 180 m deep-rod preview removes it
- Real travel-button taps across all 18 spots; saved selection, Main selection and rendered stage agree
- Enter, pause/Back and return-to-lobby paths for all six new ocean spots; ocean horizon and sea-ambience configuration
- Repeated detail / zoom / catalog / preparation / lobby navigation and zero mutation of browsing-only saved progress
- Separate runs and captures at 720×1280 and 720×1584; no reduced original-image resolution

The fixture freezes gameplay processing for deterministic UI checks. A test-only rendering optimization suppresses the main viewport’s 3D draw only when a real fullscreen GradientTexture2D overlay is verified to have alpha 1 at every stop and in its modulation. The actual imported world/resources remain loaded, independent SubViewports are untouched, and transparent lobby/uncovered fishing views restore the main 3D draw. Every ocean entry and world capture asserts rendering resumed, and each capture manifest records this flag. This is not a production rendering change or a performance benchmark. For fishing-HUD captures only, it settles the unchanged production camera interpolation with `_update_camera(100.0)` rather than substituting a custom viewpoint.

## Native startup harness fix

Production Main deliberately yields between loading stages only under a native renderer. Ten existing Main test harnesses and four Main capture helpers previously accessed scenery/sound immediately after `add_child`, which could fail before native startup completed. They now wait at most 120 seconds for the real `_startup_complete` flag, then fail/quit if it was never set. Existing content assertions and production loading UX remain unchanged. The new ocean suite uses its own equivalent 180-second bound.

Affected existing tests: `core`, `main_travel`, `fish_art_ui`, `fish_notebook_ui`, `natural_history`, `slice3d`, `ui_style`, `touch_scroll`, `ui_iteration`, and `fast_recast_camera`.

Affected capture helpers: `capture_float_material_smoke.gd`, `capture_float_presentation.gd`, `capture_full44_main.gd`, and `capture_observation_video.gd`.

## Evidence status

Prior-configuration checkpoint: the first full headless baseline run passed 695/695 checks with no script/runtime errors (`build/ocean-ui-headless-initial/1280-native-input.log`). That run predates the subsequently requested fresh-profile progression and giant-bait changes. This earlier pass is not acceptance of the new configuration. Static review and `git diff --check` have passed. Godot 4.6.3 `--headless --check-only` passes for the new ocean suite and all 14 startup-patched harnesses; the latter evidence is `build/ocean-ui-startup-parse/summary.json`. Earlier development attempts exposed and corrected two harness issues, not production defects: the optional `reduce_motion` fixture field needs an explicit String key for SaveStore JSON safety; fixed footer Buttons require native mouse events because direct Viewport touch injection bypasses global touch-to-mouse emulation. Catalog/travel gestures remain real ScreenTouch/ScreenDrag events. No production validation or UI assertions were weakened.

Native command shape, after the coordinated import:

```sh
python3 tools/render_godot.py --timeout 3600 -- \
  --path game --script res://tests/ocean_ui_tests.gd -- \
  --output=/absolute/new/evidence/directory
# Add --tall after the second -- for 720x1584.
```

The render harness provides isolated HOME/XDG paths and an authenticated temporary display. Each output directory must be new. Each native evidence manifest records size, renderer/adapter, check counts and failures, captures with SHA256 digests, elapsed time and production source/manifest digests. The suite verifies those source inputs remained unchanged throughout its run.


### Prior-configuration native attempts

- `build/ocean-ui-native/720x1280.log`: strict startup and all featured detail/zoom/scroll, LRU, depth-preview and gear checks progressed without logged assertion/script failures, then the external 1,200-second render budget expired before full travel coverage. This is an incomplete run, not a pass.
- `build/ocean-ui-native/720x1584.log`: equivalent partial captures were produced, then the renderer ended with signal 9 (wrapper exit 247). The exact termination cause was not established; this is not a pass or an Android result.
- `build/ocean-ui-native-final/720x1280.log`: sequential unchanged retry used a 3,600-second budget, then was intentionally interrupted through its own execution session (exit 130) when the new user scope arrived. No final acceptance report was produced.
- Partial real captures were visually checked for catalog layout/end reachability, great white and hammerhead/Atlantic-bluefin details, tall source buttons, full-resolution active-image retention, and 90 m/180 m wolffish preparation. These showed no clipping or loss of image content. All partial evidence is retained under the above directories and must not be described as final two-aspect validation.


## Earlier fresh-profile and giant-bait checkpoint

The production freeze now includes the coexisting-installation identity, 1500-currency/six-earlier-region fresh profile, all twelve baits/four giant-bait icons, and corrected giant-landing camera margin.

- Headless 720×1280: **836/836 passed**, exit 0, no script/runtime errors; `build/ocean-ui-giant-baits/headless-1280.log`
- Headless 720×1584: **836/836 passed**, exit 0, no script/runtime errors; `build/ocean-ui-giant-baits/headless-1584.log`
- Optimized native 720×1280: **902/902 functional assertions passed**, 27 real captures, exit 0, 366.786 seconds; `build/ocean-ui-giant-baits/native-720x1280/manifest.json`
- Optimized native 720×1584: **902/902 functional assertions passed**, 27 real captures, exit 0, 313.637 seconds; `build/ocean-ui-giant-baits/native-720x1584/manifest.json`
- A suspected blank-wallet/partial-pause issue from multi-image preview review was overturned by exact saved-PNG checks: all baseline fishing-frame SHA256 values match their manifests, and all ten wallet and pause text masks are byte-identical and nonempty. Separate gold-coin/pause-icon masks and independent single-image inspection confirm complete HUD content. No production UI change was warranted.
- Both native runs report seven Texture RIDs at renderer shutdown. The same warning exists in the earlier stage-only `build/ocean-baseline/ocean-render.log`, before the new UI harness/viewport suppression. It is recorded separately; its exact cause and Android implications are not established.
- These first giant-bait native runs preceded a separately identified exact JSON-readback persistence correction. Both aspects were subsequently rerun against the corrected frozen Store, as recorded in the final result above. The earlier passes remain historical evidence only.

The four giant-bait IDs tested explicitly are `large_fish_chunk`, `whole_mackerel`, `large_squid`, and `large_surface_lure`. Source evidence now also fingerprints their actual PNGs and the production icon, catalog and encounter scripts. Public signing-certificate identity metadata is outside the runtime fingerprint list and cannot establish Android installation/upgrade success.
