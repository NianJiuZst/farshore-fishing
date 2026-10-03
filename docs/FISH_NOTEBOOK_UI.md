# Fish notebook UI

The native Godot notebook groups the catalogue, species page and favourites into one paper-like reading flow. Original 44 fish photos are shown by the existing `FishArtView`; source textures, alpha bounds, anatomical landmarks, ruler and in-world 3D scene are unchanged.

## Integration contract

`FishNotebookUI` is a `RefCounted` presentation builder. Main owns navigation, session state, search/filter fields and every persistent write.

- `populate_catalog(app, page, refill) -> GridContainer` builds the discovery totals, Chinese/Latin search, region/discovery filters and sort control
- `fill_catalog(app, grid, open_species)` populates the filtered grid from a detached `SaveStore.state` snapshot
- `populate_species(app, page, species_id, open_zoom, favorite)` reads the real biological description, morphology, in-game locations, bait weighting, sources and saved capture records
- `populate_favorites(app, page, open_catalog, open_species)` shows the actual saved collection and a useful empty state

Navigation callbacks receive the species ID. They can preserve the originating page and catalogue scroll position. The builder does not settle catches, unlock species, alter favourites or write a save. Main's existing favourite callback is the only mutation path, and its control is disabled in save protection mode.

## Whole-fish input contract

Each catalogue/favourite entry is one native `Button`, named `FishTile_<species_id>`, with `fish_species_id` and `notebook_tile` metadata. Its native `text` is the Chinese fish name for accessibility. The text is visually transparent because a separate child label provides the intended hierarchy. All children, including the original `FishArtView`, use `MOUSE_FILTER_IGNORE`; there are no nested buttons or native Range controls inside a tile.

The existing production `TouchScroll` finds the Button ancestor from the actual image, title or whitespace hit. It owns Android touch cancellation and synthesized mouse suppression. The notebook does not implement a competing gesture recognizer. Filters and actions have 96px logical minimum heights, while specimen targets are 324px tall.

## Record truth and first screen

The detail page puts the Chinese name, Latin name, full-resolution specimen and personal capture summary before the biological reading sections. `CatchRecordSummary` contains semantic `CatchCount`, `MaxLength` and `MaxWeight` nodes.

- Zero captures: show `0 条`, missing-record dashes and a clear undiscovered state; species information is readable without creating a catch
- One capture: show the exact committed count and measurements, with a first-encounter message
- Multiple captures: read `max_length` and `max_weight` independently and retain both original snapshots
- `CatchSnapshot_max_length`, `CatchSnapshot_max_weight`, `CatchSnapshot_first` and `CatchSnapshot_last` carry detached snapshot metadata for audit and display each original pair of measurements, location and time
- Regional totals come only from `species_stats[species_id].regions`; unavailable early-save details remain explicitly unavailable

The headline never constructs a fictional fish by combining the longest specimen's length with the heaviest specimen's weight. Both maxima are separate metrics; the full entries below retain their own dimensions and provenance.

## Focused verification

`game/tests/fish_notebook_ui_tests.gd` instantiates the actual Main scene, requires production content/model/photo validation and refuses to run outside isolated `/tmp/farshore-*` HOME and XDG data roots. Fixtures use `begin_session`, `settle_catch`, `dispose_catch` and `commit_state`, never a player save or direct private-state injection.

Coverage includes actual Viewport ScreenTouch on all 44 catalogue fish images, title and whitespace hits, favourite action and favourite photo, vertical/horizontal ScreenDrag cancellation, unchanged discovery state after unknown-species browsing, above-fold zero/one/many summaries, exact separate maxima/first/latest snapshots, 2+1 regional counts, catalogue filtering and empty/full favourites.

Run a headless behavior pass:

```sh
HOME=/tmp/farshore-notebook-home XDG_DATA_HOME=/tmp/farshore-notebook-data XDG_CACHE_HOME=/tmp/farshore-notebook-cache godot --headless --audio-driver Dummy --path game --script res://tests/fish_notebook_ui_tests.gd
```

Run actual desktop Vulkan/Mesa captures through the repository's isolated rendering harness:

```sh
python3 tools/render_godot.py --timeout 240 -- --path game --rendering-method mobile --rendering-driver vulkan --script res://tests/fish_notebook_ui_tests.gd -- --output=/tmp/farshore-notebook-portrait
```

Add `--tall` for a 720×1584 viewport. The ordinary portrait viewport is 720×1280. Output states are catalogue unknown/discovered, species zero/one/many and favourites empty/one/six. Real rendered screenshots require pixel inspection; passing this desktop suite does not claim Android hardware validation.

## Verified beta.3 result

On 2026-10-03, the integrated production Main passed 313/313 headless checks at 720×1280 and 322/322 checks with real Vulkan screenshots at both 720×1280 and 720×1584. Nine captures per viewport cover unknown/discovered catalogue, zero/one/many species summary, the separate detailed record snapshots, and empty/one/six favourites.

Pixel review confirmed readable Chinese/Latin hierarchy, full fish bodies, no dark or filled specimen cards, unclipped count/size summaries above the fold, separate longest/heaviest measurements with their own original locations and dates, and usable empty collection guidance. The final portrait rerun also exited cleanly after screenshot reference cleanup. Original photo, ruler and 3D assets were not edited.
