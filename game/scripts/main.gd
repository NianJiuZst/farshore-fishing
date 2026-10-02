extends Control
const Catalog = preload("res://scripts/catalog.gd")
const Store = preload("res://scripts/save_store.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Scenery = preload("res://scripts/scenery_view.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const INK: Color = Color("244449")
const NAVY: Color = Color("102f3b")
const GOLD: Color = Color("ab742b")
const Art = preload("res://scripts/ui_art.gd")
const IconButton=preload("res://scripts/icon_action.gd")
const Ruler = preload("res://scripts/measure_ruler.gd")
const MUTED: Color = Color("587872")
const PAPER: Color = Color("f5f0e3")
const TEAL: Color = Color("327d76")
const CORAL: Color = Color("edb078")
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
var _weather_icon: Control
var _spot_label: Label
var _nav_rail: VBoxContainer
var _bait_control: Button
var _tension_label: Label
var _progress_label: Label
var _page_footer: VBoxContainer
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
var _list: GridContainer
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
var _collection: Label
var _bait_label: Label
var _page_notice: Label

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_content_ok = catalog.load_all(true)
	var icon_errors: Array[String]=Art.validate_assets()
	if not icon_errors.is_empty():
		catalog.errors.append_array(icon_errors)
		_content_ok=false
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
	if store.read_only or not _content_ok: _show_home()
	else: _session_changed(Session.State.IDLE)
	get_viewport().size_changed.connect(_safe_area)
	_safe_area()

func _apply_theme() -> void:
	var style: Theme=Theme.new()
	var chinese_font: FontFile=load("res://assets/fonts/NotoSansCJK-Regular.ttc")
	chinese_font.set_face_index(0,2)
	style.default_font=chinese_font
	style.default_font_size=24
	style.set_color("font_color","Label",INK)
	for type_name: String in ["Button","OptionButton","LineEdit"]:
		for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]: style.set_stylebox(state,type_name,StyleBoxEmpty.new())
		style.set_color("font_color",type_name,INK)
		style.set_color("font_hover_color",type_name,TEAL)
		style.set_color("font_pressed_color",type_name,GOLD)
		style.set_color("font_disabled_color",type_name,Color("8c9e95"))
	style.set_color("font_placeholder_color","LineEdit",MUTED)
	style.set_color("caret_color","LineEdit",TEAL)
	style.set_constant("separation","VBoxContainer",14)
	style.set_constant("separation","HBoxContainer",12)
	style.set_stylebox("panel","PopupMenu",_box(Color("edf1e5"),0))
	style.set_color("font_color","PopupMenu",INK)
	style.set_constant("v_separation","PopupMenu",30)
	var dropdown_arrow: Texture2D=Art.scaled_texture("arrow",24,true)
	if dropdown_arrow!=null:style.set_icon("arrow","OptionButton",dropdown_arrow)
	theme=style

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
	label.add_theme_color_override("font_outline_color",Color("21454b") if color.get_luminance()>0.55 else Color(0.96,0.98,0.91,0.82))
	label.add_theme_constant_override("outline_size",5 if color.get_luminance()>0.55 else 1)
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button: Button=IconButton.new()
	button.text=value
	button.custom_minimum_size.y=96
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.icon_kind=_action_symbol(value)
	button.label_color=GOLD if primary else INK
	button.add_theme_font_size_override("font_size",26 if primary else 24)
	button.pressed.connect(callback)
	return button

func _action_symbol(value: String) -> String:
	if "返回" in value: return "back"
	if "放" in value: return "release"
	if "出售" in value or "购买" in value or "带上" in value: return "coin"
	if "收藏" in value: return "heart"
	if "图鉴" in value or "记录" in value or "保存" in value or "插画" in value or "欣赏" in value: return "book"
	if "竿" in value or "装备" in value: return "rod"
	if "鱼饵" in value: return "lure"
	if "声音" in value or "音量" in value: return "sound"
	if "设置" in value or "震动" in value or "许可" in value: return "settings"
	if "旅" in value or "启程" in value: return "compass"
	return "arrow"

func _icon(kind: String, extent: float = 72) -> Control:
	var icon: Control = Art.new()
	icon.kind=kind
	icon.custom_minimum_size=Vector2(extent,extent)
	icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	return icon

func _card(_color: Color = Color.TRANSPARENT, margin_px: int = 18) -> PanelContainer:
	var card: PanelContainer=PanelContainer.new()
	var style: StyleBoxEmpty=StyleBoxEmpty.new()
	style.content_margin_left=margin_px
	style.content_margin_right=margin_px
	style.content_margin_top=margin_px
	style.content_margin_bottom=margin_px
	card.add_theme_stylebox_override("panel",style)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return card

func _section(value: String, detail: String = "") -> void:
	var row: HBoxContainer=HBoxContainer.new()
	row.add_child(_text(value,27,GOLD))
	if not detail.is_empty():
		var right: Label=_text(detail,20,MUTED)
		right.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(right)
	_page.add_child(row)

func _navigation(label: String, kind: String, callback: Callable) -> Button:
	var button: Button=_button(label,callback)
	button.custom_minimum_size=Vector2(110,120)
	button.icon_kind=kind
	button.stacked=true
	button.icon_extent=72
	button.label_color=Color.WHITE
	button.light_label=true
	button.add_theme_font_size_override("font_size",24)
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
	var top: HBoxContainer=HBoxContainer.new()
	top.add_theme_constant_override("separation",10)
	var top_glass: PanelContainer=_card(Color(0.035,0.13,0.17,0.88),10)
	layout.add_child(top_glass)
	top_glass.add_child(top)
	var heading: VBoxContainer=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation",0)
	heading.alignment=BoxContainer.ALIGNMENT_CENTER
	top.add_child(heading)
	_place=_text("雾林湖",31,Color.WHITE)
	_place.add_theme_color_override("font_shadow_color",NAVY)
	_place.add_theme_constant_override("shadow_offset_y",2)
	heading.add_child(_place)
	_spot_label=_text("",20,Color.WHITE)
	heading.add_child(_spot_label)
	var money: PanelContainer=_card(Color(0.05,0.17,0.21,0.9),8)
	money.size_flags_horizontal=Control.SIZE_SHRINK_END
	var money_row: HBoxContainer=HBoxContainer.new()
	money_row.add_theme_constant_override("separation",0)
	money.add_child(money_row)
	money_row.add_child(_icon("coin",40))
	_wallet=_text("120",27,Color.WHITE)
	_wallet.custom_minimum_size.x=60
	money_row.add_child(_wallet)
	top.add_child(money)
	var pause_button: Button=_button("暂停",_show_pause)
	pause_button.custom_minimum_size=Vector2(96,96)
	pause_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	pause_button.add_theme_font_size_override("font_size",23)
	pause_button.text="暂停"
	pause_button.icon_kind="pause"
	pause_button.stacked=true
	pause_button.icon_extent=53
	pause_button.label_color=Color.WHITE
	pause_button.light_label=true
	top.add_child(pause_button)
	var facts: HBoxContainer=HBoxContainer.new()
	layout.add_child(facts)
	_weather_icon=_icon("sun",42)
	facts.add_child(_weather_icon)
	_condition=_text("",22,Color("f7f6dd"))
	_condition.add_theme_color_override("font_shadow_color",NAVY)
	_condition.add_theme_constant_override("shadow_offset_y",2)
	var fact_style: StyleBoxFlat=_box(Color(0.04,0.16,0.20,0.80),12)
	fact_style.content_margin_left=10
	fact_style.content_margin_right=10
	fact_style.content_margin_top=4
	fact_style.content_margin_bottom=4

	facts.add_child(_condition)
	_collection=_text("",20,Color("fff1bb"))
	_collection.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	_collection.size_flags_horizontal=Control.SIZE_SHRINK_END
	_collection.custom_minimum_size.x=150
	_collection.autowrap_mode=TextServer.AUTOWRAP_OFF

	_collection.add_theme_color_override("font_shadow_color",NAVY)
	_collection.add_theme_constant_override("shadow_offset_y",2)
	facts.add_child(_collection)
	var field: Control=Control.new()
	field.size_flags_vertical=Control.SIZE_EXPAND_FILL
	field.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layout.add_child(field)
	var edge: VBoxContainer=VBoxContainer.new()
	_nav_rail=edge
	edge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	edge.offset_left=-110
	edge.offset_top=66
	edge.add_theme_constant_override("separation",16)
	field.add_child(edge)
	for item: Array in [["旅行","compass",_show_travel],["图鉴","book",_show_catalog],["收藏","heart",_show_favorites],["行囊","bag",_show_gear]]:
		edge.add_child(_navigation(str(item[0]),str(item[1]),item[2]))
	_toast=_text("",23,PAPER)
	_toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

	_toast.visible=false
	layout.add_child(_toast)
	_status=_text("准备抛竿",30,PAPER)
	_status.add_theme_color_override("font_shadow_color",NAVY)
	_status.add_theme_constant_override("shadow_offset_y",2)
	_status.visible=false
	layout.add_child(_status)
	_hint=_text("长按蓄力，松手抛竿",21,Color("cbe4d9"))
	layout.add_child(_hint)
	_charge=_bar(GOLD)
	_charge.visible=false
	layout.add_child(_charge)
	_bars=VBoxContainer.new()
	_bars.custom_minimum_size.x=370
	_bars.size_flags_horizontal=Control.SIZE_SHRINK_END
	_bars.add_theme_constant_override("separation",8)
	layout.add_child(_bars)
	_tension=_bar(CORAL)
	_progress=_bar(TEAL)
	for pair: Array in [["张力",_tension],["收线",_progress]]:
		var row: HBoxContainer=HBoxContainer.new()
		var caption: Label=_text(str(pair[0]),20,Color.WHITE)
		caption.custom_minimum_size.x=140
		caption.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		row.add_child(caption)
		var gauge: ProgressBar=pair[1]
		gauge.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		gauge.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(gauge)
		_bars.add_child(row)
		if pair[0]=="张力":_tension_label=caption
		else:_progress_label=caption
	var danger_mark: ColorRect=ColorRect.new()
	danger_mark.color=Color("dc6654")
	danger_mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	danger_mark.anchor_left=0.82
	danger_mark.anchor_right=0.82
	danger_mark.anchor_bottom=1.0
	danger_mark.offset_right=3
	_tension.add_child(danger_mark)
	_bars.visible=false
	var action_row: HBoxContainer=HBoxContainer.new()
	layout.add_child(action_row)
	var bait: Button=_navigation("鱼饵",bait_id,_show_gear)
	_bait_control=bait
	bait.custom_minimum_size=Vector2(112,118)
	bait.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	action_row.add_child(bait)
	var action_space: Control=Control.new()
	action_space.mouse_filter=Control.MOUSE_FILTER_IGNORE
	action_space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	action_row.add_child(action_space)
	_action=_button("抛竿",func() -> void: pass,true)
	_action.custom_minimum_size=Vector2(210,180)
	_action.size_flags_horizontal=Control.SIZE_SHRINK_END
	_action.stacked=true
	_action.icon_extent=114
	_action.icon_kind="rod"
	_action.label_color=Color.WHITE
	_action.light_label=true
	_action.add_theme_font_size_override("font_size",38)
	_action.button_down.connect(_action_down)
	_action.button_up.connect(_action_up)
	_action.mouse_exited.connect(_action_cancel)
	action_row.add_child(_action)

func _bar(color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size.y = 18
	bar.show_percentage = false
	bar.max_value = 1.0
	var background: StyleBoxFlat=_box(Color(0.12,0.26,0.28,0.45),9)
	var fill: StyleBoxFlat=_box(color,9)
	for style: StyleBoxFlat in [background,fill]:
		style.content_margin_top=0
		style.content_margin_bottom=0
		style.content_margin_left=0
		style.content_margin_right=0
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
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
		if is_instance_valid(_page_notice): _page_notice.visible=_toast_seconds>0 and not _page_notice.text.is_empty()
	_charge.value = session.charge
	_tension.value = session.tension
	_progress.value = session.progress
	if session.state == Session.State.FIGHT:
		_status.text = "张力 %d%%  ·  收线 %d%%" % [roundi(session.tension*100),roundi(session.progress*100)]
		_tension_label.text="张力 %d%%" % roundi(session.tension*100)
		_progress_label.text="收线 %d%%" % roundi(session.progress*100)
		_tension_label.add_theme_color_override("font_color",Color("ff9276") if session.tension>0.82 else Color.WHITE)
		_hint.text="张力过高，松手卸力" if session.tension>0.82 else "按住收线，松手卸力"
		_action.text = "卸力" if session.reeling else "收线"
	elif session.state == Session.State.CHARGING:
		_hint.text = "落点距离 %d%% · 松手投出" % roundi(session.charge*100)

func _update_conditions() -> void:
	time_of_day = "day" if int(game_clock/150.0)%2 == 0 else "dusk"
	weather = "clear" if int(game_clock/240.0)%2 == 0 else "rain"
	scenery.time_of_day = time_of_day
	scenery.weather = weather
	_weather_icon.kind="rain" if weather=="rain" else ("dusk" if time_of_day=="dusk" else "sun")
	_condition.text = "%s  ·  %s" % ["晴" if weather == "clear" else "微雨","日间" if time_of_day == "day" else "黄昏"]

func _refresh_location() -> void:
	scenery.set_region(catalog.region(region_id),catalog.spots.get(spot_id,{}))
	_place.text = str(catalog.region(region_id).get("name",""))
	_spot_label.text=str(catalog.spots.get(spot_id,{}).get("name",""))
	_bait_control.icon_kind=bait_id
	_update_wallet()

func _update_wallet() -> void:
	_wallet.text = str(int(store.state.get("currency",0)))
	if _collection: _collection.text="图鉴 %d / %d" % [store.discovered_count(),catalog.fish.size()]

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
	_action.icon_kind="reel" if value==Session.State.FIGHT else ("hook" if value==Session.State.BITE else "rod")
	_nav_rail.visible=value!=Session.State.FIGHT
	_charge.visible = value == Session.State.CHARGING
	_bars.visible = value == Session.State.FIGHT
	_action.disabled = value in [Session.State.CASTING,Session.State.WAITING,Session.State.NIBBLE,Session.State.CAUGHT,Session.State.ESCAPED,Session.State.PAUSED]
	match value:
		Session.State.IDLE:
			_status.text = "准备抛竿"
			_hint.text = "长按蓄力，松手抛竿 · " + catalog.bait_name(bait_id)
			_action.text = "抛竿"
		Session.State.CHARGING:
			_status.text = "蓄力中"
			_action.text = "投出"
		Session.State.CASTING:
			_status.text = "正在抛竿"
			_hint.text = "落点会影响能遇见的鱼群"
			_action.text = "抛竿中"
		Session.State.WAITING:
			_status.text = "等待咬钩"
			_hint.text = "浮漂轻动是试探，明显下沉后再提竿"
			_action.text = "静候咬钩"
		Session.State.NIBBLE:
			_status.text = "有鱼在试探"
			_hint.text = "再耐心一点，准备提竿"
			_action.text = "试探"
		Session.State.BITE:
			_status.text = "咬钩了！"
			_hint.text = "现在点击，提起鱼竿"
			_action.text = "提竿！"
		Session.State.FIGHT:
			_action.text = "收线"
		Session.State.PAUSED:
			_status.text = "已暂停"
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
		_open_page("escape","鱼已逃脱",_finish_result)
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
		remove_child(_overlay)
		_overlay.queue_free()
	session.cancel_input()
	if session.state != Session.State.PAUSED: session.pause()
	sound.suspend(true)
	_screen=id
	_overlay=Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim: ColorRect=ColorRect.new()
	dim.color=Color("edf2e5")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var atmospheric: TextureRect=_scene_picture(str(catalog.spots.get(spot_id,{}).get("scene",catalog.region(region_id).get("scene",""))),0)
	atmospheric.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmospheric.modulate=Color(1,1,1,0.14)
	atmospheric.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(atmospheric)
	var margin: MarginContainer=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",28)
	margin.add_theme_constant_override("margin_right",28)
	margin.add_theme_constant_override("margin_top",maxi(24,_safe.get_theme_constant("margin_top")))
	margin.add_theme_constant_override("margin_bottom",maxi(24,_safe.get_theme_constant("margin_bottom")))
	_overlay.add_child(margin)
	var outer: VBoxContainer=VBoxContainer.new()
	outer.add_theme_constant_override("separation",12)
	margin.add_child(outer)
	var head: HBoxContainer=HBoxContainer.new()
	outer.add_child(head)
	var title_box: VBoxContainer=VBoxContainer.new()
	title_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation",0)
	head.add_child(title_box)
	_title=_text(heading,37,INK)
	title_box.add_child(_title)
	var close: Button=_button("返回",back if back.is_valid() else _close_page)
	close.custom_minimum_size=Vector2(108,96)
	close.stacked=true
	close.icon_extent=50
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	head.add_child(close)
	var line: ColorRect=ColorRect.new()
	line.color=Color(0.30,0.47,0.44,0.30)
	line.custom_minimum_size.y=1
	outer.add_child(line)
	_page_notice=_text("",21,GOLD)
	_page_notice.visible=false

	outer.add_child(_page_notice)
	var scroll: ScrollContainer=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_page=VBoxContainer.new()
	_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation",18)
	scroll.add_child(_page)
	_page_footer=VBoxContainer.new()
	_page_footer.visible=false
	outer.add_child(_page_footer)

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
	_open_page("home","玩法说明")
	_page.add_child(_text("%d 处水域 · %d 种真实鱼 · 完全离线" % [catalog.regions.size(),catalog.fish.size()]+"",24,MUTED))
	_page.add_child(_scene_picture("res://assets/scenery/lake.png",320))
	_page.add_child(_button("开始钓鱼",_close_page,true))
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
	_open_page("pause","暂停")
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
	_open_page("travel","旅行")
	_page.add_child(_text("%d 处水域  /  %d 个钓点  ·  选择水域与钓点" % [catalog.regions.size(),catalog.spots.size()],21,MUTED))
	for region: Dictionary in catalog.regions:
		var rid: String=str(region.region_id)
		var unlocked: bool=rid in store.state.get("unlocked_regions",[])
		var card: PanelContainer=_card(Color("1b4550"),0)
		card.clip_contents=true
		_page.add_child(card)
		var contents: VBoxContainer=VBoxContainer.new()
		contents.add_theme_constant_override("separation",0)
		card.add_child(contents)
		var hero: Control=Control.new()
		hero.custom_minimum_size.y=285
		contents.add_child(hero)
		var scene: TextureRect=_scene_picture(str(region.scene),0)
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hero.add_child(scene)
		var shade: ColorRect=ColorRect.new()
		shade.color=Color.TRANSPARENT
		shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		shade.offset_top=-108
		hero.add_child(shade)
		var title: Label=_text(str(region.name),34,Color.WHITE)
		title.position=Vector2(24,180)
		title.size=Vector2(390,54)
		hero.add_child(title)
		var subtitle: Label=_text(str(region.subtitle),20,Color("d2e7dd"))
		subtitle.position=Vector2(24,238)
		subtitle.size=Vector2(580,35)
		hero.add_child(subtitle)
		var stamp: Label=_text("当前水域" if rid==region_id else ("已解锁" if unlocked else "未解锁"),20,GOLD)
		stamp.position=Vector2(24,18)
		stamp.size=Vector2(190,50)
		stamp.autowrap_mode=TextServer.AUTOWRAP_OFF
		stamp.add_theme_color_override("font_color",PAPER)
		stamp.add_theme_color_override("font_outline_color",NAVY)
		stamp.add_theme_constant_override("outline_size",4)
		hero.add_child(stamp)
		var inner: VBoxContainer=VBoxContainer.new()
		var padding: MarginContainer=MarginContainer.new()
		for side: String in ["left","right","top","bottom"]: padding.add_theme_constant_override("margin_"+side,18)
		contents.add_child(padding)
		padding.add_child(inner)
		var regional_total: int=0
		var regional_known: int=0
		for species: FishDefinition in catalog.fish.values():
			if rid in species.regions():
				regional_total+=1
				if _count(species.species_id)>0: regional_known+=1
		inner.add_child(_text("当地鱼种 %d  ·  已发现 %d" % [regional_total,regional_known],22,MUTED))
		if not unlocked:
			var need: int=int(region.unlock_count)
			var cost: int=int(region.unlock_cost)
			var unlock: Button=_button("启程  ·  %d 种发现  +  %d 旅币" % [need,cost],_unlock_region.bind(rid),true)
			unlock.disabled=store.discovered_count()<need or int(store.state.currency)<cost
			inner.add_child(unlock)
		else:
			for sid: String in region.spots:
				var spot: Dictionary=catalog.spots[sid]
				var min_gear: int=int(spot.min_gear)
				var label: String=("当前 · " if sid==spot_id else "")+str(spot.name)+"   %s–%s m" % [str(spot.depth_min_m),str(spot.depth_max_m)]
				if int(store.state.gear)<min_gear: label+="  ·  需升级装备"
				var go: Button=_button(label,_choose_spot.bind(rid,sid),sid==spot_id)
				go.disabled=int(store.state.gear)<min_gear
				inner.add_child(go)

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
	_open_page("gear","行囊")
	_page.add_child(_text("旅币 %d  ·  每一种鱼饵，都可以无限补给" % int(store.state.currency),22,MUTED))
	_section("我的钓竿","")
	for item: Dictionary in catalog.gear:
		var id: int=int(item.id)
		var current: bool=int(store.state.gear)==id
		var card: PanelContainer=_card(Color("28535a") if current else Color("193d49"))
		_page.add_child(card)
		var box: VBoxContainer=VBoxContainer.new()
		card.add_child(box)
		var row: HBoxContainer=HBoxContainer.new()
		box.add_child(row)
		var icon: Control=_icon("rod",104)

		row.add_child(icon)
		var info: VBoxContainer=VBoxContainer.new()
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_text(str(item.name),28,GOLD if current else INK))
		info.add_child(_text(str(item.description),21,MUTED))
		info.add_child(_text("探深 %d m   /   控线容错 ×%.2f" % [int(item.max_depth_m),float(item.tolerance)],20,TEAL))
		var owned: bool=id in store.state.owned_gear
		var label: String="已装备" if current else ("装备" if owned else "购买  ·  %d 旅币" % int(item.price))
		var action: Button=_button(label,_equip.bind(id),not owned)
		action.disabled=current or (not owned and int(store.state.currency)<int(item.price))
		box.add_child(action)
	_section("鱼饵","无限补给")
	var grid: GridContainer=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	_page.add_child(grid)
	for bait: Dictionary in catalog.baits:
		var card: PanelContainer=_card()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var box: VBoxContainer=VBoxContainer.new()
		card.add_child(box)
		box.add_child(_icon(str(bait.bait_id),82))
		box.add_child(_button(("已选 · " if bait.bait_id==bait_id else "")+str(bait.name),_set_bait.bind(str(bait.bait_id)),bait.bait_id==bait_id))
		box.add_child(_text(str(bait.hint),20,MUTED))

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
	_bait_control.icon_kind=bait_id

func _show_catalog() -> void:
	_open_page("catalog","图鉴")
	_page.add_theme_constant_override("separation",10)
	_page.add_child(_text("已发现 %d / %d 种   ·   累计 %d 条" % [store.discovered_count(),catalog.fish.size(),store.total_count()],23,INK))
	var filters: HBoxContainer=HBoxContainer.new()
	filters.add_theme_constant_override("separation",8)
	_page.add_child(filters)
	var search_row: HBoxContainer=HBoxContainer.new()
	search_row.custom_minimum_size=Vector2(192,96)
	search_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search_row.add_theme_constant_override("separation",6)
	search_row.add_child(_icon("search",36))
	var search: LineEdit=LineEdit.new()
	search.placeholder_text="搜索"
	search.text=_search
	search.custom_minimum_size=Vector2(144,96)
	search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search.text_changed.connect(func(value: String) -> void: _search=value; _fill_catalog())
	search_row.add_child(search)
	filters.add_child(search_row)
	var region_choice: OptionButton=OptionButton.new()
	region_choice.custom_minimum_size=Vector2(160,96)
	region_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	region_choice.add_item("全部水域")
	for region: Dictionary in catalog.regions:region_choice.add_item(str(region.name))
	for i: int in range(catalog.regions.size()):
		if str(catalog.regions[i].region_id)==_region_filter:region_choice.select(i+1)
	region_choice.item_selected.connect(func(index: int) -> void: _region_filter="all" if index==0 else str(catalog.regions[index-1].region_id); _fill_catalog())
	filters.add_child(region_choice)
	var discovery: OptionButton=OptionButton.new()
	discovery.custom_minimum_size=Vector2(112,96)
	for value: String in ["全部","已发现","待发现"]:discovery.add_item(value)
	discovery.select(_discovery_filter)
	discovery.item_selected.connect(func(index: int) -> void: _discovery_filter=index; _fill_catalog())
	filters.add_child(discovery)
	var sort_button: Button=_button("数量" if _sort_count else "名称",func() -> void: _sort_count=not _sort_count; _show_catalog())
	sort_button.custom_minimum_size=Vector2(112,96)
	sort_button.icon_kind="sort"
	sort_button.icon_extent=34
	sort_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	filters.add_child(sort_button)
	_list=GridContainer.new()
	_list.columns=2
	_list.add_theme_constant_override("h_separation",16)
	_list.add_theme_constant_override("v_separation",16)
	_page.add_child(_list)
	_fill_catalog()

func _fill_catalog() -> void:
	if _list == null: return
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var values: Array=catalog.fish.values()
	values.sort_custom(func(a: FishDefinition,b: FishDefinition) -> bool:
		if _sort_count:
			var ac: int=_count(a.species_id)
			var bc: int=_count(b.species_id)
			if ac!=bc: return ac>bc
		return a.name.naturalnocasecmp_to(b.name)<0)
	var shown: int=0
	for fish: FishDefinition in values:
		var known: bool=_count(fish.species_id)>0
		if _region_filter!="all" and _region_filter not in fish.regions(): continue
		if _discovery_filter==1 and not known: continue
		if _discovery_filter==2 and known: continue
		if not _search.is_empty() and not (_search in fish.name or _search.to_lower() in fish.scientific_name.to_lower()): continue
		shown+=1
		var card: PanelContainer=_card(Color("dce5d4") if known else Color("a7bbb1"),10)
		card.custom_minimum_size.x=305
		_list.add_child(card)
		var box: VBoxContainer=VBoxContainer.new()
		box.add_theme_constant_override("separation",5)
		card.add_child(box)
		var image: TextureRect=_fish_image(fish,true,not known,175)
		box.add_child(image)
		var title: Button=_button(fish.name,_show_species.bind(fish.species_id))
		title.custom_minimum_size.y=96
		title.icon_kind="none"
		title.icon_extent=0
		title.add_theme_font_size_override("font_size",24)
		box.add_child(title)
		var description: Label=_text("累计 %d 条" % _count(fish.species_id) if known else "待发现 · "+str(catalog.region(str(fish.regions()[0])).get("name","")),18,Color("355a58"))
		description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(description)
	if shown==0: _list.add_child(_text("没有符合条件的鱼，试试换个筛选",23,MUTED))

func _count(id: String) -> int:
	var stats: Dictionary = store.state.get("species_stats",{}).get(id,{})
	return int(stats.get("catch_count",0))

func _show_species(id: String) -> void:
	var fish: FishDefinition=catalog.fish[id]
	_open_page("species",fish.name,_show_catalog)
	var known: bool=_count(id)>0
	_page.add_child(_text(fish.scientific_name,22,MUTED))
	var plate: PanelContainer=_card(Color("e8ecd9"),20)
	_page.add_child(plate)
	var art_box: VBoxContainer=VBoxContainer.new()
	plate.add_child(art_box)
	art_box.add_child(_fish_image(fish,false,not known,285))
	var caption: Label=_text(str(fish.raw.get("rarity","")) if known else "尚未发现",17,Color("56776d"))
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	art_box.add_child(caption)
	if known: _page.add_child(_button("查看大图",_show_zoom.bind(id)))
	_page.add_child(_text(fish.description,25))
	if bool(fish.raw.get("release_only",false)):
		_page.add_child(_text("保护观察 · 仅在游戏中虚拟相遇，记录后即刻放归水中",22,GOLD))
	_section("形态特征","")
	_page.add_child(_text(fish.morphology,23,MUTED))
	_section("分布与钓点")
	var where: Array[String]=[]
	for sid: String in fish.spots():
		where.append(str(catalog.region(str(catalog.spots[sid].region_id)).name)+" · "+str(catalog.spots[sid].name))
	_page.add_child(_text("\n".join(where),23))
	var preferred: String="worm"
	var best: float=-1
	for bait: Dictionary in catalog.baits:
		var weight: float=fish.weight_for("bait_weights",str(bait.bait_id))
		if weight>best: preferred=str(bait.bait_id); best=weight
	_page.add_child(_text("鱼饵线索  /  "+catalog.bait_name(preferred)+"\n尺寸、行为与出现倍率含游戏调校",21,MUTED))
	_section("钓获纪录","累计 %d 条" % _count(id))
	if known:
		var stats: Dictionary=store.state.species_stats[id]
		for pair: Array in [["最长个体","max_length"],["最重个体","max_weight"],["首次钓获","first"],["最近钓获","last"]]:
			var card: PanelContainer=_card()
			_page.add_child(card)
			var box: VBoxContainer=VBoxContainer.new()
			card.add_child(box)
			box.add_child(_text(str(pair[0]),25,GOLD))
			box.add_child(_text(_record_text(stats.get(pair[1],{})),21,MUTED))
		var favorite: bool=id in store.state.favorites
		_page.add_child(_button("移出收藏" if favorite else "加入收藏",_favorite.bind(id),not favorite))
	else: _page.add_child(_text("尚无钓获纪录",23,MUTED))
	_section("资料参考")
	for source: Dictionary in fish.raw.get("sources",[]):
		_page.add_child(_text(str(source.get("title",""))+"\n"+str(source.get("url","")),17,MUTED))

func _show_zoom(id: String) -> void:
	var fish: FishDefinition=catalog.fish[id]
	_open_page("zoom",fish.name+" · 细看",_show_species.bind(id))
	var plate: PanelContainer=_card(Color("e8ecd9"),18)
	_page.add_child(plate)
	plate.add_child(_fish_image(fish,false,false,590))
	_page.add_child(_text(fish.scientific_name,23,TEAL))
	_page.add_child(_text(fish.morphology,26))
	_page.add_child(_text("轻柔摆动的高清自然插画。AI 辅助生成并经开发校对，不替代野外物种鉴定。",20,MUTED))

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
	_open_page("favorites","收藏")
	var favorites: Array=store.state.get("favorites",[])
	_page.add_child(_text("已收藏 %d / 6 种" % favorites.size(),23,MUTED))
	var grid: GridContainer=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",16)
	_page.add_child(grid)
	for slot: int in range(6):
		var card: PanelContainer=_card(Color("1d4852"),14)
		card.custom_minimum_size=Vector2(302,290)
		grid.add_child(card)
		var box: VBoxContainer=VBoxContainer.new()
		card.add_child(box)
		if slot>=favorites.size() or not catalog.fish.has(str(favorites[slot])):
			box.add_child(_icon("heart",112))
			box.add_child(_button("添加收藏",_show_catalog))
			var empty: Label=_text("在图鉴中收藏喜欢的鱼",18,MUTED)
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(empty)
			continue
		var id: String=str(favorites[slot])
		var fish: FishDefinition=catalog.fish[id]
		var plate: PanelContainer=_card(Color("dce5d4"),6)
		box.add_child(plate)
		plate.add_child(_fish_image(fish,true,false,122))
		box.add_child(_button(fish.name,_show_species.bind(id)))
		var stats: Dictionary=store.state.species_stats.get(id,{})
		var record: Dictionary=stats.get("max_length",{})
		var detail: Label=_text("最长 "+_length(int(record.get("length_mm",0)))+" · %d 条" % _count(id),18,GOLD)
		detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(detail)

func _show_result() -> void:
	var id: String=str(_last_record.get("species_id",""))
	if not catalog.fish.has(id): return
	var fish: FishDefinition=catalog.fish[id]
	var protected: bool=bool(_last_record.get("release_only",fish.raw.get("release_only",false)))
	_open_page("result","保护观察" if protected else "钓获")
	var flags: Array[String]=[]
	if bool(_last_settlement.get("new_species",false)): flags.append("首次发现")
	if bool(_last_settlement.get("new_length",false)): flags.append("长度新纪录")
	if bool(_last_settlement.get("new_weight",false)): flags.append("重量新纪录")
	if not flags.is_empty():
		var ribbon: Label=_text("  ·  ".join(flags),22,GOLD)
		ribbon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_page.add_child(ribbon)
	var fish_name: Label=_text(fish.name,43,INK)
	fish_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(fish_name)
	var latin: Label=_text(fish.scientific_name,21,MUTED)
	latin.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(latin)
	var plate: PanelContainer=_card(Color("e8ecd9"),20)
	_page.add_child(plate)
	var specimen: VBoxContainer=VBoxContainer.new()
	specimen.add_theme_constant_override("separation",4)
	plate.add_child(specimen)
	var size_fraction: float=clampf(float(_last_record.get("size_fraction",0.3)),0,1)
	var image: TextureRect=_fish_image(fish,false,false,235+size_fraction*90)
	var center: CenterContainer=CenterContainer.new()
	center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	specimen.add_child(center)
	image.custom_minimum_size.x=lerpf(355.0,595.0,size_fraction)
	center.add_child(image)
	var ruler: Control=Ruler.new()
	ruler.length_mm=int(_last_record.get("length_mm",0))
	ruler.specimen=image
	specimen.add_child(ruler)
	var note: Label=_text("吻端至尾端  ·  厘米 cm",16,Color("678275"))
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	specimen.add_child(note)
	var measurements: HBoxContainer=HBoxContainer.new()
	_page.add_child(measurements)
	for pair: Array in [["体长",_length(int(_last_record.length_mm))],["体重",_weight(int(_last_record.weight_g))]]:
		var box: VBoxContainer=VBoxContainer.new()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation",0)
		measurements.add_child(box)
		var value: Label=_text(str(pair[1]),35,GOLD)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(value)
		var title: Label=_text(str(pair[0]),18,MUTED)
		title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(title)
	var place: Label=_text(str(_last_record.get("size_class","标准"))+"个体  /  "+str(catalog.spots.get(str(_last_record.get("spot_id",spot_id)),{}).get("name","")),21,MUTED)
	place.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(place)
	if not _save_ok:
		_page.add_child(_text("保存未成功："+str(_last_settlement.get("error",store.error_message))+"\n请重试保存，不要退出。",23,CORAL))
		_page_footer.add_child(_button("重试保存",_settle,true))
		_page_footer.visible=true
		return
	var saved: Label=_text("已记入图鉴  ·  累计 %d 条  ·  +%d 旅币" % [_count(id),int(_last_record.get("reward",0))],21,TEAL)
	saved.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(saved)
	if protected:
		_page.add_child(_text("保护观察 · 仅为游戏内虚拟相遇\n记录后即刻放归，不对应现实捕捞",21,GOLD))
		_page_footer.add_child(_button("放归自然  ·  +8 旅币",_dispose_result.bind("released"),true))
	else:
		var actions: HBoxContainer=HBoxContainer.new()
		_page_footer.add_child(actions)
		actions.add_child(_button("出售  +%d" % int(_last_record.get("sale_value",0)),_dispose_result.bind("sold"),true))
		actions.add_child(_button("放生  +8",_dispose_result.bind("released")))
	var kept: Label=_text("放归后保留图鉴与纪录" if protected else "出售或放生均保留图鉴与纪录",18,MUTED)
	kept.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page_footer.add_child(kept)
	_page_footer.visible=true

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
	_open_page("pending","待处理钓获")
	var pending: Dictionary=store.state.get("pending_catches",{})
	if pending.is_empty(): _page.add_child(_text("所有钓获都已妥善处理",26))
	for id: String in pending:
		var record: Dictionary=pending[id]
		var fish: FishDefinition=catalog.fish.get(str(record.species_id))
		var protected: bool=bool(record.get("release_only",fish.raw.get("release_only",false) if fish else false))
		var card: PanelContainer=_card()
		_page.add_child(card)
		var box: VBoxContainer=VBoxContainer.new()
		card.add_child(box)
		if fish: box.add_child(_fish_image(fish,true,false,150))
		box.add_child(_text((fish.name if fish else str(record.species_id))+"\n"+_record_text(record),24))
		if not protected: box.add_child(_button("出售 · +%d 旅币" % int(record.get("sale_value",0)),_dispose_pending.bind(id,"sold")))
		else: box.add_child(_text("保护观察 · 记录后即刻放归",21,GOLD))
		box.add_child(_button("放归自然 · +8 旅币",_dispose_pending.bind(id,"released"),true))

func _dispose_pending(id: String,action: String) -> void:
	var result: Dictionary = store.dispose_catch(id,action)
	if bool(result.get("ok",false)): _show_pending()
	else: _page.add_child(_text(str(result.get("error",store.error_message)),24,CORAL))

func _show_settings() -> void:
	_open_page("settings","设置")
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
	_page.add_child(_text("远岸钓记 "+str(ProjectSettings.get_setting("application/config/version","1.1.0"))+"\nGodot 4.6.3 · 离线单机 · 自然图鉴\n鱼类与场景插画：AI 辅助生成并开发校对\n字体：Noto Sans CJK（SIL Open Font License）\n音效：本项目程序合成原创\nGodot Engine：MIT License",21,MUTED))
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
	if _overlay!=null and is_instance_valid(_page_notice):
		_page_notice.text=value
		_page_notice.visible=true

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
