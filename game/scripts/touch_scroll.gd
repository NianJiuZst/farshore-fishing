class_name TouchScroll
extends ScrollContainer
## Gesture owner above GUI hit testing. A vertical swipe never presses its
## Button, OptionButton or Slider child, including Android mouse emulation.
const DRAG_THRESHOLD: float = 14.0
const MIN_INERTIA: float = 45.0
const DECELERATION: float = 7.5
const NATIVE_DISPATCH_DEVICE: int = 101
var _finger: int = -1
var _origin: Vector2
var _previous: Vector2
var _dragging: bool = false
var _tap_cancelled: bool = false
var _velocity: float = 0.0
var _last_msec: int = 0
var _ignore_mouse_until: int = 0
var _tap_target: BaseButton
var _native_target: Control
var _native_drag: bool = false
var _scroll_position: float = 0.0
var completed_drags: int = 0
var cancelled_taps: int = 0

func _ready() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_deadzone = int(DRAG_THRESHOLD)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if _finger >= 0 or Time.get_ticks_msec() < _ignore_mouse_until:
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
			_native_drag = false
			_velocity = 0.0
			_scroll_position = float(scroll_vertical)
			_tap_target = _button_at(self, touch.position)
			_native_target = _native_control_at(self, touch.position)
			# Do not let native controls see a down yet: OptionButton opens on
			# down and HSlider grabs immediately, before a swipe is recognizable.
			_consume_touch()
			return
		if touch.index != _finger: return
		var target: BaseButton = _tap_target
		var native: Control = _native_target
		var tap: bool = not touch.canceled and not _tap_cancelled and not _dragging
		var dispatch_native: bool = tap and is_instance_valid(native) and native.get_global_rect().has_point(touch.position)
		var dispatch_button: bool = tap and native == null and is_instance_valid(target) and target.get_global_rect().has_point(touch.position) and not target.disabled
		if _dragging:
			completed_drags += 1
			if is_instance_valid(target): cancelled_taps += 1
		if _native_drag: _send_native_button(touch.position, false)
		_consume_touch()
		_finger = -1
		_tap_target = null
		_native_target = null
		_native_drag = false
		if touch.canceled: _velocity = 0.0
		# Finish this event before a tap callback replaces/deletes the page.
		if dispatch_native: _activate_native.call_deferred(native, touch.position)
		elif dispatch_button: _activate_button.call_deferred(target)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index != _finger: return
		var displacement: Vector2 = drag.position - _origin
		if displacement.length() >= DRAG_THRESHOLD: _tap_cancelled = true
		if not _dragging and not _native_drag:
			if absf(displacement.y) >= DRAG_THRESHOLD and absf(displacement.y) >= absf(displacement.x) * 0.7:
				_dragging = true
			elif _native_target is HSlider and absf(displacement.x) >= DRAG_THRESHOLD:
				# Horizontal slider editing gets a balanced native drag sequence;
				# a vertical gesture never starts one in the first place.
				_native_drag = true
				_send_native_button(_origin, true)
		if _native_drag:
			_send_native_motion(drag.position, drag.position - _previous)
		elif _dragging:
			var movement: float = drag.position.y - _previous.y
			var elapsed: float = maxf(0.008, float(Time.get_ticks_msec() - _last_msec) / 1000.0)
			_velocity = lerpf(_velocity, clampf(-movement / elapsed, -2400.0, 2400.0), 0.65)
			_apply_scroll(-movement)
		_consume_touch()
		_previous = drag.position
		_last_msec = Time.get_ticks_msec()

func _consume_touch() -> void:
	get_viewport().set_input_as_handled()
	_ignore_mouse_until = Time.get_ticks_msec() + 160

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
	if _native_drag and is_inside_tree(): _send_native_button(_previous, false)
	_finger = -1
	_dragging = false
	_tap_cancelled = true
	_velocity = 0.0
	_tap_target = null
	_native_target = null
	_native_drag = false
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

func _activate_native(control: Control, point: Vector2) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree(): return
	if control is BaseButton and control.disabled: return
	_send_native_button(point, true)
	_send_native_button(point, false)

func _send_native_button(point: Vector2, pressed: bool) -> void:
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.device = NATIVE_DISPATCH_DEVICE
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	mouse.position = point
	mouse.global_position = point
	mouse.pressed = pressed
	get_viewport().push_input(mouse, true)

func _send_native_motion(point: Vector2, relative: Vector2) -> void:
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse.device = NATIVE_DISPATCH_DEVICE
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse.position = point
	mouse.global_position = point
	mouse.relative = relative
	get_viewport().push_input(mouse, true)

func _button_at(node: Node, point: Vector2) -> BaseButton:
	for index: int in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(index)
		if child is Control and (not child.is_visible_in_tree() or (child.clip_contents and not child.get_global_rect().has_point(point))): continue
		var found: BaseButton = _button_at(child, point)
		if found != null: return found
	if node is BaseButton and node.get_global_rect().has_point(point) and not node.disabled: return node as BaseButton
	return null

func _native_control_at(node: Node, point: Vector2) -> Control:
	for index: int in range(node.get_child_count() - 1, -1, -1):
		var child: Node = node.get_child(index)
		if child is Control and (not child.is_visible_in_tree() or (child.clip_contents and not child.get_global_rect().has_point(point))): continue
		var found: Control = _native_control_at(child, point)
		if found != null: return found
	if (node is LineEdit or node is TextEdit or node is Range or node is OptionButton) and node is Control and node.get_global_rect().has_point(point): return node as Control
	return null
