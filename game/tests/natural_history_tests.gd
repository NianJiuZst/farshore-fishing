extends "res://tests/fish_notebook_ui_tests.gd"
## Enriched offline encyclopedia contract plus real Main/Viewport input QA.
## Native --output captures are desktop Mobile/Vulkan, never Android evidence.
## Source callables are inspected, disconnected, and intercepted before input.
const CatalogData = preload("res://scripts/catalog.gd")
const HistoryData = preload("res://scripts/fish_natural_history.gd")
const SessionData = preload("res://scripts/fishing_session.gd")
var intercepted_urls: Array[String] = []
var capture_rows: Array[Dictionary] = []

func _run() -> void:
	var isolated: String = OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(isolated + "/"):
		printerr("NATURAL_HISTORY: refusing non-isolated save environment")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_empty() and DirAccess.dir_exists_absolute(output):
		printerr("NATURAL_HISTORY: refusing existing capture directory")
		quit(2)
		return
	_test_content()
	root.size = Vector2i(720, 1584 if "--tall" in OS.get_cmdline_user_args() else 1280)
	root.disable_3d = true
	app = Main.instantiate()
	root.add_child(app)
	# Native Main startup yields between loading stages; wait for its real completion.
	var startup_deadline: int = Time.get_ticks_msec() + 120000
	while not app._startup_complete and Time.get_ticks_msec() < startup_deadline:
		await process_frame
	if not app._startup_complete:
		_check(false, "Main startup timed out before _startup_complete")
		quit(1)
		return
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)
	# UI-only QA needs no Dummy-driver ambience playback retained at exit.
	app.sound.ambience.stop()
	app.sound.ambience.stream = null
	app.sound.effect.stop()
	app.sound.effect.stream = null
	_check(app._content_ok and app.natural_history.complete, "actual Main loads 110 fish and one mammal natural history")
	save = Store.new()
	_check(save.initialize(isolated.path_join("natural-%s" % Time.get_ticks_usec())), "isolated SaveStore fixture")
	app.store = save
	await _layout()
	_check(app.size == Vector2(root.size), "Main layout fills the requested portrait viewport")
	if not output.is_empty(): _check(RenderingServer.get_current_rendering_method() == "mobile", "native capture uses production Mobile renderer")
	app.encounter.rng.seed = 20261003
	await _test_all_details()
	await _test_records_and_sections()
	await _test_current_taxonomy()
	await _test_origin_and_source_gestures()
	_check(intercepted_urls.size() == 1, "one explicit source tap intercepted; no browser/network calls")
	if not output.is_empty(): _write_evidence()
	app.fish_art._textures.clear()
	app.queue_free()
	app = null
	save = null
	for frame: int in range(5): await process_frame
	print("NATURAL_HISTORY_TESTS: ", checks - failures, "/", checks, " passed; ", root.size, "; isolated Main + Viewport input; browser never opened")
	call_deferred("quit", 0 if failures == 0 else 1)

func _test_content() -> void:
	var catalog: ContentCatalog = CatalogData.new()
	_check(catalog.load_all(false), "base catalog validates")
	var history: FishNaturalHistory = HistoryData.new()
	_check(history.load_all(catalog), "natural-history load validates: " + str(history.errors))
	_check(history.complete and history.entries.size() == 111 and catalog.fish.size() == 111, "exact111 animal histories without extra/missing identities")
	_check(catalog.fish_species_count() == 110 and not catalog.is_fishing_species(catalog.fish["blue_whale"]), "natural history retains blue whale as a mammal outside the 110 fishing species")
	var seen: Dictionary = {}
	for path: String in HistoryData.FILES:
		var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_check(envelope is Dictionary and envelope.schema_version == 1 and envelope.entries is Array, "version1 envelope: " + path)
		for entry: Dictionary in envelope.entries:
			var id: String = str(entry.species_id)
			_check(not seen.has(id) and catalog.fish.has(id), "unique stable catalog species ID: " + id)
			seen[id] = true
			_check(HistoryData.validate_entry(entry).is_empty(), "schema, taxonomy, field references and URLs: " + id)
			_check(str(entry.accepted_scientific_name).get_slice(" ", 0) == str(entry.taxonomy.genus_scientific), "accepted genus matches binomial: " + id)
			for key: String in ["max_length", "max_weight"]:
				var value: Variant = entry[key]["value_cm" if key == "max_length" else "value_kg"]
				_check(value == null or float(value) > 0.0, "positive or unknown natural " + key + ": " + id)
	var valid: Dictionary = history.get_entry("common_carp")
	var changed: Dictionary = valid.duplicate(true)
	changed.taxonomy.family_zh = "MUTATED TEST COPY"
	_check(history.get_entry("common_carp").taxonomy.family_zh != changed.taxonomy.family_zh, "get_entry is a defensive copy")
	_check(history.scientific_name("missing", "Fallback name") == "Fallback name", "absent-entry scientific-name fallback")
	var bad: Dictionary = valid.duplicate(true)
	bad.erase("species_id")
	_reject(bad, "missing species ID")
	for invalid_id: Variant in [42, "", "wrong id", "../outside"]:
		bad = valid.duplicate(true)
		bad.species_id = invalid_id
		_reject(bad, "invalid stable species ID: " + str(invalid_id))
	for invalid_caption: Variant in [0, "", "   "]:
		bad = valid.duplicate(true)
		bad.max_length.record_label = invalid_caption
		_reject(bad, "invalid record scope caption")
	bad = valid.duplicate(true)
	bad.taxonomy.genus_scientific = "Wronggenus"
	_reject(bad, "accepted name and genus conflict")
	for field: String in ["taxonomy", "typical_size", "max_length", "max_weight", "habitat", "distribution", "behavior", "diet", "story"]:
		bad = valid.duplicate(true)
		bad[field].erase("source_ids")
		_reject(bad, "missing field references: " + field)
		bad = valid.duplicate(true)
		bad[field].source_ids = ["undefined_source"]
		_reject(bad, "unresolved field reference: " + field)
	bad = valid.duplicate(true)
	bad.sources[0].url = "javascript:alert(1)"
	_reject(bad, "unsafe source URL")
	bad = valid.duplicate(true)
	bad.sources[1].id = bad.sources[0].id
	_reject(bad, "duplicate source ID")
	for field: String in ["max_length", "max_weight"]:
		for number: Variant in [0, -1, "unknown", INF, NAN]:
			bad = valid.duplicate(true)
			bad[field]["value_cm" if field == "max_length" else "value_kg"] = number
			_reject(bad, "invalid maximum " + field + ": " + str(number))
	bad = valid.duplicate(true)
	bad.max_length.value_cm = null
	bad.max_weight.value_kg = null
	_check(HistoryData.validate_entry(bad).is_empty(), "null maxima accepted with textual explanation and references")
	bad = valid.duplicate(true)
	bad.max_length.length_type = "invented_unit"
	_reject(bad, "unknown length measure")
	for url: String in ["http://example.org/fish", "file:///tmp/fish", "javascript:alert(1)", "https://user@example.org", "https://a:b@example.org", "https://example.org:8443/x", "https://example.org/with space", "https://example.org/\n", "https://example.org\\evil", "https:///fish", "https://localhost/fish"]:
		_check(not HistoryData.safe_source_url(url), "reject unsafe source URL fixture: " + url.c_escape())
	for url: String in ["https://example.org/fish", "https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?family=Acipenseridae&tbl=species"]:
		_check(HistoryData.safe_source_url(url), "allow ordinary documented HTTPS source")
	var missing_catalog: ContentCatalog = CatalogData.new()
	missing_catalog.load_all(false)
	missing_catalog.fish.erase("common_carp")
	_check(not history.load_all(missing_catalog) and not history.complete, "loader rejects ID outside the catalog")

func _reject(entry: Dictionary, label: String) -> void:
	_check(not HistoryData.validate_entry(entry).is_empty(), "reject bad fixture: " + label)

func _test_all_details() -> void:
	var before: Dictionary = save.state
	for id: String in app.catalog.fish:
		app._show_species(id)
		await _layout()
		var entry: Dictionary = app.natural_history.get_entry(id)
		if not app.catalog.is_fishing_species(app.catalog.fish[id]):
			_test_mammal_history(id, entry)
			continue
		_check(_text_contains(app._page, str(entry.accepted_scientific_name)), "accepted name in actual detail: " + id)
		for field: String in ["typical_size", "habitat", "distribution", "behavior", "diet", "story"]:
			var paragraph: Label = app._page.find_child("Natural_" + field, true, false) as Label
			_check(paragraph != null and str(entry[field].text) in paragraph.text and "[" in paragraph.text, "complete offline paragraph with numbered citations: " + id + "/" + field)
		_check(_text_contains(app._page, str(entry.taxonomy.family_scientific)) and _text_contains(app._page, str(entry.taxonomy.genus_scientific)), "Latin family and genus in actual detail: " + id)
		_check(_summary_above_fold(), "personal summary fits first screen: " + id)
		var source_count: int = 0
		for button: BaseButton in _buttons(app._page):
			if not str(button.name).begins_with("NotebookSource_"): continue
			source_count += 1
			var bindings: Array = button.pressed.get_connections()
			_check(bindings.size() == 1 and bindings[0].callable.get_object() == app and bindings[0].callable.get_method() == "_open_species_source" and bindings[0].callable.get_bound_arguments() == [button.get_meta("source_url")], "source binding matches explicit guarded Main action: " + id + "/" + str(source_count))
		_check(source_count == entry.sources.size(), "every reference has one source button: " + id)
	_check(before == save.state and save.total_count() == 0 and save.discovered_count() == 0, "reading all111 animal histories never changes player state or discovers fish")

func _test_mammal_history(id: String, entry: Dictionary) -> void:
	_check(id == "blue_whale" and app._screen == "whale_notebook" and app._page.name == "WhaleNaturalHistory", "mammal history opens its independent production page: " + id)
	_check(_text_contains(app._page, str(entry.accepted_scientific_name)) and _text_contains(app._page, "哺乳纲") and _text_contains(app._page, str(entry.taxonomy.family_zh)), "whale page identifies the accepted species and mammal family")
	for field: String in ["typical_size", "max_length", "max_weight", "habitat", "distribution", "behavior", "diet", "story"]:
		_check(_text_contains(app._page, str(entry[field].text)), "complete offline mammal paragraph: " + field)
	_check(app._page.find_child("CatchRecordSummary", true, false) == null and app._page.find_child("CatchCount", true, false) == null, "whale history has no fish-catch summary")
	_check(_text_contains(app._page, "不使用鱼饵") and _text_contains(app._page, "不拉上岸"), "whale page explains its independent fantasy observation challenge")
	var source_count: int = 0
	for button: BaseButton in _buttons(app._page):
		for binding: Dictionary in button.pressed.get_connections():
			var action: Callable = binding.callable
			if action.get_object() != app or action.get_method() != "_open_species_source": continue
			source_count += 1
			var arguments: Array = action.get_bound_arguments()
			_check(arguments.size() == 1 and HistoryData.safe_source_url(str(arguments[0])), "whale source uses the guarded explicit HTTPS action")
	_check(source_count == entry.sources.size(), "every whale reference has one source button")

func _test_records_and_sections() -> void:
	app._show_species("common_carp")
	await _layout()
	_check(_metric_text("CatchCount") == "0 条" and _metric_text("MaxLength") == "—" and _metric_text("MaxWeight") == "—", "unknown personal values are zero/dashes")
	await _capture("01_carp_unknown_zero")
	var first: Dictionary = _settle("nature_first", "lake_shore", "lake", 600, 1200, "2026-10-01T09:00:00")
	app._show_species("common_carp")
	await _layout()
	_check(_metric_text("CatchCount") == "1 条" and _metric_text("MaxLength") == "60.0 cm" and _metric_text("MaxWeight") == "1.20 kg" and _summary_above_fold(), "one actual settled fixture catch in first screen")
	await _capture("02_carp_one_fixture_catch")
	var second: Dictionary = _settle("nature_second", "yangtze_river", "yangtze", 500, 1700, "2026-10-02T10:00:00")
	var latest: Dictionary = _settle("nature_latest", "lake_bay", "lake", 450, 900, "2026-10-03T11:00:00")
	app._show_species("common_carp")
	await _layout()
	var before: Dictionary = save.state
	_check(_metric_text("CatchCount") == "3 条" and _metric_text("MaxLength") == "60.0 cm" and _metric_text("MaxWeight") == "1.70 kg" and _summary_above_fold(), "three settled catches with independent personal maxima fit first screen")
	_check(_snapshot("max_length") == first and _snapshot("max_weight") == second and _snapshot("first") == first and _snapshot("last") == latest, "exact independent personal record snapshots preserved")
	await _capture("03_carp_three_fixture_catches")
	_check(_text_contains(app._page, "自然界资料") and _text_contains(app._page, "游戏尺寸设定") and _text_contains(app._page, "个人钓获纪录"), "biology, gameplay and personal statistics are explicitly separated")
	_check(_metric_text("NaturalMaxLength") == "129 cm" and _metric_text("NaturalMaxWeight") == "40.1 kg", "natural published sizes remain distinct from personal caught sizes")
	await _jump("NatureSection")
	await _capture("04_carp_taxonomy_size")
	await _scroll_to_node("Natural_behavior", 70)
	await _capture("05_carp_habits_diet_story")
	await _jump("PersonalRecordSection")
	_check(_snapshot("max_length") != _snapshot("max_weight"), "personal jump retains separate longest and heaviest individuals")
	await _capture("06_carp_personal_records")
	await _jump("ReferenceSection")
	_check(_text_contains(app._page, "外部浏览器") and _text_contains(app._page, "本页内容可离线阅读"), "source area discloses optional external browser and offline text")
	await _capture("07_carp_sources")
	await _scroll_to_node("NotebookZoom")
	await _tap((app._page.find_child("NotebookZoom", true, false) as Button).get_global_rect().get_center())
	_check(app._screen == "zoom" and _text_contains(app._page, "Cyprinus carpio"), "actual zoom touch opens current species image and accepted name")
	app._handle_back()
	await _layout()
	_check(app._screen == "species" and app._active_species_id == "common_carp", "zoom back returns to correct species")
	_check(before == save.state, "reading/jumping/zooming never changes three catches or any personal record")
	app._show_species("southern_catfish")
	await _layout()
	_check(_metric_text("CatchCount") == "0 条" and _metric_text("MaxLength") == "—", "uncaught Southern catfish has no borrowed personal catch")
	await _jump("NatureSection")
	_check(_metric_text("NaturalMaxLength") == "未见可靠值" and _metric_text("NaturalMaxWeight") == "未见可靠值", "unknown scientific maxima explicitly stay unknown")
	_check(_text_contains(app._page, "143厘米") and _text_contains(app._page, "22.8千克"), "verified specimen is explained separately from unknown species maxima")
	await _capture("08_southern_catfish_unknown_maxima")

func _test_current_taxonomy() -> void:
	for id: String in ["chinese_sturgeon", "saddled_seabream"]:
		var fish: FishDefinition = app.catalog.fish[id]
		var current: String = app._scientific_name(fish)
		_check(current != fish.scientific_name, "accepted taxonomy correction has a searchable historical spelling: " + id)
		for query: String in [current, fish.scientific_name]:
			app._search = query
			app._show_catalog()
			await _layout()
			var tile: Button = _tile(id)
			_check(tile != null and app._list.get_child_count() == 1 and _text_contains(tile, current), "current and legacy Latin searches find accepted-name tile: " + query)
		app._show_species(id)
		await _layout()
		_check(_text_contains(app._page, current), "detail displays accepted current Latin name: " + id)
		if id == "chinese_sturgeon":
			_check(current == "Acipenser sinensis", "current verified Chinese sturgeon taxonomy is Acipenser sinensis")
			await _capture("09_sturgeon_current_name_zero_catch")
			await _jump("NatureSection")
			await _capture("10_sturgeon_taxonomy_size")
		app._show_zoom(id)
		await _layout()
		_check(_text_contains(app._page, current), "zoom displays accepted name: " + id)
		var spot: String = str(fish.spots()[0])
		app._last_record = app.encounter.make_individual(fish, spot, str(app.catalog.spots[spot].region_id), "worm", 2, "day", "clear")
		app._show_result()
		await _layout()
		_check(app._screen == "result" and _text_contains(app._page, current), "catch presentation displays accepted name: " + id)
	app._search = ""
	app._last_record = {}

func _test_origin_and_source_gestures() -> void:
	var before: Dictionary = save.state
	app._show_catalog()
	await _layout()
	_scroll().scroll_vertical = 720
	await _layout()
	var saved_scroll: int = _scroll().scroll_vertical
	app._open_fish_details("common_carp")
	await _layout()
	app._handle_back()
	await _layout()
	_check(app._screen == "catalog" and _scroll().scroll_vertical == saved_scroll, "Back restores catalog origin and scroll")
	var candidate: Dictionary = save.state
	candidate.favorites = ["common_carp"]
	_check(save.commit_state(candidate), "known carp favorite fixture")
	app._show_favorites()
	await _layout()
	await _tap(_tile("common_carp").get_global_rect().get_center())
	_check(app._screen == "species" and app._notebook_origin == "favorites", "actual favorite tile remembers origin")
	app._handle_back()
	await _layout()
	_check(app._screen == "favorites", "Back returns to favorites")
	candidate = save.state
	candidate.favorites = before.favorites
	_check(save.commit_state(candidate), "restore favorite fixture using current save revision")
	_check(save.state.species_stats == before.species_stats, "origin/favorite navigation preserves every personal record")
	before = save.state
	app._show_species("common_carp")
	await _layout()
	await _jump("ReferenceSection")
	var source: Button = app._page.find_child("NotebookSource_1", true, false) as Button
	var connections: Array = source.pressed.get_connections()
	_check(connections.size() == 1 and connections[0].callable.get_method() == "_open_species_source", "inspect original source binding before interception")
	for connection: Dictionary in connections: source.pressed.disconnect(connection.callable)
	source.pressed.connect(_intercept_source.bind(str(source.get_meta("source_url"))))
	await _scroll_to_node("NotebookSource_1")
	await _tap(source.get_global_rect().get_center())
	_check(intercepted_urls == [str(source.get_meta("source_url"))], "one explicit source touch reaches exact source URL through intercepted binding")
	await _scroll_to_node("NotebookSource_1")
	await _drag_control(source, Vector2(0, -22))
	_check(intercepted_urls.size() == 1 and app._screen == "species", "vertical source-button swipe never invokes browser action")
	await _scroll_to_node("NotebookSource_1")
	await _drag_control(source, Vector2(19, 0))
	_check(intercepted_urls.size() == 1 and app._screen == "species", "horizontal source-button drag cancels activation")
	app._open_species_source("file:///forbidden-test-source")
	_check(app._screen == "species" and before == save.state, "guarded invalid-source call leaves notebook and all player data intact")
	_check(source.has_focus(), "explicit source tap retains native button focus")
	var page_before: Control = app._page
	var scroll_before: int = _scroll().scroll_vertical
	for notification_id: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_APPLICATION_RESUMED]:
		app.propagate_notification(notification_id)
		await _layout()
		_check(app.session.state == SessionData.State.PAUSED and app._screen == "species" and app._page == page_before, "source-page focus/background lifecycle remains paused: " + str(notification_id))
	_check(_scroll().scroll_vertical == scroll_before and save.state.species_stats == before.species_stats and save.total_count() == 3, "return from background preserves reading position and all independent catch records")
	_check(intercepted_urls.size() == 1, "lifecycle notifications do not reopen a source")

func _jump(section: String) -> void:
	await _scroll_to_node("NotebookJump_" + section)
	var button: Button = app._page.find_child("NotebookJump_" + section, true, false) as Button
	await _tap(button.get_global_rect().get_center())
	var target: Control = app._page.find_child(section, true, false) as Control
	var expected: int = mini(maxi(0, roundi(target.position.y) - 8), int(_scroll().get_v_scroll_bar().max_value - _scroll().get_v_scroll_bar().page))
	_check(abs(_scroll().scroll_vertical - expected) <= 2, "actual jump-link touch reaches " + section)

func _scroll_to_node(node_name: String, offset: int = 20) -> void:
	var target: Control = app._page.find_child(node_name, true, false) as Control
	_check(target != null, "scroll target exists: " + node_name)
	if target == null: return
	_scroll().stop_gesture()
	_scroll().scroll_vertical += roundi(target.global_position.y - _scroll().global_position.y) - offset
	await _layout()
	_check(_scroll().get_global_rect().has_point(target.get_global_rect().get_center()), "scroll target center is in visible viewport: " + node_name)

func _drag_control(control: Control, step: Vector2) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	_touch(point, true)
	for i: int in range(1, 7):
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point + step * i
		drag.relative = step
		root.push_input(drag, true)
		await process_frame
	_touch(point + step * 6, false)
	await _layout()
	_scroll().stop_gesture()

func _intercept_source(url: String) -> void:
	intercepted_urls.append(url)

func _capture(label: String) -> void:
	if output.is_empty(): return
	if DisplayServer.get_name() == "headless":
		_check(false, "native captures require a real renderer")
		return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	_check(picture.get_size() == root.size, "framebuffer equals requested actual window size")
	_check(picture.save_png(output.path_join(label + ".png")) == OK, "saved native framebuffer " + label)
	capture_rows.append({"file": label + ".png", "width": picture.get_width(), "height": picture.get_height(), "screen": app._screen, "species_id": app._active_species_id, "scroll": _scroll().scroll_vertical, "fixture_total_catch_count": save.total_count(), "selected_species_catch_count": app._count(app._active_species_id), "scope": "Actual production Main UI; isolated artificial catch fixtures; not a player save or Android hardware"})
	picture = null

func _write_evidence() -> void:
	var evidence: Dictionary = {"scope": "Native desktop Mobile/Vulkan production Main UI; root 3D disabled for notebook-only presentation; no phone/device performance claim", "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "api": RenderingServer.get_video_adapter_api_version(), "viewport": str(root.size), "app_size": str(app.size), "browser_opened": false, "source_taps_intercepted": intercepted_urls.size(), "checks": checks, "failures": failures, "captures": capture_rows, "hashes": {}}
	for path: String in ["res://scripts/main.gd", "res://scripts/fish_notebook_ui.gd", "res://scripts/fish_natural_history.gd", "res://tests/natural_history_tests.gd"] + HistoryData.FILES:
		evidence.hashes[path] = FileAccess.get_sha256(path)
	var file: FileAccess = FileAccess.open(output.path_join("evidence.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t") + "\n")
