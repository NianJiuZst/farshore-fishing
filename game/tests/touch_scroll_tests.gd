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
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
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
	_emulated_button(start,true)
	_drag(start + Vector2(0,-5),Vector2(0,-5))
	_check(scroll.scroll_vertical == 0, "below-threshold motion keeps list still")
	for step: int in range(1,8):
		_drag(start + Vector2(0,-step*42),Vector2(0,-42))
		_emulated_motion(start + Vector2(0,-step*42),Vector2(0,-42))
		await process_frame
	_touch(start + Vector2(0,-294),false)
	_emulated_button(start + Vector2(0,-294),false)
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
	if "--preview-only" in OS.get_cmdline_user_args():
		root.remove_child(host)
		host.queue_free()
		await process_frame
		await _test_preview_factory()
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
	print("LAYOUT_SCOPE: physical=",root.size," logical=",root.get_visible_rect().size," aspect=",ProjectSettings.get_setting("display/window/stretch/aspect","keep"),"; representative desktop layout only")
	_check(app._screen == "home" and app._mode == "lobby", "production default screen is lobby")
	_check(not app._action.is_visible_in_tree(), "lobby has no visible cast button")
	_check(app.scenery is Node3D and app.scenery.camera is Camera3D, "production background is actual Node3D and Camera3D")
	for label: String in ["开始钓鱼","行囊","图鉴","设置"]:
		_check(_find_button(app._overlay,label) != null,"lobby exposes " + label)
	app._handle_back()
	_check(app._screen == "lobby_exit","lobby system Back opens explicit exit choice")
	app._handle_back()
	await create_timer(0.22).timeout
	await _layout_frames()
	_check(app._screen == "home" and not app._action.is_visible_in_tree(),"canceling lobby exit drains duplicate input before returning to lobby without entering fishing")
	var old_selection: Dictionary = app.store.state.selection.duplicate(true)
	await _test_native_controls(app)
	app._show_prepare()
	await _layout_frames()
	_check(app.region_id == str(old_selection.region_id) and app.spot_id == str(old_selection.spot_id) and app.store.state.selection == old_selection,"preparation preserves the actual saved region/spot/loadout")
	for method: String in ["_show_gear","_show_travel","_show_catalog","_show_settings","_show_licenses"]:
		app.call(method)
		await _layout_frames()
		var page_scroll: ScrollContainer = _find_type(app._overlay,"ScrollContainer") as ScrollContainer
		_check(page_scroll != null and page_scroll.get_script() == TouchScrollScript,method + " uses production touch gesture owner")
		if page_scroll == null: continue
		var range_max: float = page_scroll.get_v_scroll_bar().max_value-page_scroll.get_v_scroll_bar().page
		if range_max <= 0:
			# A genuinely taller logical viewport may fit Settings in full. Keep
			# the baseline overflow requirement, but validate visible reachability
			# rather than inventing scrolling when a tall page has no overflow.
			_check(method == "_show_settings" or ("--tall" in OS.get_cmdline_user_args() and root.get_visible_rect().size.y>1280),method + " compact settings or tall content genuinely fits without invented scrolling")
			var final_button: Button = _last_button(app._page)
			_check(final_button!=null and page_scroll.get_global_rect().encloses(final_button.get_global_rect()),method + " nonoverflowing tall page exposes its final real action")
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
		var before_screen: String = app._screen
		var before_bait: String = app.bait_id
		await _drag_to_bottom(page_scroll)
		_check(page_scroll.scroll_vertical >= roundi(range_max)-2,method + " repeated real touch drags reach the actual bottom")
		_check(app._screen == before_screen and app.bait_id == before_bait,method + " bottom-reaching drags do not activate child controls")
		var last_button: Button = _last_button(app._page)
		if last_button != null:
			_check(page_scroll.get_global_rect().intersects(last_button.get_global_rect()) and last_button.get_global_rect().end.y <= page_scroll.get_global_rect().end.y+2,method + " final actual button is visible at bottom")
		var bottom_before: int = page_scroll.scroll_vertical
		var reverse_start: Vector2 = page_scroll.get_global_rect().get_center()
		_touch(reverse_start,true)
		_drag(reverse_start+Vector2(0,120),Vector2(0,120))
		_touch(reverse_start+Vector2(0,120),false)
		_check(page_scroll.scroll_vertical < bottom_before,method + " reverse touch swipe moves back from bottom")
		page_scroll.stop_gesture()
	app._set_bait("worm")
	app._show_gear()
	await _layout_frames()
	var bag: ScrollContainer = _find_type(app._overlay,"ScrollContainer") as ScrollContainer
	var bait: Button = _find_button(app._overlay,"旋转亮片")
	if bait == null: bait = _find_button(app._overlay,"已选 · 旋转亮片")
	_check(bait != null,"production bait button exists")
	if bait != null:
		await _drag_to_bottom(bag)
		await _layout_frames()
		var before: String = app.bait_id
		var origin: Vector2 = bait.get_global_rect().get_center()
		_touch(origin,true)
		_drag(origin+Vector2(0,80),Vector2(0,80))
		_touch(origin+Vector2(0,80),false)
		await _layout_frames()
		_check(app.bait_id == before and app._screen == "gear","touch drag over real bait cannot select or rebuild page")
		bag.stop_gesture()
		await _drag_to_bottom(bag)
		await _layout_frames()
		origin = bait.get_global_rect().get_center()
		var revision_before: int = int(app.store.state.save_revision)
		_touch(origin,true)
		_touch(origin,false)
		await _layout_frames()
		_check(app.bait_id == "spinner" and app.store.state.selection.bait_id == "spinner" and int(app.store.state.save_revision) == revision_before+1,"real bait ScreenTouch tap updates persisted choice exactly once")
	await _test_expanded_tackle_controls(app)
	await _test_production_preview_page(app)
	app._show_prepare()
	app._show_gear()
	app._close_page()
	await _layout_frames()
	_check(app._screen == "prepare","bag Back returns to prepare context")
	if not app._models_complete:
		_check(not app._content_ok and not app._model_errors.is_empty(),"incomplete44 registry blocks gameplay without substitution")
		var entry: Button = _find_button(app._overlay,"进入钓点")
		_check(entry!=null and entry.disabled,"partial-development preparation explicitly disables entry")
		app._enter_fishery()
		_check(app._mode=="lobby" and app._overlay!=null,"direct entry callback cannot bypass strict44 gate")
		if "--require-full" in OS.get_cmdline_user_args(): _check(false,"release run requires all44 real models; gameplay assertions not run")
		print("TOUCH_SCOPE: partial development; full gameplay assertions deferred, no readiness override")
		app.queue_free()
		await process_frame
		production_completed=true
		return
	print("TOUCH_SCOPE: complete44 registry; full gameplay assertions enabled")
	app._enter_fishery()
	await _layout_frames()
	_check(app._overlay == null and app._action.is_visible_in_tree() and app._mode == "fishing","enter location reveals casting HUD")
	app._action_down()
	app.session.charge = 0.65
	app._action_up()
	_check(app.session.state == FishingSession.State.CASTING and app.scenery.cast_in_progress,"real cast starts stage presentation")
	_check(str(app.session.individual.region_id)==app.region_id and str(app.session.individual.spot_id)==app.spot_id,"real Encounter records the selected historical region and spot")
	var encounter_species: FishDefinition = app.catalog.fish[str(app.session.individual.species_id)]
	_check(app.spot_id in encounter_species.spots(),"real Encounter honors full-catalog species location eligibility")
	var elapsed: float = app.session.elapsed
	for iteration: int in range(20): app._process(0.05)
	_check(app.session.elapsed == elapsed,"Session clock cannot overtake 3D cast presentation")
	app.session.set_state(FishingSession.State.FIGHT)
	app.scenery.cast_in_progress = false
	app.session._finish(true,"")
	var catch_id: String = str(app._last_record.get("catch_id",""))
	var count: int = app.store.total_count()
	_check(app._save_ok and app.store.state.pending_catches.has(catch_id),"successful catch is durably pending before landing presentation")
	_check(app._landing_pending and app._overlay == null and app._action.text == "起鱼中" and app._action.disabled,"result waits for landing with an accurate disabled landing caption")
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

func _drag_to_bottom(page_scroll: ScrollContainer) -> void:
	var maximum: int = roundi(page_scroll.get_v_scroll_bar().max_value-page_scroll.get_v_scroll_bar().page)
	var extent: Rect2 = page_scroll.get_global_rect()
	var distance: float = maxf(80.0,extent.size.y-150.0)
	var origin: Vector2 = Vector2(extent.get_center().x,extent.end.y-70.0)
	var attempts: int = ceili(float(maximum)/distance)+2
	for iteration: int in range(attempts):
		if page_scroll.scroll_vertical >= maximum-1: break
		_touch(origin,true)
		_drag(origin-Vector2(0,distance),Vector2(0,-distance))
		_touch(origin-Vector2(0,distance),false)
		page_scroll.stop_gesture()
		await process_frame
	print("PRODUCTION_TOUCH_BOTTOM offset=",page_scroll.scroll_vertical," maximum=",maximum)

func _last_button(node: Node) -> Button:
	for index: int in range(node.get_child_count()-1,-1,-1):
		var found: Button = _last_button(node.get_child(index))
		if found != null: return found
	return node as Button if node is Button else null

func _emulated_button(position: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position = position
	event.pressed = down
	root.push_input(event,true)

func _emulated_motion(position: Vector2, relative: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = position
	event.relative = relative
	root.push_input(event,true)

func _test_native_controls(app: Control) -> void:
	app._show_settings()
	await _layout_frames()
	var slider: HSlider = _find_type(app._page,"HSlider") as HSlider
	var original_volume: float = slider.value
	var center: Vector2 = slider.get_global_rect().get_center()
	_touch(center,true)
	_emulated_button(center,true)
	_drag(center-Vector2(0,90),Vector2(0,-90))
	_emulated_motion(center-Vector2(0,90),Vector2(0,-90))
	_touch(center-Vector2(0,90),false)
	_emulated_button(center-Vector2(0,90),false)
	await _layout_frames()
	_check(is_equal_approx(slider.value,original_volume),"vertical touch over native HSlider does not adjust or grab volume")
	var stable_volume: float = slider.value
	_emulated_motion(center+Vector2(180,0),Vector2(180,0))
	await process_frame
	_check(is_equal_approx(slider.value,stable_volume),"post-release emulated motion cannot keep slider grabbed")
	app._show_settings()
	await _layout_frames()
	slider = _find_type(app._page,"HSlider") as HSlider
	var slider_rect: Rect2 = slider.get_global_rect()
	var counts: Dictionary = {"start":0,"end":0}
	slider.drag_started.connect(func() -> void: counts.start += 1)
	slider.drag_ended.connect(func(_changed: bool) -> void: counts.end += 1)
	var tap_at: Vector2 = slider_rect.position + Vector2(slider_rect.size.x * 0.25,slider_rect.size.y*0.5)
	_touch(tap_at,true)
	_emulated_button(tap_at,true)
	_touch(tap_at,false)
	_emulated_button(tap_at,false)
	await _layout_frames()
	_check(slider.value < 0.4 and is_equal_approx(float(app.store.state.settings.volume),slider.value),"native HSlider tap still edits and persists the chosen value")
	_check(counts.start == 1 and counts.end == 1,"native slider tap dispatch is balanced and not doubled by mouse emulation")
	center = slider_rect.get_center()
	_touch(center,true)
	_emulated_button(center,true)
	_drag(center+Vector2(110,0),Vector2(110,0))
	_emulated_motion(center+Vector2(110,0),Vector2(110,0))
	_touch(center+Vector2(110,0),false)
	_emulated_button(center+Vector2(110,0),false)
	await _layout_frames()
	_check(slider.value > 0.6 and counts.start == 2 and counts.end == 2,"horizontal touch drag retains native slider editing with exactly one release")
	stable_volume = slider.value
	var stray: InputEventMouseMotion = InputEventMouseMotion.new()
	stray.device = 101
	stray.position = slider_rect.position+Vector2(20,slider_rect.size.y*0.5)
	stray.global_position = stray.position
	stray.relative = Vector2(-200,0)
	stray.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(stray,true)
	_check(is_equal_approx(slider.value,stable_volume),"slider is no longer grabbed after native horizontal touch release")
	app._show_catalog()
	await _layout_frames()
	var option: OptionButton = _find_type(app._page,"OptionButton") as OptionButton
	var original_choice: int = option.selected
	center = option.get_global_rect().get_center()
	_touch(center,true)
	_emulated_button(center,true)
	_drag(center-Vector2(0,110),Vector2(0,-110))
	_emulated_motion(center-Vector2(0,110),Vector2(0,-110))
	_touch(center-Vector2(0,110),false)
	_emulated_button(center-Vector2(0,110),false)
	await _layout_frames()
	_check(not option.get_popup().visible and option.selected == original_choice,"vertical touch over native OptionButton never opens or changes dropdown")
	option.get_popup().hide()

	app._show_catalog()
	await _layout_frames()
	option = _find_type(app._page,"OptionButton") as OptionButton
	center = option.get_global_rect().get_center()
	_touch(center,true)
	_emulated_button(center,true)
	_touch(center,false)
	_emulated_button(center,false)
	await _layout_frames()
	_check(option.get_popup().visible,"native OptionButton tap still opens dropdown")
	option.get_popup().hide()
	app._show_catalog()
	await _layout_frames()
	var search: LineEdit = _find_type(app._page,"LineEdit") as LineEdit
	center = search.get_global_rect().get_center()
	_touch(center,true)
	_touch(center,false)
	await _layout_frames()
	_check(search.has_focus(),"native search field touch still receives keyboard focus")

func _swipe_to_control(scroll: ScrollContainer, control: Control) -> void:
	var area: Rect2 = scroll.get_global_rect()
	var limit: int = ceili(scroll.get_v_scroll_bar().max_value/250.0)+4
	for repeat: int in range(limit):
		var bounds: Rect2 = control.get_global_rect()
		if bounds.position.y >= area.position.y+6 and bounds.end.y <= area.end.y-6: return
		var movement: float = -250.0 if bounds.end.y > area.end.y-6 else 250.0
		var point: Vector2 = area.get_center()
		_touch(point,true)
		_drag(point+Vector2(0,movement),Vector2(0,movement))
		_touch(point+Vector2(0,movement),false)
		scroll.stop_gesture()
		await process_frame

func _test_expanded_tackle_controls(app: Control) -> void:
	var starting_currency: int = int(app.store.state.currency)
	for bait: Dictionary in app.catalog.baits:
		app._show_gear()
		await _layout_frames()
		var id: String = str(bait.bait_id)
		var label: String = ("已选 · " if app.bait_id == id else "")+str(bait.name)
		var button: Button = _find_button(app._page,label)
		_check(button!=null,"all8 bait controls exist: "+id)
		if button==null: continue
		var bag: ScrollContainer = app._page.get_parent()
		await _swipe_to_control(bag,button)
		_check(bag.get_global_rect().encloses(button.get_global_rect()),"actual repeated touch swipes reveal bait control: "+id)
		var revision: int = int(app.store.state.save_revision)
		var point: Vector2 = button.get_global_rect().get_center()
		_touch(point,true)
		_emulated_button(point,true)
		_touch(point,false)
		_emulated_button(point,false)
		await _layout_frames()
		_check(app.bait_id==id and app.store.state.selection.bait_id==id and int(app.store.state.save_revision)==revision+1,"actual touch selects and persists bait exactly once: "+id)
		_check(app._bait_control.icon_kind==id,"HUD reflects actual selected bait bitmap: "+id)
	_check(int(app.store.state.currency)==starting_currency,"all8 unlimited baits cost no currency")
	var snapshot: Dictionary = app.store.state.duplicate(true)
	for id: int in range(5):
		app._borrow_gear(id)
		await _layout_frames()
		_check(app._effective_gear_id()==id and app.store.state==snapshot,"temporary rod selection leaves save/ownership/currency untouched: "+str(id))
		_check(app.scenery.gear_id==id,"3D rod receives selected geometry/material profile: "+str(id))
		app._show_prepare()
		app._enter_fishery()
		if app._models_complete:
			app._action_down()
			app.session.charge=1.0
			app._action_up()
			_check(app.session.state==FishingSession.State.CASTING and int(app.session.individual.equipment)==id and is_equal_approx(app.session.gear_power,float(app.catalog.gear[id].power)) and is_equal_approx(app.session.charge,float(app.catalog.gear[id].reach)),"borrowed rod drives actual encounter/fight stats and cast reach: "+str(id))
			app._abandon_round()
			app._return_to_lobby()
		else:
			_check(app._mode=="lobby" and app._overlay!=null and not app._content_ok,"borrowed rod cannot bypass incomplete44-model gate: "+str(id))
	app._clear_trial_gear()
	_check(app._trial_gear_id==-1 and app._effective_gear_id()==int(snapshot.gear) and app.store.state==snapshot,"ending trial borrowing restores saved rod without fake unlocks")
	app._page_context="prepare"

func _test_preview_factory() -> void:
	var factory: Control = load("res://scripts/main.gd").new()
	_check(factory.catalog.load_all(true) and factory.fish_art.load_all(factory.catalog),"preview factory requires all44 canonical photos")
	var preview: TextureRect = factory._fish_image(factory.catalog.fish["common_carp"],false,false,300)
	preview.position=Vector2(60,140)
	preview.size=Vector2(600,300)
	root.add_child(preview)
	await _layout_frames()
	_check(preview.get_script()==load("res://scripts/fish_art_view.gd") and preview.texture is AtlasTexture and preview.has_art_landmarks,"Main detail/result factory creates a genuine species-specific photo")
	_check(preview.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Main photo never captures page swipe input")
	var ruler: Control = load("res://scripts/measure_ruler.gd").new()
	ruler.length_mm=640
	ruler.specimen=preview
	ruler.position=Vector2(60,450)
	ruler.size=Vector2(600,50)
	root.add_child(ruler)
	await _layout_frames()
	var endpoints: Array[Vector2]=preview.measurement_endpoints()
	_check(endpoints.size()==2 and absf(endpoints[1].x-endpoints[0].x)>100 and absf(endpoints[1].x-endpoints[0].x)<=preview.size.x,"ruler follows actual nose/tail landmarks inside the cropped photo")
	_check(ruler.specimen==preview,"ruler consumes the same actual photo displayed above it")
	var absent = load("res://scripts/fish_definition.gd").new({"species_id":"no_such_species","art":"res://assets/fish/no_such_species.png"})
	var missing: TextureRect=factory._fish_image(absent,false,false,300)
	_check(missing.texture==null and not missing.has_art_landmarks,"missing photo does not substitute another species")
	missing.free()
	ruler.queue_free()
	preview.queue_free()
	factory.free()
	await process_frame
	print("PREVIEW_SCOPE: actual Main photo factory and body-landmark ruler; no gameplay readiness override")

func _test_production_preview_page(app: Control) -> void:
	app._show_species("common_carp")
	await _layout_frames()
	var nodes: Array[Node]=app._overlay.find_children("FishArtPreview","TextureRect",true,false)
	var preview: TextureRect=nodes[0] as TextureRect if nodes.size()==1 else null
	_check(preview!=null and preview.texture is AtlasTexture and preview.has_art_landmarks,"actual production detail page mounts the registered photoreal fish")
	if preview!=null:
		var page_scroll: ScrollContainer=app._page.get_parent()
		var maximum: int=maxi(0,floori(page_scroll.get_v_scroll_bar().max_value-page_scroll.get_v_scroll_bar().page))
		var prior_drags: int=page_scroll.completed_drags
		_check(maximum>0 or page_scroll.get_global_rect().grow(1.0).encloses(app._page.get_global_rect()),"photo detail is scrollable or completely fits without clipping")
		if maximum==0:
			_check(page_scroll.get_global_rect().grow(1.0).encloses(app._page.get_global_rect()),"nonoverflowing tall detail keeps all page content visible")
		var start: Vector2=preview.get_global_rect().get_center()
		_touch(start,true)
		_emulated_button(start,true)
		_drag(start-Vector2(0,180),Vector2(0,-180))
		_emulated_motion(start-Vector2(0,180),Vector2(0,-180))
		_touch(start-Vector2(0,180),false)
		_emulated_button(start-Vector2(0,180),false)
		await process_frame
		print("PREVIEW_TOUCH_RANGE maximum=",page_scroll.get_v_scroll_bar().max_value-page_scroll.get_v_scroll_bar().page," offset=",page_scroll.scroll_vertical," completed_drags=",page_scroll.completed_drags)
		_check(page_scroll.scroll_vertical>=mini(170,maximum) and page_scroll.completed_drags==prior_drags+1 and app._screen=="species","real drag starting on the static fish photo is owned by page and reaches its available scroll range without input capture")
		page_scroll.stop_gesture()
	app._show_prepare()
	await _layout_frames()
	_check(app.find_children("FishArtPreview","TextureRect",true,false).is_empty(),"closing detail removes its photo view")
