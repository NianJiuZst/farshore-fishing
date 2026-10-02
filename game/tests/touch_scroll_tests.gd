extends SceneTree
const TouchScrollScript = preload("res://scripts/touch_scroll.gd")
var failures: int = 0
var checks: int = 0
var taps: int = 0
var production_completed: bool = false
var scroll: ScrollContainer
var first: Button
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(720,1280)
	var host: Control = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	scroll = TouchScrollScript.new()
	scroll.position = Vector2(30,120)
	scroll.size = Vector2(660,1000)
	host.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	for index: int in range(30):
		var panel: PanelContainer = PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		column.add_child(panel)
		var button: Button = Button.new()
		button.text = "Row " + str(index)
		button.custom_minimum_size.y = 120
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(func() -> void: taps += 1)
		panel.add_child(button)
		if index == 0: first = button
	for frame: int in range(4): await process_frame
	_check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "nested button list genuinely overflows")
	var start: Vector2 = first.get_global_rect().get_center()
	_touch(start,true)
	_touch(start + Vector2(2,3),false)
	await process_frame
	_check(taps == 1, "ScreenTouch through Viewport activates normal button tap exactly once")
	for down: bool in [true,false]:
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.device = InputEvent.DEVICE_ID_EMULATION
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		mouse.position = start
		root.push_input(mouse,true)
	await process_frame
	_check(taps == 1,"touch-generated emulated mouse cannot cause a second click")
	_touch(start,true)
	_drag(start + Vector2(90,0),Vector2(90,0))
	_touch(start + Vector2(90,0),false)
	await process_frame
	_check(taps == 1,"horizontal swipe also cancels a button tap")
	_touch(start,true)
	_drag(start + Vector2(0,-5),Vector2(0,-5))
	_check(scroll.scroll_vertical == 0, "below-threshold motion keeps list still")
	for step: int in range(1,8):
		_drag(start + Vector2(0,-step*42),Vector2(0,-42))
		await process_frame
	_touch(start + Vector2(0,-294),false)
	var after_drag: int = scroll.scroll_vertical
	_check(after_drag > 200, "real vertical ScreenDrag scrolls over nested STOP button/panel")
	_check(taps == 1, "drag over button suppresses click")
	_check(scroll.completed_drags == 1 and scroll.cancelled_taps == 1, "gesture completion and cancelled tap recorded")
	for frame: int in range(8): await process_frame
	_check(scroll.scroll_vertical > after_drag, "touch release continues with inertia")
	scroll.stop_gesture()
	var frozen: int = scroll.scroll_vertical
	for frame: int in range(3): await process_frame
	_check(scroll.scroll_vertical == frozen, "page/background cancellation stops inertia")
	var middle: Vector2 = scroll.get_global_rect().get_center()
	_touch(middle,true)
	_drag(middle + Vector2(0,200),Vector2(0,200))
	_touch(middle + Vector2(0,200),false)
	_check(scroll.scroll_vertical < frozen, "reverse touch drag returns toward earlier content")
	scroll.stop_gesture()
	scroll.scroll_vertical = 0
	await process_frame
	_touch(start,true)
	var cancel: InputEventScreenTouch = InputEventScreenTouch.new()
	cancel.position = start
	cancel.index = 0
	cancel.pressed = false
	cancel.canceled = true
	root.push_input(cancel,true)
	await process_frame
	_check(taps == 1, "Android cancellation does not activate button")
	if "--production" in OS.get_cmdline_user_args():
		root.remove_child(host)
		host.queue_free()
		await process_frame
		await _test_main_pages()
		_check(production_completed,"production integration suite reached completion without a script abort")
	print("TOUCH_SCROLL_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; actual Viewport ScreenTouch/ScreenDrag")
	quit(0 if failures == 0 else 1)
func _touch(position: Vector2, down: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = down
	root.push_input(event,true)
func _drag(position: Vector2, relative: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = relative
	root.push_input(event,true)
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL TOUCH: ",label)

func _layout_frames() -> void:
	for frame: int in range(5): await process_frame

func _find_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name): return node
	for child: Node in node.get_children():
		var found: Node = _find_type(child,type_name)
		if found != null: return found
	return null

func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child: Node in node.get_children():
		var found: Button = _find_button(child,text)
		if found != null: return found
	return null

func _test_main_pages() -> void:
	if not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"):
		_check(false,"production touch tests require isolated /tmp/farshore- XDG_DATA_HOME")
		return
	var scene: PackedScene = load("res://scenes/main.tscn")
	var app: Control = scene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.sound.suspend(true)
	await _layout_frames()
	_check(app._screen == "home" and app._mode == "lobby", "production default screen is lobby")
	_check(not app._action.is_visible_in_tree(), "lobby has no visible cast button")
	_check(app.scenery is Node3D and app.scenery.camera is Camera3D, "production background is actual Node3D and Camera3D")
	for label: String in ["开始钓鱼","行囊","图鉴","设置"]:
		_check(_find_button(app._overlay,label) != null,"lobby exposes " + label)
	var old_selection: Dictionary = app.store.state.selection.duplicate(true)
	app._show_prepare()
	app._set_trial_target("alligator_gar")
	await _layout_frames()
	_check(app._trial_target == "alligator_gar" and app.store.state.selection == old_selection,"trial target is explicit and never overwrites legacy selection")
	for method: String in ["_show_gear","_show_catalog","_show_settings","_show_licenses"]:
		app.call(method)
		await _layout_frames()
		var page_scroll: ScrollContainer = _find_type(app._overlay,"ScrollContainer") as ScrollContainer
		_check(page_scroll != null and page_scroll.get_script() == TouchScrollScript,method + " uses production touch gesture owner")
		if page_scroll == null: continue
		var range_max: float = page_scroll.get_v_scroll_bar().max_value-page_scroll.get_v_scroll_bar().page
		if range_max <= 0:
			_check(false,method + " fixture overflows for real drag test")
			continue
		var start: Vector2 = page_scroll.get_global_rect().get_center() + Vector2(0,200)
		_touch(start,true)
		for step: int in range(1,8):
			_drag(start+Vector2(0,-step*45),Vector2(0,-45))
			await process_frame
		_touch(start+Vector2(0,-315),false)
		print("PRODUCTION_TOUCH ",method," offset=",page_scroll.scroll_vertical," maximum=",range_max)
		_check(page_scroll.scroll_vertical >= mini(100,roundi(range_max)),method + " scrolls from actual ScreenDrag over live page children")
		page_scroll.stop_gesture()
	app._show_gear()
	await _layout_frames()
	var bag: ScrollContainer = _find_type(app._overlay,"ScrollContainer") as ScrollContainer
	var bait: Button = _find_button(app._overlay,"谷物")
	if bait == null: bait = _find_button(app._overlay,"已选 · 谷物")
	_check(bait != null,"production bait button exists")
	if bait != null:
		bag.ensure_control_visible(bait)
		await _layout_frames()
		var before: String = app.bait_id
		var origin: Vector2 = bait.get_global_rect().get_center()
		_touch(origin,true)
		_drag(origin+Vector2(0,80),Vector2(0,80))
		_touch(origin+Vector2(0,80),false)
		await _layout_frames()
		_check(app.bait_id == before and app._screen == "gear","touch drag over real bait cannot select or rebuild page")
		bag.stop_gesture()
		bag.ensure_control_visible(bait)
		await _layout_frames()
		origin = bait.get_global_rect().get_center()
		_touch(origin,true)
		_touch(origin,false)
		await _layout_frames()
		_check(app.bait_id == "grain" and app.store.state.selection.bait_id == "grain","real bait ScreenTouch tap updates persisted choice exactly once")
	app._close_page()
	await _layout_frames()
	_check(app._screen == "prepare","bag Back returns to prepare context")
	app._enter_fishery()
	await _layout_frames()
	_check(app._overlay == null and app._action.is_visible_in_tree() and app._mode == "fishing","enter location reveals casting HUD")
	app._action_down()
	app.session.charge = 0.65
	app._action_up()
	_check(app.session.state == FishingSession.State.CASTING and app.scenery.cast_in_progress,"real cast starts stage presentation")
	var elapsed: float = app.session.elapsed
	for iteration: int in range(20): app._process(0.05)
	_check(app.session.elapsed == elapsed,"Session clock cannot overtake 3D cast presentation")
	app.session.set_state(FishingSession.State.FIGHT)
	app.scenery.cast_in_progress = false
	app.session._finish(true,"")
	var catch_id: String = str(app._last_record.get("catch_id",""))
	var count: int = app.store.total_count()
	_check(app._save_ok and app.store.state.pending_catches.has(catch_id),"successful catch is durably pending before landing presentation")
	_check(app._landing_pending and app._overlay == null,"result overlay waits for landing presentation")
	app._show_pause()
	_check(app._screen == "pause" and app._landing_pending,"Back pauses landing without bypassing result gate")
	app._close_page()
	_check(app._overlay == null and app._landing_pending,"resume preserves pending landing")
	app._landing_presentation_finished(app._last_record.duplicate(true))
	await _layout_frames()
	_check(app._screen == "result" and not app._landing_pending,"matching landing signal reveals result")
	app._fishing_ended(true,app._last_record.duplicate(true))
	_check(app._screen == "result" and not app._landing_pending,"duplicate terminal completion cannot re-arm a completed landing")
	app._settle()
	_check(app.store.total_count() == count,"retry result settlement never duplicates catch")
	app._dispose_result("released")
	_check(not app.store.state.pending_catches.has(catch_id) and app._last_record.is_empty(),"disposition resolves pending reward once and resets round")
	_check(app.store.state.selection.region_id == old_selection.region_id and app.store.state.selection.spot_id == old_selection.spot_id,"3D flow never rewrites legacy region or spot selection")
	app.queue_free()
	await process_frame
	production_completed = true
