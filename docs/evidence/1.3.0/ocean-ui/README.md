# Final ocean UI evidence

This is production Main UI verification on desktop software Vulkan, with an isolated test profile. It is not Android installation, device, safe-area, FPS, memory-growth, thermal or battery validation.

## Final results

- [720×1280 log](native-720x1280.log): **902/902 passed**, exit 0, 27 original PNG captures, 339.069 seconds
- [720×1584 log](native-720x1584.log): **902/902 passed**, exit 0, 27 original PNG captures, 354.996 seconds
- [Exact-source and PNG/HUD audit](capture_audit.json): **462/462 passed**, no failures
- Renderer: Godot 4.6.3, Mobile/Vulkan, Mesa `llvmpipe (LLVM 19.1.7, 256 bits)`
- Corrected SaveStore SHA256: `900a7ae2f9b5d30f7b32737c14b9411c588947bba12dd7ff67d91dae08f43660`
- Final corrected-Store headless UI result: **836/836 passed**, recorded in working validation output `build/ocean-final-fixed-qa/ocean_ui.log`

The [baseline manifest](native-720x1280.manifest.json) and [tall manifest](native-720x1584.manifest.json) retain all 54 original frame names, dimensions, hashes, production-input hashes and main-viewport 3D state. Every fishing capture has main-world rendering enabled. The [evidence index](evidence_index.json) binds these selected files to exact source paths, byte counts and SHA256 values; [SHA256SUMS](SHA256SUMS) also covers the local evidence files.

## Representative original frames

1. [Fresh lobby: 1500 currency and zero discoveries](fresh_profile_lobby_720x1280.png)
2. [Great-white detail at the taller aspect](great_white_detail_720x1584.png)
3. [Actual Indian Ocean boat/HUD with restored world rendering](ocean_boat_720x1584.png)
4. [All twelve baits are reachable; four new giant-bait choices](twelve_baits_720x1280.png)

Only these four PNGs are duplicated into the source repository. All **54** original PNGs remain in `build/ocean-ui-final`; that full directory is the input for the separate release-validation ZIP. The manifests therefore reference additional frames that are in the full validation collection, not in this compact source-evidence folder.

## Reproduce the read-only audit

From a complete source checkout, after extracting the full validation collection:

```sh
python3 tools/audit_ocean_ui_captures.py build/ocean-ui-final
```

An [exact copy of the audit tool](audit_ocean_ui_captures.py) is preserved here for inspection. It reads original RGB pixels without resizing or changing screenshots, compares all PNG/source SHA256 values, checks renderer/aspect/world-restoration metadata, and checks wallet text, coin, pause label and pause icon against independently reviewed nonempty foreground masks. These masks verify pixel presence and shape, not OCR or device behavior.

The UI harness suppresses the main viewport's 3D draw only behind a verified fully opaque, fullscreen 2D gradient. Actual scene/resources remain loaded; independent SubViewports are untouched. It restores 3D before every visible-world assertion/capture. See the [full validation report](../../../OCEAN_UI_VALIDATION.md).

## Retained warning and resolved review discrepancy

Both completed runs emit `WARNING: 7 RIDs of type "Texture" were leaked` at renderer shutdown. The same warning appeared in the earlier independent Stage-only ocean renderer without Main/HUD or viewport toggling. Its exact cause remains unproven; no production cache clearing or assertion suppression was added to hide it. This warning does not establish Android memory behavior or runtime growth.

An apparent missing wallet/pause issue during visual review was disproved by inspecting the exact saved PNGs and their pixel masks. All 20 fishing frames retain complete, identical nonempty wallet/coin/pause foregrounds at both aspects. No production HUD repair was needed.
