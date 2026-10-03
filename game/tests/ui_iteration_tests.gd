extends SceneTree
## Beta3 production Main journeys; isolated fixtures, actual viewport input.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Failure = preload("res://scripts/fishing_failure_modal.gd")
const Photo = preload("res://scripts/fish_art_view.gd")
# Literal schema-2 beta2-shaped save, independent of current default_state().
const BETA2_JSON: String = '{"schema_version":2,"save_revision":17,"currency":321,"gear":0,"owned_gear":[0],"unlocked_regions":["lake"],"species_stats":{"common_carp":{"catch_count":7,"first":{"catch_id":"beta2_first","session_id":"beta2_session","species_id":"common_carp","length_mm":400,"weight_g":1100,"region_id":"lake","spot_id":"lake_shore","caught_at":"2026-10-02T08:00:00Z","game_time":10,"weather":"clear","equipment":{"gear":0,"name":"旅行手竿"},"bait_id":"worm","disposition":"pending","reward":25,"sale_value":20},"last":{"catch_id":"beta2_last","session_id":"beta2_session_last","species_id":"common_carp","length_mm":430,"weight_g":1200,"region_id":"lake","spot_id":"lake_shore","caught_at":"2026-10-02T08:10:00Z","game_time":20,"weather":"clear","equipment":{"gear":0,"name":"旅行手竿"},"bait_id":"worm","disposition":"pending","reward":25,"sale_value":20},"max_length":{"catch_id":"beta2_longest","session_id":"beta2_session_longest","species_id":"common_carp","length_mm":600,"weight_g":1500,"region_id":"lake","spot_id":"lake_shore","caught_at":"2026-10-02T08:04:00Z","game_time":14,"weather":"clear","equipment":{"gear":0,"name":"旅行手竿"},"bait_id":"worm","disposition":"pending","reward":25,"sale_value":20},"max_weight":{"catch_id":"beta2_heaviest","session_id":"beta2_session_heaviest","species_id":"common_carp","length_mm":500,"weight_g":2000,"region_id":"lake","spot_id":"lake_shore","caught_at":"2026-10-02T08:06:00Z","game_time":16,"weather":"clear","equipment":{"gear":0,"name":"旅行手竿"},"bait_id":"worm","disposition":"pending","reward":25,"sale_value":20},"regions":{"lake":7}}},"favorites":["common_carp"],"pending_catches":{},"recent_ids":["beta2_first","beta2_last","beta2_longest","beta2_heaviest"],"settings":{"sound":false,"vibration":false,"volume":0.6},"selection":{"region_id":"lake","spot_id":"lake_shore","bait_id":"worm"},"game_clock":20}'
var app: Control
var checks: int = 0
var failures: int = 0
var fixture_path: String
var journeys: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var data: String = OS.get_environment("XDG_DATA_HOME")
	if not data.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(data+"/"):
		printerr("UI_ITERATION: refusing non-isolated HOME/XDG_DATA_HOME")
		quit(2)
		return
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
	app = Main.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	_check(app._content_ok and app._models_complete and app.fish_art.complete,"actual Main all44 model/art readiness, no bypass")
	if not app._content_ok or not app._models_complete: quit(1); return
	fixture_path = data.path_join("beta3-ui-iteration-"+str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(fixture_path)
	var file: FileAccess = FileAccess.open(fixture_path.path_join("save.json"),FileAccess.WRITE)
	file.store_string(BETA2_JSON)
	file.close()
	file = null
	var fixture: SaveStore = Store.new()
	_check(fixture.initialize(fixture_path),"literal beta2 schema-2 save remains readable")
	app.store = fixture
	app.encounter.rng.seed = 20261003
	app.session._rng.seed = 2468
	await _test_literal_beta2_read()
	await _test_failures()
	await _test_notebook_routes()
	await _test_pending_result()
	await _test_pause_settings()
	await _test_home_readability()
	await _test_lobby_exit_cancel()
	var reloaded: SaveStore = Store.new()
	_check(reloaded.initialize(fixture_path),"fixture still reloads after production UI journeys")
	var disk_records: Variant = JSON.parse_string(JSON.stringify(reloaded.state.species_stats,"",true,true))
	var memory_records: Variant = JSON.parse_string(JSON.stringify(fixture.state.species_stats,"",true,true))
	_check(reloaded.total_count() == fixture.total_count() and disk_records == memory_records,"UI journeys preserve persisted catch counts and full records")
	app.fish_art._textures.clear()
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	app = null
	for frame: int in range(4): await process_frame
	print("UI_ITERATION_JOURNEYS: ",", ".join(journeys))
	print("UI_ITERATION_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; physical=",root.size," logical=",root.get_visible_rect().size,"; production Main + viewport touch; not Android hardware")
	call_deferred("quit",0 if failures == 0 else 1)

func _test_literal_beta2_read() -> void:
	var before: Dictionary = app.store.state
	_check(app.store.total_count() == 7 and int(before.currency) == 321,"beta2 fixture retains historical count and currency")
	_check(before.species_stats.common_carp.max_length.catch_id == "beta2_longest" and before.species_stats.common_carp.max_weight.catch_id == "beta2_heaviest","independent historical length/weight snapshots remain distinct")
	app._show_species("common_carp")
	await _layout()
	_check(_has_text(app._page,"60.0 cm") and _has_text(app._page,"2.00 kg") and _has_text(app._page,"7 条"),"new detail renders literal beta2 records accurately")
	app._show_catalog()
	await _layout()
	app._show_favorites()
	await _layout()
	_check(app.store.state == before and FileAccess.get_file_as_string(fixture_path.path_join("save.json")) == BETA2_JSON,"reading beta2 details/catalog/favorites does not rewrite the save")
	journeys.append("literal-beta2-read")

func _test_failures() -> void:
	app._enter_fishery()
	await _layout()
	var counts: int = app.store.total_count()
	var currency: int = int(app.store.state.currency)
	var selection: Dictionary = app.store.state.selection
	_start_cast()
	_tick(2.25)
	_check(app.session.state == Session.State.WAITING,"ordinary generated cast reaches actual observation phase")
	var sid: String = app.session.session_id
	var record: Dictionary = app.session.individual.duplicate(true)
	app._action_down()
	app._action_up()
	await _layout()
	_check_failure("空竿收回")
	var overlay_id: int = app._overlay.get_instance_id()
	app.session.ended.emit(false,record)
	app._fishing_ended(false,record)
	_check(app._overlay.get_instance_id() == overlay_id,"duplicate terminal notifications retain one modal instance")
	_check(app.session.state == Session.State.PAUSED and app.session.before_pause == Session.State.ESCAPED and app.session.session_id == sid,"terminal session is paused without replacing its identity")
	var dismiss: Vector2 = app._overlay.get_test_handles().dismiss.get_global_rect().get_center()
	_touch(dismiss,true,0)
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_touch(dismiss,false,0)
	await _drain()
	_check(app._screen == "escape" and app._overlay.get_instance_id() == overlay_id,"focus loss cancels held dismissal and preserves result")
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _drain()
	_check(app._screen == "escape" and app.session.state == Session.State.PAUSED,"resume does not auto-dismiss or start another cast")
	_touch(dismiss,true,0)
	_touch(Vector2(40,80),true,1)
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_touch(dismiss,false,0)
	await _drain()
	_check(app._screen == "escape","hardware Back waits for other held fingers")
	_touch(Vector2(40,80),false,1)
	_mouse_emulation(dismiss,true)
	_mouse_emulation(dismiss,false)
	await _drain()
	_check_idle("hardware Back")
	_check(app.store.total_count() == counts and int(app.store.state.currency) == currency and app.store.state.selection == selection,"empty cast/dismiss preserves catch count, currency, bait and location")
	# These two fixtures exercise real terminal routing, not the physical hazard thresholds.
	for reason: String in ["松手太久，鱼带着松线挣脱了","迎着冲势猛拉，鱼线绷断了。留意鱼身转向和竿梢蓄力"]:
		_start_cast()
		app.session._finish(false,reason)
		await _layout()
		_check_failure("鱼线断了" if "断" in reason else "鱼已逃脱")
		var retry: Vector2 = app._overlay.get_test_handles().retry.get_global_rect().get_center()
		_touch(retry,true,1)
		_touch(retry,false,1)
		await process_frame
		_mouse_emulation(retry,true)
		_mouse_emulation(retry,false)
		await _drain()
		_check_idle("retry")
	_check(app.store.total_count() == counts and int(app.store.state.currency) == currency and app.store.state.pending_catches.is_empty(),"all three non-catch routes award nothing and create no pending result")
	journeys.append("real-empty/slack/break + Back/focus/retry")

func _check_failure(title: String) -> void:
	_check(app._screen == "escape" and app._overlay is FishingFailureModal,"failed session opens compact native modal")
	if not app._overlay is FishingFailureModal: return
	_check(app._overlay.get_test_handles().title.text == title,"terminal cause is presented truthfully: "+title)
	_check(app._overlay.get_panel_rect().size.y < 480 and app._overlay.get_panel_rect().size.x <= 596,"terminal panel stays content-sized")
	_check(app.scenery.visible and app.scenery.camera != null and not app._safe.visible,"terminal keeps 3D scene and hides inactive fishing HUD")

func _check_idle(label: String) -> void:
	_check(app._screen.is_empty() and app._overlay == null and app.session.state == Session.State.IDLE and app.session.individual.is_empty(),label+" returns to IDLE without auto-cast")
	_check(app._safe.visible and not app.scenery._suspended and not app.session.reeling,label+" restores ready HUD/scenery without held reel")

func _start_cast() -> void:
	app._action_down()
	_check(app.session.state == Session.State.CHARGING,"fresh press starts the next charge")
	_tick(0.45)
	app._action_up()
	_check(app.session.state == Session.State.CASTING and not app.session.session_id.is_empty(),"fresh release creates a real encounter/cast")

func _test_notebook_routes() -> void:
	app._search = "a"
	# The search/sort filter spans regions so the list genuinely overflows even
	# at 720x1584; the lake-only result fits a tall screen without scrolling.
	app._region_filter = "all"
	app._discovery_filter = 0
	app._sort_count = true
	app._show_catalog()
	await _layout()
	var tile: Button = app._overlay.find_child("FishTile_common_carp",true,false) as Button
	_check(tile != null,"filtered catalog includes the fixture's carp tile")
	if tile == null: return
	var image: Control = _first_photo(tile)
	var catalog_scroll: ScrollContainer = app._overlay.find_child("PageScroll",true,false) as ScrollContainer
	catalog_scroll.scroll_vertical = 180
	await _layout()
	await _reveal(image)
	var old_scroll: int = app._current_scroll()
	_check(old_scroll > 0,"catalog return fixture starts from a genuinely scrolled list")
	await _tap(image)
	_check(app._screen == "species" and app._active_species_id == "common_carp" and app._notebook_origin == "catalog","actual image touch opens species with catalog origin")
	await _tap(app._overlay.find_child("NotebookZoom",true,false))
	_check(app._screen == "zoom","detail's actual zoom action opens full image")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _layout()
	_check(app._screen == "species" and app._active_species_id == "common_carp","first Back returns zoom to same species")
	await _tap(_button(app._overlay,"返回"))
	_check(app._screen == "catalog" and app._search == "a" and app._region_filter == "all" and app._discovery_filter == 0 and app._sort_count,"second Back restores all catalog filters/order")
	_check(abs(app._current_scroll()-old_scroll) <= 1,"catalog scroll is restored after detail/zoom")
	app._show_favorites()
	await _layout()
	tile = app._overlay.find_child("FishTile_common_carp",true,false) as Button
	await _tap(_first_photo(tile))
	_check(app._screen == "species" and app._notebook_origin == "favorites","favorite image records favorites origin")
	await _tap(app._overlay.find_child("NotebookZoom",true,false))
	app._handle_back()
	await _layout()
	app._handle_back()
	await _layout()
	_check(app._screen == "favorites","two Back actions return favorite zoom to favorites")
	journeys.append("catalog-filter/image/zoom/Back + favorites-origin")

func _test_pending_result() -> void:
	app._close_page()
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","worm",0,"day","clear")
	# Bracket insertion keeps JSON keys as String, not new StringName keys.
	record["session_id"] = "iteration_pending_session"
	record["catch_id"] = "iteration_pending_catch"
	app.store.begin_session(record.session_id)
	var settled: Dictionary = app.store.settle_catch(record)
	_check(bool(settled.get("ok",false)),"pending-result fixture uses actual SaveStore transaction: "+str(settled))
	if not bool(settled.get("ok",false)): return
	app._last_record = record
	app._last_settlement = settled
	app._save_ok = true
	app._landing_pending = false
	app._show_result()
	await _layout()
	var before: Dictionary = app.store.state
	await _tap(_button(app._overlay,"查看鱼种资料与纪录"))
	_check(app._screen == "species" and app._notebook_origin == "result","pending result detail retains result origin")
	app._handle_back()
	await _layout()
	_check(app._screen == "result" and app.store.state == before and app.store.state.pending_catches.has(record.catch_id),"Back returns to unresolved result without a duplicate save/reward")
	await _tap(_button(app._overlay,"放生  +8"))
	_check(app._overlay == null and app.session.state == Session.State.IDLE and app.store.state.pending_catches.is_empty(),"actual disposition resolves pending result and returns ready")
	var balance: int = int(app.store.state.currency)
	_check(balance == int(before.currency)+8 and app.store.total_count() == 8,"one release gives exactly eight coins and preserves catch record")
	app._dispose_result("released")
	_check(int(app.store.state.currency) == balance and app.store.total_count() == 8,"stale result disposition cannot reward twice")
	journeys.append("pending-result/details/Back/release-once")

func _test_pause_settings() -> void:
	_start_cast()
	_tick(2.25)
	var sid: String = app.session.session_id
	var individual: Dictionary = app.session.individual.duplicate(true)
	var elapsed: float = app.session.elapsed
	app._show_pause()
	await _layout()
	await _tap(_button(app._overlay,"设置"))
	_check(app._screen == "settings" and app._settings_back.is_valid(),"pause enters settings with an explicit return route")
	var prior: bool = bool(app.store.state.settings.vibration)
	await _tap(_button_prefix(app._overlay,"震动："))
	_check(bool(app.store.state.settings.vibration) != prior and app._screen == "settings","actual toggle saves and rebuilds settings")
	await _tap(_button(app._overlay,"关于游戏与开源许可"))
	_check(app._screen == "about","settings opens About")
	app._handle_back()
	await _layout()
	_check(app._screen == "settings","About Back returns settings")
	app._handle_back()
	await _layout()
	_check(app._screen == "pause" and app.session.state == Session.State.PAUSED,"settings Back after a toggle returns pause")
	app._handle_back()
	await _layout()
	_check(app._overlay == null and app.session.state == Session.State.WAITING and app.session.session_id == sid and app.session.individual == individual and is_equal_approx(app.session.elapsed,elapsed),"pause Back resumes the same untouched actual session")
	app._abandon_round()
	journeys.append("pause/settings-toggle/About/Back/same-session")

func _test_home_readability() -> void:
	app._show_home()
	await _layout()
	# Parent sets stable names when the narrow-header correction is integrated.
	var progress: Control = app._overlay.find_child("LobbyProgress",true,false) as Control
	if progress == null:
		_check(false,"integrated lobby exposes stable LobbyProgress")
		return
	for label: Node in progress.find_children("*","Label",true,false):
		_check(label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x >= label.get_minimum_size().x,"home progress stays single-line at full required width")
	_check(progress.get_global_rect().end.x <= app.size.x-24,"home progress fits safe right edge")
	journeys.append("home-progress-width")

func _test_lobby_exit_cancel() -> void:
	var before: Dictionary = app.store.state
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _layout()
	_check(app._screen == "lobby_exit" and app._overlay is FishingFailureModal,"lobby Back opens the same compact confirmation framework")
	if not app._overlay is FishingFailureModal: return
	var handles: Dictionary = app._overlay.get_test_handles()
	_check(handles.title.text == "退出游戏" and handles.retry.text == "退出游戏" and handles.dismiss.text == "继续游戏","generic confirmation has exit/continue copy")
	_check(not handles.note.visible and not _has_visible_text(app._overlay,"这一竿") and not _has_visible_text(app._overlay,"鱼饵"),"generic exit does not leak fishing failure copy")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _drain()
	_check(app._screen == "home" and app._mode == "lobby" and not app._action.is_visible_in_tree(),"hardware Back cancels exit into lobby without exposing cast")
	app._show_lobby_exit()
	await _layout()
	await _tap(app._overlay.get_test_handles().dismiss)
	await _drain()
	_check(app._screen == "home" and app.store.state == before,"actual Continue action cancels exit without save/reward mutation")
	journeys.append("lobby-exit/Back/continue-only")

func _tick(seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.00001:
		var delta: float = minf(remaining,0.025)
		if not app.scenery._suspended:
			app.scenery._animator.advance(delta)
			if app.scenery._fish_animator:
				app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				app.scenery._fish_animator.advance(delta)
		app.scenery._process(delta)
		app._process(delta)
		remaining -= delta

func _layout() -> void:
	for frame: int in range(5): await process_frame

func _drain() -> void:
	await create_timer(0.21).timeout
	await _layout()

func _reveal(control: Control) -> void:
	if control == null: return
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			break
		parent = parent.get_parent()
	await _layout()

func _tap(control: Control) -> void:
	_check(control != null,"requested production action exists")
	if control == null: return
	await _reveal(control)
	var point: Vector2 = control.get_global_rect().get_center()
	_touch(point,true,0)
	_touch(point,false,0)
	_mouse_emulation(point,true)
	_mouse_emulation(point,false)
	await _layout()

func _touch(point: Vector2, pressed: bool, index: int) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.index = index
	event.pressed = pressed
	root.push_input(event,true)

func _mouse_emulation(point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	root.push_input(event,true)

func _button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption: return node
	for child: Node in node.get_children():
		var found: Button = _button(child,caption)
		if found != null: return found
	return null

func _button_prefix(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix): return node
	for child: Node in node.get_children():
		var found: Button = _button_prefix(child,prefix)
		if found != null: return found
	return null

func _first_photo(node: Node) -> Control:
	if node == null: return null
	if node.get_script() == Photo: return node
	for child: Node in node.get_children():
		var found: Control = _first_photo(child)
		if found != null: return found
	return null

func _has_text(node: Node, value: String) -> bool:
	if node is Label and value in node.text: return true
	for child: Node in node.get_children():
		if _has_text(child,value): return true
	return false

func _has_visible_text(node: Node, value: String) -> bool:
	if node is Label and node.is_visible_in_tree() and value in node.text: return true
	for child: Node in node.get_children():
		if _has_visible_text(child,value): return true
	return false

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL UI_ITERATION: ",label)
