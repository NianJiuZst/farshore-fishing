# Ocean photoreal fish artwork

Thirty separate, newly AI-generated fish portraits for Farshore Fishing, generated on 2026-10-04 with OpenAI's built-in image-generation tool. These are photorealistic illustrations, not actual wildlife photographs or diagnostic scientific plates.

- `masters/`: 30 accepted original RGBA PNG outputs, 1,536–1,947 pixels wide, preserved byte-exactly
- `runtime/`: 30 byte-identical master copies
- `thumbs/`: 30 lossless RGBA PNG derivatives, 512 pixels wide, downsampled with ImageMagick Lanczos
- `asset_manifest.json`: full dimensions, exact alpha bounds at threshold 24, normalized anatomical nose/bill and tail endpoints, orientation, file hashes and morphology references
- `art_provenance.json`: actual original prompts, chronological edit prompts, final image identities, source citations and review scope
- `generation_specs.json` and `*_prompt.txt`: preserved species-specific generation and correction specifications
- `manual_endpoints.json`: reviewed full-canvas source-pixel endpoints. All fish face left. Billfish include bill tip; sharks use the farthest natural caudal tip. No barbels occur in this set
- `revision_history/`: nine superseded original/edit outputs, excluded from runtime. Their hashes are in `revision_history.json`
- `review/contact_sheet.jpg`: paper-background review composite of the 30 accepted portraits
- `validation_report.json`: technical and visual-review outcome

There are 90 production PNGs in this archive plus nine superseded historical PNGs. Each fish was generated independently. No third-party fish image was downloaded or embedded; no atlas splitting, alternate-species reuse, procedural fish drawing, recoloring or full-resolution upscaling substitutes were used. Biological references support morphology and do not grant or assert image licensing. No public-domain or Creative Commons claim is made.

## Anatomy review and revisions

Every original full-body output was reviewed, and the accepted set was checked on the game's paper color `#edf0e4`. Species-level distinctions include short/long tuna pectorals, skipjack lower-body stripes, adult yellowfin sickles, billfish dorsal profiles, absence of swordfish pelvic fins, grouper rounded tail, barracuda separate dorsals, roosterfish comb, opah proportions, and shark head/gill/fin/tail patterns. Hammerhead body profiles are lateral, with slight natural cephalofoil foreshortening to make their different leading edges visible.

Accepted targeted edits corrected blue-marlin stray finlets, tiger-shark tail-base bumps, cobia separate dorsal spines, yellowfin pectoral reach, and opah pectoral/pelvic proportions. Cobia's final visible spine count is seven, within its referenced 7–9 range. Roosterfish had a background-extraction recheck; its alpha was confirmed clean on paper compositing. The opah's last edit repaired alpha after an anatomy edit. Historical outputs and exact prompts remain retained.

Review checks major illustrative morphology and recognizability. It does not certify every fin-ray count, precise diagnostic proportions or taxonomy. The two bluefin species are naturally similar and were generated as distinct specimens rather than assigned fabricated diagnostic colors.

## Runtime integration

Canonical game assets are `game/assets/fish/<species_id>.png` and `<species_id>_thumb.png`. New Godot import metadata uses the existing lossless texture settings, with transparent-RGB border repair enabled. Decoded RGBA8 image hashes were computed in an isolated Godot 4.6.3 project using the identical `res://assets/fish/` paths and identical import parameters. The complete game manifest preserves all 44 previous entries and adds these 30. It binds both immutable source manifests using `source_manifests`; the old legacy `source_manifest_sha256` is retained unchanged.

`build_asset_variants.py` rebuilds copies, thumbnails and source manifests from existing generated masters and reviewed landmarks. It does not generate or paint fish. Rebuilding changes source-manifest bytes and requires re-running decoded-image audit/binding before runtime integration. Use `python3 verify_backup.py` for read-only verification.
