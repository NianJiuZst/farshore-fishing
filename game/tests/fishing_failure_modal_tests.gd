extends SceneTree
## Native viewport dispatch, not pressed.emit(), exercises the input boundary.
const IconActionScript = preload("res://scripts/icon_action.gd")
const Modal = preload("res://scripts/fishing_failure_modal.gd")
var checks: int = 0
var failures: int = 0
var host: Control
var modal: Control
var retry_count: int = 0
var dismiss_count: int = 0
var cast_count: int = 0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
	host = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var app_theme: Theme = Theme.new()
	var font: FontFile = load("res://assets/fonts/NotoSansCJK-Regular.ttc")
	font.set_face_index(0,2)
	app_theme.default_font = font
	app_theme.default_font_size = 24
	host.theme = app_theme
	root.add_child(host)
	var cast: Button = Button.new()
	cast.name = "UnderlyingCast"
	cast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cast.text = "Underlying fishing input"
	cast.pressed.connect(func() -> void: cast_count += 1)
	host.add_child(cast)
	await _fresh("空竿收回，鱼还没有咬牢。下次再多观察一会儿浮漂")
	_check(modal.get_test_handles().title.text == "空竿收回","empty cast has short outcome title")
	_check(modal.get_test_handles().body.text.length() < 36,"short useful empty-cast guidance")
	var panel: Rect2 = modal.get_panel_rect()
	_check(panel.size.x <= 596.1 and panel.size.y < 480,"result is a compact panel, not a full-screen page")
	_check(absf(panel.get_center().x-host.size.x*0.5) < 1,"panel centers across normal phone width")
	_check(panel.position.y > 250 and panel.end.y < host.size.y-250,"scene remains visible above and below result")
	for action: String in ["retry","dismiss"]:
		var button: Button = modal.get_test_handles()[action]
		_check(button.size.x >= 96 and button.size.y >= 96,action+" target >=96 logical pixels")
		_audit_action_surface(button, action)
		_check(panel.encloses(button.get_global_rect()),action+" fits inside compact panel")
	_check(modal.theme == null and modal.get_theme_default_font() == font,"modal inherits actual Chinese font/theme")
	_check(modal.get_test_handles().scrim.color.a < 0.35,"subtle scrim keeps fishing scene legible")
	_check(root.gui_get_focus_owner() == modal.get_test_handles().retry,"initial keyboard focus stays on a modal action")
	for step: int in range(4):
		var tab: InputEventKey = InputEventKey.new()
		tab.keycode = KEY_TAB
		tab.pressed = true
		root.push_input(tab,true)
		await process_frame
		_check(root.gui_get_focus_owner() in [modal.get_test_handles().retry,modal.get_test_handles().dismiss],"Tab stays inside result panel")
	modal.set_safe_insets(Vector4(48,112,32,84))
	await _layout()
	panel = modal.get_panel_rect()
	_check(panel.position.x >= 48 and panel.end.x <= host.size.x-32 and panel.position.y >= 112 and panel.end.y <= host.size.y-84,"synthetic all-edge safe insets keep entire panel safe")
	var safe_center: Vector2 = Vector2(48,112)+(host.size-Vector2(80,196))*0.5
	_check(panel.get_center().distance_to(safe_center) < 1,"panel centers within asymmetric safe rectangle")
	var outside: Vector2 = Vector2(40,host.size.y-80)
	_touch(outside,true,0)
	_touch(outside,false,0)
	_mouse(outside,true,InputEvent.DEVICE_ID_EMULATION)
	_mouse(outside,false,InputEvent.DEVICE_ID_EMULATION)
	_mouse(outside,true)
	_mouse(outside,false)
	await _drain()
	_check(cast_count == 0 and retry_count == 0 and dismiss_count == 0,"scrim swallows touch and mouse without dismissing or casting")
	var retry: Vector2 = modal.get_test_handles().retry.get_global_rect().get_center()
	_touch(retry,true,0)
	_touch(retry,false,0)
	_mouse(retry,true,InputEvent.DEVICE_ID_EMULATION)
	_mouse(retry,false,InputEvent.DEVICE_ID_EMULATION)
	modal.request_retry()
	modal.request_dismiss()
	await _drain()
	_check(retry_count == 1 and dismiss_count == 0 and cast_count == 0,"touch retry and emulated duplicate dispatch exactly one retry, no cast")
	await _fresh("松手太久，鱼带着松线挣脱了")
	_check("松线" in modal.get_test_handles().body.text and modal.get_test_handles().art.kind == "release","slack outcome supplies useful guidance and existing icon")
	var dismiss: Vector2 = modal.get_test_handles().dismiss.get_global_rect().get_center()
	_touch(dismiss,true,1)
	_touch(dismiss,false,1)
	await _drain()
	_check(dismiss_count == 1 and cast_count == 0,"touch index 1 can dismiss once without casting through")
	await _fresh("迎着冲势猛拉，鱼线绷断了。留意鱼身转向和竿梢蓄力")
	_check(modal.get_test_handles().title.text == "鱼线断了" and "拉力" in modal.get_test_handles().body.text,"overload break has concise actionable copy")
	_check("磨损" in Modal.copy_for_reason("僵持后的鱼线磨损越来越重，终于断开了").body,"wear break keeps distinct cause")
	_check("及时收线" in Modal.copy_for_reason("浮漂又浮了回来，鱼已经松口游走了").body,"missed bite keeps relevant guidance")
	retry = modal.get_test_handles().retry.get_global_rect().get_center()
	_touch(retry,true,0)
	_drag(retry+Vector2(45,0),0)
	_touch(retry+Vector2(45,0),false,0)
	await _drain()
	_check(retry_count == 1,"drag cancels action instead of activating retry")
	_touch(retry,true,0)
	_touch(retry,false,0,true)
	await _drain()
	_check(retry_count == 1,"Android canceled touch does not activate retry")
	_touch(retry,true,0)
	modal.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	modal.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_touch(retry,false,0)
	await _drain()
	_check(retry_count == 1 and dismiss_count == 1,"background interruption cancels held input")
	_touch(retry,true,0)
	_touch(outside,true,1)
	modal.request_dismiss()
	_touch(retry,false,0)
	await _drain()
	_check(dismiss_count == 1,"Back waits while another finger is held")
	_touch(outside,false,1)
	await _drain()
	_check(dismiss_count == 2 and retry_count == 1 and cast_count == 0,"Back completes once after every finger releases")
	await _fresh("鱼逃走了")
	retry = modal.get_test_handles().retry.get_global_rect().get_center()
	_mouse(retry,true)
	_mouse(retry,false)
	await _drain()
	_check(retry_count == 2,"ordinary desktop mouse activates same retry signal")
	await _fresh("鱼逃走了")
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape,true)
	await _drain()
	_check(dismiss_count == 3 and cast_count == 0,"keyboard Back dismisses without underlying input")
	await _fresh("空竿收回")
	modal.request_retry()
	modal.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _drain()
	modal.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await _drain()
	_check(retry_count == 2,"pause cancels pending action, resume does not auto-retry")
	for repeat: int in range(4):
		await _fresh("空竿收回")
		modal.request_dismiss()
		modal.queue_free()
		modal = null
		await process_frame
	_check(dismiss_count == 3,"replacement/free cancels pending signals and open tween safely")
	await _fresh("空竿收回")
	modal.dismiss_requested.connect(func() -> void:
		host.remove_child(modal)
		modal.queue_free()
		modal = null
	)
	dismiss = modal.get_test_handles().dismiss.get_global_rect().get_center()
	_touch(dismiss,true,0)
	_touch(dismiss,false,0)
	await process_frame
	_mouse(dismiss,true,InputEvent.DEVICE_ID_EMULATION)
	_mouse(dismiss,false,InputEvent.DEVICE_ID_EMULATION)
	await _drain()
	_check(modal == null and dismiss_count == 4 and cast_count == 0,"real removal callback drains next-frame emulated click before exposing cast")
	print("FISHING_FAILURE_MODAL_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; Viewport ScreenTouch index0/index1, drag/cancel, emulated/native mouse, Back, pause, safe insets; physical=",root.size," logical=",host.size,"; not Android hardware testing")
	host.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

# Exact 1afda37 IconAction surface contract. The modal deliberately inherits
# these rounded actions; transparent-only assertions predate the upstream UI.
func _audit_action_surface(button: Button, label: String) -> void:
	_check(button.get_script() == IconActionScript and button.appearance == "surface" and not button.light_label, label + " uses the real upstream surface IconAction")
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style: StyleBox = button.get_theme_stylebox(state)
		_check(style is StyleBoxFlat, label + " " + state + " uses StyleBoxFlat")
		if not style is StyleBoxFlat: continue
		var flat: StyleBoxFlat = style as StyleBoxFlat
		var fill: Color = Color("e8eeea")
		var border: Color = Color(0.17,0.34,0.31,0.12)
		var width: int = 1
		if state == "hover": fill = fill.lightened(0.06)
		if state in ["pressed", "hover_pressed"]: fill = fill.darkened(0.12)
		if state == "disabled": fill = Color(fill,0.25)
		if state == "focus":
			fill = Color.TRANSPARENT
			border = Color("d0ad64")
			width = 3
		_check(flat.draw_center and flat.bg_color.is_equal_approx(fill), label + " " + state + " exact upstream fill")
		_check(flat.border_color.is_equal_approx(border) and flat.border_width_top == width and flat.border_width_bottom == width and flat.border_width_left == width and flat.border_width_right == width, label + " " + state + " exact upstream border/focus ring")
		_check(flat.corner_radius_top_left == 18 and flat.corner_radius_top_right == 18 and flat.corner_radius_bottom_left == 18 and flat.corner_radius_bottom_right == 18 and flat.shadow_size == 0, label + " " + state + " rounded corners without extra shadow")
	var caption: Label = button.get("_caption") as Label
	_check(caption != null and caption.text == button.text and caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " has the real readable nonblocking caption")
	if caption != null:
		var fg: float = caption.get_theme_color("font_color").srgb_to_linear().get_luminance()
		var bg: float = Color("e8eeea").srgb_to_linear().get_luminance()
		_check(caption.get_theme_font_size("font_size") >= 24 and (maxf(fg,bg)+0.05)/(minf(fg,bg)+0.05) >= 3.0, label + " large caption contrasts with its actual rounded surface")

func _fresh(reason: String) -> void:
	if is_instance_valid(modal):
		host.remove_child(modal)
		modal.queue_free()
	modal = Modal.new()
	modal.configure(reason)
	modal.retry_requested.connect(func() -> void: retry_count += 1)
	modal.dismiss_requested.connect(func() -> void: dismiss_count += 1)
	host.add_child(modal)
	await _layout()

func _layout() -> void:
	for frame: int in range(5): await process_frame

func _drain() -> void:
	await create_timer(0.21).timeout
	await process_frame

func _touch(point: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event,true)

func _drag(point: Vector2, index: int) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.relative = Vector2(45,0)
	root.push_input(event,true)

func _mouse(point: Vector2, pressed: bool, device: int = 0) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.device = device
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	root.push_input(event,true)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL FAILURE_MODAL: ",label)
