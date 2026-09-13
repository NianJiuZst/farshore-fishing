extends Control
const Catalog = preload("res://scripts/catalog.gd")
const Store = preload("res://scripts/save_store.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Scenery = preload("res://scripts/scenery_view.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const INK: Color = Color("244449")
const MUTED: Color = Color("6c827e")
const PAPER: Color = Color("f5f0e3")
const TEAL: Color = Color("266b70")
const CORAL: Color = Color("be6850")
var catalog: ContentCatalog = Catalog.new()
var store: SaveStore = Store.new()
var encounter: EncounterGenerator = Encounter.new()
var session: FishingSession = Session.new()
var scenery: SceneryView
var sound: FishingAudio
var region_id: String = "lake"
var spot_id: String = "lake_shore"
var bait_id: String = "worm"
var game_clock: float = 0.0
var weather: String = "clear"
var time_of_day: String = "day"
var _screen: String = ""
var _overlay: Control
var _page: VBoxContainer
var _title: Label
var _place: Label
var _condition: Label
var _wallet: Label
var _status: Label
var _hint: Label
var _action: Button
var _tension: ProgressBar
var _progress: ProgressBar
var _bars: VBoxContainer
var _charge: ProgressBar
var _toast: Label
var _toast_seconds: float = 0.0
var _list: VBoxContainer
var _search: String = ""
var _region_filter: String = "all"
var _discovery_filter: int = 0
var _sort_count: bool = false
var _last_record: Dictionary = {}
var _last_settlement: Dictionary = {}
var _last_committed_id: String = ""
var _save_ok: bool = false
var _content_ok: bool = false
var _safe: MarginContainer

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_content_ok = catalog.load_all(true)
	store.initialize()
	var saved: Dictionary = store.state
	var selection: Dictionary = saved.get("selection", {})
	region_id = str(selection.get("region_id", "lake"))
	spot_id = str(selection.get("spot_id", "lake_shore"))
	bait_id = str(selection.get("bait_id", "worm"))
	if not catalog.spots.has(spot_id):
		region_id = "lake"
		spot_id = "lake_shore"
	game_clock = float(saved.get("game_clock", 0.0))
	_apply_theme()
	sound = Audio.new()
	add_child(sound)
	sound.apply(saved.get("settings", {}))
	_build_fishing_screen()
	session.changed.connect(_session_changed)
	session.ended.connect(_fishing_ended)
	session.cue.connect(sound.cue)
	_refresh_location()
	_show_home()
	get_viewport().size_changed.connect(_safe_area)
	_safe_area()

func _apply_theme() -> void:
	var style: Theme = Theme.new()
	var chinese_font: FontFile = load("res://assets/fonts/NotoSansCJK-Regular.ttc")
	chinese_font.set_face_index(0, 2)
	style.default_font = chinese_font
	style.default_font_size = 24
	style.set_color("font_color", "Label", INK)
	style.set_color("font_color", "Button", INK)
	style.set_color("font_hover_color", "Button", TEAL)
	style.set_color("font_pressed_color", "Button", PAPER)
	style.set_color("font_disabled_color", "Button", Color("97a5a0"))
	style.set_stylebox("normal", "Button", _box(Color("e7e6d8"), 15))
	style.set_stylebox("hover", "Button", _box(Color("dde8dc"), 15))
	style.set_stylebox("pressed", "Button", _box(TEAL, 15))
	style.set_stylebox("disabled", "Button", _box(Color("ede9de"), 15))
	style.set_stylebox("focus", "Button", _box(Color(0,0,0,0),15,TEAL,2))
	style.set_stylebox("normal", "LineEdit", _box(Color("e6e7dc"),12))
	style.set_color("font_color", "LineEdit", INK)
	style.set_color("font_placeholder_color", "LineEdit", MUTED)
	style.set_color("caret_color", "LineEdit", TEAL)
	style.set_constant("separation", "VBoxContainer", 14)
	style.set_constant("separation", "HBoxContainer", 12)
	theme = style

func _box(color: Color, radius: int = 16, border: Color = Color(0,0,0,0), width: int = 0) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = color
	b.corner_radius_top_left = radius
	b.corner_radius_top_right = radius
	b.corner_radius_bottom_left = radius
	b.corner_radius_bottom_right = radius
	b.content_margin_left = 18
	b.content_margin_right = 18
	b.content_margin_top = 12
	b.content_margin_bottom = 12
	b.border_color = border
	b.set_border_width_all(width)
	return b

func _text(value: String, size_px: int = 24, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = value
	button.custom_minimum_size.y = 96
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if primary:
		button.add_theme_stylebox_override("normal", _box(TEAL, 16))
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_stylebox_override("hover", _box(TEAL.lightened(0.1),16))
	button.pressed.connect(callback)
	return button

func _build_fishing_screen() -> void:
	scenery = Scenery.new()
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scenery.session = session
	add_child(scenery)
	_safe = MarginContainer.new()
	_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_safe)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_PASS
	_safe.add_child(layout)
	var top_panel: PanelContainer = PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _box(Color(0.96,0.95,0.89,0.93),20))
	layout.add_child(top_panel)
	var top: VBoxContainer = VBoxContainer.new()
	top.add_theme_constant_override("separation", 2)
	top_panel.add_child(top)
	var heading: HBoxContainer = HBoxContainer.new()
	top.add_child(heading)
	_place = _text("雾林湖",32)
	heading.add_child(_place)
	var pause_button: Button = _button("暂停",_show_pause)
	pause_button.custom_minimum_size = Vector2(112,96)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	heading.add_child(pause_button)
	_condition = _text("",21,MUTED)
	top.add_child(_condition)
	var fill: Control = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(fill)
	_toast = _text("",23,PAPER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_stylebox_override("normal",_box(Color(0.05,0.18,0.20,0.85),16))
	_toast.visible = false
	layout.add_child(_toast)
	var bottom: PanelContainer = PanelContainer.new()
	bottom.add_theme_stylebox_override("panel",_box(Color(0.96,0.94,0.88,0.97),22))
	layout.add_child(bottom)
	var controls: VBoxContainer = VBoxContainer.new()
	controls.add_theme_constant_override("separation",8)
	bottom.add_child(controls)
	_status = _text("沿着水声，慢慢开始",28)
	controls.add_child(_status)
	_hint = _text("长按蓄力，松手抛竿",20,MUTED)
	controls.add_child(_hint)
	_charge = _bar(Color("d4a266"))
	_charge.visible = false
	controls.add_child(_charge)
	_bars = VBoxContainer.new()
	_bars.add_theme_constant_override("separation",5)
	controls.add_child(_bars)
	_tension = _bar(CORAL)
	_progress = _bar(TEAL)
	_bars.add_child(_tension)
	_bars.add_child(_progress)
	_bars.visible = false
	_action = _button("长按 · 抛竿",func() -> void: pass,true)
	_action.custom_minimum_size.y = 102
	_action.add_theme_font_size_override("font_size",29)
	_action.button_down.connect(_action_down)
	_action.button_up.connect(_action_up)
	_action.mouse_exited.connect(_action_cancel)
	controls.add_child(_action)
	var nav: HBoxContainer = HBoxContainer.new()
	controls.add_child(nav)
	for item: Array in [["旅行",_show_travel],["图鉴",_show_catalog],["收藏",_show_favorites],["行囊",_show_gear]]:
		var b: Button = _button(str(item[0]),item[1])
		b.custom_minimum_size.y = 96
		b.add_theme_font_size_override("font_size",23)
		nav.add_child(b)
	_wallet = _text("",19,MUTED)
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(_wallet)

func _bar(color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size.y = 18
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.add_theme_stylebox_override("background",_box(Color("d5dbce"),9))
	bar.add_theme_stylebox_override("fill",_box(color,9))
	return bar

func _safe_area() -> void:
	if _safe == null: return
	var top: int = 22
	var bottom: int = 20
	if OS.get_name() == "Android":
		var area: Rect2i = DisplayServer.get_display_safe_area()
		var screen: Vector2i = DisplayServer.screen_get_size()
		var scale_y: float = size.y / maxf(1.0, float(screen.y))
		top = maxi(top, ceili(float(area.position.y) * scale_y) + 8)
		bottom = maxi(bottom, ceili(float(screen.y-area.end.y) * scale_y) + 8)
	_safe.add_theme_constant_override("margin_left",20)
	_safe.add_theme_constant_override("margin_right",20)
	_safe.add_theme_constant_override("margin_top",top)
	_safe.add_theme_constant_override("margin_bottom",bottom)

func _process(delta: float) -> void:
	if not is_node_ready(): return
	session.step(delta)
	if session.state != Session.State.PAUSED:
		game_clock += delta
	_update_conditions()
	if _toast_seconds > 0:
		_toast_seconds -= delta
		_toast.visible = _toast_seconds > 0
	_charge.value = session.charge
	_tension.value = session.tension
	_progress.value = session.progress
	if session.state == Session.State.FIGHT:
		_status.text = "张力 %d%%  ·  收线 %d%%" % [roundi(session.tension*100),roundi(session.progress*100)]
		_hint.text = session.behavior_phase + ("  ⚠ 卸力！" if session.tension > 0.82 else "")
		_action.text = "松手 · 卸力" if session.reeling else "按住 · 收线"
	elif session.state == Session.State.CHARGING:
		_hint.text = "落点距离 %d%% · 松手投出" % roundi(session.charge*100)

func _update_conditions() -> void:
	time_of_day = "day" if int(game_clock/150.0)%2 == 0 else "dusk"
	weather = "clear" if int(game_clock/240.0)%2 == 0 else "rain"
	scenery.time_of_day = time_of_day
	scenery.weather = weather
	_condition.text = "%s · %s · %s" % ["日间" if time_of_day == "day" else "黄昏","晴" if weather == "clear" else "微雨",catalog.bait_name(bait_id)]

func _refresh_location() -> void:
	scenery.set_region(catalog.region(region_id),catalog.spots.get(spot_id,{}))
	_place.text = str(catalog.region(region_id).get("name","")) + " / " + str(catalog.spots.get(spot_id,{}).get("name",""))
	_update_wallet()

func _update_wallet() -> void:
	_wallet.text = "旅币 %d  ·  发现 %d / %d  ·  累计钓获 %d" % [int(store.state.get("currency",0)),store.discovered_count(),catalog.fish.size(),store.total_count()]

func _action_down() -> void:
	if _overlay != null or store.read_only or not _content_ok: return
	if session.state == Session.State.IDLE and store.state.get("pending_catches",{}).size() >= Store.MAX_PENDING:
		_show_pending()
		return
	session.press()

func _action_up() -> void:
	if session.state == Session.State.CHARGING:
		var gear_id: int = int(store.state.get("gear",0))
		var cast_power: float = clampf(session.charge,0.05,float(catalog.gear[gear_id].reach))
		var fish: Dictionary = encounter.generate(catalog,spot_id,bait_id,gear_id,cast_power,time_of_day,weather)
		if not fish.is_empty(): fish["game_time"] = game_clock
		if session.cast(fish,catalog.gear[gear_id]):
			store.begin_session(session.session_id)
		else:
			_toast_message("这个落点暂时没有合适的鱼。换个抛竿距离、钓点或装备试试")
	session.release()

func _action_cancel() -> void:
	# Pointer leaving the action region cancels charging/reeling; it never leaves a held input behind.
	session.cancel_input()

func _session_changed(value: int) -> void:
	_charge.visible = value == Session.State.CHARGING
	_bars.visible = value == Session.State.FIGHT
	_action.disabled = value in [Session.State.CASTING,Session.State.WAITING,Session.State.NIBBLE,Session.State.CAUGHT,Session.State.ESCAPED,Session.State.PAUSED]
	match value:
		Session.State.IDLE:
			_status.text = "沿着水声，慢慢开始"
			_hint.text = "长按蓄力，松手抛竿 · " + catalog.bait_name(bait_id)
			_action.text = "长按 · 抛竿"
		Session.State.CHARGING:
			_status.text = "选择这一竿的距离"
			_action.text = "松手 · 投出"
		Session.State.CASTING:
			_status.text = "鱼线划过水面"
			_hint.text = "落点会影响能遇见的鱼群"
			_action.text = "正在抛竿…"
		Session.State.WAITING:
			_status.text = "听水，等一个小小的信号"
			_hint.text = "浮漂轻动是试探，明显下沉后再提竿"
			_action.text = "等待咬钩…"
		Session.State.NIBBLE:
			_status.text = "有鱼在试探"
			_hint.text = "再耐心一点，准备提竿"
			_action.text = "轻微试探…"
		Session.State.BITE:
			_status.text = "咬钩了！"
			_hint.text = "现在点击，提起鱼竿"
			_action.text = "点击 · 提竿！"
		Session.State.FIGHT:
			_action.text = "按住 · 收线"
		Session.State.PAUSED:
			_status.text = "旅程已暂停"
			_hint.text = "鱼、张力与计时保持原位"

func _fishing_ended(success: bool, record: Dictionary) -> void:
	var active_state: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	if str(record.get("session_id", "")) != session.session_id: return
	if success and active_state != Session.State.CAUGHT: return
	if not success and active_state != Session.State.ESCAPED: return
	if success:
		_last_record = record
		_save_ok = false
		_settle()
	else:
		store.abandon_session(session.session_id)
		sound.cue("escape")
		_open_page("escape","把这次相遇留给水面",_finish_result)
		_page.add_child(_text(session.escape_reason,27))
		_page.add_child(_text("逃脱不会增加钓获数，也不会消耗鱼饵。下一竿随时可以开始。",22,MUTED))
		_page.add_child(_button("再试一竿",_finish_result,true))

func _settle() -> void:
	if _last_record.is_empty(): return
	if str(_last_record.get("catch_id", "")) == _last_committed_id:
		_save_ok = true
		_show_result()
		return
	_last_settlement = store.settle_catch(_last_record)
	_save_ok = bool(_last_settlement.get("ok",false))
	if _save_ok:
		_last_committed_id = str(_last_record.catch_id)
		sound.cue("catch")
		_update_wallet()
	_show_result()

func _open_page(id: String, heading: String, back: Callable = Callable()) -> void:
	if _overlay != null:
		_overlay.queue_free()
		session.cancel_input()
	if session.state != Session.State.PAUSED:
		session.pause()
	sound.suspend(true)
	_screen = id
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02,0.09,0.11,0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",20)
	margin.add_theme_constant_override("margin_right",20)
	margin.add_theme_constant_override("margin_top",maxi(30,_safe.get_theme_constant("margin_top")))
	margin.add_theme_constant_override("margin_bottom",maxi(28,_safe.get_theme_constant("margin_bottom")))
	_overlay.add_child(margin)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_box(PAPER,23))
	margin.add_child(panel)
	var outer: VBoxContainer = VBoxContainer.new()
	panel.add_child(outer)
	var head: HBoxContainer = HBoxContainer.new()
	outer.add_child(head)
	_title = _text(heading,31)
	head.add_child(_title)
	var close: Button = _button("返回",back if back.is_valid() else _close_page)
	close.custom_minimum_size = Vector2(98,96)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(close)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation",18)
	scroll.add_child(_page)

func _close_page() -> void:
	if _screen == "result" and (not _save_ok or store.state.get("pending_catches",{}).has(str(_last_record.get("catch_id","")))):
		_toast_message("请先出售、放生，或保存失败时重试")
		return
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_screen = ""
	session.resume()
	sound.suspend(false)
	_update_wallet()

func _show_home() -> void:
	_open_page("home","远岸钓记")
	_page.add_child(_text("把世界，钓成一本旅行手册",36))
	_page.add_child(_text("风从远岸来，水里藏着新的相遇。\n4 处水域 · 32 种真实鱼 · 完全离线",24,MUTED))
	_page.add_child(_scene_picture("res://assets/scenery/lake.png",320))
	_page.add_child(_button("继续我的旅程",_close_page,true))
	_page.add_child(_text("第一竿\n1  长按蓄力，松手抛竿\n2  浮漂明显下沉时，点击提竿\n3  按住收线，张力太高就松手\n4  成功后出售或放生，历史纪录一直保留",24))
	_page.add_child(_button("声音、震动与存档说明",_show_settings))
	if not store.status_message.is_empty(): _page.add_child(_text(store.status_message,23,CORAL))
	if not _content_ok:
		_page.add_child(_text("内容校验失败，已暂停游戏以保护纪录：\n"+"\n".join(catalog.errors),23,CORAL))
	if store.read_only:
		_page.add_child(_text("存档受到保护：" + store.error_message + "\n当前不能钓鱼或覆盖存档，请先保留文件并联系开发者。",24,CORAL))
	if not store.state.get("pending_catches",{}).is_empty():
		_page.add_child(_button("处理上次已保存的钓获",_show_pending))

func _show_pause() -> void:
	var active_state: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	if active_state == Session.State.CAUGHT and not _last_record.is_empty():
		_show_result()
		return
	if active_state == Session.State.ESCAPED:
		_finish_result()
	_open_page("pause","停一会儿，风景还在")
	_page.add_child(_text("当前鱼与钓鱼进度保持不变。\n切到后台时也会暂停，回来后由你决定继续。",26))
	_page.add_child(_button("继续钓鱼",_close_page,true))
	_page.add_child(_button("设置",_show_settings))
	_page.add_child(_button("旅行手册",_show_catalog))
	_page.add_child(_button("结束这一竿，回到钓点",_abandon_round))
	_page.add_child(_button("退出游戏",_exit_game))

func _abandon_round() -> void:
	if not _last_record.is_empty() and not _save_ok:
		_show_result()
		return
	store.abandon_session(session.session_id)
	session.reset()
	_close_page()

func _exit_game() -> void:
	if not _last_record.is_empty() and not _save_ok:
		_show_result()
		return
	_save_selection()
	get_tree().quit()

func _show_travel() -> void:
	_open_page("travel","下一段旅程")
	_page.add_child(_text("发现新物种，攒下一段路费。所有时间与天气都会在游戏里流转。",22,MUTED))
	for region: Dictionary in catalog.regions:
		var rid: String = str(region.region_id)
		_page.add_child(_scene_picture(str(region.scene),220))
		_page.add_child(_text(str(region.name) + "  " + str(region.subtitle),28))
		_page.add_child(_text(str(region.description),22,MUTED))
		var unlocked: bool = rid in store.state.get("unlocked_regions",[])
		if not unlocked:
			var need: int = int(region.unlock_count)
			var cost: int = int(region.unlock_cost)
			var unlock: Button = _button("解锁旅程 · %d 种发现 + %d 旅币" % [need,cost],_unlock_region.bind(rid))
			unlock.disabled = store.discovered_count()<need or int(store.state.currency)<cost
			_page.add_child(unlock)
		else:
			for sid: String in region.spots:
				var spot: Dictionary = catalog.spots[sid]
				var min_gear: int = int(spot.min_gear)
				var label: String = str(spot.name) + "  ·  " + str(spot.depth_min_m) + "–" + str(spot.depth_max_m) + " m"
				if int(store.state.gear)<min_gear: label += "  需" + str(catalog.gear[min_gear].name)
				var go: Button = _button(label,_choose_spot.bind(rid,sid))
				go.disabled = int(store.state.gear)<min_gear
				_page.add_child(go)
				_page.add_child(_text(str(spot.habitat),20,MUTED))

func _unlock_region(id: String) -> void:
	var region: Dictionary = catalog.region(id)
	var candidate: Dictionary = store.state.duplicate(true)
	if id in candidate.unlocked_regions or store.discovered_count()<int(region.unlock_count) or int(candidate.currency)<int(region.unlock_cost): return
	candidate.currency = int(candidate.currency)-int(region.unlock_cost)
	candidate.unlocked_regions.append(id)
	if _commit(candidate): _show_travel()

func _choose_spot(rid: String,sid: String) -> void:
	if _active_round():
		_toast_message("这一竿还在进行。先继续钓鱼，或在暂停页结束这一竿")
		_show_pause()
		return
	var previous_region: String = region_id
	var previous_spot: String = spot_id
	region_id = rid
	spot_id = sid
	if _save_selection():
		_refresh_location()
		_close_page()
		_toast_message(str(catalog.spots[sid].cast_hint))
	else:
		region_id = previous_region
		spot_id = previous_spot

func _active_round() -> bool:
	var value: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	return value not in [Session.State.IDLE,Session.State.CAUGHT,Session.State.ESCAPED]

func _show_gear() -> void:
	_open_page("gear","行囊与鱼饵")
	_page.add_child(_text("旅币 %d · 基础鱼饵无限补给" % int(store.state.currency),25))
	for item: Dictionary in catalog.gear:
		var id: int = int(item.id)
		_page.add_child(_text(str(item.name),28))
		_page.add_child(_text(str(item.description)+"\n可探水深：%d m" % int(item.max_depth_m),22,MUTED))
		var owned: bool = id in store.state.owned_gear
		var label: String = "已装备" if int(store.state.gear)==id else ("换上这套装备" if owned else "购买 · %d 旅币" % int(item.price))
		var action: Button = _button(label,_equip.bind(id))
		action.disabled = int(store.state.gear)==id or (not owned and int(store.state.currency)<int(item.price))
		_page.add_child(action)
	_page.add_child(_text("为下一次相遇挑选鱼饵",29))
	for bait: Dictionary in catalog.baits:
		_page.add_child(_button(("✓ " if bait.bait_id==bait_id else "")+str(bait.name)+" · 无限补给",_set_bait.bind(str(bait.bait_id))))
		_page.add_child(_text(str(bait.hint),22,MUTED))

func _equip(id: int) -> void:
	if id < int(catalog.spots[spot_id].min_gear):
		_toast_message("这处钓点需要更高阶装备，先旅行到较浅的钓点")
		return
	if _active_round():
		_toast_message("请在这一竿结束后更换装备")
		return
	var candidate: Dictionary = store.state.duplicate(true)
	if id not in candidate.owned_gear:
		var cost: int = int(catalog.gear[id].price)
		if int(candidate.currency)<cost: return
		candidate.currency = int(candidate.currency)-cost
		candidate.owned_gear.append(id)
	candidate.gear = id
	if _commit(candidate): _show_gear()

func _set_bait(id: String) -> void:
	if _active_round():
		_toast_message("这一竿的鱼饵与鱼已经确定，下次抛竿前再换")
		return
	var previous_bait: String = bait_id
	bait_id = id
	if _save_selection(): _show_gear()
	else: bait_id = previous_bait

func _show_catalog() -> void:
	_open_page("catalog","自然图鉴")
	_page.add_child(_text("已发现 %d / %d 种  ·  累计钓获 %d 条" % [store.discovered_count(),catalog.fish.size(),store.total_count()],24))
	var search: LineEdit = LineEdit.new()
	search.placeholder_text = "搜索中文名或学名"
	search.text = _search
	search.custom_minimum_size.y = 96
	search.text_changed.connect(func(value: String) -> void: _search=value; _fill_catalog())
	_page.add_child(search)
	var filters: HBoxContainer = HBoxContainer.new()
	_page.add_child(filters)
	var region_choice: OptionButton = OptionButton.new()
	region_choice.custom_minimum_size.y = 96
	region_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_choice.add_item("全部水域")
	for region: Dictionary in catalog.regions: region_choice.add_item(str(region.name))
	for i: int in range(catalog.regions.size()):
		if str(catalog.regions[i].region_id)==_region_filter: region_choice.select(i+1)
	region_choice.item_selected.connect(func(index: int) -> void: _region_filter="all" if index==0 else str(catalog.regions[index-1].region_id); _fill_catalog())
	filters.add_child(region_choice)
	var discovery: OptionButton = OptionButton.new()
	discovery.custom_minimum_size.y = 96
	for value: String in ["全部","已发现","待发现"]: discovery.add_item(value)
	discovery.select(_discovery_filter)
	discovery.item_selected.connect(func(index: int) -> void: _discovery_filter=index; _fill_catalog())
	filters.add_child(discovery)
	_page.add_child(_button("排序："+("累计数量" if _sort_count else "名称")+" · 点击切换",func() -> void: _sort_count=not _sort_count; _show_catalog()))
	_list = VBoxContainer.new()
	_page.add_child(_list)
	_fill_catalog()

func _fill_catalog() -> void:
	if _list == null: return
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var values: Array = catalog.fish.values()
	values.sort_custom(func(a: FishDefinition,b: FishDefinition) -> bool:
		if _sort_count:
			var ac: int = _count(a.species_id)
			var bc: int = _count(b.species_id)
			if ac != bc: return ac>bc
		return a.name.naturalnocasecmp_to(b.name)<0)
	var shown: int = 0
	for fish: FishDefinition in values:
		var known: bool = _count(fish.species_id)>0
		if _region_filter!="all" and _region_filter not in fish.regions(): continue
		if _discovery_filter==1 and not known: continue
		if _discovery_filter==2 and known: continue
		if not _search.is_empty() and not (_search in fish.name or _search.to_lower() in fish.scientific_name.to_lower()): continue
		shown += 1
		var row: HBoxContainer = HBoxContainer.new()
		_list.add_child(row)
		var image: TextureRect = _fish_image(fish, true, not known, 100)
		image.custom_minimum_size.x = 180
		image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(image)
		var text: String = fish.name + ("\n累计 %d 条" % _count(fish.species_id) if known else "\n待发现 · "+str(catalog.region(str(fish.regions()[0])).get("name","")))
		row.add_child(_button(text,_show_species.bind(fish.species_id)))
	if shown==0: _list.add_child(_text("没有符合条件的鱼，试试换个筛选",23,MUTED))

func _count(id: String) -> int:
	var stats: Dictionary = store.state.get("species_stats",{}).get(id,{})
	return int(stats.get("catch_count",0))

func _show_species(id: String) -> void:
	var fish: FishDefinition = catalog.fish[id]
	_open_page("species",fish.name,_show_catalog)
	var known: bool = _count(id)>0
	var art: TextureRect = _fish_image(fish,false,not known,330)
	_page.add_child(art)
	if known: _page.add_child(_button("放大查看插画",_show_zoom.bind(id)))
	_page.add_child(_text(fish.scientific_name,23,MUTED))
	_page.add_child(_text(fish.description,25))
	_page.add_child(_text("辨认线索："+fish.morphology,22,MUTED))
	var where: Array[String] = []
	for sid: String in fish.spots():
		where.append(str(catalog.region(str(catalog.spots[sid].region_id)).name)+" · "+str(catalog.spots[sid].name))
	_page.add_child(_text("去哪里寻找\n"+"\n".join(where),24))
	var preferred: String = "worm"
	var best: float = -1
	for bait: Dictionary in catalog.baits:
		var weight: float = fish.weight_for("bait_weights",str(bait.bait_id))
		if weight>best:
			preferred=str(bait.bait_id)
			best=weight
	_page.add_child(_text("鱼饵提示："+catalog.bait_name(preferred)+"\n体型、行为与出现倍率含游戏调校。",22,MUTED))
	_page.add_child(_text("累计成功钓获：%d 条" % _count(id),29))
	if known:
		var stats: Dictionary = store.state.species_stats[id]
		for pair: Array in [["首次钓获","first"],["最近钓获","last"],["最长个体","max_length"],["最重个体","max_weight"]]:
			_page.add_child(_text(str(pair[0])+"\n"+_record_text(stats.get(pair[1],{})),23))
		var favorite: bool = id in store.state.favorites
		_page.add_child(_button("移出我的收藏" if favorite else "收藏这个鱼种（最多 6 种）",_favorite.bind(id)))
	_page.add_child(_text("资料参考",24))
	for source: Dictionary in fish.raw.get("sources",[]):
		_page.add_child(_text(str(source.get("title",""))+"\n"+str(source.get("url","")),17,MUTED))

func _show_zoom(id: String) -> void:
	var fish: FishDefinition = catalog.fish[id]
	_open_page("zoom",fish.name+" · 插画",_show_species.bind(id))
	var art: TextureRect = _fish_image(fish,false,false,520)
	_page.add_child(art)
	_page.add_child(_text("完整轮廓与识别特征\n"+fish.morphology,25))
	_page.add_child(_text("插画为 AI 辅助生成并经开发校对的自然题材游戏美术，不能替代野外物种鉴定。",21,MUTED))

func _fish_image(fish: FishDefinition, thumbnail: bool, silhouette: bool, height: float) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	var path: String = fish.thumb if thumbnail else fish.art
	if ResourceLoader.exists(path): rect.texture=load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size.y = height
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if silhouette or not thumbnail:
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load("res://assets/fish_motion.gdshader")
		material.set_shader_parameter("silhouette", silhouette)
		rect.material = material
	return rect

func _scene_picture(path: String,height: float) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	if ResourceLoader.exists(path): rect.texture=load(path)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.custom_minimum_size.y=height
	rect.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return rect

func _record_text(record: Dictionary) -> String:
	if record.is_empty(): return "尚无纪录"
	var sid: String = str(record.get("spot_id",""))
	var rid: String = str(record.get("region_id",""))
	return "%s · %s\n%s / %s\n%s" % [_length(int(record.get("length_mm",0))),_weight(int(record.get("weight_g",0))),str(catalog.region(rid).get("name",rid)),str(catalog.spots.get(sid,{}).get("name",sid)),str(record.get("caught_at",""))]

func _length(mm: int) -> String:
	return "%.1f cm" % (mm/10.0)

func _weight(grams: int) -> String:
	return ("%.2f kg" % (grams/1000.0)) if grams>=1000 else ("%d g" % grams)

func _favorite(id: String) -> void:
	var candidate: Dictionary = store.state.duplicate(true)
	if id in candidate.favorites: candidate.favorites.erase(id)
	elif candidate.favorites.size()<6: candidate.favorites.append(id)
	else:
		_toast_message("收藏册已有 6 种鱼，先移出一种再添加")
		return
	if _commit(candidate): _show_species(id)

func _show_favorites() -> void:
	_open_page("favorites","我的收藏")
	_page.add_child(_text("把喜欢的相遇，留在这一页。\n收藏只引用真实纪录，不会增加钓获数量。",24,MUTED))
	var favorites: Array = store.state.get("favorites",[])
	if favorites.is_empty():
		_page.add_child(_text("还没有收藏。钓获新鱼后，在图鉴详情中点“收藏”。",27))
		_page.add_child(_button("打开图鉴",_show_catalog,true))
	for id: String in favorites:
		if not catalog.fish.has(id): continue
		var fish: FishDefinition = catalog.fish[id]
		_page.add_child(_fish_image(fish,true,false,180))
		_page.add_child(_button(fish.name+" · 累计 %d 条" % _count(id),_show_species.bind(id)))
		var stats: Dictionary = store.state.species_stats.get(id,{})
		_page.add_child(_text("最长纪录\n"+_record_text(stats.get("max_length",{})),22,MUTED))

func _show_result() -> void:
	var id: String = str(_last_record.get("species_id",""))
	if not catalog.fish.has(id): return
	var fish: FishDefinition = catalog.fish[id]
	_open_page("result","一段新的相遇")
	var flags: Array[String] = []
	if bool(_last_settlement.get("new_species",false)): flags.append("首次发现")
	if bool(_last_settlement.get("new_length",false)): flags.append("长度新纪录")
	if bool(_last_settlement.get("new_weight",false)): flags.append("重量新纪录")
	_page.add_child(_text(" · ".join(flags) if not flags.is_empty() else "又见到你了",25,CORAL))
	_page.add_child(_text(fish.name,38))
	_page.add_child(_text(fish.scientific_name,22,MUTED))
	var image: TextureRect = _fish_image(fish,false,false,220+float(_last_record.get("size_fraction",0.3))*180)
	var displayed_fraction: float = float(_last_record.get("size_fraction",0.3))
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var sized_row: HBoxContainer = HBoxContainer.new()
	var spacer_left: Control = Control.new()
	var spacer_right: Control = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.custom_minimum_size.x = lerpf(330.0,590.0,displayed_fraction)
	sized_row.add_child(spacer_left)
	sized_row.add_child(image)
	sized_row.add_child(spacer_right)
	_page.add_child(sized_row)
	_page.add_child(_text(_length(int(_last_record.length_mm))+"   /   "+_weight(int(_last_record.weight_g)),35))
	_page.add_child(_text(str(_last_record.get("size_class","标准"))+"个体 · "+str(catalog.spots[spot_id].name),24,MUTED))
	_page.add_child(_text("同种鱼按个体大小缩放展示 · 尺寸以数字为准",18,MUTED))
	if not _save_ok:
		_page.add_child(_text("保存未成功："+str(_last_settlement.get("error",store.error_message))+"\n本次钓获暂存于内存，还没有重复发放奖励。请重试保存，不要退出。",24,CORAL))
		_page.add_child(_button("重试保存",_settle,true))
		return
	_page.add_child(_text("已保存 · 累计 %d 条 · 钓获奖励 +%d 旅币" % [_count(id),int(_last_record.reward)],23,TEAL))
	_page.add_child(_button("出售 · +%d 旅币" % int(_last_record.sale_value),_dispose_result.bind("sold"),true))
	_page.add_child(_button("放生 · +8 旅币",_dispose_result.bind("released")))
	_page.add_child(_text("出售和放生都保留图鉴、累计数量与个人纪录",21,MUTED))

func _dispose_result(action: String) -> void:
	if _last_record.is_empty() or not _save_ok: return
	var result: Dictionary = store.dispose_catch(str(_last_record.catch_id),action)
	if bool(result.get("ok",false)):
		_finish_result()
		_toast_message("钓获已处理，图鉴纪录已保留")
	else:
		_page.add_child(_text("保存处理结果失败："+str(result.get("error",store.error_message))+"。请再次点击重试。",23,CORAL))

func _finish_result() -> void:
	_screen = ""
	_last_record = {}
	_save_ok = true
	session.reset()
	_close_page()
	_save_selection()

func _show_pending() -> void:
	_open_page("pending","尚未处理的钓获")
	var pending: Dictionary = store.state.get("pending_catches",{})
	if pending.is_empty():
		_page.add_child(_text("所有钓获都已妥善处理",26))
	for id: String in pending:
		var record: Dictionary = pending[id]
		var fish: FishDefinition = catalog.fish.get(str(record.species_id))
		_page.add_child(_text((fish.name if fish else str(record.species_id))+"\n"+_record_text(record),25))
		_page.add_child(_button("出售 · +%d 旅币" % int(record.get("sale_value",0)),_dispose_pending.bind(id,"sold")))
		_page.add_child(_button("放生 · +8 旅币",_dispose_pending.bind(id,"released")))

func _dispose_pending(id: String,action: String) -> void:
	var result: Dictionary = store.dispose_catch(id,action)
	if bool(result.get("ok",false)): _show_pending()
	else: _page.add_child(_text(str(result.get("error",store.error_message)),24,CORAL))

func _show_settings() -> void:
	_open_page("settings","设置与旅程说明")
	var settings: Dictionary = store.state.get("settings",{})
	for pair: Array in [["sound","声音"],["vibration","震动"]]:
		var key: String = str(pair[0])
		var label: String = str(pair[1])
		_page.add_child(_button(label+"："+("开" if bool(settings.get(key,true)) else "关"),_toggle_setting.bind(key)))
	_page.add_child(_text("总音量",25))
	var volume: HSlider = HSlider.new()
	volume.min_value=0.0
	volume.max_value=1.0
	volume.step=0.05
	volume.value=float(settings.get("volume",0.6))
	volume.custom_minimum_size.y=70
	volume.drag_ended.connect(func(changed_value: bool) -> void:
		if changed_value:
			var candidate: Dictionary=store.state.duplicate(true)
			candidate.settings.volume=volume.value
			if _commit(candidate): sound.apply(candidate.settings))
	_page.add_child(volume)
	_page.add_child(_text("游戏内时间",28))
	_page.add_child(_text("日间与黄昏每 2 分 30 秒切换；晴与微雨每 4 分钟切换。暂停时停止流转，不需要在现实中的特定时间上线。",23,MUTED))
	_page.add_child(_text("离线存档",28))
	_page.add_child(_text("所有纪录只属于这份本地存档。卸载、清除应用数据会丢失进度。正常覆盖更新请保持相同包名与签名。每次钓获、出售/放生、购买、解锁与收藏都会立即保存。",23,MUTED))
	_page.add_child(_button("处理已保存但未出售/放生的鱼",_show_pending))
	_page.add_child(_text("远岸钓记 1.0.0\nGodot 4.6.3 · 离线单机 · 32 种自然图鉴\n鱼类与场景插画：AI 辅助生成并开发校对\n字体：Noto Sans CJK（SIL Open Font License）\n音效：本项目程序合成原创\nGodot Engine：MIT License",21,MUTED))
	_page.add_child(_button("查看引擎与字体许可",_show_licenses))

func _show_licenses() -> void:
	_open_page("licenses","开源许可",_show_settings)
	for path: String in ["res://data/GODOT_LICENSE.txt","res://data/FONT_LICENSE.txt"]:
		if FileAccess.file_exists(path): _page.add_child(_text(FileAccess.get_file_as_string(path),17,MUTED))

func _toggle_setting(key: String) -> void:
	var candidate: Dictionary=store.state.duplicate(true)
	candidate.settings[key]=not bool(candidate.settings.get(key,true))
	if _commit(candidate):
		sound.apply(candidate.settings)
		_show_settings()

func _save_selection() -> bool:
	var candidate: Dictionary=store.state.duplicate(true)
	candidate.selection={"region_id":region_id,"spot_id":spot_id,"bait_id":bait_id}
	candidate.game_clock=game_clock
	return _commit(candidate)

func _commit(candidate: Dictionary) -> bool:
	if store.commit_state(candidate):
		_update_wallet()
		return true
	_toast_message("保存失败："+store.error_message)
	if _page != null and is_instance_valid(_page): _page.add_child(_text("保存失败："+store.error_message,23,CORAL))
	return false

func _toast_message(value: String) -> void:
	_toast.text=value
	_toast.visible=true
	_toast_seconds=5.0

func _notification(what: int) -> void:
	if not is_node_ready(): return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		session.cancel_input()
		session.pause()
		sound.suspend(true)
		_save_selection()
		if _overlay==null: call_deferred("_show_pause")
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _screen == "result": _show_result()
		else: _show_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()

func _handle_back() -> void:
	match _screen:
		"": _show_pause()
		"species","zoom": _show_catalog()
		"result": _show_result()
		"escape": _finish_result()
		_: _close_page()
