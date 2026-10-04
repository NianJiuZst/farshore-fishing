class_name WhaleChallengeUI
extends Control
## Touchscreen HUD and cinematic completion for the independent whale challenge.
signal exit_requested
signal retry_requested
signal save_retry_requested
signal discard_requested
signal notebook_requested
signal pause_requested
signal resume_requested

const Challenge = preload("res://scripts/blue_whale_challenge.gd")
const WhaleStage = preload("res://scripts/whale_challenge_stage_3d.gd")
const INK: Color = Color("e8f9ed")
const DIM: Color = Color("a8d3d7")
var challenge: BlueWhaleChallenge
var stage: WhaleChallengeStage3D
var saved: bool = false
var save_error: String = ""
var new_best: bool = false
var safe_margins: Vector4 = Vector4(28.0, 28.0, 28.0, 28.0)
var _title: Label
var _instruction: Label
var _detail: Label
var _gauge: Control
var _track: ColorRect
var _band: ColorRect
var _cursor: ColorRect
var _progress: ProgressBar
var _phase_status: Label
var _controls: HBoxContainer
var _terminal_controls: VBoxContainer
var _primary: Button
var _left: Button
var _right: Button
var _pause: Button
var _left_held: bool = false
var _right_held: bool = false
var _last_state: int = -1

func configure(value: BlueWhaleChallenge, margins: Vector4) -> void:
	challenge = value
	safe_margins = margins

func _ready() -> void:
	name = "WhaleChallengeUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = WhaleStage.new()
	stage.name = "WhaleChallengeCinematic"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.bind_challenge(challenge)
	add_child(stage)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair: Array in [["left", safe_margins.x], ["top", safe_margins.y], ["right", safe_margins.z], ["bottom", safe_margins.w]]:
		margin.add_theme_constant_override("margin_" + str(pair[0]), maxi(24, int(pair[1])))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var outer: VBoxContainer = VBoxContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)
	var heading: PanelContainer = _panel()
	outer.add_child(heading)
	var column: VBoxContainer = VBoxContainer.new()
	heading.add_child(column)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	var exit: Button = _button("退出", func() -> void: exit_requested.emit())
	exit.name = "WhaleExit"
	exit.custom_minimum_size.x = 106.0
	exit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(exit)
	_title = _label("鲸影共鸣", 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_title)
	_pause = _button("暂停", func() -> void: pause_requested.emit())
	_pause.custom_minimum_size.x = 106.0
	_pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(_pause)
	column.add_child(_label("幻想挑战 · 26 米蓝鲸影 · 光线连接外侧光环", 20, DIM))
	_instruction = _label("", 24)
	column.add_child(_instruction)
	var space: Control = Control.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(space)
	var card: PanelContainer = _panel()
	outer.add_child(card)
	var bottom: VBoxContainer = VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	card.add_child(bottom)
	_phase_status = _label("", 22, DIM)
	bottom.add_child(_phase_status)
	_gauge = Control.new()
	_gauge.name = "WhaleControlGauge"
	_gauge.custom_minimum_size.y = 36.0
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_gauge)
	_track = ColorRect.new()
	_track.color = Color("244c60")
	_track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.add_child(_track)
	_band = ColorRect.new()
	_band.name = "WhaleTargetGreenBand"
	_band.color = Color("298970")
	_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.add_child(_band)
	_cursor = ColorRect.new()
	_cursor.name = "WhaleInputCursor"
	_cursor.color = Color("fff1b1")
	_cursor.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.add_child(_cursor)
	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 10.0
	_progress.add_theme_stylebox_override("background", _box(Color("244c60"), 5))
	_progress.add_theme_stylebox_override("fill", _box(Color("80d8b4"), 5))
	bottom.add_child(_progress)
	_detail = _label("", 20, DIM)
	bottom.add_child(_detail)
	_controls = HBoxContainer.new()
	_controls.name = "WhaleTouchControls"
	_controls.add_theme_constant_override("separation", 14)
	bottom.add_child(_controls)
	_left = _button("向左", Callable(), true)
	_left.name = "WhaleCurrentLeft"
	_left.button_down.connect(func() -> void: _left_held = true; _update_direction())
	_left.button_up.connect(func() -> void: _left_held = false; _update_direction())
	_left.mouse_exited.connect(func() -> void: _left_held = false; _update_direction())
	_controls.add_child(_left)
	_right = _button("向右", Callable(), true)
	_right.name = "WhaleCurrentRight"
	_right.button_down.connect(func() -> void: _right_held = true; _update_direction())
	_right.button_up.connect(func() -> void: _right_held = false; _update_direction())
	_right.mouse_exited.connect(func() -> void: _right_held = false; _update_direction())
	_controls.add_child(_right)
	_primary = _button("按住调谐", Callable(), true)
	_primary.name = "WhalePulseOrTension"
	_primary.button_down.connect(func() -> void: challenge.set_hold(true))
	_primary.button_up.connect(func() -> void: challenge.set_hold(false))
	_primary.mouse_exited.connect(func() -> void: challenge.set_hold(false))
	_controls.add_child(_primary)
	_terminal_controls = VBoxContainer.new()
	_terminal_controls.name = "WhaleCompletionActions"
	bottom.add_child(_terminal_controls)
	challenge.changed.connect(_state_changed)
	_state_changed(challenge.state)

func _exit_tree() -> void:
	# Main removes a previous HUD immediately and frees it at the frame boundary.
	# It must stop receiving model signals before a retry creates the next HUD.
	if challenge != null and challenge.changed.is_connected(_state_changed):
		challenge.changed.disconnect(_state_changed)

func _label(value: String, font_size: int, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size.y = 96.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _box(Color("236d71") if primary else Color("204650"), 16))
	button.add_theme_stylebox_override("pressed", _box(Color("439c88"), 16))
	button.add_theme_stylebox_override("hover", _box(Color("2f7c7d"), 16))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 16))
	if callback.is_valid(): button.pressed.connect(callback)
	return button

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

func _panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.02, 0.10, 0.14, 0.91), 22))
	return panel

func _update_direction() -> void:
	challenge.set_direction((1 if _right_held else 0) - (1 if _left_held else 0))

func _state_changed(value: int) -> void:
	_left_held = false
	_right_held = false
	challenge.cancel_input()
	stage.suspend(value == Challenge.State.PAUSED)
	_title.text = challenge.phase_title()
	_instruction.text = challenge.instruction()
	_controls.visible = value in [Challenge.State.LINK, Challenge.State.CURRENT, Challenge.State.RESONANCE]
	_gauge.visible = _controls.visible
	_progress.visible = _controls.visible
	_pause.visible = _controls.visible
	_primary.visible = value in [Challenge.State.LINK, Challenge.State.RESONANCE]
	_primary.text = "按住调谐" if value == Challenge.State.LINK else "按住收紧 · 松手放松"
	_left.visible = value == Challenge.State.CURRENT
	_right.visible = value == Challenge.State.CURRENT
	_build_terminal_actions()
	if value == Challenge.State.SUCCESS: stage.show_success()
	_last_state = value
	_update_readout()

func set_settlement(value: bool, error: String = "", best: bool = false) -> void:
	saved = value
	save_error = error
	new_best = best
	if is_node_ready(): _build_terminal_actions(); _update_readout()

func _build_terminal_actions() -> void:
	for child: Node in _terminal_controls.get_children():
		_terminal_controls.remove_child(child)
		child.queue_free()
	_terminal_controls.visible = challenge.state in [Challenge.State.SUCCESS, Challenge.State.FAILED, Challenge.State.PAUSED]
	match challenge.state:
		Challenge.State.PAUSED:
			_terminal_controls.add_child(_button("继续鲸影挑战", func() -> void: resume_requested.emit(), true))
		Challenge.State.FAILED:
			_terminal_controls.add_child(_button("重新挑战", func() -> void: retry_requested.emit(), true))
			_terminal_controls.add_child(_button("返回钓点", func() -> void: exit_requested.emit()))
		Challenge.State.SUCCESS:
			if saved:
				_terminal_controls.add_child(_button("蓝鲸自然图鉴", func() -> void: notebook_requested.emit(), true))
				_terminal_controls.add_child(_button("再挑战一次", func() -> void: retry_requested.emit()))
				_terminal_controls.add_child(_button("返回钓点", func() -> void: exit_requested.emit()))
			else:
				_terminal_controls.add_child(_button("重试保存纪录", func() -> void: save_retry_requested.emit(), true))
				_terminal_controls.add_child(_button("结束 · 放弃未保存纪录", func() -> void: discard_requested.emit()))

func _process(_delta: float) -> void:
	if challenge == null: return
	_update_readout()

func _update_readout() -> void:
	_progress.value = challenge.progress()
	var band: Vector2 = challenge.gauge_band()
	# Explicit geometry avoids Control.set_anchor moving/pushing the opposite
	# anchor, which could turn the eight-pixel cursor into a wide filled region.
	_band.position = Vector2(_gauge.size.x * clampf(band.x, 0.0, 1.0),0.0)
	_band.size = Vector2(_gauge.size.x * (clampf(band.y, 0.0, 1.0) - clampf(band.x, 0.0, 1.0)),_gauge.size.y)
	_cursor.position = Vector2(_gauge.size.x * challenge.gauge_value() - 4.0,-5.0)
	_cursor.size = Vector2(8.0,_gauge.size.y + 10.0)
	var remaining: int = maxi(0, ceili(float(Challenge.PHASE_LIMITS.get(challenge.state, 0.0)) - challenge.phase_elapsed))
	match challenge.state:
		Challenge.State.LINK:
			_phase_status.text = "光环 %d / 3 · 当前蓄光 %d%%" % [challenge.links, roundi(challenge.link_time / Challenge.LINK_SECONDS * 100.0)]
			_detail.text = "绿带 42–66%% · 本阶段剩余 %d 秒" % remaining
		Challenge.State.CURRENT:
			_phase_status.text = "潮流同步 %.1f / 10 秒" % challenge.current_sync
			_detail.text = "亮点是你的航向，绿带是目标 · 剩余 %d 秒" % remaining
		Challenge.State.RESONANCE:
			_phase_status.text = "能量张力 %d%% · 共鸣 %.1f / 8 秒" % [roundi(challenge.tension * 100.0), challenge.resonance_sync]
			_detail.text = ("幻线正在失稳，立即调整张力" if challenge.danger_time > 0.5 else "绿带 38–65%% · 剩余 %d 秒" % remaining)
		Challenge.State.SUCCESS:
			_phase_status.text = "共鸣完成 %.1f 秒 · 26 米鲸影保持自由游动" % (float(challenge.record.get("duration_ms", 0)) / 1000.0)
			_detail.text = ("已保存鲸类独立纪录" + (" · 新的最快完成纪录" if new_best else "") + " · 不计入鱼获数量") if saved else "完成已确认，纪录尚未保存：" + (save_error if not save_error.is_empty() else "正在保存")
		Challenge.State.FAILED:
			_phase_status.text = "蓝鲸影未受影响，你可以重新连起幻线"
			_detail.text = "没有消耗鱼饵、金币或改变原有鱼获。"
		Challenge.State.PAUSED:
			_phase_status.text = "暂停前进度已保留"
			_detail.text = "返回后台会暂停，不会留下持续按住的操作。"

func _unhandled_key_input(event: InputEvent) -> void:
	if challenge == null: return
	if event.is_action("ui_left") or event.is_action("ui_right"):
		if event.is_action("ui_left"): _left_held = event.is_pressed()
		if event.is_action("ui_right"): _right_held = event.is_pressed()
		_update_direction()
		get_viewport().set_input_as_handled()
	elif event.is_action("ui_accept"):
		challenge.set_hold(event.is_pressed())
		get_viewport().set_input_as_handled()
