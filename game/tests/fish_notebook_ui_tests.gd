extends SceneTree
## Real Main, isolated SaveStore fixtures, and actual Viewport touch injection.
## --output=/absolute/path enables real rendered zero/one/many screenshots.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const View = preload("res://scripts/fish_art_view.gd")
var app: Control
var checks: int = 0
var failures: int = 0
var output: String = ""
var save: SaveStore

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var isolated: String = OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(isolated + "/"):
		printerr("NOTEBOOK_UI: refusing non-isolated save environment")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	root.size = Vector2i(720, 1584 if "--tall" in OS.get_cmdline_user_args() else 1280)
	root.disable_3d = true
	app = Main.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)
	_check(app._content_ok and app._models_complete and app.fish_art.complete, "production assets and all74 original photos are valid")
	save = Store.new()
	_check(save.initialize(isolated.path_join("notebook-%s" % Time.get_ticks_usec())), "isolated production SaveStore fixture")
	app.store = save
	app.encounter.rng.seed = 20261003
	app._show_catalog()
	await _layout()
	_check(app._page.name == "FishNotebookCatalog", "Main routes to the production notebook builder")
	if app._page.name != "FishNotebookCatalog":
		app.queue_free()
		quit(1)
		return
	_check(app._list.get_child_count() == 74, "all74 fish have native whole-tile targets")
	await _capture("catalog_zero")
	var before: Dictionary = save.state
	# Touch each actual species image, including entries initially off screen.
	for id: String in app.catalog.fish:
		app._show_catalog()
		await _layout()
		var tile: Button = _tile(id)
		_check(tile != null and tile.text == app.catalog.fish[id].name, "species has one named native Button: " + id)
		if tile == null: continue
		_check(_buttons(tile).size() == 1, "image/title never form nested buttons: " + id)
		var scroll: ScrollContainer = _scroll()
		scroll.scroll_vertical = int(tile.position.y)
		await _layout()
		var photo: Control = tile.find_child("FishArtPreview", true, false)
		_check(photo != null and photo.mouse_filter == Control.MOUSE_FILTER_IGNORE, "native full-tile target owns image hit: " + id)
		if photo == null: continue
		var point: Vector2 = photo.get_global_rect().get_center()
		_check(scroll.get_global_rect().has_point(point), "image tap is inside actual visible viewport: " + id)
		await _tap(point)
		_check(app._screen == "species", "actual ScreenTouch on fish image opens details: " + id)
		var latin: Label = app._page.find_child("SpeciesScientificName", true, false)
		_check(latin != null and latin.text == app._scientific_name(app.catalog.fish[id]), "details match tapped Chinese and accepted Latin species: " + id)
	_check(before == save.state and save.discovered_count() == 0, "browsing all74 unknown fish never creates catches or unlocks")
	app._show_species("common_carp")
	await _layout()
	_check(_metric_text("CatchCount") == "0 条" and _metric_text("MaxLength") == "—" and _metric_text("MaxWeight") == "—", "zero-catch summary uses honest count and missing-record dashes")
	_check(app._page.find_child("NotebookFavorite", true, false) == null, "unknown fish has no favorite mutation")
	_check(_summary_above_fold(), "zero-catch summary is above fold")
	_check(_text_contains(app._page, str(app.natural_history.get_entry("common_carp").typical_size.text)), "verified natural-history introduction is present")
	_check(_text_contains(app._page, app.catalog.fish.common_carp.morphology), "actual morphology remains present")
	_check(_text_contains(app._page, "游戏内寻鱼") and _text_contains(app._page, "游戏鱼饵线索"), "game locations and bait clues are separately labelled")
	await _capture("species_zero")
	app._show_favorites()
	await _layout()
	_check(_text_contains(app._page, "收藏第一种喜欢的鱼"), "empty favorites gives a useful honest state")
	await _capture("favorites_zero")
	var first: Dictionary = _settle("first", "lake_shore", "lake", 600, 1200, "2026-10-01T09:00:00")
	app._show_species("common_carp")
	await _layout()
	_check(_metric_text("CatchCount") == "1 条" and _metric_text("MaxLength") == "60.0 cm" and _metric_text("MaxWeight") == "1.20 kg", "one-catch headline reflects exact settled measurements")
	_check(_summary_above_fold(), "one-catch summary is above fold")
	for key: String in ["max_length", "max_weight", "first", "last"]: _check(_snapshot(key) == first, "single catch is the actual " + key + " snapshot")
	await _capture("species_one")
	var second: Dictionary = _settle("second", "yangtze_river", "yangtze", 500, 1700, "2026-10-02T10:00:00")
	var last: Dictionary = _settle("last", "lake_bay", "lake", 450, 900, "2026-10-03T11:00:00")
	app._show_species("common_carp")
	await _layout()
	_check(_metric_text("CatchCount") == "3 条" and _metric_text("MaxLength") == "60.0 cm" and _metric_text("MaxWeight") == "1.70 kg", "many-catch summary reads independent length/weight maxima")
	_check(_snapshot("max_length") == first and _snapshot("max_weight") == second, "longest and heaviest retain separate real fish instead of invented combined individual")
	_check(_snapshot("first") == first and _snapshot("last") == last, "first/latest retain exact original catch snapshots")
	_check(_text_contains(app._page.find_child("CatchRegion_lake", true, false), "2 条") and _text_contains(app._page.find_child("CatchRegion_yangtze", true, false), "1 条"), "regional counts reflect legitimate 2+1 catch fixture")
	_check(_summary_above_fold(), "many-catch summary is above fold")
	await _capture("species_many")
	var length_snapshot: Control = app._page.find_child("CatchSnapshot_max_length", true, false)
	if length_snapshot != null: _scroll().scroll_vertical = int(length_snapshot.position.y)
	await _layout()
	await _capture("species_many_records")
	# Whole-tile title and whitespace are real touch targets too.
	for part: String in ["title", "edge"]:
		app._search = "Cyprinus carpio"
		app._show_catalog()
		await _layout()
		var tile: Button = _tile("common_carp")
		var point: Vector2 = tile.find_child("FishTileName", true, false).get_global_rect().get_center() if part == "title" else tile.get_global_rect().position + Vector2(tile.size.x - 3, 24)
		await _tap(point)
		_check(app._screen == "species", "actual ScreenTouch on tile " + part + " opens details")
	app._search = ""
	app._show_catalog()
	await _layout()
	await _test_drag(false)
	app._show_catalog()
	await _layout()
	await _test_drag(true)
	app._show_species("common_carp")
	await _layout()
	var favorite: Button = app._page.find_child("NotebookFavorite", true, false)
	await _tap(favorite.get_global_rect().get_center())
	_check("common_carp" in save.state.favorites, "actual touch on favorite commits through Main and SaveStore")
	app._show_favorites()
	await _layout()
	await _capture("favorites_one")
	var favorite_tile: Button = _tile("common_carp")
	await _tap(favorite_tile.find_child("FishArtPreview", true, false).get_global_rect().get_center())
	_check(app._screen == "species", "favorite image is an actual native touch target")
	# Render a fuller collection from legitimate captures, retaining the distinct maxima.
	for id: String in ["european_perch", "olive_flounder", "atlantic_cod", "painted_comber", "alligator_gar"]:
		_settle_other(id)
	var candidate: Dictionary = save.state
	candidate.favorites = ["common_carp", "european_perch", "olive_flounder", "atlantic_cod", "painted_comber", "alligator_gar"]
	_check(save.commit_state(candidate), "six favorites committed from legitimately caught species")
	app._show_favorites()
	await _layout()
	await _capture("favorites_six")
	app._discovery_filter = 1
	app._show_catalog()
	await _layout()
	_check(app._list.get_child_count() == 6, "discovery filter uses real SaveStore counts")
	await _capture("catalog_discovered")
	_check(app.scenery is Node3D and app.scenery.camera is Camera3D, "notebook preserves actual 3D world")
	app.fish_art._textures.clear()
	app.queue_free()
	app = null
	save = null
	for frame: int in range(5): await process_frame
	print("FISH_NOTEBOOK_UI_TESTS: ", checks - failures, "/", checks, " passed; ", root.size, "; actual Main + Viewport touch, no Android claim")
	call_deferred("quit", 0 if failures == 0 else 1)

func _settle(tag: String, spot: String, region: String, length_mm: int, weight_g: int, caught_at: String) -> Dictionary:
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish.common_carp, spot, region, "worm", 2, "day", "clear")
	record["session_id"] = "notebook_" + tag
	record["catch_id"] = "notebook_catch_" + tag
	record.length_mm = length_mm
	record.weight_g = weight_g
	record.caught_at = caught_at
	save.begin_session(record.session_id)
	var settled: Dictionary = save.settle_catch(record)
	_check(bool(settled.get("ok", false)), "legitimate settled fixture: " + tag + " " + str(settled))
	_check(bool(save.dispose_catch(record.catch_id, "released").get("ok", false)), "legitimate released fixture: " + tag)
	return record

func _settle_other(id: String) -> void:
	var fish: FishDefinition = app.catalog.fish[id]
	var spot: String = str(fish.spots()[0])
	var region: String = str(app.catalog.spots[spot].region_id)
	var record: Dictionary = app.encounter.make_individual(fish, spot, region, "worm", 2, "day", "clear")
	record["session_id"] = "notebook_" + id
	record["catch_id"] = "notebook_catch_" + id
	save.begin_session(record.session_id)
	_check(bool(save.settle_catch(record).get("ok", false)), "legitimate collection fixture: " + id)
	_check(bool(save.dispose_catch(record.catch_id, "released").get("ok", false)), "release collection fixture: " + id)

func _test_drag(horizontal: bool) -> void:
	var scroll: ScrollContainer = _scroll()
	scroll.scroll_vertical = 0
	await _layout()
	var tile: Button = app._list.get_child(0)
	var start: Vector2 = tile.find_child("FishArtPreview", true, false).get_global_rect().get_center()
	_touch(start, true)
	var step: Vector2 = Vector2(20, 0) if horizontal else Vector2(0, -24)
	for index: int in range(1, 9):
		var event: InputEventScreenDrag = InputEventScreenDrag.new()
		event.index = 0
		event.position = start + step * index
		event.relative = step
		root.push_input(event, true)
		await process_frame
	_touch(start + step * 8, false)
	await _layout()
	_check(app._screen == "catalog", "horizontal drag cancels detail activation" if horizontal else "vertical drag over fish never opens details")
	if not horizontal: _check(scroll.scroll_vertical > 100, "actual fish-image swipe scrolls the production list")
	scroll.stop_gesture()

func _tile(id: String) -> Button:
	return app._page.find_child("FishTile_" + id, true, false) as Button
func _scroll() -> ScrollContainer:
	return app._overlay.find_child("PageScroll", true, false) as ScrollContainer
func _metric_text(key: String) -> String:
	var metric: Node = app._page.find_child(key, true, false)
	return str(metric.get_child(1).text) if metric != null else "MISSING"
func _snapshot(key: String) -> Dictionary:
	var node: Node = app._page.find_child("CatchSnapshot_" + key, true, false)
	return node.get_meta("snapshot", {}) if node != null else {}
func _summary_above_fold() -> bool:
	var summary: Control = app._page.find_child("CatchRecordSummary", true, false)
	return summary != null and _scroll().get_global_rect().encloses(summary.get_global_rect())
func _buttons(node: Node) -> Array[BaseButton]:
	var result: Array[BaseButton] = []
	if node is BaseButton: result.append(node)
	for child: Node in node.get_children(): result.append_array(_buttons(child))
	return result
func _text_contains(node: Node, value: String) -> bool:
	if node == null: return false
	if node is Label and value in node.text: return true
	for child: Node in node.get_children():
		if _text_contains(child, value): return true
	return false
func _touch(point: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 0
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)
func _tap(point: Vector2) -> void:
	_touch(point, true)
	_touch(point, false)
	await _layout()
func _layout() -> void:
	for frame: int in range(5): await process_frame
func _capture(label: String) -> void:
	if output.is_empty(): return
	if DisplayServer.get_name() == "headless":
		_check(false, "screenshots need real renderer")
		return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	_check(picture.save_png(output.path_join(label + ".png")) == OK, "saved actual rendered " + label)
	picture = null
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL NOTEBOOK_UI: ", label)
