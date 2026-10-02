extends SceneTree
## Production-scene borderless UI contract. See docs/UI_STYLE_TESTS.md.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const IconActionScript = preload("res://scripts/icon_action.gd")
const STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]
const MIN_TARGET: float = 96.0
var app: Control
var checks: int = 0
var failures: int = 0
var buttons_checked: int = 0
var routes: Array[String] = []
var test_root: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Main._ready initializes user:// before the fixture is installed. Refuse to
	# construct it unless both the engine's data directory and HOME are isolated.
	var isolated_data: String = OS.get_environment("XDG_DATA_HOME")
	if not isolated_data.begins_with("/tmp/farshore-ui-style-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-ui-style-") or not OS.get_user_data_dir().begins_with(isolated_data + "/"):
		printerr("UI_STYLE_TESTS: refusing non-isolated HOME/XDG_DATA_HOME; see docs/UI_STYLE_TESTS.md")
		quit(2)
		return
	test_root = isolated_data.path_join("fixtures")
	root.size = Vector2i(720, 1280)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)
	_check(app._content_ok, "actual Main loaded its production catalog and textures")
	_check(not app.store.read_only, "isolated startup save is writable")
	_check(app.size.is_equal_approx(Vector2(720, 1280)), "actual Main layout uses the 720x1280 design viewport")
	var fixture: SaveStore = Store.new()
	_check(fixture.initialize(test_root), "production SaveStore fixture initializes")
	app.store = fixture
	app._close_page()
	app.session.reset()
	await _audit("fishing", app)
	for pair: Array in [["旅行", "compass"], ["图鉴", "book"], ["收藏", "heart"], ["行囊", "bag"], ["鱼饵", "lure"], ["抛竿", "rod"]]:
		var action: Button = _find_button(app, str(pair[0]))
		_check(action != null, "main navigation exists: " + str(pair[0]))
		if action != null:
			_check(action.get("icon_kind") == pair[1], "main action has the correct icon: " + str(pair[0]))
	# Starter saves expose disabled unlock/equipment controls and empty collections.
	for method: String in ["_show_home", "_show_pause", "_show_travel", "_show_gear", "_show_catalog", "_show_favorites", "_show_settings", "_show_licenses", "_show_pending"]:
		app.call(method)
		await _audit("starter/" + method.trim_prefix("_show_"), app._overlay)
	app._show_species("chinese_sturgeon")
	await _audit("undiscovered_species", app._overlay)
	_check(_seed_collection(fixture), "legitimate settled/released collection fixture")
	for method: String in ["_show_travel", "_show_gear", "_show_catalog", "_show_favorites"]:
		app.call(method)
		await _audit("discovered/" + method.trim_prefix("_show_"), app._overlay)
	app._show_species("common_carp")
	await _audit("discovered_species", app._overlay)
	app._show_zoom("common_carp")
	await _audit("specimen_zoom", app._overlay)
	await _test_active_feedback()
	# Check real callbacks survive repeated replacement of overlays.
	for repeat: int in range(3):
		app._show_settings()
		await _settle_layout()
		var back: Button = _find_button(app._overlay, "返回")
		_check(back != null, "repeated settings route has Back")
		if back != null: back.pressed.emit()
		await _settle_layout()
		_check(app._overlay == null and app._screen.is_empty(), "real Back dismisses overlay without a stale screen")
	for species: String in ["common_carp", "chinese_sturgeon"]:
		await _audit_catch(species)
	app._close_page()
	app.session.reset()
	app.session.start_charge()
	await _audit("charging", app)
	var fish: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"], "lake_shore", "lake", "worm", 2, "day", "clear")
	app.session.cast(fish, app.catalog.gear[2])
	app.session.set_state(FishingSession.State.BITE)
	await _audit("bite", app)
	app.session.press()
	await _audit("fight", app)
	app.session._finish(false, "UI test escape")
	await _audit("escape", app._overlay)
	app._finish_result()
	await _settle_layout()
	app.queue_free()
	await process_frame
	print("UI_STYLE_ROUTES: ", ", ".join(routes))
	print("UI_STYLE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures, "; button visits=", buttons_checked, "; logical viewport=720x1280")
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL UI: ", label)

func _settle_layout() -> void:
	for frame: int in range(4): await process_frame

func _audit(route: String, subtree: Node) -> void:
	await _settle_layout()
	_check(is_instance_valid(subtree), route + " production subtree exists")
	if not is_instance_valid(subtree): return
	routes.append(route)
	var before: int = buttons_checked
	_walk(subtree, route)
	_check(buttons_checked > before, route + " contains actual actionable production controls")
	print("UI_STYLE_ROUTE ", route, " buttons=", buttons_checked - before)

func _walk(node: Node, route: String) -> void:
	if node is Button:
		_audit_button(node as Button, route)
	elif node is PanelContainer:
		_check(_transparent_style((node as PanelContainer).get_theme_stylebox("panel")), route + ": no card backplate at " + str(node.get_path()))
	elif node is LineEdit:
		var search: LineEdit = node as LineEdit
		_check(search.size.x + 0.1 >= MIN_TARGET and search.size.y + 0.1 >= MIN_TARGET, route + ": search target >=96 logical units")
		for state: String in ["normal", "focus"]:
			var style: StyleBox = search.get_theme_stylebox(state)
			var underline_only: bool = style is StyleBoxFlat and (style as StyleBoxFlat).bg_color.a <= 0.001 and (style as StyleBoxFlat).border_width_top == 0 and (style as StyleBoxFlat).border_width_left == 0 and (style as StyleBoxFlat).border_width_right == 0
			_check(_transparent_style(style) or underline_only, route + ": search has no filled backplate in " + state)
	elif node is ColorRect:
		var rect: ColorRect = node as ColorRect
		_check(not (rect.color.a > 0.1 and rect.color.get_luminance() < 0.2 and rect.size.x > MIN_TARGET and rect.size.y > MIN_TARGET), route + ": no dark rectangular backplate at " + str(node.get_path()))
	# Progress bars/sliders/rulers remain meaningful functional indicators. Their
	# track/fill is deliberately not treated as a button or decorative backplate.
	for child: Node in node.get_children():
		_walk(child, route)

func _audit_button(button: Button, route: String) -> void:
	buttons_checked += 1
	var label: String = route + ": " + button.text + " [" + button.get_class() + "]"
	for state: String in STATES:
		# hover_pressed is not used by every button type, but an inherited opaque
		# default still violates the visual contract if that state becomes active.
		_check(_transparent_style(button.get_theme_stylebox(state)), label + " transparent " + state)
	_check(button.size.x + 0.1 >= MIN_TARGET and button.size.y + 0.1 >= MIN_TARGET, label + " target >=96 logical units, actual=" + str(button.size))
	_check(not button.text.strip_edges().is_empty(), label + " has a text label")
	_check(button.mouse_filter != Control.MOUSE_FILTER_IGNORE, label + " is a real interactive hit target")
	if button is OptionButton:
		_check(button.get_theme_icon("arrow") != null or button.icon != null, label + " visible selection icon")
		return
	_check(button.get_script() == IconActionScript, label + " uses the production borderless icon control")
	if button.get_script() != IconActionScript: return
	var icon: Control = button.get("_art") as Control
	var caption: Label = button.get("_caption") as Label
	_check(caption != null and caption.text == button.text, label + " visible caption mirrors its action")
	if caption != null:
		_check(caption.get_theme_constant("outline_size") > 0 or caption.get_theme_color("font_shadow_color").a > 0, label + " text legibility uses outline/shadow")
		_check(caption.position.x >= -0.1 and caption.position.y >= -0.1 and caption.position.x + caption.size.x <= button.size.x + 0.1 and caption.position.y + caption.size.y <= button.size.y + 0.1, label + " caption stays inside target: " + str(caption.get_rect()))
		_check(caption.get_line_count() * caption.get_line_height() <= caption.size.y + 2, label + " caption fits vertically")
	var has_icon: bool = icon != null and icon.size.x > 0 and icon.size.y > 0 and str(button.get("icon_kind")) not in ["", "none"]
	# A fish catalog entry legitimately uses its adjacent species illustration as
	# its icon. Do not require a redundant second pictogram below the specimen.
	if not has_icon: has_icon = _has_specimen_sibling(button)
	_check(has_icon, label + " has an icon or its own adjacent specimen illustration")
	if icon != null:
		_check(icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " icon does not steal taps")
	if caption != null:
		_check(caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " caption does not steal taps")
		if button.disabled:
			_check(caption.modulate.a < 1 and icon != null and icon.modulate.a < 1, label + " disabled state changes icon/text rather than background")

func _test_active_feedback() -> void:
	app._show_settings()
	await _settle_layout()
	var button: Button = _find_button(app._overlay, "返回")
	_check(button != null, "active-feedback test uses actual settings Back button")
	if button == null: return
	var icon: Control = button.get("_art") as Control
	var caption: Label = button.get("_caption") as Label
	var resting_icon: Color = icon.modulate
	var resting_label: Color = caption.get_theme_color("font_color")
	var point: Vector2 = button.get_global_rect().get_center()
	var move: InputEventMouseMotion = InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	await _settle_layout()
	_check(button.is_hovered(), "native input hovers actual production target")
	_check(icon.modulate != resting_icon or caption.get_theme_color("font_color") != resting_label, "actual hover changes icon/text rather than background")
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await _settle_layout()
	_check(button.button_pressed, "native press holds actual production target")
	_check(_transparent_style(button.get_theme_stylebox("hover_pressed")), "held hover stays borderless")
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	root.push_input(release, true)
	await _settle_layout()
	_check(app._overlay == null, "native release invokes actual Back callback")

func _transparent_style(style: StyleBox) -> bool:
	if style is StyleBoxEmpty: return true
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = style as StyleBoxFlat
		var border_visible: bool = flat.border_color.a > 0 and (flat.border_width_top > 0 or flat.border_width_bottom > 0 or flat.border_width_left > 0 or flat.border_width_right > 0)
		return (not flat.draw_center or flat.bg_color.a <= 0.001) and not border_visible and (flat.shadow_size <= 0 or flat.shadow_color.a <= 0.001)
	return false

func _has_specimen_sibling(button: Button) -> bool:
	for sibling: Node in button.get_parent().get_children():
		if sibling is TextureRect and (sibling as TextureRect).texture != null and (sibling as TextureRect).texture.resource_path.begins_with("res://assets/fish/"):
			return true
	return false

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text: return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button(child, text)
		if found != null: return found
	return null

func _seed_collection(fixture: SaveStore) -> bool:
	var index: int = 0
	for species: FishDefinition in app.catalog.fish.values():
		var sid: String = str(species.spots()[0])
		var rid: String = str(app.catalog.spots[sid].region_id)
		var record: Dictionary = app.encounter.make_individual(species, sid, rid, "worm", 2, "day", "clear")
		record["session_id"] = "ui_style_seed_%d" % index
		record["catch_id"] = "ui_style_seed_catch_%d" % index
		fixture.begin_session(record.session_id)
		if not fixture.settle_catch(record).get("ok", false): return false
		if not fixture.dispose_catch(record.catch_id, "released").get("ok", false): return false
		index += 1
	var candidate: Dictionary = fixture.state
	candidate["gear"] = 2
	candidate["owned_gear"] = [0, 1, 2]
	candidate["unlocked_regions"] = ["lake", "japan", "norway", "med", "bayou", "yangtze"]
	candidate["favorites"] = ["common_carp", "olive_flounder", "atlantic_cod", "atlantic_wolffish", "painted_comber", "gilthead_seabream"]
	return fixture.commit_state(candidate)

func _audit_catch(species_id: String) -> void:
	app._close_page()
	app.session.reset()
	var species: FishDefinition = app.catalog.fish[species_id]
	var sid: String = str(species.spots()[0])
	var rid: String = str(app.catalog.spots[sid].region_id)
	app.spot_id = sid
	app.region_id = rid
	app._refresh_location()
	var record: Dictionary = app.encounter.make_individual(species, sid, rid, "worm", 2, "day", "clear")
	app.session.start_charge()
	_check(app.session.cast(record, app.catalog.gear[2]), species_id + " actual session casts")
	app.store.begin_session(app.session.session_id)
	app.session.set_state(FishingSession.State.FIGHT)
	app.session._finish(true, "")
	_check(app._save_ok and app._screen == "result", species_id + " actual catch settles into result page")
	await _audit("catch/" + species_id, app._overlay)
	app._show_pending()
	await _audit("pending/" + species_id, app._overlay)
	app._show_result()
	app._dispose_result("released")
	await _settle_layout()
	_check(app._overlay == null and app._last_record.is_empty(), species_id + " real release clears result")
