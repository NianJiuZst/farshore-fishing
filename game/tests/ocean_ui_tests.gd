extends SceneTree
## Actual production Main and strict assets, in an isolated HOME/XDG fixture.
## --tall: 720x1584. --output=/absolute/path: real software-Vulkan captures.
## This is source/UI regression evidence, never Android device/FPS validation.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Session = preload("res://scripts/fishing_session.gd")
const GIANT_BAITS: Array[String] = ["large_fish_chunk", "whole_mackerel", "large_squid", "large_surface_lure"]
const FEATURED: Array[String] = ["great_white_shark", "great_hammerhead", "atlantic_bluefin_tuna", "california_sheephead", "barreleye", "pacific_halibut", "turbot", "grey_gurnard", "atlantic_flyingfish", "humphead_wrasse", "bluespotted_ribbontail_ray", "russells_oarfish", "red_sea_clownfish", "sohal_surgeonfish", "bluespotted_cornetfish"]
var app: Control
var checks: int = 0
var failures: Array[String] = []
var output: String = ""
var captures: Array[Dictionary] = []
var initial_hashes: Dictionary = {}
var began: int = 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL OCEAN UI: ", label)

func contains(node: Node, fragment: String) -> bool:
	if node == null: return false
	if node is Label and fragment in node.text: return true
	for child: Node in node.get_children():
		if contains(child, fragment): return true
	return false

func _run() -> void:
	began = Time.get_ticks_msec()
	var data: String = OS.get_environment("XDG_DATA_HOME")
	if not data.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(data + "/"):
		printerr("OCEAN_UI_TESTS: refusing non-isolated HOME/XDG/player data")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_empty() and (not output.is_absolute_path() or DirAccess.dir_exists_absolute(output)):
		printerr("OCEAN_UI_TESTS: output must be a fresh absolute directory")
		quit(2)
		return
	root.size = Vector2i(720, 1584 if "--tall" in OS.get_cmdline_user_args() else 1280)
	initial_hashes = _source_hashes()
	app = Main.instantiate()
	root.add_child(app)
	# Native Main intentionally paints between startup stages. Do not dereference
	# scenery/sound, or override any readiness flag, before real startup ends.
	var deadline: int = Time.get_ticks_msec() + 180000
	while not app._startup_complete and Time.get_ticks_msec() < deadline:
		await process_frame
	check(app._startup_complete, "real staged Main startup completes")
	check(app._content_ok and app._models_complete and app.fish_art.complete, "all111 real models/illustrations/histories accepted by the strict gate")
	if not app._startup_complete or not app._content_ok or not app._models_complete or not app.fish_art.complete:
		printerr("OCEAN_UI_STARTUP_ERRORS: ", app.catalog.errors)
		await _finish()
		return
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)
	check(app.catalog.regions.size() == 10 and app.catalog.spots.size() == 21 and app.catalog.fish.size() == 111 and app.catalog.fish_species_count() == 110 and app.catalog.gear.size() == 6, "complete10-region/21-spot catalog with 110 fish, one mammal and six rods")
	check(root.get_visible_rect().size == Vector2(root.size) and app.size == Vector2(root.size), "production Main and logical viewport fill requested physical aspect")
	if DisplayServer.get_name() != "headless":
		check(RenderingServer.get_current_rendering_method() == "mobile" and RenderingServer.get_current_rendering_driver_name() == "vulkan", "native QA uses production Mobile/Vulkan renderer")
		check(root.msaa_3d == Viewport.MSAA_4X, "native actual viewport retains production4x MSAA")
	await _test_fresh_profile()
	var store: SaveStore = Store.new()
	check(store.initialize(data.path_join("ocean-ui")), "isolated fixture initializes")
	var state: Dictionary = store.state
	state.gear = 4
	state.owned_gear = [0, 1, 2, 3, 4]
	state.settings["reduce_motion"] = true
	state.settings.sound = false
	state.settings.vibration = false
	state.unlocked_regions = []
	for region: Dictionary in app.catalog.regions: state.unlocked_regions.append(str(region.region_id))
	var fixture_ok: bool = store.commit_state(state)
	check(fixture_ok, "travel-only fixture unlocks all regions without fabricating catches: " + store.error_message)
	if not fixture_ok:
		await _finish()
		return
	app.store = store
	await _test_catalog_and_details(store)
	await _test_texture_lru(store)
	await _test_depth_preview()
	await _test_bait_selection(store)
	await _test_travel(store)
	await _test_repeated_back_navigation(store)
	check(store.total_count() == 0 and store.discovered_count() == 0, "all browsing/travel/navigation leaves actual catch history empty")
	check(initial_hashes == _source_hashes(), "production source manifests and UI scripts unchanged throughout run")
	await _finish()

func _test_fresh_profile() -> void:
	var fresh: Dictionary = app.store.state
	check(int(fresh.currency) == 1500, "real fresh profile starts with1500 currency")
	var regions: Array = fresh.unlocked_regions.duplicate()
	regions.sort()
	check(regions == ["bayou", "japan", "lake", "med", "norway", "yangtze"], "real fresh profile unlocks exact six earlier regions")
	var available_spots: int = 0
	for region: Dictionary in app.catalog.regions:
		if str(region.region_id) in regions: available_spots += region.spots.size()
	check(available_spots == 12, "fresh regional progression includes twelve earlier spots without changing rod gates")
	for id: String in ["pacific_ocean", "atlantic_ocean", "indian_ocean", "red_sea"]:
		check(id not in fresh.unlocked_regions, "new ocean stays locked on a fresh profile " + id)
	check(int(fresh.gear) == 0 and fresh.owned_gear == [0], "fresh starter gear ownership remains unchanged")
	check(app.store.total_count() == 0 and app.store.discovered_count() == 0 and fresh.pending_catches.is_empty(), "fresh progress has zero real or pending catches")
	await _layout()
	check(contains(app._overlay, "1500"), "actual fresh lobby displays the initial currency")
	await _capture("fresh_profile_lobby")
	app._show_travel()
	await _layout()
	for region: Dictionary in app.catalog.regions:
		if str(region.region_id) in regions:
			for sid: String in region.spots:
				check(_button_named(str(app.catalog.spots[sid].name), app._page) != null, "fresh travel exposes the earlier spot while retaining gear requirements " + sid)
		else:
			var unlock: Button = _button_named("解锁水域 · %d 旅币" % int(region.unlock_cost), app._page)
			check(unlock != null and unlock.disabled, "fresh ocean unlock still requires discoveries " + str(region.region_id))
	var unlock_controls: int = 0
	for child: Node in app._page.get_children():
		if child is Button and child.text.begins_with("解锁水域"):
			unlock_controls += 1
			check(child.disabled, "each actual fresh ocean unlock button is discovery-gated")
	check(unlock_controls == 4, "actual fresh travel page contains exactly four remaining region unlock controls")
	await _bottom_reachable("fresh travel and locked oceans")
	await _capture("fresh_oceans_locked")
	await _back()
	check(app._screen == "home" and app.store.state == fresh, "fresh travel browsing returns to lobby without modifying granted progress")

func _test_bait_selection(store: SaveStore) -> void:
	check(app.catalog.baits.size() == 12, "production catalog exposes twelve differentiated bait choices")
	var hints: Array[String] = []
	for id: String in GIANT_BAITS:
		var bait: Dictionary = app.catalog.bait_definition(id)
		check(not bait.is_empty() and not str(bait.get("hint", "")).is_empty() and str(bait.get("hint", "")) not in hints, "new giant bait has an independent visible description " + id)
		hints.append(str(bait.get("hint", "")))
	var before: Dictionary = store.state
	var original: String = app.bait_id
	app._show_gear()
	await _layout()
	for bait: Dictionary in app.catalog.baits:
		var id: String = str(bait.bait_id)
		var button: Button = _button_named(str(bait.name), app._page)
		check(button != null and button.icon_kind == id, "real bait control has matching identity and icon " + id)
		check(contains(app._page, str(bait.hint)), "real bait control includes its differentiated hint " + id)
		if button == null: continue
		await _reveal(button)
		await _tap(button.get_global_rect().get_center())
		check(app._screen == "gear" and app.bait_id == id and str(store.state.selection.bait_id) == id, "real bait tap updates loadout and durable selection " + id)
		var selected: Button = _button_named(str(bait.name), app._page)
		check(selected != null and selected.text == "已选 · " + str(bait.name), "selected bait state is visible after page rebuild " + id)
		if id in GIANT_BAITS:
			app._enter_fishery()
			app.scenery._update_camera(100.0)
			await _layout()
			check(app._mode == "fishing" and not root.disable_3d, "selected giant bait can return to the real visible fishing world " + id)
			var caption: Label = app._bait_control._caption
			check(app._bait_control.text == str(bait.name) and caption.text == str(bait.name), "fishing HUD retains exact selected giant-bait name " + id)
			check(app._bait_control.get_global_rect().encloses(caption.get_global_rect()), "giant-bait HUD caption fits its native touch surface " + id)
			await _capture("fishing_bait_" + id)
			app._return_to_lobby()
			app._show_gear()
			await _layout()
	await _bottom_reachable("twelve-bait gear page")
	await _capture("gear_twelve_baits_bottom")
	var restart: SaveStore = Store.new()
	check(restart.initialize(OS.get_environment("XDG_DATA_HOME").path_join("ocean-ui")) and str(restart.state.selection.bait_id) == app.bait_id, "last bait choice survives isolated save reload")
	var restore: Button = _button_named(app.catalog.bait_name(original), app._page)
	await _reveal(restore)
	if restore != null: await _tap(restore.get_global_rect().get_center())
	check(app.bait_id == original, "original bait restored through actual gear control")
	for key: String in ["currency", "gear", "owned_gear", "unlocked_regions", "species_stats", "pending_catches", "favorites"]:
		check(store.state[key] == before[key], "free bait selection does not change unrelated progress " + key)

func _test_catalog_and_details(store: SaveStore) -> void:
	app._search = ""
	app._region_filter = "all"
	app._discovery_filter = 0
	app._catalog_scroll = 0
	app._show_catalog()
	await _layout()
	check(app._page.name == "FishNotebookCatalog" and app._list.get_child_count() == 110, "real notebook exposes all110 whole-tile fish buttons")
	check(_tile("blue_whale") == null, "blue whale stays outside the ordinary fish grid")
	var regions: OptionButton = app._page.find_child("NotebookRegionFilter", true, false)
	check(regions != null and regions.item_count == 11, "region filter contains all10 regions and all-regions option")
	for id: String in app.catalog.fish:
		if not app.catalog.is_fishing_species(app.catalog.fish[id]): continue
		var tile: Button = _tile(id)
		check(tile != null and tile.text == app.catalog.fish[id].name, "actual catalog tile names correct species " + id)
		var photo: TextureRect = tile.find_child("FishArtPreview", true, false) if tile != null else null
		check(photo != null and photo.texture is AtlasTexture and photo.texture.atlas != null, "actual catalog tile owns imported thumbnail " + id)
	await _capture("catalog_top")
	await _swipe_up()
	check(_scroll().scroll_vertical > 100 and app._screen == "catalog", "actual touchscreen swipe scrolls catalog without opening a fish")
	await _bottom_reachable("catalog")
	await _capture("catalog_bottom")
	var before: Dictionary = store.state
	for id: String in FEATURED:
		app._show_catalog()
		await _layout()
		var tile: Button = _tile(id)
		if tile == null: continue # Missing tile has already failed above.
		await _reveal(tile)
		var old_scroll: int = _scroll().scroll_vertical
		await _tap(tile.get_global_rect().get_center())
		check(app._screen == "species" and app._active_species_id == id, "actual catalog touch opens matching featured species " + id)
		if app._screen != "species": continue
		var latin: Label = app._page.find_child("SpeciesScientificName", true, false)
		check(latin != null and latin.text == app._scientific_name(app.catalog.fish[id]), "accepted scientific name matches featured species " + id)
		check(contains(app._page, "虚构的游戏范围") and contains(app._page, "自然界资料"), "fictional game limits explicitly separated from natural history " + id)
		check(contains(app._page, str(app.natural_history.get_entry(id).typical_size.text)), "complete verified natural-history paragraph is present " + id)
		var image: TextureRect = app._page.find_child("FishArtPreview", true, false)
		check(image != null and image.texture is AtlasTexture and image.texture.atlas.get_width() >= 1536, "featured details use full-quality original " + id)
		var summary: Control = app._page.find_child("CatchRecordSummary", true, false)
		check(summary != null and _scroll().get_global_rect().encloses(summary.get_global_rect()), "honest zero-catch summary visible above fold " + id)
		if id in ["great_white_shark", "great_hammerhead", "atlantic_bluefin_tuna"]: await _capture("species_" + id)
		var zoom: Button = app._page.find_child("NotebookZoom", true, false)
		await _reveal(zoom)
		await _tap(zoom.get_global_rect().get_center())
		check(app._screen == "zoom", "actual zoom button opens original image " + id)
		await _back()
		check(app._screen == "species" and app._active_species_id == id, "Back from zoom preserves featured fish " + id)
		await _swipe_up()
		check(_scroll().scroll_vertical > 100 and app._screen == "species", "actual swipe reads long natural history " + id)
		await _bottom_reachable("species " + id)
		var count: int = app.natural_history.get_entry(id).sources.size()
		var source: Button = app._page.find_child("NotebookSource_" + str(count), true, false)
		check(source != null and _scroll().get_global_rect().encloses(source.get_global_rect()), "last source action reachable without opening external website " + id)
		if id == "great_white_shark": await _capture("species_great_white_sources")
		await _back()
		check(app._screen == "catalog" and absi(_scroll().scroll_vertical - old_scroll) <= 1, "Back restores original catalog position " + id)
	check(store.state == before, "catalog/details/zoom/scroll cannot mutate saved progress")

func _test_texture_lru(store: SaveStore) -> void:
	app._show_species("great_white_shark")
	await _layout()
	var visible_art: TextureRect = app._page.find_child("FishArtPreview", true, false)
	var active_atlas: AtlasTexture = visible_art.texture
	var active_source: Texture2D = active_atlas.atlas
	var active_id: int = active_source.get_instance_id()
	var before: Dictionary = store.state
	for id: String in app.catalog.fish:
		var texture: Texture2D = app.fish_art.texture_for(app.catalog.fish[id])
		check(texture != null and texture.get_width() >= 1536, "full-quality original available " + id)
		check(app.fish_art._full_texture_order.size() <= 4, "bounded four-entry original cache " + id)
	check(not app.fish_art._textures.has(app.catalog.fish.great_white_shark.art), "active image's catalog cache reference was genuinely evicted")
	check(is_instance_valid(active_source) and visible_art.texture == active_atlas and active_atlas.atlas.get_instance_id() == active_id, "live detail image retains its original texture after LRU eviction")
	var pixels: Image = active_source.get_image()
	check(pixels != null and not pixels.is_empty() and pixels.get_width() >= 1536, "evicted active texture remains readable at original resolution")
	var thumbnail: Texture2D = app.fish_art.texture_for(app.catalog.fish.great_white_shark, true)
	check(thumbnail != null and app.fish_art._textures.has(app.catalog.fish.great_white_shark.thumb), "thumbnail remains available independently of original LRU")
	await _capture("species_active_after_lru")
	check(store.state == before, "texture cache paging cannot mutate saved progress")

func _test_depth_preview() -> void:
	app._trial_gear_id = -1
	app._show_prepare()
	app._choose_spot("norway", "norway_boat")
	await _layout()
	check(app.region_id == "norway" and app.spot_id == "norway_boat", "legacy fjord still loads")
	check(int(app.catalog.gear[4].max_depth_m) == 90, "giant rod has actual90m reach")
	check(contains(app._page, "当前装备可遇见"), "preparation describes actual loadout")
	check(contains(app._page, "狼鱼 · 钓竿需探深至少 100 m"), "90m giant rod shows exact wolffish depth blocker")
	await _bottom_reachable("90m preparation")
	await _capture("prepare_wolffish_blocked_90m")
	app._borrow_gear(2)
	app._show_prepare()
	await _layout()
	check(int(app.catalog.gear[2].max_depth_m) == 180, "deep rod has actual180m reach")
	check(contains(app._page, "狼鱼") and not contains(app._page, "狼鱼 · 钓竿需探深至少"), "180m deep rod lists wolffish without depth blocker")
	await _bottom_reachable("180m preparation")
	await _capture("prepare_wolffish_available_180m")
	app._clear_trial_gear()
	app._show_gear()
	await _layout()
	await _swipe_up()
	check(_scroll().scroll_vertical > 100, "actual swipe scrolls complete gear page")
	await _bottom_reachable("gear")
	await _capture("gear_bottom")

func _test_travel(store: SaveStore) -> void:
	var visited: int = 0
	var oceans: int = 0
	for region: Dictionary in app.catalog.regions:
		var rid: String = str(region.region_id)
		check(ResourceLoader.exists(str(region.scene)), "real rendered travel card exists " + rid)
		for sid: String in region.spots:
			app.session.reset()
			app._show_travel()
			await _layout()
			check(contains(app._page, str(region.name)), "travel lists expected region " + rid)
			var target: Button = _button_named(str(app.catalog.spots[sid].name), app._page)
			check(target != null and not target.disabled, "actual travel control available " + sid)
			if target == null or target.disabled: continue
			await _reveal(target)
			var sea_region: bool = rid.ends_with("_ocean") or rid == "red_sea"
			if sea_region and sid == str(region.spots[0]): await _capture("travel_" + rid)
			await _tap(target.get_global_rect().get_center())
			check(app.region_id == rid and app.spot_id == sid and app.scenery.region_id == rid and app.scenery.spot_id == sid and str(store.state.selection.spot_id) == sid, "travel commits Main/save/actual scene together " + sid)
			check(app._screen == "prepare" and contains(app._page, str(app.catalog.spots[sid].name)), "travel returns matching production preparation " + sid)
			if sea_region:
				check(app.scenery._ocean_horizon_water.visible and not app.scenery._reflection_probe.visible, "ocean uses distant water/skylight " + sid)
				app.sound.set_environment(sid, "clear", "day")
				check(is_equal_approx(app.sound._water_gain, 0.4) and is_zero_approx(app.sound._current_gain), "ocean uses sea ambience rather than river " + sid)
				var enter: Button = _button_named("进入钓点", app._page_footer)
				check(enter != null and not enter.disabled, "strict gate allows entering new ocean " + sid)
				if enter != null and not enter.disabled:
					await _click(enter.get_global_rect().get_center())
					var entered: bool = app._mode == "fishing" and app._screen.is_empty() and app._safe.visible
					check(entered, "actual native Enter button opens ocean fishing HUD " + sid)
					check(not root.disable_3d, "visible ocean world rendering resumes after opaque preparation " + sid)
					if not entered: continue
					# Settle the unchanged production camera interpolation, not a custom viewpoint.
					app.scenery._update_camera(100.0)
					await _layout()
					await _capture("fishing_" + sid)
					await _back()
					check(app._screen == "pause", "Back from new ocean opens pause " + sid)
					var home: Button = _button_named("返回大厅", app._page)
					await _reveal(home)
					if home == null: continue
					await _tap(home.get_global_rect().get_center())
					check(app._screen == "home" and app._mode == "lobby", "actual return action leaves ocean safely " + sid)
					oceans += 1
			visited += 1
	check(visited == 21 and oceans == 9, "all21 travel spots and all9 ocean/Red Sea Enter/Back/return flows exercised")
	app._show_prepare()
	app._show_travel()
	await _layout()
	await _bottom_reachable("all10-region travel page")
	await _capture("travel_bottom")
	await _back()
	check(app._screen == "prepare", "Back from long travel returns to preparation")

func _test_repeated_back_navigation(store: SaveStore) -> void:
	var before: Dictionary = store.state
	for attempt: int in range(3):
		app._show_home()
		app._show_prepare()
		app._show_catalog()
		await _layout()
		app._open_fish_details("great_hammerhead")
		app._show_zoom("great_hammerhead")
		await _back()
		check(app._screen == "species", "repeated zoom Back has one current detail " + str(attempt))
		await _back()
		check(app._screen == "catalog", "repeated detail Back has one current catalog " + str(attempt))
		await _back()
		check(app._screen == "prepare", "repeated catalog Back restores preparation " + str(attempt))
		await _back()
		check(app._screen == "home", "repeated preparation Back restores lobby " + str(attempt))
	check(store.state == before, "repeated Back navigation cannot alter save")

func _scroll() -> ScrollContainer:
	return app._overlay.find_child("PageScroll", true, false) as ScrollContainer

func _tile(id: String) -> Button:
	return app._page.find_child("FishTile_" + id, true, false) as Button

func _button_named(value: String, node: Node) -> Button:
	if node is Button and (node.text == value or node.text == "当前 · " + value or node.text == "已选 · " + value): return node
	for child: Node in node.get_children():
		var result: Button = _button_named(value, child)
		if result != null: return result
	return null

func _reveal(control: Control) -> void:
	check(control != null, "requested native control exists")
	if control == null: return
	_scroll().stop_gesture()
	_scroll().ensure_control_visible(control)
	await _layout()
	check(_scroll().get_global_rect().encloses(control.get_global_rect()), "native control is fully reachable in current scroll viewport " + control.name)

func _bottom_reachable(label: String) -> void:
	var scroll: ScrollContainer = _scroll()
	scroll.stop_gesture()
	scroll.scroll_vertical = 1000000
	await _layout()
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var maximum: float = maxf(0.0, bar.max_value - bar.page)
	check(absf(float(scroll.scroll_vertical) - maximum) <= 1.1, "scroll reaches actual page end " + label)
	check(app._page.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1.1, "last content is not clipped below page end " + label)
	check(app._page.get_global_rect().size.x <= scroll.get_global_rect().size.x + 1.1, "long page has no horizontal overflow " + label)

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

func _click(point: Vector2) -> void:
	# Viewport.push_input deliberately bypasses Input's touch-to-mouse emulation.
	# Fixed footers lie outside TouchScroll, so exercise their real native Button
	# path with balanced mouse input rather than emitting the pressed signal.
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.device = 101
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
	await _layout()

func _swipe_up() -> void:
	var scroll: ScrollContainer = _scroll()
	scroll.stop_gesture()
	scroll.scroll_vertical = 0
	await _layout()
	var start: Vector2 = scroll.get_global_rect().get_center()
	_touch(start, true)
	for index: int in range(1, 9):
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = 0
		drag.position = start + Vector2(0, -24 * index)
		drag.relative = Vector2(0, -24)
		root.push_input(drag, true)
		await process_frame
	_touch(start + Vector2(0, -192), false)
	await _layout()
	scroll.stop_gesture()

func _back() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = false
	root.push_input(event, true)
	await _layout()

func _opaque_overlay_covers_world() -> bool:
	if not is_instance_valid(app) or not is_instance_valid(app._overlay) or app._overlay.get_child_count() == 0: return false
	var overlay: Control = app._overlay
	var background: Node = overlay.get_child(0)
	if not background is TextureRect or not background.texture is GradientTexture2D: return false
	if overlay.modulate.a < 1.0 or overlay.self_modulate.a < 1.0 or background.modulate.a < 1.0 or background.self_modulate.a < 1.0: return false
	if not background.get_global_rect().encloses(root.get_visible_rect()): return false
	for color: Color in background.texture.gradient.colors:
		if color.a < 1.0: return false
	return true

func _sync_test_rendering() -> void:
	# Test-only optimization: no visible 3D is omitted. Actual imported scenes,
	# resources and independent SubViewports remain intact; transparent lobby
	# overlays and the uncovered fishing HUD always restore main-world rendering.
	root.disable_3d = _opaque_overlay_covers_world()

func _layout() -> void:
	for frame: int in range(5):
		_sync_test_rendering()
		await process_frame

func _capture(label: String) -> void:
	if output.is_empty(): return
	if DisplayServer.get_name() == "headless":
		check(false, "requested screenshot requires real renderer " + label)
		return
	_sync_test_rendering()
	if label.begins_with("fishing_"): check(not root.disable_3d, "real world rendering restored before ocean capture " + label)
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = output.path_join(label + ".png")
	check(picture != null and picture.get_size() == root.size, "actual rendered capture has requested aspect " + label)
	check(picture.save_png(path) == OK, "saved real rendered capture " + label)
	captures.append({"label": label, "path": path.get_file(), "width": picture.get_width(), "height": picture.get_height(), "sha256": FileAccess.get_sha256(path), "screen": app._screen, "main_viewport_3d_disabled": root.disable_3d})

func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in ["res://project.godot", "res://scenes/main.tscn", "res://scripts/main.gd", "res://scripts/ui_art.gd", "res://scripts/icon_action.gd", "res://scripts/catalog.gd", "res://scripts/encounter.gd", "res://scripts/fish_art_catalog.gd", "res://scripts/fish_art_view.gd", "res://scripts/fish_notebook_ui.gd", "res://scripts/fishing_menu_pages.gd", "res://scripts/touch_scroll.gd", "res://scripts/audio_manager.gd", "res://scripts/fishing_stage_3d.gd", "res://scripts/save_store.gd", "res://data/fish_art.json", "res://data/fish_3d.json", "res://data/world.json", "res://data/fish_a.json", "res://data/fish_b.json", "res://data/fish_c.json", "res://data/fish_d.json", "res://data/fish_e.json", "res://data/fish_f.json", "res://data/encyclopedia_a.json", "res://data/encyclopedia_b.json", "res://data/encyclopedia_c.json", "res://data/encyclopedia_d.json", "res://data/encyclopedia_e.json", "res://data/encyclopedia_f.json"]:
		result[path] = FileAccess.get_sha256(path)
	for path: String in ["res://data/fish_g.json", "res://data/fish_h.json", "res://data/fish_whale.json", "res://data/encyclopedia_g.json", "res://data/encyclopedia_h.json", "res://data/encyclopedia_whale.json", "res://scripts/blue_whale_challenge.gd"]:
		result[path] = FileAccess.get_sha256(path)
	for id: String in GIANT_BAITS:
		var path: String = "res://assets/ui/icons/" + id + ".png"
		result[path] = FileAccess.get_sha256(path)
	return result

func _finish() -> void:
	var report: Dictionary = {"scope": "production Main UI; strict asset gates; isolated test save", "not_android_device_or_fps_validation": true, "test_optimization": "Suppress main viewport3D only behind a verified fullscreen alpha1 gradient; restore whenever world can be visible; retain actual imported resources and independent SubViewports", "checks": checks, "passed": checks - failures.size(), "failures": failures, "physical_size": [root.size.x, root.size.y], "logical_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(), "rendering_driver": RenderingServer.get_current_rendering_driver_name(), "adapter": RenderingServer.get_video_adapter_name(), "duration_seconds": float(Time.get_ticks_msec() - began) / 1000.0, "source_sha256": initial_hashes, "captures": captures}
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		var file: FileAccess = FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report, "  ") + "\n")
		else: check(false, "capture manifest is writable")
	if is_instance_valid(app): app.queue_free()
	app = null
	for frame: int in range(5): await process_frame
	print("OCEAN_UI_TESTS: %d/%d passed; failures=%d; physical=%s; actual Main/headless or desktop only" % [checks - failures.size(), checks, failures.size(), str(root.size)])
	quit(0 if failures.is_empty() else 1)
