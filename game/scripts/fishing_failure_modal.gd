class_name FishingFailureModal
extends Control
## A presentation-only terminal result. Main owns session/pause/save changes.
signal retry_requested
signal dismiss_requested

const IconButton = preload("res://scripts/icon_action.gd")
const Art = preload("res://scripts/ui_art.gd")
const PAPER: Color = Color("f5f2e9")
const INK: Color = Color("213c41")
const MUTED: Color = Color("4d6965")
const GOLD: Color = Color("95601e")
const INPUT_DRAIN_MSEC: int = 160
const TAP_SLOP: float = 24.0

var animate_open: bool = true
var _reason: String = ""
var _confirmation: Dictionary = {}
var _safe_insets: Vector4 = Vector4(20,22,20,20) # left, top, right, bottom; logical pixels
var _panel: PanelContainer
var _scrim: ColorRect
var _title_label: Label
var _body_label: Label
var _note_label: Label
var _outcome_art: Control
var _retry: Button
var _dismiss: Button
var _open_tween: Tween
var _layout_queued: bool = false
var _touches: Dictionary = {}
var _finger: int = -1
var _origin: Vector2
var _touch_action: String = ""
var _pending_action: String = ""
var _emitted: bool = false
var _input_block_until: int = 0
var _backgrounded: bool = false

func configure(reason: String, safe_insets: Vector4 = Vector4(20,22,20,20)) -> void:
	_confirmation = {}
	_reason = reason
	_safe_insets = safe_insets
	if is_node_ready():
		_apply_copy()
		_queue_layout()

func configure_confirmation(title: String, body: String, primary: String, secondary: String, icon_kind: String, safe_insets: Vector4 = Vector4(20,22,20,20)) -> void:
	_confirmation = {"title":title,"body":body,"primary":primary,"secondary":secondary,"icon":icon_kind}
	_safe_insets = safe_insets
	if is_node_ready():
		_apply_copy()
		_queue_layout()

func set_safe_insets(insets: Vector4) -> void:
	_safe_insets = Vector4(maxf(0,insets.x),maxf(0,insets.y),maxf(0,insets.z),maxf(0,insets.w))
	_queue_layout()

func _ready() -> void:
	name = "FishingFailureModal"
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim = ColorRect.new()
	_scrim.name = "FailureScrim"
	_scrim.color = Color(0.035,0.095,0.105,0.28)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)
	_panel = PanelContainer.new()
	_panel.name = "FailurePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.set_corner_radius_all(24)
	paper.set_border_width_all(1)
	paper.border_color = Color(0.40,0.49,0.40,0.24)
	paper.shadow_color = Color(0.02,0.07,0.08,0.20)
	paper.shadow_size = 16
	paper.shadow_offset = Vector2(0,8)
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 28
	paper.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel",paper)
	add_child(_panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "FailureContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation",18)
	_panel.add_child(content)
	var heading: HBoxContainer = HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation",18)
	content.add_child(heading)
	_outcome_art = Art.new()
	_outcome_art.name = "OutcomeArt"
	_outcome_art.custom_minimum_size = Vector2(80,80)
	_outcome_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(_outcome_art)
	var heading_text: VBoxContainer = VBoxContainer.new()
	heading_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading_text.add_theme_constant_override("separation",3)
	heading.add_child(heading_text)
	var eyebrow: Label = _label("这一竿已结束",18,MUTED)
	eyebrow.name = "OutcomeEyebrow"
	heading_text.add_child(eyebrow)
	_title_label = _label("",34,INK)
	_title_label.name = "OutcomeTitle"
	heading_text.add_child(_title_label)
	_body_label = _label("",25,INK)
	_body_label.name = "OutcomeBody"
	content.add_child(_body_label)
	_note_label = _label("未计入钓获 · 鱼饵未消耗",20,MUTED)
	_note_label.name = "OutcomeNote"
	content.add_child(_note_label)
	var divider: ColorRect = ColorRect.new()
	divider.name = "ActionDivider"
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.color = Color(0.30,0.47,0.44,0.20)
	divider.custom_minimum_size.y = 1
	content.add_child(divider)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "FailureActions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation",18)
	content.add_child(actions)
	_retry = _action("RetryAction","再试一竿","rod",GOLD,26)
	_retry.pressed.connect(request_retry)
	actions.add_child(_retry)
	_dismiss = _action("DismissAction","返回钓点","back",MUTED,24)
	_dismiss.pressed.connect(request_dismiss)
	actions.add_child(_dismiss)
	# Keep keyboard/controller focus inside this modal while the HUD stays visible.
	for pair: Array in [[_retry,_dismiss],[_dismiss,_retry]]:
		var current: Button = pair[0]
		var other: Button = pair[1]
		current.focus_next = current.get_path_to(other)
		current.focus_previous = current.get_path_to(other)
		current.focus_neighbor_left = current.get_path_to(other)
		current.focus_neighbor_right = current.get_path_to(other)
		current.focus_neighbor_top = current.get_path_to(other)
		current.focus_neighbor_bottom = current.get_path_to(other)
	_retry.grab_focus()
	_apply_copy()
	resized.connect(_queue_layout)
	_panel.minimum_size_changed.connect(_queue_layout)
	_queue_layout()
	if animate_open:
		_panel.modulate.a = 0.0
		_scrim.modulate.a = 0.0
		_open_tween = create_tween().set_parallel(true)
		_open_tween.tween_property(_panel,"modulate:a",1.0,0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_open_tween.tween_property(_scrim,"modulate:a",1.0,0.14)

func _label(value: String, pixels: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",color)
	# The solid paper supplies contrast; avoid the HUD's heavy outdoor shadow.
	label.add_theme_constant_override("outline_size",0)
	label.add_theme_constant_override("shadow_offset_x",0)
	label.add_theme_constant_override("shadow_offset_y",0)
	return label

func _action(node_name: String, caption: String, icon: String, color: Color, pixels: int) -> Button:
	var button: Button = IconButton.new()
	button.name = node_name
	button.text = caption
	button.icon_kind = icon
	button.icon_extent = 48
	button.label_color = color
	button.custom_minimum_size = Vector2(216,96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",pixels)
	return button

func _apply_copy() -> void:
	var copy: Dictionary = copy_for_reason(_reason) if _confirmation.is_empty() else _confirmation
	var eyebrow: Label = find_child("OutcomeEyebrow",true,false) as Label
	if eyebrow != null: eyebrow.text = "这一竿已结束" if _confirmation.is_empty() else "退出确认"
	_note_label.visible = _confirmation.is_empty()
	_retry.text = "再试一竿" if _confirmation.is_empty() else str(_confirmation.primary)
	_retry.icon_kind = "rod" if _confirmation.is_empty() else str(_confirmation.icon)
	_dismiss.text = "返回钓点" if _confirmation.is_empty() else str(_confirmation.secondary)
	_title_label.text = str(copy.title)
	_body_label.text = str(copy.body)
	_outcome_art.kind = str(copy.icon)

static func copy_for_reason(reason: String) -> Dictionary:
	if reason.begins_with("空竿"):
		return {"title":"空竿收回", "body":"鱼还没咬牢。下次多观察一会儿鱼漂。", "icon":"hook"}
	if "磨损" in reason:
		return {"title":"鱼线断了", "body":"鱼线磨损过重。下次把握收线与卸力的节奏。", "icon":"reel"}
	if "断" in reason:
		return {"title":"鱼线断了", "body":"拉力太大。留意鱼的冲势，及时松手卸力。", "icon":"reel"}
	if "松线" in reason or "松手太久" in reason:
		return {"title":"鱼已逃脱", "body":"松线太久，鱼挣脱了。下次及时收紧鱼线。", "icon":"release"}
	if "松口" in reason:
		return {"title":"鱼已逃脱", "body":"鱼已松口游走。下次留意鱼漂，及时收线。", "icon":"release"}
	return {"title":"鱼已逃脱", "body":"这次没能留住它。调整节奏，再试一竿。", "icon":"release"}

func _queue_layout() -> void:
	if not is_node_ready() or _layout_queued: return
	_layout_queued = true
	_layout_panel.call_deferred()

func _layout_panel() -> void:
	_layout_queued = false
	if not is_node_ready(): return
	var usable: Rect2 = Rect2(Vector2(_safe_insets.x,_safe_insets.y),Vector2(maxf(1,size.x-_safe_insets.x-_safe_insets.z),maxf(1,size.y-_safe_insets.y-_safe_insets.w)))
	var width: float = minf(596.0,maxf(1,usable.size.x-32.0))
	_panel.size = Vector2(width,0)
	var panel_height: float = _panel.get_combined_minimum_size().y
	_panel.size = Vector2(width,panel_height)
	_panel.position = usable.position + (usable.size-_panel.size)*0.5

func get_panel_rect() -> Rect2:
	return _panel.get_global_rect() if is_instance_valid(_panel) else Rect2()

func get_test_handles() -> Dictionary:
	return {"panel":_panel,"scrim":_scrim,"title":_title_label,"body":_body_label,"note":_note_label,"retry":_retry,"dismiss":_dismiss,"art":_outcome_art}

func request_retry() -> void:
	_request_action("retry")

func request_dismiss() -> void:
	_request_action("dismiss")

func _request_action(action: String) -> void:
	if _emitted or not _pending_action.is_empty() or _backgrounded: return
	_pending_action = action
	_input_block_until = maxi(_input_block_until,Time.get_ticks_msec()+INPUT_DRAIN_MSEC)
	_retry.disabled = true
	_dismiss.disabled = true

func _process(_delta: float) -> void:
	if _pending_action.is_empty() or _emitted or _backgrounded or not _touches.is_empty(): return
	if Time.get_ticks_msec() < _input_block_until: return
	_emitted = true
	if _pending_action == "retry": retry_requested.emit()
	else: dismiss_requested.emit()

func _action_at(point: Vector2) -> String:
	if not _retry.disabled and _retry.get_global_rect().has_point(point): return "retry"
	if not _dismiss.disabled and _dismiss.get_global_rect().has_point(point): return "dismiss"
	return ""

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		_input_block_until = Time.get_ticks_msec()+INPUT_DRAIN_MSEC
		if event.pressed:
			_touches[event.index] = true
			if _finger < 0 and _touches.size() == 1:
				_finger = event.index
				_origin = event.position
				_touch_action = _action_at(event.position)
		else:
			_touches.erase(event.index)
			if event.index == _finger:
				var selected: String = _touch_action
				_finger = -1
				_touch_action = ""
				if not event.canceled and not selected.is_empty() and event.position.distance_to(_origin) < TAP_SLOP and _action_at(event.position) == selected:
					_request_action(selected)
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()
		if event.index == _finger and event.position.distance_to(_origin) >= TAP_SLOP: _touch_action = ""
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
		_input_block_until = Time.get_ticks_msec()+INPUT_DRAIN_MSEC
	elif event is InputEventKey and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if not event.echo: request_dismiss()

func _gui_input(_event: InputEvent) -> void:
	# Scrim/panel taps deliberately stay here. Only the two named actions leave.
	accept_event()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		_backgrounded = true
		_cancel_gesture()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
		_backgrounded = false
		_input_block_until = Time.get_ticks_msec()+INPUT_DRAIN_MSEC
	elif what == NOTIFICATION_EXIT_TREE:
		if _open_tween != null and _open_tween.is_valid(): _open_tween.kill()

func _cancel_gesture() -> void:
	_touches.clear()
	_finger = -1
	_touch_action = ""
	_pending_action = ""
	if is_instance_valid(_retry): _retry.disabled = false
	if is_instance_valid(_dismiss): _dismiss.disabled = false
