# Native photoreal fish presentation

## Runtime contract

All static fish views use `FishArtView`, a native `TextureRect` backed by an `AtlasTexture`: catalog and favorites thumbnails, species details, the enlarged view, pending-catch thumbnails, and the catch settlement above the ruler. Actual swimming, fighting, breach, and lifting keep their existing 3D models and animation.

- Canonical paths and the four species-data JSON files stay unchanged: `res://assets/fish/<species_id>.png` and `<species_id>_thumb.png`
- Full PNGs are byte-identical to the approved generated masters; no resampling, recoloring, procedural replacement, fake motion shader, or body-aspect distortion is added
- The atlas crops the artist-reviewed alpha subject bounds, plus two source pixels of padding. Cropping does not alter the original PNG
- The catch image's allocated height follows the cropped aspect so the ruler stays close below the fish
- Ruler endpoints use separately reviewed anatomical nose and tail coordinates on the original full canvas, excluding whisker extensions. Right-facing European plaice remains right-facing, with zero at its nose on the right
- Undiscovered catalog thumbnails use a static silhouette shader. Species detail remains visible before discovery, matching the prior behavior
- Views ignore input, retaining the existing `PageScroll` touch-scrolling controls. No pinch gesture was added

## Final integrity gate

`FishArtCatalog.REQUIRE_PHOTOREAL` is true. Startup requires a complete 44-entry `res://data/fish_art.json` with exactly the canonical species set and these integrity checks:

1. Canonical full and thumbnail textures exist and decode to nonempty transparent images
2. Original PNG SHA-256, when source PNGs are available, matches the artist's manifest
3. Decoded imported RGBA8 SHA-256 matches for full and thumbnail textures. These checks also work in exports where only Godot's imported `.ctex` data is available
4. Full and thumbnail sizes and exact subject alpha bounds at threshold 24 match
5. Normalized bounds match original-pixel bounds, and valid nose/tail coordinates lie within the subject
6. Ruler extent matches the anatomical endpoints, including reversed orientation

Missing, partial, duplicate, unknown, empty, invalid, or mismatched content blocks play. The validator does not keep all44 full-resolution GPU textures resident after startup; display textures are loaded as needed. Integrity validation is not biological species certification or Android performance certification.

The artist's manifest is the source for dimensions, bounds, anatomical landmarks, and PNG hashes. After copying approved PNGs to their canonical paths and running the Godot import, this source-only helper adds the decoded imported-image hashes:

    godot --headless --path game --script res://tests/fish_art_import_audit.gd -- --input=<complete-artist-manifest.json> --output=<audited-fish_art.json>

The helper requires `complete:true`, verifies all44 and all88 files, and writes nothing when validation fails. It does not turn on the production gate itself. Generated source hashes are preserved even though Godot's normal import can repair RGB values under transparent pixels.

## Focused tests

Use isolated HOME, XDG_CONFIG_HOME, XDG_DATA_HOME and XDG_CACHE_HOME under `/tmp/farshore-*`, never a player's save directory:

    godot --headless --path game --script res://tests/fish_art_tests.gd
    godot --headless --path game --script res://tests/fish_art_ui_tests.gd
    godot --headless --path game --script res://tests/fish_art_ui_tests.gd -- --tall

`fish_art_tests.gd` covers proportional atlas geometry, full-canvas coordinate transforms, barbel exclusion, right-facing anatomy, static silhouettes, stale-image clearing, low-alpha residue, and corrupt/missing manifest, source-hash, imported-hash and alpha-bound rejection.

`fish_art_ui_tests.gd` loads the actual main scene and final all44 integrity gate, makes legitimate isolated catch records through `SaveStore`, and traverses the real catalog, all44 catch/detail/zoom views, favorites, filters and repeated replacements. It asserts no static 3D fish preview remains, touch scrolling is retained, caught length is unchanged, and the ruler follows the correct photo with a small gap. The real world scene and camera still instantiate. This focused static-page suite disables rendering of the hidden 3D background behind the opaque overlay; inworld rendering remains the responsibility of the existing 3D suites.

To capture selected actual native pages through desktop Mobile Vulkan:

    python3 tools/render_godot.py --timeout 180 -- --path game --script res://tests/fish_art_ui_tests.gd -- --species=european_perch,common_carp,alligator_gar,chinese_sturgeon,european_plaice,southern_catfish,olive_flounder --reference-perch --output=<absolute-output-folder>

`--reference-perch` creates an isolated review specimen of 33.1 cm / 585 g matching the user's reference screenshot, without modifying species data or a player save. `--tall` tests the 720×1584 logical layout. `--photo-fixtures=<manifest>` exists solely for explicitly labeled external-art QA and does not overwrite canonical PNGs or set the production completeness flag.

These checks and captures are desktop/headless evidence. They do not claim a new Android package, target-phone run, safe-area result, frame rate, heat profile, or release upload.
