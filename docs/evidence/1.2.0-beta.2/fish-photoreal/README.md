# Canonical all44 static fish art proof

- Complete 44-species manifest, 88 full/thumbnail files: source PNG hashes, decoded imported RGBA8 hashes, nonempty transparency, exact alpha bounds and anatomical landmarks passed
- Post-import canonical PNGs remain byte-identical to the 44 approved runtime masters and 44 thumbnails. No master resampling or recoloring
- Focused geometry and fail-closed gate tests: 34/34
- Actual production main-scene static routes for all 44 species: 1182/1182 at 720×1280 and 1182/1182 at 720×1584
- Real desktop Mobile Vulkan render through Mesa lavapipe: 280/280 for seven selected species (perch, carp, gar, corrected sturgeon, right-facing plaice, southern catfish, flounder), including 23 saved page captures. Final verbose process exit is clean
- The preserved perch catch uses an explicit isolated 33.1 cm / 585 g review record to match the supplied reference screenshot. It is not a player's catch or saved progress
- The five included screenshots are actual native UI captures. The right-facing plaice keeps its orientation and zero at its nose; catfish ruler length excludes barbels; sturgeon uses the final corrected four-barbel PNG
- The art author independently reviewed the final-asset native catalog/detail/zoom and catch composites before canonical integration and requested no art revisions

Scope: Godot 4.6.3, isolated desktop/headless fixtures. The focused static-page render disables the hidden 3D background behind the opaque overlay; the actual world still instantiates and its assets remain unchanged. Separate existing suites own inworld 3D rendering, fishing mechanics and aggregate regression coverage. This evidence does not claim an Android export, target-phone test, release upload, hardware performance or thermal result.

See `docs/FISH_PHOTO_UI.md` for the runtime contract and reproducible test commands. The final production gate is `FishArtCatalog.REQUIRE_PHOTOREAL=true` with `game/data/fish_art.json`. Missing or mismatched final assets block play.
