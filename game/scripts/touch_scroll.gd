class_name TouchScroll
extends ScrollContainer
## A gesture owner above GUI hit testing. Nested panels and buttons cannot eat
## ScreenDrag before this container sees it; a drag never dispatches a tap.
const DRAG_THRESHOLD: float = 14.0
const MIN_INERTIA: float = 45.0
const DECELERATION: float = 7.5
var _finger: int = -1
var _origin: Vector2
var _previous: Vector2
var _dragging: bool = false
var _tap_cancelled: bool = false
var _velocity: float = 0.0
var _last_msec: int = 0
var _ignore_mouse_until: int = 0
var _tap_target: BaseButton
var _native_target: bool = false
var _scroll_position: float = 0.0
var completed_drags: int = 0
var cancelled_taps: int = 0

func _ready() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Our gesture threshold replaces the native touch path, while wheel and
	# scrollbar interaction still use ScrollContainer normally.
	scroll_deadzone = int(DRAG_THRESHOLD)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if (_finger >= 0 and not _native_target) or Time.get_ticks_msec() < _ignore_mouse_until:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _finger >= 0:
				if get_global_rect().has_point(touch.position): get_viewport().set_input_as_handled()
				return
			if not get_global_rect().has_point(touch.position): return
			_finger = touch.index
			_origin = touch.position
			_previous = touch.position
			_last_msec = Time.get_ticks_msec()
			_dragging = false
			_tap_cancelled = false
			_velocity = 0.0
			_scroll_position = float(scroll_vertical)
			_tap_target = _button_at(self, touch.position)
			_native_target = _native_control_at(self, touch.position)
			if not _native_target:
				get_viewport().set_input_as_handled()
				_ignore_mouse_until = Time.get_ticks_msec() + 160
			return
		if touch.index != _finger: return
		var native_tap: bool = _native_target and not _dragging
		var target: BaseButton = _tap_target
		var dispatch_tap: bool = not touch.canceled and not _tap_cancelled and not _dragging and not _native_target and is_instance_valid(target) and target.get_global_rect().has_point(touch.position) and not target.disabled
		if _dragging:
			completed_drags += 1
			if is_instance_valid(target): cancelled_taps += 1
		if not native_tap:
			get_viewport().set_input_as_handled()
			_ignore_mouse_until = Time.get_ticks_msec() + 160
		_finger = -1
		_tap_target = null
		_native_target = false
		if touch.canceled: _velocity = 0.0
		# Deferred dispatch lets this ScreenTouch finish before a callback replaces
		# or deletes the page. There is exactly one dispatch for a completed tap.
		if dispatch_tap: _activate_button.call_deferred(target)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index != _finger: return
		var displacement: Vector2 = drag.position - _origin
		if displacement.length() >= DRAG_THRESHOLD: _tap_cancelled = true
		if not _dragging and absf(displacement.y) >= DRAG_THRESHOLD and absf(displacement.y) >= absf(displacement.x) * 0.7:
			_dragging = true
			if is_instance_valid(_tap_target): _tap_target.set_pressed_no_signal(false)
		if _dragging:
			var movement: float = drag.position.y - _previous.y
			var elapsed: float = maxf(0.008, float(Time.get_ticks_msec() - _last_msec) / 1000.0)
			_velocity = lerpf(_velocity, clampf(-movement / elapsed, -2400.0, 2400.0), 0.65)
			_apply_scroll(-movement)
			get_viewport().set_input_as_handled()
			_ignore_mouse_until = Time.get_ticks_msec() + 160
		elif not _native_target:
			get_viewport().set_input_as_handled()
		_previous = drag.position
		_last_msec = Time.get_ticks_msec()

func _process(delta: float) -> void:
	if _finger >= 0 or not is_visible_in_tree(): return
	if absf(_velocity) < MIN_INERTIA:
		_velocity = 0.0
		return
	_apply_scroll(_velocity * minf(delta, 0.05))
	_velocity *= exp(-DECELERATION * delta)

func _apply_scroll(amount: float) -> void:
	var bar: VScrollBar = get_v_scroll_bar()
	var maximum: float = maxf(0.0, bar.max_value - bar.page)
	_scroll_position = clampf(_scroll_position + amount, 0.0, maximum)
	scroll_vertical = roundi(_scroll_position)
	if _scroll_position <= 0.0 or _scroll_position >= maximum: _velocity = 0.0

func stop_gesture() -> void:
	_finger = -1
	_dragging = false
	_tap_cancelled = true
	_velocity = 0.0
	_tap_target = null
	_native_target = false
	_ignore_mouse_until = Time.get_ticks_msec() + 160

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_EXIT_TREE]: stop_gesture()

func _activate_button(button: BaseButton) -> void:
	if not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled: return
	button.grab_focus()
	button.button_down.emit()
	button.button_up.emit()
	if button.toggle_mode: button.button_pressed = not button.button_pressed
	button.pressed.emit()

func _button_at(node: Node, point: Vector2) -> BaseButton:
	for index: int in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(index)
		if child is Control and (not child.is_visible_in_tree() or (child.clip_contents and not child.get_global_rect().has_point(point))): continue
		var found: BaseButton = _button_at(child, point)
		if found != null: return found
	if node is BaseButton and node.get_global_rect().has_point(point) and not node.disabled: return node as BaseButton
	return null

func _native_control_at(node: Node, point: Vector2) -> bool:
	for child: Node in node.get_children():
		if child is Control and not child.is_visible_in_tree(): continue
		if _native_control_at(child, point): return true
	return (node is LineEdit or node is TextEdit or node is Range or node is OptionButton) and node is Control and node.get_global_rect().has_point(point)
