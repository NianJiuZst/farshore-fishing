extends SceneTree
## Production-scene rounded surface contract from upstream 1afda37.
## See docs/OCEAN_UPSTREAM_TEST_ALIGNMENT.md for baseline evidence and scope.
const MainScene = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const IconActionScript = preload("res://scripts/icon_action.gd")
const ArtScript = preload("res://scripts/ui_art.gd")
const Registry = preload("res://scripts/fish_3d_registry.gd")
const Preview = preload("res://scripts/fish_art_view.gd")
const FailureModalScript = preload("res://scripts/fishing_failure_modal.gd")
const EXPECTED_ICONS: Array[String] = ["rod", "reel", "hook", "bag", "compass", "book", "heart", "coin", "badge", "pause", "settings", "sound", "back", "arrow", "sort", "search", "release", "worm", "grain", "shrimp", "lure", "sun", "dusk", "rain", "ruler", "sweetcorn", "dough", "cut_fish", "spinner", "rod_spinning", "rod_heavy", "large_fish_chunk", "whole_mackerel", "large_squid", "large_surface_lure"]
const RETIRED_COPY: Array[String] = ["F A R S H O R E", "NATURAL HISTORY", "沿着水声，去往远岸", "把世界，钓成一本旅行手册", "风从远岸来", "停一会儿，风景还在", "把下一站，交给海风", "真实的相遇，是最好的旅行纪念", "水下还有一个未曾见过的身影"]
const STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]
const MIN_TARGET: float = 96.0
var app: Control
var checks: int = 0
var failures: int = 0
var buttons_checked: int = 0
var routes: Array[String] = []
var test_root: String
var idle_action_rect: Rect2
var rendered_icon_kinds: Dictionary = {}
var logical_viewport_size: Vector2 = Vector2(720,1280)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Main._ready initializes user:// before the fixture is installed. Refuse to
	# construct it unless both the engine's data directory and HOME are isolated.
	var isolated_data: String = OS.get_environment("XDG_DATA_HOME")
	if not isolated_data.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(isolated_data + "/"):
		printerr("UI_STYLE_TESTS: refusing non-isolated HOME/XDG_DATA_HOME; see docs/UI_STYLE_TESTS.md")
		quit(2)
		return
	test_root = isolated_data.path_join("fixtures-%s-%s" % [OS.get_process_id(),Time.get_ticks_usec()])
	_test_raster_assets()
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
	app = MainScene.instantiate()
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
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.scenery._process(0.025)
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)
	var errors: Array[String] = Registry.validate_catalog(app.catalog,true)
	_check(app._content_ok and app._models_complete and errors.is_empty(), "actual Main requires all111 models, catalog and textures: " + str(errors))
	if not app._content_ok or not app._models_complete:
		print("UI_STYLE_SCOPE: full production pages NOT RUN; actual111-model dependency failed, no readiness override")
		app.queue_free()
		await process_frame
		print("UI_STYLE_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; incomplete dependency, not acceptance")
		quit(1)
		return
	_check(not app.store.read_only, "isolated startup save is writable")
	_test_theme_contract()
	logical_viewport_size = root.get_visible_rect().size
	var expected_height: float = 1584.0 if "--tall" in OS.get_cmdline_user_args() and str(ProjectSettings.get_setting("display/window/stretch/aspect","keep"))=="expand" else 1280.0
	_check(app.size.is_equal_approx(Vector2(720,expected_height)), "actual Main logical viewport follows the production stretch policy")
	_check(app._safe.get_theme_constant("margin_top")>=22 and app._safe.get_theme_constant("margin_bottom")>=20 and app._safe.get_theme_constant("margin_left")>=20 and app._safe.get_theme_constant("margin_right")>=20,"native desktop fallback safe margins are retained")
	print("LAYOUT_SCOPE: physical=",root.size," logical=",logical_viewport_size," aspect=",ProjectSettings.get_setting("display/window/stretch/aspect","keep"),"; representative desktop layout, not Android safe-area or hardware certification")
	var fixture: SaveStore = Store.new()
	_check(fixture.initialize(test_root), "production SaveStore fixture initializes")
	app.store = fixture
	# Stable production RNG avoids record-banner/count drift between runs.
	app.encounter.rng.seed = 20261002
	app.session._rng.seed = 2468
	await _audit("lobby", app._overlay)
	_check(app._mode == "lobby" and not app._action.is_visible_in_tree(), "startup lobby does not expose a casting control")
	app._show_prepare()
	await _audit("prepare", app._overlay)
	app._enter_fishery()
	app.session.reset()
	await _audit("fishing", app)
	for pair: Array in [["旅行", "compass"], ["图鉴", "book"], ["收藏", "heart"], ["行囊", "bag"], [app.catalog.bait_name(app.bait_id), app.bait_id], ["抛竿", "rod"]]:
		var action: Button = _find_button(app, str(pair[0]))
		_check(action != null, "main navigation exists: " + str(pair[0]))
		if action != null:
			_check(action.get("icon_kind") == pair[1], "main action has the correct icon: " + str(pair[0]))
	idle_action_rect = app._action.get_global_rect()
	_check(idle_action_rect.position.x >= 450 and idle_action_rect.end.x <= logical_viewport_size.x and idle_action_rect.end.y >= logical_viewport_size.y-40 and idle_action_rect.end.y <= logical_viewport_size.y, "main action occupies the safe bottom-right edge")
	_check(app._nav_rail.get_global_rect().position.x >= 570, "secondary navigation occupies the right screen edge")
	_check(app._place.get_global_rect().end.y < 160 and app._condition.get_global_rect().end.y < 210, "essential location/weather HUD stays compact at top")
	await _test_synthetic_insets()
	await _test_selected_bait_and_weather()
	await _test_retained_3d_scenery()
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
	_check_photo_preview("common_carp","discovered species detail")
	app._show_zoom("common_carp")
	await _audit("specimen_zoom", app._overlay)
	_check_photo_preview("common_carp","enlarged specimen")
	app._enter_fishery()
	await _test_active_feedback()
	await _test_catalog_controls()
	await _test_pause_back_settings()
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
	app.session.set_seed(2468)
	app.session.start_charge()
	await _audit("charging", app)
	_check_action_position("charging", "rod")
	var fish: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"], "lake_shore", "lake", "worm", 2, "day", "clear")
	app.encounter.apply_float_presentation(fish,app.catalog,0.6)
	_check(app.session.cast(fish, app.catalog.gear[2]),"observation bitmap fixture casts an actual fish")
	var float_ui: Array = []
	for phase: int in [FishingSession.State.WAITING, FishingSession.State.NIBBLE, FishingSession.State.BITE]:
		var reached: bool = _advance_live_phase(phase)
		_check(reached,"bitmap fixture reaches real observation phase: " + str(phase))
		if not reached: break
		await _audit("float_observation_%d" % phase, app)
		_check_action_position("float_observation_%d" % phase, "reel")
		_check(not app._action.disabled and app._action.text == "收线", "reel stays enabled and equally labeled throughout float observation")
		var signature: Array = [app._action.text, app._action.icon_kind, app._action.disabled, app._action.label_color, app._action.modulate, app._status.text, app._hint.text, app._bars.visible, app._nav_rail.visible]
		if float_ui.is_empty(): float_ui = signature
		else: _check(signature == float_ui, "nibble/bite provides no HUD, color, label, or navigation giveaway")
	_check(app.session.float_encounter.can_hook(),"fight bitmap fixture has actual seated bait possession before input")
	app._action_down()
	app._action_up()
	_check(app.session.state == FishingSession.State.FIGHT and app._overlay == null,"fresh actual action hooks the bitmap fixture rather than opening an empty-cast modal")
	if app.session.state == FishingSession.State.FIGHT:
		await _audit("fight", app)
		_check_action_position("fight", "reel")
		_check(not app._nav_rail.is_visible_in_tree(), "nonessential navigation hides during the fight")
	app.session._finish(false, "UI test escape")
	await _audit("escape", app._overlay)
	app._finish_result()
	await _settle_layout()
	app.queue_free()
	await process_frame
	print("UI_BITMAP_BINDINGS: ", rendered_icon_kinds.keys())
	print("UI_STYLE_ROUTES: ", ", ".join(routes))
	print("UI_STYLE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures, "; button visits=", buttons_checked, "; physical viewport=",root.size,"; logical viewport=",logical_viewport_size)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL UI: ", label)

func _settle_layout() -> void:
	for frame: int in range(4): await process_frame

func _tick_live_fixture(delta: float = 0.025) -> void:
	if not app.scenery._suspended:
		if app.scenery._animator: app.scenery._animator.advance(delta)
		if app.scenery._fish_animator:
			app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			app.scenery._fish_animator.advance(delta)
	app.scenery._process(delta)
	app._process(delta)

func _advance_live_phase(target: int) -> bool:
	# UI fixtures use a documented reproducible encounter seed and actual
	# presentation/session progress. Assigning BITE is not hook possession.
	for tick: int in 3600:
		if app.session.state == target: return true
		if app.session.state in [FishingSession.State.ESCAPED,FishingSession.State.CAUGHT,FishingSession.State.PAUSED]: return false
		if target == FishingSession.State.FIGHT and app.session.float_encounter.can_hook():
			app._action_down()
			app._action_up()
			return app.session.state == FishingSession.State.FIGHT
		_tick_live_fixture()
	return false

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
	if node.get_script() == ArtScript:
		var kind: String = str(node.get("kind"))
		if kind != "none":
			_check(kind in EXPECTED_ICONS, route + ": icon is a required generated bitmap: " + kind)
			var texture: Texture2D = ArtScript.texture_for(kind)
			_check(texture != null and texture.resource_path == ArtScript.ICON_ROOT + kind + ".png", route + ": live icon resolves its production PNG: " + kind)
			rendered_icon_kinds[kind] = true
			_check(kind != "badge", route + ": no decorative branding emblem")
	if node is Label:
		for retired: String in RETIRED_COPY:
			_check(not retired in (node as Label).text, route + ": no retired decorative/poetic copy: " + retired)
	if node is Button:
		_audit_button(node as Button, route)
	elif node is PanelContainer:
		if node.name == "FailurePanel" and node.get_parent().get_script() == FailureModalScript:
			_check(node.size.y <= 500 and node.size.x <= 620, route + ": explicit failure popup is compact, never a full-screen page")
			_check_flat_style((node as PanelContainer).get_theme_stylebox("panel"), app.PAPER, Color(0.40,0.49,0.40,0.24), 1, 24, route + ": failure paper", 16, Color(0.02,0.07,0.08,0.20), Vector2(0,8))
		else: _audit_card(node as PanelContainer, route)
	elif node is LineEdit:
		var search: LineEdit = node as LineEdit
		_check(search.size.x + 0.1 >= MIN_TARGET and search.size.y + 0.1 >= MIN_TARGET, route + ": search target >=96 logical units")
		_audit_input_styles(search, route + ": search")
		_check(_contrast(search.get_theme_color("font_color"), Color("fbfcf6")) >= 4.5, route + ": search text contrasts with its actual pale input surface")
	elif node is HSlider:
		var slider: HSlider = node as HSlider
		_check(slider.size.x >= MIN_TARGET and slider.size.y >= MIN_TARGET, route + ": volume slider touch target >=96 logical units, actual=" + str(slider.size))
	elif node is ColorRect:
		var rect: ColorRect = node as ColorRect
		if rect.name == "FailureScrim" and rect.get_parent().get_script() == FailureModalScript:
			_check(rect.color.a <= 0.35, route + ": requested modal scrim preserves the world")
		else: _check(not (rect.color.a > 0.1 and rect.color.get_luminance() < 0.2 and rect.size.x > MIN_TARGET and rect.size.y > MIN_TARGET), route + ": no dark rectangular backplate at " + str(node.get_path()))
	# Progress bars/sliders/rulers remain meaningful functional indicators. Their
	# track/fill is deliberately not treated as a button or decorative backplate.
	for child: Node in node.get_children():
		_walk(child, route)

func _audit_button(button: Button, route: String) -> void:
	buttons_checked += 1
	var label: String = route + ": " + button.text + " [" + button.get_class() + "]"
	if button is OptionButton:
		_audit_input_styles(button, label)
	elif button.has_meta("notebook_tile"):
		_audit_notebook_styles(button, label)
	elif button.get_script() == IconActionScript:
		_audit_icon_styles(button, label)
	else:
		_check(false, label + " has an explicitly supported surface contract")
	_check(button.size.x + 0.1 >= MIN_TARGET and button.size.y + 0.1 >= MIN_TARGET, label + " target >=96 logical units, actual=" + str(button.size))
	_check(not button.text.strip_edges().is_empty(), label + " has a text label")
	_check(button.mouse_filter != Control.MOUSE_FILTER_IGNORE, label + " is a real interactive hit target")
	if button is OptionButton:
		var arrow: Texture2D = button.get_theme_icon("arrow")
		_check(arrow != null and arrow == ArtScript.scaled_texture("arrow", 24, true), label + " dropdown uses the generated arrow bitmap, not an inherited vector")
		return
	if button.has_meta("notebook_tile"):
		var photos: Array[Node] = button.find_children("FishArtPreview","TextureRect",true,false)
		_check(photos.size()==1 and photos[0].get_script()==Preview, label + " whole fish target contains its genuine specimen art")
		_check(str(button.get_meta("fish_species_id","")) in app.catalog.fish, label + " whole target is bound to a real species")
		if photos.size()==1: _check(photos[0].mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" fish image leaves tap/drag to the native tile")
		var title: Label = button.find_child("FishTileName",true,false) as Label
		_check(title != null and title.text==button.text and title.mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" whole tile has one readable nonblocking title")
		return
	_check(button.get_script() == IconActionScript, label + " uses the production rounded icon control")
	if button.get_script() != IconActionScript: return
	var icon: Control = button.get("_art") as Control
	var caption: Label = button.get("_caption") as Label
	_check(caption != null and caption.text == button.text, label + " visible caption mirrors its action")
	if caption != null:
		if not button.disabled:
			var fg: Color = caption.get_theme_color("font_color")
			var normal: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
			if normal != null:
				# Composite translucent world surfaces over white, the conservative
				# bright-scene case. Large >=24 px captions use the 3:1 threshold.
				var background: Color = Color.WHITE.blend(normal.bg_color) if bool(button.get("light_label")) or str(button.get("appearance")) == "glass" else app.PAPER.blend(normal.bg_color)
				var minimum: float = 3.0 if caption.get_theme_font_size("font_size") >= 24 else 4.5
				_check(_contrast(fg, background) >= minimum, label + " caption contrasts with its actual surface, ratio=" + str(_contrast(fg, background)))
		_check(caption.get_theme_constant("outline_size") == 0, label + " rounded surfaces preserve the upstream unoutlined caption")
		_check(caption.position.x >= -0.1 and caption.position.y >= -0.1 and caption.position.x + caption.size.x <= button.size.x + 0.1 and caption.position.y + caption.size.y <= button.size.y + 0.1, label + " caption stays inside target: " + str(caption.get_rect()))
		_check(caption.get_line_count() * caption.get_line_height() <= caption.size.y + 2, label + " caption fits vertically")
	var has_icon: bool = icon != null and icon.size.x > 0 and icon.size.y > 0 and str(button.get("icon_kind")) not in ["", "none"]
	# A fish catalog entry legitimately uses its adjacent species illustration as
	# its icon. Do not require a redundant second pictogram below the specimen.
	if not has_icon: has_icon = _has_specimen_sibling(button)
	var quality_selector: bool = _is_quality_selector(button)
	_check(has_icon or quality_selector, label + " has an icon/specimen or is an exact upstream text-only quality selector")
	if quality_selector:
		var quality: String = str(app.store.state.settings.get("visual_quality", "balanced"))
		var names: Dictionary = {"low":"省电", "balanced":"均衡", "high":"精致"}
		var selected: bool = button.text == "✓ " + str(names[quality])
		_check(button.appearance == ("primary" if selected else "surface") and button.label_color == (app.PAPER if selected else app.INK), label + " quality selection keeps its exact primary/surface contrast pair")
		_check(caption != null and caption.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and caption.get_theme_font_size("font_size") == 23 and caption.position == Vector2.ZERO and caption.size == button.size and icon != null and icon.size == Vector2.ZERO, label + " quality selector intentionally centers text with no redundant pictogram")
	if icon != null:
		_check(icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " icon does not steal taps")
	if caption != null:
		_check(caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " caption does not steal taps")
		if button.disabled:
			_check(caption.modulate.a < 1 and icon != null and icon.modulate.a < 1, label + " disabled state dims both icon and text")

func _is_quality_selector(button: Button) -> bool:
	if app._screen != "settings" or button.icon_extent != 0 or not button.get_parent() is HBoxContainer or button.get_parent().get_child_count() != 3: return false
	var names: Dictionary = {"省电":"low", "均衡":"balanced", "精致":"high"}
	var caption: String = button.text.trim_prefix("✓ ")
	if not names.has(caption): return false
	for connection: Dictionary in button.pressed.get_connections():
		if connection.callable == Callable(app, "_set_quality").bind(str(names[caption])): return true
	return false

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
	_check(icon.modulate != resting_icon or caption.get_theme_color("font_color") != resting_label, "actual hover changes icon/text alongside the hover surface")
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await _settle_layout()
	_check(button.button_pressed, "native press holds actual production target")
	_audit_icon_styles(button, "native held Back")
	_check((button.get_theme_stylebox("hover_pressed") as StyleBoxFlat).bg_color != (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, "held hover visibly darkens the production surface")
	_check(button.has_focus(), "native press focuses the real production control")
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	root.push_input(release, true)
	await _settle_layout()
	_check(app._overlay == null, "native release invokes actual Back callback")

# Explicit constants below were read from upstream 1afda37, not obtained by
# invoking the same production style builder that is being tested.
func _test_theme_contract() -> void:
	for state: String in STATES:
		_check(app.theme.get_stylebox(state, "Button") is StyleBoxEmpty, "base Button theme intentionally stays clear in " + state)
	for type_name: String in ["LineEdit", "TextEdit", "OptionButton"]:
		_check_flat_style(app.theme.get_stylebox("normal", type_name), Color("fbfcf6"), Color("c3d1c7"), 1, 16, type_name + " theme normal")
		_check_flat_style(app.theme.get_stylebox("hover", type_name), Color("f1f6ee"), Color("b3cabe"), 1, 16, type_name + " theme hover")
		_check_flat_style(app.theme.get_stylebox("focus", type_name), Color(0,0,0,0), Color("256b63"), 2, 16, type_name + " theme clear focus overlay")
	_check_flat_style(app.theme.get_stylebox("panel", "PopupMenu"), Color("edf1e5"), Color(0,0,0,0), 0, 0, "popup paper")
	for primary: bool in [false, true]:
		var sample: Button = app._button("返回", func() -> void: pass, primary)
		_check(sample.appearance == ("primary" if primary else "surface") and sample.label_color == (app.PAPER if primary else app.INK), "Main button factory selects the exact upstream surface and ink pair")
		sample.free()

func _audit_input_styles(control: Control, label: String) -> void:
	for state: String in STATES:
		match state:
			"normal": _check_flat_style(control.get_theme_stylebox(state), Color("fbfcf6"), Color("c3d1c7"), 1, 16, label + " " + state)
			"hover": _check_flat_style(control.get_theme_stylebox(state), Color("f1f6ee"), Color("b3cabe"), 1, 16, label + " " + state)
			"focus": _check_flat_style(control.get_theme_stylebox(state), Color(0,0,0,0), Color("256b63"), 2, 16, label + " clear focus overlay")
			_: _check(control.get_theme_stylebox(state) is StyleBoxEmpty and _transparent_style(control.get_theme_stylebox(state)), label + " intentionally clear inherited " + state)

func _audit_icon_styles(button: Button, label: String) -> void:
	var appearance: String = str(button.get("appearance"))
	var light: bool = bool(button.get("light_label"))
	_check(appearance in ["surface", "primary", "glass", "subtle"], label + " uses a known upstream surface variant")
	var base: Color = Color("e8eeea")
	if appearance == "primary": base = Color("28675e")
	elif appearance == "glass" or light: base = Color(0.035,0.12,0.15,0.82)
	elif appearance == "subtle": base = Color(0.85,0.90,0.86,0.35)
	for state: String in STATES:
		var fill: Color = base
		var border: Color = Color(0.75,0.88,0.80,0.20) if light or appearance == "primary" else Color(0.17,0.34,0.31,0.12)
		var width: int = 1
		if state == "hover": fill = base.lightened(0.06)
		if state in ["pressed", "hover_pressed"]: fill = base.darkened(0.12)
		if state == "disabled": fill = Color(base,0.25)
		if state == "focus":
			fill = Color.TRANSPARENT
			border = Color("d0ad64")
			width = 3
		_check_flat_style(button.get_theme_stylebox(state), fill, border, width, 22 if appearance == "primary" else 18, label + " " + state)

func _audit_notebook_styles(button: Button, label: String) -> void:
	var species: String = str(button.get_meta("fish_species_id", ""))
	var count: int = app._count(species)
	var base: Color = Color("fafbf3") if count > 0 else Color("e7ece5")
	for state: String in STATES:
		var fill: Color = base
		var border: Color = Color("c6d5c9")
		var width: int = 1
		if state == "hover": fill = base.lightened(0.04)
		if state == "pressed": fill = base.darkened(0.04)
		if state == "focus":
			fill = Color.TRANSPARENT
			border = Color("256b63")
			width = 2
		_check_flat_style(button.get_theme_stylebox(state), fill, border, width, 20, label + " notebook " + state)

func _audit_card(card: PanelContainer, route: String) -> void:
	var style: StyleBox = card.get_theme_stylebox("panel")
	var label: String = route + ": paper/glass card at " + str(card.get_path())
	_check(style is StyleBoxFlat, label + " uses the upstream flat surface")
	if not style is StyleBoxFlat: return
	var flat: StyleBoxFlat = style as StyleBoxFlat
	var fills: Array[Color] = [Color("fffcf4"), Color("e8ecd9"), Color(0.035,0.13,0.17,0.88), Color(0.05,0.17,0.21,0.9)]
	var variant: int = fills.find(flat.bg_color)
	_check(variant >= 0, label + " uses an explicit upstream card fill")
	if variant < 0: return
	_check_flat_style(flat, fills[variant], Color(0.30,0.43,0.38,0.12), 1, 22, label)
	var margins: Array = [[18.0], [18.0,20.0], [10.0], [8.0]][variant]
	_check(flat.content_margin_left in margins and flat.content_margin_top == flat.content_margin_left and flat.content_margin_right == flat.content_margin_left and flat.content_margin_bottom == flat.content_margin_left, label + " preserves its upstream content insets")

func _check_flat_style(style: StyleBox, fill: Color, border: Color, width: int, radius: int, label: String, shadow_size: int = 0, shadow: Color = Color(0,0,0,0.6), shadow_offset: Vector2 = Vector2.ZERO) -> void:
	_check(style is StyleBoxFlat, label + " is StyleBoxFlat")
	if not style is StyleBoxFlat: return
	var flat: StyleBoxFlat = style as StyleBoxFlat
	_check(flat.draw_center and flat.bg_color.is_equal_approx(fill), label + " exact upstream fill")
	_check(flat.border_color.is_equal_approx(border) and flat.border_width_left == width and flat.border_width_top == width and flat.border_width_right == width and flat.border_width_bottom == width, label + " exact upstream border")
	_check(flat.corner_radius_top_left == radius and flat.corner_radius_top_right == radius and flat.corner_radius_bottom_left == radius and flat.corner_radius_bottom_right == radius, label + " exact upstream corner radius")
	_check(flat.shadow_size == shadow_size and flat.shadow_offset.is_equal_approx(shadow_offset) and (shadow_size == 0 or flat.shadow_color.is_equal_approx(shadow)), label + " no unrequested shadow")
	if fill.a == 0 and width > 0:
		_check(border.a == 1.0 and width >= 2 and flat.bg_color.a == 0.0, label + " opaque visible focus ring leaves the underlying surface clear")

func _contrast(foreground: Color, background: Color) -> float:
	var a: float = foreground.srgb_to_linear().get_luminance()
	var b: float = background.srgb_to_linear().get_luminance()
	return (maxf(a,b)+0.05)/(minf(a,b)+0.05)

func _transparent_style(style: StyleBox) -> bool:
	if style is StyleBoxEmpty: return true
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = style as StyleBoxFlat
		var border_visible: bool = flat.border_color.a > 0 and (flat.border_width_top > 0 or flat.border_width_bottom > 0 or flat.border_width_left > 0 or flat.border_width_right > 0)
		return (not flat.draw_center or flat.bg_color.a <= 0.001) and not border_visible and (flat.shadow_size <= 0 or flat.shadow_color.a <= 0.001)
	return false

func _has_specimen_sibling(button: Button) -> bool:
	for sibling: Node in button.get_parent().get_children():
		if sibling is TextureRect and sibling.get_script() == Preview and sibling.texture is AtlasTexture:
			var source: Texture2D = (sibling.texture as AtlasTexture).atlas
			if source != null and source.resource_path.begins_with("res://assets/fish/"): return true
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
		if not app.catalog.is_fishing_species(species): continue
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
	app.encounter.apply_float_presentation(record,app.catalog,0.6)
	app.session.set_seed(2468)
	app.session.start_charge()
	_check(app.session.cast(record, app.catalog.gear[2]), species_id + " actual session casts")
	app.store.begin_session(app.session.session_id)
	var hooked: bool = _advance_live_phase(FishingSession.State.FIGHT)
	_check(hooked,species_id + " result art fixture reaches fight through a real held-bait hook")
	if not hooked: return
	# Result-page content is an explicit settled UI fixture; full fight and
	# Imported geometry for all110 ordinary fish is exercised by ocean_landing_tests.
	app.session._finish(true, "")
	_check(app._save_ok and app._landing_pending and app._screen != "result", species_id + " catch is saved before its 3D landing finishes")
	for tick: int in 90: app.scenery._process(0.05)
	_check(app._save_ok and app._screen == "result", species_id + " actual catch settles into result page")
	await _audit("catch/" + species_id, app._overlay)
	_check_photo_preview(species_id,"result " + species_id)
	if species_id == "chinese_sturgeon":
		_check(not "出售" in _all_label_text(app._overlay), "protected result contains no misleading sale instructions")
		_check("放归后保留图鉴与纪录" in _all_label_text(app._page_footer), "protected footer explicitly explains release-only record preservation")
	var retained_record: Dictionary = app._last_record.duplicate(true)
	var retained_count: int = app.store.total_count()
	var retained_currency: int = int(app.store.state.currency)
	for repeat: int in range(3):
		app._handle_back()
		await _settle_layout()
		_check(app._screen == "result" and app._last_record == retained_record, species_id + " repeated Back protects the exact pending result")
		_check(app.store.total_count() == retained_count and int(app.store.state.currency) == retained_currency, species_id + " repeated result Back cannot duplicate rewards")
	app._show_pending()
	await _audit("pending/" + species_id, app._overlay)
	app._show_result()
	var release: Button = _find_button_prefix(app._overlay, "放归自然" if species_id == "chinese_sturgeon" else "放生")
	_check(release != null and not release.disabled, species_id + " actual result release is available")
	if release != null:
		var rect: Rect2 = release.get_global_rect()
		_check(rect.position.y >= 0 and rect.end.y <= logical_viewport_size.y and rect.position.x >= 0 and rect.end.x <= logical_viewport_size.x, species_id + " actual release control remains inside viewport")
		release.pressed.emit()
	await _settle_layout()
	_check(app._overlay == null and app._last_record.is_empty(), species_id + " real release clears result")

func _test_raster_assets() -> void:
	_check(ArtScript.REQUIRED_ICONS.size() == 35, "production declares exactly35 required generated raster icons")
	var hashes: Dictionary = {}
	for kind: String in EXPECTED_ICONS:
		_check(kind in ArtScript.REQUIRED_ICONS, "production manifest contains " + kind)
		var path: String = ArtScript.ICON_ROOT + kind + ".png"
		_check(FileAccess.file_exists(path), "runtime PNG exists: " + path)
		_check(not FileAccess.file_exists(ArtScript.ICON_ROOT + kind + ".svg"), "no vector fallback for " + kind)
		var texture: Texture2D = ArtScript.texture_for(kind)
		_check(texture != null and texture.resource_path == path, "production texture resolver loads exact PNG: " + kind)
		if texture == null: continue
		_check(texture.get_width() >= 512 and texture.get_height() >= 512, "HD production dimensions >=512: " + kind)
		var picture: Image = Image.new()
		var decoded: Error = picture.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		_check(decoded == OK, "source file decodes as actual PNG: " + kind)
		_check(picture != null and picture.get_format() == Image.FORMAT_RGBA8, "source PNG is real RGBA8: " + kind)
		if decoded != OK: continue
		var imported: Image = texture.get_image()
		_check(imported != null and imported.detect_alpha() != Image.ALPHA_NONE, "runtime texture retains transparent alpha: " + kind)
		var pixels: PackedByteArray = picture.get_data()
		var clear_pixels: int = 0
		var painted_pixels: int = 0
		var blended_pixels: int = 0
		for offset: int in range(3, pixels.size(), 4):
			var alpha: int = pixels[offset]
			if alpha <= 8: clear_pixels += 1
			elif alpha >= 240: painted_pixels += 1
			else: blended_pixels += 1
		var total: int = picture.get_width() * picture.get_height()
		_check(clear_pixels > total / 10, "genuine transparent cutout space >10%: " + kind)
		_check(painted_pixels > total / 50, "nonempty painted subject >2%: " + kind)
		_check(blended_pixels > 20, "real antialiased transparent edges: " + kind)
		for point: Vector2i in [Vector2i.ZERO, Vector2i(picture.get_width()-1, 0), Vector2i(0, picture.get_height()-1), Vector2i(picture.get_width()-1, picture.get_height()-1)]:
			_check(picture.get_pixelv(point).a <= 0.01, "transparent PNG corner " + str(point) + ": " + kind)
		var digest: String = FileAccess.get_sha256(path)
		_check(not hashes.has(digest), "distinct source image, not a reused generic icon: " + kind)
		hashes[digest] = kind
	_check(ArtScript.validate_assets().is_empty(), "production startup validator accepts complete HD icon set")
	var renderer_source: String = FileAccess.get_file_as_string("res://scripts/ui_art.gd")
	_check("draw_texture_rect(" in renderer_source, "runtime art renderer actually paints its loaded texture")
	for forbidden: String in ["draw_line(", "draw_polyline(", "draw_polygon(", "draw_colored_polygon(", "draw_circle(", "draw_arc(", "draw_rect(", ".svg", "GradientTexture", "load_svg"]:
		_check(not forbidden in renderer_source, "icon renderer has no primitive/vector fallback: " + forbidden)
	print("UI_BITMAP_ASSETS: ", hashes.size(), "/35 distinct HD RGBA PNGs checked")

func _check_action_position(state_name: String, expected_icon: String) -> void:
	_check(app._action.get_global_rect().is_equal_approx(idle_action_rect), state_name + ": primary action does not move between fishing states")
	_check(app._action.icon_kind == expected_icon, state_name + ": primary action uses correct actual bitmap")

func _test_synthetic_insets() -> void:
	# Exercise layout under representative large cutouts without pretending that
	# desktop DisplayServer returned a real Android phone's safe-area values.
	app._safe.add_theme_constant_override("margin_top",104)
	app._safe.add_theme_constant_override("margin_bottom",80)
	await _settle_layout()
	_check(app._place.get_global_rect().position.y>=104,"synthetic top inset keeps live location HUD below cutout")
	_check(app._action.get_global_rect().end.y<=logical_viewport_size.y-80,"synthetic bottom inset keeps primary action above gesture area")
	app._show_settings()
	await _audit("synthetic_insets/settings",app._overlay)
	var margin: MarginContainer = app._overlay.get_node("OverlayMargin") as MarginContainer
	_check(margin.get_theme_constant("margin_top")>=104 and margin.get_theme_constant("margin_bottom")>=80,"overlay inherits the same synthetic safe insets")
	app._close_page()
	app._safe_area()
	await _settle_layout()
	_check(app._action.get_global_rect().is_equal_approx(idle_action_rect),"restoring native margins restores exact primary-action placement")
	print("SAFE_AREA_SCOPE: 104px top/80px bottom injected solely for layout testing; actual Android cutouts still require device testing")

func _test_selected_bait_and_weather() -> void:
	for bait: Dictionary in app.catalog.baits:
		app._show_gear()
		await _settle_layout()
		var id: String = str(bait.bait_id)
		var choice: Button = _find_button(app._overlay, ("已选 · " if id == app.bait_id else "") + str(bait.name))
		_check(choice != null and not choice.disabled, "real bait control available: " + id)
		if choice != null: choice.pressed.emit()
		await _settle_layout()
		_check(app.bait_id == id and app.store.state.selection.bait_id == id, "bait selection persists through actual control: " + id)
		app._close_page()
		await _settle_layout()
		_check(app._bait_control.icon_kind == id and app._bait_control._art.kind == id, "HUD renders current selected bait: " + id)
		_check(ArtScript.texture_for(app._bait_control._art.kind).resource_path == ArtScript.ICON_ROOT + id + ".png", "selected bait binds actual raster: " + id)
	app._set_bait("worm")
	app._close_page()
	for pair: Array in [[0.0, "sun"], [150.0, "dusk"], [240.0, "rain"], [480.0, "dusk"], [600.0, "sun"]]:
		app.game_clock = float(pair[0])
		app._update_conditions()
		rendered_icon_kinds[str(pair[1])] = true
		_check(app._weather_icon.kind == pair[1], "live weather/time chooses correct bitmap at " + str(pair[0]))
		_check(ArtScript.texture_for(app._weather_icon.kind).resource_path == ArtScript.ICON_ROOT + str(pair[1]) + ".png", "live condition binds actual raster " + str(pair[1]))
	app.game_clock = 0.0
	app._update_conditions()

func _test_catalog_controls() -> void:
	app._show_catalog()
	await _settle_layout()
	var search: LineEdit = _find_type(app._overlay, "LineEdit") as LineEdit
	_check(search != null, "catalog exposes actual editable search")
	if search == null: return
	search.text = "Cyprinus carpio"
	search.text_changed.emit(search.text)
	await _settle_layout()
	_check(app._search == "Cyprinus carpio" and app._list.get_child_count() == 1, "real search callback filters to one scientific-name match")
	var carp: Button = _find_button(app._list, app.catalog.fish["common_carp"].name)
	_check(carp != null, "filtered catalog exposes matching species action")
	if carp != null: carp.pressed.emit()
	await _settle_layout()
	_check(app._screen == "species", "real species action opens detail")
	var zoom: Button = _find_button(app._overlay, "查看大图")
	_check(zoom != null, "discovered species exposes real zoom action")
	if zoom != null: zoom.pressed.emit()
	await _settle_layout()
	_check(app._screen == "zoom", "real zoom action opens specimen")
	var back: Button = _find_button(app._overlay, "返回")
	if back != null: back.pressed.emit()
	await _settle_layout()
	_check(app._screen == "species", "visible zoom Back returns to the correct species")
	app._handle_back()
	await _settle_layout()
	_check(app._screen == "catalog" and app._search == "Cyprinus carpio" and app._list.get_child_count() == 1, "system Back returns to catalog without losing search")
	search = _find_type(app._overlay, "LineEdit") as LineEdit
	search.text = "no_species_matches_this_query"
	search.text_changed.emit(search.text)
	await _settle_layout()
	_check(app._list.get_child_count() == 1 and "暂时没有鱼" in _all_label_text(app._list), "active empty search displays its explanatory hint")
	search.text = ""
	search.text_changed.emit("")
	var choices: Array[Node] = []
	_find_all_type(app._overlay, "OptionButton", choices)
	_check(choices.size() == 2, "catalog has actual region and discovery controls")
	if choices.size() == 2:
		var region: OptionButton = choices[0] as OptionButton
		var discovery: OptionButton = choices[1] as OptionButton
		region.select(2)
		region.item_selected.emit(2)
		await _settle_layout()
		var rid: String = str(app.catalog.regions[1].region_id)
		var expected: int = 0
		for fish: FishDefinition in app.catalog.fish.values():
			if app.catalog.is_fishing_species(fish) and rid in fish.regions(): expected += 1
		_check(app._region_filter == rid and app._list.get_child_count() == expected, "real region selection callback filters the production fish set")
		discovery.select(2)
		discovery.item_selected.emit(2)
		await _settle_layout()
		_check(app._discovery_filter == 2 and "暂时没有鱼" in _all_label_text(app._list), "real undiscovered filter respects the complete discovered fixture")
		discovery.select(1)
		discovery.item_selected.emit(1)
		await _settle_layout()
		_check(app._list.get_child_count() == expected, "real discovered filter restores the exact region count")
	var was_sorted_by_count: bool = app._sort_count
	var sort_button: Button = _find_button(app._overlay, "按数量" if was_sorted_by_count else "按名称")
	_check(sort_button != null, "real sort action exists")
	if sort_button != null: sort_button.pressed.emit()
	await _settle_layout()
	_check(app._sort_count != was_sorted_by_count and app._screen == "catalog", "real sort callback toggles order and rebuilds the catalog")
	await _audit("catalog_active_filters", app._overlay)
	app._region_filter = "all"
	app._discovery_filter = 0
	app._search = ""
	app._sort_count = false
	app._close_page()

func _test_pause_back_settings() -> void:
	app._close_page()
	app.session.reset()
	for repeat: int in range(3):
		app._handle_back()
		await _settle_layout()
		_check(app._screen == "pause" and app.session.state == FishingSession.State.PAUSED, "system Back opens paused overlay from idle")
		app._handle_back()
		await _settle_layout()
		_check(app._overlay == null and app._screen.is_empty() and app.session.state == FishingSession.State.IDLE, "repeated system Back closes pause without stale overlays")
	for active: int in [FishingSession.State.CASTING, FishingSession.State.WAITING, FishingSession.State.NIBBLE, FishingSession.State.BITE, FishingSession.State.FIGHT]:
		app.session.reset()
		app.session.set_seed(2468)
		app.session.start_charge()
		var fish: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"], "lake_shore", "lake", "worm", 2, "day", "clear")
		app.encounter.apply_float_presentation(fish,app.catalog,0.6)
		_check(app.session.cast(fish, app.catalog.gear[2]), "pause fixture starts an actual encounter")
		var reached: bool = _advance_live_phase(active)
		_check(reached,"pause fixture reaches actual lifecycle state: " + str(active))
		if not reached: continue
		if active == FishingSession.State.FIGHT: app._action_down()
		var identity: String = app.session.session_id
		var individual: Dictionary = app.session.individual.duplicate(true)
		app._handle_back()
		await _settle_layout()
		_check(app.session.state == FishingSession.State.PAUSED and app.session.before_pause == active and not app.session.reeling, "pause overlay freezes actual state and releases held input: " + str(active))
		var frozen_clock: float = app.game_clock
		var frozen: Array = [app.session.elapsed,app.session.tension,app.session.progress,app.session.fight_time,app.session.float_clock,app.session.float_encounter.rng.state,app.session.float_encounter.phase,app.session.float_encounter.mouth_depth,app.session.float_encounter.can_hook()]
		for step: int in range(60): app._process(0.5)
		_check(app.game_clock == frozen_clock, "pause prevents world time/weather advancing: " + str(active))
		_check(frozen == [app.session.elapsed,app.session.tension,app.session.progress,app.session.fight_time,app.session.float_clock,app.session.float_encounter.rng.state,app.session.float_encounter.phase,app.session.float_encounter.mouth_depth,app.session.float_encounter.can_hook()], "paused Main updates preserve exact fishing and possession progress: " + str(active))
		var settings: Button = _find_button(app._overlay, "设置")
		_check(settings != null, "pause provides real Settings route")
		if settings != null: settings.pressed.emit()
		await _settle_layout()
		_check(app._screen == "settings" and app.session.state == FishingSession.State.PAUSED, "Settings remains paused: " + str(active))
		var original: bool = bool(app.store.state.settings.sound)
		var toggle: Button = _find_button_prefix(app._overlay, "声音：")
		_check(toggle != null, "real sound setting exists")
		if toggle != null: toggle.pressed.emit()
		await _settle_layout()
		_check(bool(app.store.state.settings.sound) != original and app._screen == "settings", "actual sound toggle persists while preserving Settings")
		var vibration_before: bool = bool(app.store.state.settings.vibration)
		var vibration: Button = _find_button_prefix(app._overlay, "震动：")
		_check(vibration != null, "real vibration setting exists")
		if vibration != null: vibration.pressed.emit()
		await _settle_layout()
		_check(bool(app.store.state.settings.vibration) != vibration_before and app.session.state == FishingSession.State.PAUSED, "actual vibration toggle persists without advancing encounter")
		var volume: HSlider = _find_type(app._overlay, "HSlider") as HSlider
		_check(volume != null, "real volume slider exists")
		if volume != null:
			volume.value = 0.35
			volume.drag_ended.emit(true)
			_check(is_equal_approx(float(app.store.state.settings.volume), 0.35), "real slider completion persists chosen volume")
		var back: Button = _find_button(app._overlay, "返回")
		_check(back != null, "Settings has actual Back control")
		if back != null: back.pressed.emit()
		await _settle_layout()
		_check(app._screen == "pause" and app.session.state == FishingSession.State.PAUSED,"Settings Back retains its pause origin: " + str(active))
		app._handle_back()
		await _settle_layout()
		_check(app._screen.is_empty() and app._overlay == null and app.session.state == active,"pause Back explicitly resumes the original live state: " + str(active))
		_check(app.session.session_id == identity and app.session.individual == individual and not app.session.reeling, "paused navigation preserves exact encounter without latched input: " + str(active))
		if active == FishingSession.State.FIGHT:
			_check(not app._nav_rail.is_visible_in_tree(), "resumed fight again hides nonessential navigation")
	app.session.reset()
	app.sound.apply({"sound": false, "vibration": false, "volume": 0.0})
	app.sound.suspend(true)

func _find_button_prefix(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix): return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button_prefix(child, prefix)
		if found != null: return found
	return null

func _find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name): return node
	for child: Node in node.get_children():
		var found: Node = _find_type(child, type_name)
		if found != null: return found
	return null

func _find_all_type(node: Node, type_name: String, found: Array[Node]) -> void:
	if node.is_class(type_name): found.append(node)
	for child: Node in node.get_children(): _find_all_type(child, type_name, found)

func _all_label_text(node: Node) -> String:
	var combined: String = (node as Label).text if node is Label else ""
	for child: Node in node.get_children(): combined += "\n" + _all_label_text(child)
	return combined

func _check_photo_preview(species: String, label: String) -> void:
	var previews: Array[Node] = []
	for node: Node in app._overlay.find_children("FishArtPreview","TextureRect",true,false):
		if node.get_script() == Preview: previews.append(node)
	_check(previews.size() == 1,label + " has exactly one genuine high-resolution fish illustration")
	if previews.size() != 1: return
	var preview: TextureRect = previews[0]
	_check(preview.species_id == species and preview.has_art_landmarks and preview.texture is AtlasTexture,label + " uses exact species art and reviewed body landmarks")
	_check(preview.mouse_filter == Control.MOUSE_FILTER_IGNORE and preview.material == null and not preview.silhouette,label + " static revealed specimen cannot steal scroll or apply fake motion")
	_check((preview.texture as AtlasTexture).atlas.resource_path == "res://assets/fish/"+species+".png",label + " binds the full-resolution canonical PNG")
	_check(app._overlay.find_children("*","SubViewportContainer",true,false).is_empty(),label + " contains no coarse 3D substitute in the static card")

func _test_retained_3d_scenery() -> void:
	_check(app.scenery is Node3D, "production scenery is a real Node3D world")
	_check(app.scenery.camera is Camera3D and app.scenery.camera.current, "production world has an active perspective camera")
	var meshes: Array[Node] = []
	_find_all_type(app.scenery, "MeshInstance3D", meshes)
	_check(meshes.size() >= 10, "production scenery retains actual environment and actor meshes")
	var retained: Array[Dictionary] = []
	var dynamic: Array[Dictionary] = []
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null:
			_check(not mesh.visible, "only hidden lazy geometry may omit a mesh: " + str(mesh.name))
			continue
		_check(mesh.mesh.get_rid().is_valid(), "3D scenery mesh retains a valid rendering resource: " + str(mesh.name))
		if mesh == app.scenery._rod_mesh or mesh == app.scenery._line:
			# Stage deliberately rebuilds curved tackle geometry at frame_pre_draw
			# after BoneAttachment poses settle. Require a retained live node and
			# valid current resource, not retention of every obsolete curve buffer.
			dynamic.append({"node":weakref(mesh),"id":mesh.get_instance_id(),"name":str(mesh.name)})
		else:
			retained.append({"resource":weakref(mesh.mesh),"name":str(mesh.name)})
	await _settle_layout()
	for entry: Dictionary in retained:
		_check(entry.resource.get_ref() != null, "static active3D mesh survives subsequent frames without a draw-local lifetime: " + str(entry.name))
	for entry: Dictionary in dynamic:
		var current: MeshInstance3D = entry.node.get_ref() as MeshInstance3D
		_check(current != null and current.get_instance_id() == int(entry.id) and current.mesh != null and current.mesh.get_rid().is_valid(),"animated tackle retains its node and valid current geometry across actual draws: " + str(entry.name))
	var selection: Dictionary = app.store.state.selection.duplicate(true)
	for sid: String in app.catalog.spots:
		var spot: Dictionary = app.catalog.spots[sid]
		var previous_root: WeakRef = weakref(app.scenery._environment_root)
		_check(app.scenery.set_location(str(spot.region_id),sid),sid + ": actual regional scene and station load")
		_check(app.scenery.region_id == str(spot.region_id) and app.scenery.spot_id == sid,sid + ": stage reports the actual selected region and spot")
		_check(app.store.state.selection == selection, sid + ": presentation-only travel cannot overwrite saved selection")
		await _settle_layout()
		var active_biomes: int = 0
		var active_stations: int = 0
		for child: Node in app.scenery.get_children():
			if str(child.name).begins_with("ActiveBiome_"): active_biomes += 1
			if str(child.name).begins_with("ActiveStation_"): active_stations += 1
		_check(active_biomes == 1 and active_stations == 1,sid + ": only one active biome and station remain in the live tree")
		var previous: Node = previous_root.get_ref()
		_check(previous == null or previous == app.scenery._environment_root or not previous.is_inside_tree(),sid + ": replaced scene is released instead of retained invisibly")
	_check(_find_type(app.scenery, "Sprite3D") == null and _find_type(app.scenery, "AnimatedSprite3D") == null, "3D environment and actors are not billboard sprite substitutes")
	_check(app._refresh_location(),"Main restores its actual saved scene after presentation-only resource checks")
