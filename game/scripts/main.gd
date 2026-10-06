extends Control
const Catalog = preload("res://scripts/catalog.gd")
const Store = preload("res://scripts/save_store.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Stage = preload("res://scripts/fishing_stage_3d.gd")
const Trial = preload("res://scripts/trial_fishery.gd") # Read historical trial catch locations only.
const Registry = preload("res://scripts/fish_3d_registry.gd")
const FishArt = preload("res://scripts/fish_art_catalog.gd")
const FishArtViewScript = preload("res://scripts/fish_art_view.gd")
const NaturalHistory = preload("res://scripts/fish_natural_history.gd")
const TouchScrollScript = preload("res://scripts/touch_scroll.gd")
const NotebookUI = preload("res://scripts/fish_notebook_ui.gd")
const MenuPages = preload("res://scripts/fishing_menu_pages.gd")
const FailureModal = preload("res://scripts/fishing_failure_modal.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const WhaleChallenge = preload("res://scripts/blue_whale_challenge.gd")
const WhaleUI = preload("res://scripts/whale_challenge_ui.gd")
const WhaleStage = preload("res://scripts/whale_challenge_stage_3d.gd")
const Clear = preload("res://scripts/clear_ui.gd")
const INK: Color = Clear.INK
const NAVY: Color = Color("102f3b")
const GOLD: Color = Clear.GOLD
const Art = preload("res://scripts/ui_art.gd")
const IconButton=preload("res://scripts/icon_action.gd")
const Ruler = preload("res://scripts/measure_ruler.gd")
const MUTED: Color = Clear.MUTED
const PAPER: Color = Color("f5f2e9")
const TEAL: Color = Clear.TEAL
const CORAL: Color = Color("9d4931")
var catalog: ContentCatalog = Catalog.new()
var fish_art: FishArtCatalog = FishArt.new()
var natural_history: FishNaturalHistory = NaturalHistory.new()
var store: SaveStore = Store.new()
var encounter: EncounterGenerator = Encounter.new()
var session: FishingSession = Session.new()
var scenery: Node3D
var _mode: String = "lobby"
var _trial_gear_id: int = -1
var _page_context: String = "home"
var _landing_pending: bool = false
var _result_waiting: bool = false
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
var _resources_ok: bool = false
var _models_complete: bool = false
var _model_errors: Array[String] = []
var _safe: MarginContainer
var _collection: Label
var _bait_label: Label
var _page_notice: Label
var notebook: FishNotebookUI = NotebookUI.new()
var menu_pages: FishingMenuPages = MenuPages.new()
var _page_back: Callable = Callable()
var _settings_back: Callable = Callable()
var _notebook_origin: String = "catalog"
var _active_species_id: String = ""
var _catalog_scroll: int = 0
var _favorites_scroll: int = 0
var _gear_scroll: int = 0
var _last_failure_session_id: String = ""
var _startup_complete: bool = false
var _boot: Control
var _boot_status: Label
var _boot_progress: ProgressBar
var _page_tween: Tween
var _settings_scroll: int = 0
var _backup_edit: TextEdit
var _backup_candidate: String = ""
var _backup_revision: int = -1
var _condition_key: String = ""
var whale_challenge: BlueWhaleChallenge = WhaleChallenge.new()
var _whale_view: WhaleChallengeUI
var _whale_navigation: Button
var _whale_origin_mode: String = "lobby"
var _whale_record: Dictionary = {}
var _whale_save_ok: bool = false
var _whale_new_best: bool = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_apply_theme()
	_show_boot()
	await _loading_stage("整理水域与鱼类资料",0.12)
	_content_ok = catalog.load_all(true)
	await _loading_stage("准备自然图鉴",0.30)
	if not fish_art.load_all(catalog):
		catalog.errors.append_array(fish_art.errors)
		_content_ok = false
	if not natural_history.load_all(catalog):
		catalog.errors.append_array(natural_history.errors)
		_content_ok = false
	var icon_errors: Array[String]=Art.validate_assets()
	if not icon_errors.is_empty():
		catalog.errors.append_array(icon_errors)
		_content_ok=false
	await _loading_stage("检查鱼类与人物模型",0.55)
	_model_errors = Registry.validate_catalog(catalog,true)
	_models_complete = _model_errors.is_empty()
	if not _models_complete:
		catalog.errors.append_array(_model_errors)
		_content_ok = false
	_resources_ok=_content_ok
	await _loading_stage("读取你的钓行记录",0.72)
	store.initialize()
	var saved: Dictionary = store.state
	var selection: Dictionary = saved.get("selection", {})
	region_id = str(selection.get("region_id", "lake"))
	spot_id = str(selection.get("spot_id", "lake_shore"))
	bait_id = str(selection.get("bait_id", "worm"))
	if not catalog.spots.has(spot_id) or str(catalog.spots.get(spot_id,{}).get("region_id","")) != region_id:
		catalog.errors.append("存档中的水域/钓点在本版不可用，已保留原选择")
		_content_ok = false
	if int(saved.get("gear",0)) < 0 or int(saved.get("gear",0)) >= catalog.gear.size():
		catalog.errors.append("存档中的钓竿在本版不可用，已保留原装备")
		_content_ok = false
	game_clock = float(saved.get("game_clock", 0.0))
	await _loading_stage("铺开水面与光影",0.86)
	sound = Audio.new()
	add_child(sound)
	sound.apply(saved.get("settings", {}))
	_build_fishing_screen()
	session.changed.connect(_session_changed)
	session.ended.connect(_fishing_ended)
	session.cue.connect(sound.cue)
	whale_challenge.ended.connect(_whale_ended)
	if not _refresh_location(): _content_ok = false
	_update_conditions()
	_apply_preferences()
	_session_changed(Session.State.IDLE)
	_startup_complete = true
	_show_home()
	if is_instance_valid(_boot):
		remove_child(_boot)
		_boot.queue_free()
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
	for type_name: String in ["LineEdit","TextEdit","OptionButton"]:
		for state: String in Clear.STATES:
			style.set_stylebox(state,type_name,Clear.surface(state=="focus",12))
		style.set_stylebox("read_only",type_name,Clear.surface(false,12))
		style.set_color("font_outline_color",type_name,Clear.OUTLINE)
		style.set_constant("outline_size",type_name,3)
	style.set_color("font_placeholder_color","LineEdit",MUTED)
	style.set_color("caret_color","LineEdit",TEAL)
	style.set_constant("separation","VBoxContainer",14)
	style.set_constant("separation","HBoxContainer",12)
	style.set_stylebox("panel","PopupMenu",Clear.surface(false,18))
	style.set_stylebox("hover","PopupMenu",Clear.surface(true,6))
	style.set_stylebox("panel","TooltipPanel",Clear.surface(false,10))
	style.set_color("font_color","TooltipLabel",INK)
	style.set_color("font_outline_color","TooltipLabel",Clear.OUTLINE)
	style.set_constant("outline_size","TooltipLabel",3)
	style.set_color("font_outline_color","PopupMenu",Clear.OUTLINE)
	style.set_constant("outline_size","PopupMenu",3)
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
	Clear.style_text(label)
	return label

func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button: Button=IconButton.new()
	button.text=value
	button.custom_minimum_size.y=96
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.icon_kind=_action_symbol(value)
	button.appearance="primary" if primary else "surface"
	button.label_color=GOLD if primary else INK
	button.animate_press=not bool(store.state.get("settings",{}).get("reduce_motion",false))
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
	var style: StyleBoxFlat=Clear.surface(false,margin_px)
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
	button.icon_only=true
	button.icon_extent=72
	button.label_color=Color.WHITE
	button.light_label=true
	button.appearance="glass"
	button.add_theme_font_size_override("font_size",24)
	return button

func _build_fishing_screen() -> void:
	scenery = Stage.new()
	scenery.name = "FishingWorld3D"
	if not scenery.set_location(region_id,spot_id):
		catalog.errors.append("当前3D钓点无法加载，已保留存档选择")
		_content_ok = false
	add_child(scenery)
	scenery.bind_session(session)
	scenery.cast_presentation_finished.connect(_cast_presentation_finished)
	scenery.cast_water_contact.connect(func() -> void: sound.cue("splash"))
	scenery.landing_finished.connect(_landing_presentation_finished)
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
	pause_button.icon_only=true
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
	edge.offset_top=40
	edge.add_theme_constant_override("separation",16)
	field.add_child(edge)
	for item: Array in [["旅行","compass",_show_travel],["图鉴","book",_show_catalog],["收藏","heart",_show_favorites],["行囊","bag",_show_gear]]:
		var navigation: Button=_navigation(str(item[0]),str(item[1]),item[2])
		navigation.custom_minimum_size=Vector2(102,100)
		navigation.icon_extent=64
		navigation.add_theme_font_size_override("font_size",21)
		edge.add_child(navigation)
	_whale_navigation = _navigation("鲸影","compass",_show_whale_briefing)
	_whale_navigation.name = "WhaleChallengeEntry"
	_whale_navigation.custom_minimum_size = Vector2(102,100)
	_whale_navigation.icon_extent = 64
	_whale_navigation.add_theme_font_size_override("font_size",21)
	edge.add_child(_whale_navigation)
	_toast=_text("",23,PAPER)
	_toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	_toast.visible=false
	layout.add_child(_toast)
	_status=_text("准备抛竿",30,PAPER)
	_status.add_theme_color_override("font_shadow_color",NAVY)
	_status.add_theme_constant_override("shadow_offset_y",2)
	_status.visible=false
	layout.add_child(_status)
	_hint=_text("长按蓄力，松手抛竿",21,Color("e4ede0"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	layout.add_child(_hint)
	_charge=_bar(GOLD)
	_charge.visible=false
	layout.add_child(_charge)
	_bars=VBoxContainer.new()
	_bars.custom_minimum_size.x=370
	_bars.size_flags_horizontal=Control.SIZE_SHRINK_END
	_bars.add_theme_constant_override("separation",8)
	layout.add_child(_bars)
	_tension=_bar(Color("edb078"))
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
	_action.appearance="primary"
	_action.size_flags_horizontal=Control.SIZE_SHRINK_END
	_action.stacked=true
	_action.icon_only=true
	_action.icon_extent=110
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
	var left: int = 20
	var right: int = 20
	if OS.get_name() == "Android":
		var area: Rect2i = DisplayServer.get_display_safe_area()
		var screen: Vector2i = DisplayServer.screen_get_size()
		var scale_y: float = size.y / maxf(1.0, float(screen.y))
		var scale_x: float = size.x / maxf(1.0, float(screen.x))
		left = maxi(left,ceili(float(area.position.x)*scale_x)+8)
		right = maxi(right,ceili(float(screen.x-area.end.x)*scale_x)+8)
		top = maxi(top, ceili(float(area.position.y) * scale_y) + 8)
		bottom = maxi(bottom, ceili(float(screen.y-area.end.y) * scale_y) + 8)
	_safe.add_theme_constant_override("margin_left",left)
	_safe.add_theme_constant_override("margin_right",right)
	_safe.add_theme_constant_override("margin_top",top)
	_safe.add_theme_constant_override("margin_bottom",bottom)
	if _overlay is FishingFailureModal:
		_overlay.set_safe_insets(Vector4(left,top,right,bottom))
	if is_instance_valid(_overlay):
		var overlay_margin: MarginContainer = _overlay.get_node_or_null("OverlayMargin") as MarginContainer
		if overlay_margin != null:
			overlay_margin.add_theme_constant_override("margin_left",maxi(32 if _screen=="home" else 28,left))
			overlay_margin.add_theme_constant_override("margin_right",maxi(32 if _screen=="home" else 28,right))
			overlay_margin.add_theme_constant_override("margin_top",maxi(32 if _screen == "home" else 24,top))
			overlay_margin.add_theme_constant_override("margin_bottom",maxi(28 if _screen == "home" else 24,bottom))

func _process(delta: float) -> void:
	if not _startup_complete: return
	if _mode == "whale":
		whale_challenge.step(delta)
		if whale_challenge.is_active() and whale_challenge.state != WhaleChallenge.State.PAUSED: game_clock += delta
		return
	if _mode == "fishing" and not scenery.cast_in_progress and not _landing_pending:
		session.step(delta)
	if _mode == "fishing" and session.state != Session.State.PAUSED:
		game_clock += delta
	_update_conditions()
	sound.update_fishing(delta,session.state==Session.State.FIGHT and _screen.is_empty(),session.reeling,session.tension,session.surge_strength)
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
		_action.text = "收线"
	elif session.state == Session.State.CHARGING:
		_hint.text = "落点距离 %d%% · 松手投出" % roundi(minf(session.charge,float(catalog.gear[_effective_gear_id()].reach))*100)

func _update_conditions() -> void:
	time_of_day = "day" if int(game_clock/150.0)%2 == 0 else "dusk"
	weather = "clear" if int(game_clock/240.0)%2 == 0 else "rain"
	var key: String=spot_id+":"+time_of_day+":"+weather
	if key==_condition_key:return
	_condition_key=key
	scenery.set_time_of_day(time_of_day)
	scenery.set_weather(weather)
	sound.set_environment(spot_id,weather,time_of_day)
	_weather_icon.kind="rain" if weather=="rain" else ("dusk" if time_of_day=="dusk" else "sun")
	_condition.text = "%s  ·  %s" % ["晴" if weather == "clear" else "微雨","日间" if time_of_day == "day" else "黄昏"]

func _refresh_location() -> bool:
	# A rejected scene change must never be presented as a successful trip.
	if not scenery.set_location(region_id,spot_id):
		_toast_message("这个3D钓点暂时无法进入，已保留原钓点")
		return false
	_refresh_location_labels()
	return true

func _refresh_location_labels() -> void:
	_place.text = str(catalog.region(region_id).get("name",region_id))
	_spot_label.text = str(catalog.spots.get(spot_id,{}).get("name",spot_id))
	_bait_control.icon_kind=bait_id
	_bait_control.text=catalog.bait_name(bait_id)
	if scenery.has_method("set_gear_profile"): scenery.set_gear_profile(catalog.gear[_effective_gear_id()])
	if session.state in [Session.State.IDLE,Session.State.CHARGING,Session.State.CASTING]: _action.icon_kind = _current_rod_icon()
	_update_wallet()
	if _whale_navigation: _whale_navigation.visible = spot_id == "pacific_bluewater" and not _active_round()

func _update_wallet() -> void:
	_wallet.text = str(int(store.state.get("currency",0)))
	if _collection: _collection.text="鱼类 %d / %d" % [store.discovered_count(),catalog.fish_species_count()]

func _action_down() -> void:
	if _mode != "fishing" or _overlay != null or _landing_pending or store.read_only or not _content_ok: return
	if session.state == Session.State.IDLE and store.state.get("pending_catches",{}).size() >= Store.MAX_PENDING:
		_show_pending()
		return
	session.press()

func _action_up() -> void:
	if session.state == Session.State.CHARGING:
		var gear_id: int = _effective_gear_id()
		var cast_power: float = clampf(session.charge,0.05,float(catalog.gear[gear_id].reach))
		session.charge = cast_power
		if not scenery.cast_target_for_charge(cast_power).is_finite():
			session.reset()
			_toast_message("这里暂时没有安全落点，请更换钓点")
			return
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
	# The reel remains visually identical throughout float observation. Only the
	# float itself can reveal a committed bite, never the control or HUD.
	_action.icon_kind="reel" if value in [Session.State.WAITING,Session.State.NIBBLE,Session.State.BITE,Session.State.FIGHT] else _current_rod_icon()
	_nav_rail.visible=value not in [Session.State.FIGHT,Session.State.CAUGHT]
	if _whale_navigation: _whale_navigation.visible = spot_id == "pacific_bluewater" and value == Session.State.IDLE
	_bait_control.disabled=value==Session.State.CAUGHT
	_charge.visible = value == Session.State.CHARGING
	_bars.visible = value == Session.State.FIGHT
	_action.disabled = value in [Session.State.CASTING,Session.State.CAUGHT,Session.State.ESCAPED,Session.State.PAUSED]
	match value:
		Session.State.IDLE:
			_status.text = "准备抛竿"
			_hint.text = "长按蓄力 · 松手抛竿"
			_action.text = "抛竿"
		Session.State.CHARGING:
			_status.text = "蓄力中"
			_action.text = "投出"
		Session.State.CASTING:
			_status.text = "正在抛竿"
			_hint.text = "落点会影响能遇见的鱼群"
			_action.text = "抛竿中"
		Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE:
			_status.text = "观察鱼漂"
			_hint.text = "观察漂相 · 点按提竿，按住收线"
			_action.text = "收线"
		Session.State.FIGHT:
			_status.text = "控线遛鱼"
			_hint.text = "按住收线，松手卸力"
			_action.text = "收线"
		Session.State.CAUGHT:
			_action.text = "起鱼中"
		Session.State.PAUSED:
			_status.text = "已暂停"
			_hint.text = "鱼、张力与计时保持原位"

func _fishing_ended(success: bool, record: Dictionary) -> void:
	var active_state: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	if str(record.get("session_id", "")) != session.session_id: return
	if success and active_state != Session.State.CAUGHT: return
	if not success and active_state != Session.State.ESCAPED: return
	# Duplicate terminal notifications must not re-arm an already completed
	# presentation. The stage intentionally will not replay the same catch ID.
	if success and not _last_record.is_empty() and str(record.get("catch_id","")) == str(_last_record.get("catch_id","")): return
	if success:
		_last_record = record.duplicate(true)
		_save_ok = false
		_landing_pending = true
		_result_waiting = false
		_settle(false)
		if _save_ok:
			_status.text = "正在起鱼"
			_hint.text = "稳住鱼竿，把鱼带向岸边"
			scenery.play_landing(_last_record)
		else:
			_landing_pending = false
			_show_result()
	else:
		if _last_failure_session_id == session.session_id: return
		_last_failure_session_id = session.session_id
		store.abandon_session(session.session_id)
		sound.cue("escape")
		_show_failure_modal(session.escape_reason)

func _settle(present_result: bool = true) -> void:
	if _last_record.is_empty(): return
	if str(_last_record.get("catch_id", "")) == _last_committed_id:
		_save_ok = true
		if present_result: _show_result()
		return
	_last_settlement = store.settle_catch(_last_record)
	_save_ok = bool(_last_settlement.get("ok",false))
	if _save_ok:
		_last_committed_id = str(_last_record.catch_id)
		sound.cue("catch")
		_update_wallet()
	if present_result: _show_result()

func _cast_presentation_finished() -> void:
	# The full character cast has already elapsed while simulation was gated.
	# Make the landed float actionable now, rather than add a second cast timer.
	# A late or duplicate animation callback cannot restart another phase.
	if session.state == Session.State.CASTING and not scenery.cast_in_progress:
		session.set_state(Session.State.WAITING)

func _landing_presentation_finished(record: Dictionary) -> void:
	if not _landing_pending or str(record.get("catch_id","")) != str(_last_record.get("catch_id","")): return
	_landing_pending = false
	_result_waiting = true
	if _overlay == null: _show_result()

func _open_page(id: String, heading: String, back: Callable = Callable()) -> void:
	_remove_overlay()
	_page_back = back if back.is_valid() else _close_page
	session.cancel_input()
	if session.state != Session.State.PAUSED: session.pause()
	sound.suspend(true)
	scenery.suspend(true)
	_safe.visible = false
	_screen=id
	_overlay=Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_add_reading_backdrop(_overlay)
	var margin: MarginContainer=MarginContainer.new()
	margin.name = "OverlayMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",maxi(28,_safe.get_theme_constant("margin_left")))
	margin.add_theme_constant_override("margin_right",maxi(28,_safe.get_theme_constant("margin_right")))
	margin.add_theme_constant_override("margin_top",maxi(24,_safe.get_theme_constant("margin_top")))
	margin.add_theme_constant_override("margin_bottom",maxi(24,_safe.get_theme_constant("margin_bottom")))
	_overlay.add_child(margin)
	var outer: VBoxContainer=VBoxContainer.new()
	outer.add_theme_constant_override("separation",14)
	margin.add_child(outer)
	var head: HBoxContainer=HBoxContainer.new()
	outer.add_child(head)
	var close: Button=_button("返回",_page_back)
	close.custom_minimum_size=Vector2(124,96)
	close.stacked=false
	close.icon_only=true
	close.icon_extent=34
	close.add_theme_font_size_override("font_size",22)
	close.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	head.add_child(close)
	_title=_text(heading,34,INK)
	_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_title)
	var balance: Control = Control.new()
	balance.custom_minimum_size.x = 124
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(balance)
	var line: ColorRect=ColorRect.new()
	line.color=Color(0.30,0.47,0.44,0.30)
	line.custom_minimum_size.y=1
	outer.add_child(line)
	_page_notice=_text("",21,GOLD)
	_page_notice.visible=false

	outer.add_child(_page_notice)
	var scroll: ScrollContainer=TouchScrollScript.new()
	scroll.name="PageScroll"
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	_page=VBoxContainer.new()
	_page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation",20)
	scroll.add_child(_page)
	_page_footer=VBoxContainer.new()
	_page_footer.visible=false
	outer.add_child(_page_footer)
	_animate_page(_overlay)

func _remove_overlay() -> void:
	if _page_tween: _page_tween.kill()
	if is_instance_valid(_overlay):
		remove_child(_overlay)
		_overlay.queue_free()
	_overlay = null
	_page = null
	_page_footer = null
	_page_notice = null
	_title = null
	_page_back = Callable()
	_screen = ""

func _close_page() -> void:
	if _mode == "whale": return
	if _screen == "result" and (not _save_ok or store.state.get("pending_catches",{}).has(str(_last_record.get("catch_id","")))):
		_toast_message("请先出售、放生，或保存失败时重试")
		return
	if _mode == "lobby":
		if _page_context == "prepare" and _screen != "prepare": _show_prepare()
		else: _show_home()
		return
	_remove_overlay()
	_safe.visible = true
	session.resume()
	scenery.suspend(false)
	sound.suspend(false)
	_update_wallet()
	if _result_waiting and not _last_record.is_empty(): _show_result()

func _show_home() -> void:
	if _mode == "whale": return
	if not _last_record.is_empty() and not _save_ok:
		_show_result()
		return
	_remove_overlay()
	_mode = "lobby"
	_page_context = "home"
	_screen = "home"
	_safe.visible = false
	session.pause()
	scenery.set_mode("lobby")
	scenery.suspend(false)
	sound.suspend(false)
	_overlay = Control.new()
	_overlay.name = "Lobby"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "OverlayMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right"]: margin.add_theme_constant_override("margin_"+side,maxi(32,_safe.get_theme_constant("margin_"+side)))
	margin.add_theme_constant_override("margin_top",maxi(32,_safe.get_theme_constant("margin_top")))
	margin.add_theme_constant_override("margin_bottom",maxi(28,_safe.get_theme_constant("margin_bottom")))
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_overlay.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation",16)
	margin.add_child(column)
	var home_head: HBoxContainer = HBoxContainer.new()
	column.add_child(home_head)
	var brand: VBoxContainer = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation",2)
	home_head.add_child(brand)
	brand.add_child(_text("远岸钓记",46,Color("f6f0dd")))
	brand.add_child(_text("水边的片刻，也是旅行",21,Color("c6d9cf")))
	var progress: VBoxContainer = VBoxContainer.new()
	progress.name = "LobbyProgress"
	progress.custom_minimum_size.x = 140
	progress.size_flags_horizontal = Control.SIZE_SHRINK_END
	home_head.add_child(progress)
	for pair: Array in [["coin",str(int(store.state.currency))],["book","%d / %d" % [store.discovered_count(),catalog.fish_species_count()]]]:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_child(_icon(str(pair[0]),32))
		var value: Label = _text(str(pair[1]),23,Color("f6f0dd"))
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.custom_minimum_size.x = 92
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
		progress.add_child(row)
	var room: Control = Control.new()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(room)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation",16)
	column.add_child(_page)
	_page_notice=_text("",22,Color("e8d69f"))
	_page_notice.visible=false
	_page.add_child(_page_notice)
	_page.add_child(_text("此刻 · "+("微雨" if weather=="rain" else "晴")+" / "+("黄昏" if time_of_day=="dusk" else "日间"),20,Color("c6d9cf")))
	_page.add_child(_text(str(catalog.region(region_id).get("name",region_id)),40,Color("f6f0dd")))
	_page.add_child(_text(str(catalog.spots.get(spot_id,{}).get("name",spot_id))+"   ·   累计钓获 %d 条" % store.total_count(),22,Color("c6d9cf")))
	var start: Button = _button("开始钓鱼",_show_prepare,true)
	start.name="StartFishing"
	start.icon_only=true
	start.custom_minimum_size.y=108
	start.icon_kind="rod"
	start.icon_extent=100
	start.add_theme_font_size_override("font_size",30)
	start.disabled=store.read_only or not _content_ok
	_page.add_child(start)
	if spot_id == "pacific_bluewater":
		var whale_entry: Button = _button("鲸影共鸣 · 蓝鲸挑战",_show_whale_briefing)
		whale_entry.name = "LobbyWhaleEntry"
		whale_entry.custom_minimum_size.y = 96
		_page.add_child(whale_entry)
	var actions: HBoxContainer = HBoxContainer.new()
	_page.add_child(actions)
	for entry: Array in [["旅行","compass",_show_travel],["行囊","bag",_show_gear],["图鉴","book",_show_catalog],["设置","settings",_show_settings]]:
		var action: Button=_navigation(str(entry[0]),str(entry[1]),entry[2])
		action.icon_extent=64
		action.custom_minimum_size=Vector2(96,104)
		action.add_theme_font_size_override("font_size",21)
		actions.add_child(action)
	if not store.state.get("pending_catches",{}).is_empty():
		var pending: Button = _navigation("处理已保存的钓获","book",_show_pending)
		pending.stacked = false
		pending.icon_extent = 40
		pending.custom_minimum_size.y = 96
		_page.add_child(pending)
	if store.read_only or not _content_ok:
		_page.add_child(_text("暂不能开始：" + (store.error_message if store.read_only else ("3D鱼类资源尚未准备完成" if not _models_complete else "内容校验失败")),22,Color("ffbfa0")))
	_animate_page(_overlay)

func _show_lobby_exit(message: String = "现在退出游戏？") -> void:
	_remove_overlay()
	session.cancel_input()
	session.pause()
	scenery.suspend(true)
	sound.suspend(true)
	_safe.visible = false
	_screen = "lobby_exit"
	var modal: FishingFailureModal = FailureModal.new()
	modal.configure_confirmation("退出游戏",message,"退出游戏","继续游戏","back",Vector4(_safe.get_theme_constant("margin_left"),_safe.get_theme_constant("margin_top"),_safe.get_theme_constant("margin_right"),_safe.get_theme_constant("margin_bottom")))
	modal.retry_requested.connect(_exit_game)
	modal.dismiss_requested.connect(_show_home if _mode == "lobby" else _show_pause)
	_overlay = modal
	add_child(modal)

func _show_prepare() -> void:
	if _mode == "whale": return
	_page_context = "prepare"
	_open_page("prepare","准备出发",_show_home)
	menu_pages.populate_prepare(self,_page)
	if spot_id == "pacific_bluewater":
		_section("海洋巨兽 · 独立挑战","蓝鲸是哺乳动物，鲸影玩法使用幻想光线")
		_page.add_child(_button("鲸影共鸣 · 蓝鲸挑战",_show_whale_briefing))

func _enter_fishery() -> void:
	if _mode == "whale": return
	if store.read_only or not _content_ok or not _can_use_spot(spot_id) or region_id not in store.state.get("unlocked_regions",[]): return
	if not _last_record.is_empty():
		_show_result()
		return
	if _active_round():
		_toast_message("请先结束这一竿，再重新进入钓点")
		_show_pause()
		return
	if not _refresh_location(): return
	_remove_overlay()
	_mode = "fishing"
	_page_context = "fishing"
	_landing_pending = false
	_result_waiting = false
	_safe.visible = true
	scenery.cancel_landing()
	scenery.set_mode("fishing")
	scenery.suspend(false)
	session.reset()
	sound.suspend(false)

func _return_to_lobby() -> void:
	if _mode == "whale": return
	if not _last_record.is_empty():
		_landing_pending = false
		scenery.cancel_landing()
		_show_result()
		return
	store.abandon_session(session.session_id)
	session.reset()
	scenery.cancel_landing()
	_show_home()

func _show_pause() -> void:
	if _mode == "whale": _pause_whale(); return
	var active_state: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	if active_state == Session.State.CAUGHT and not _last_record.is_empty() and not _landing_pending:
		_show_result()
		return
	if active_state == Session.State.ESCAPED:
		_finish_result()
	_open_page("pause","暂停")
	_page.add_child(_text("当前鱼与钓鱼进度保持不变。\n切到后台时也会暂停，回来后由你决定继续。",26))
	_page.add_child(_button("继续钓鱼",_close_page,true))
	_page.add_child(_button("设置",_show_settings))
	_page.add_child(_button("旅行手册",_show_catalog))
	if not _landing_pending: _page.add_child(_button("结束这一竿，回到钓点",_abandon_round))
	if not _landing_pending: _page.add_child(_button("返回大厅",_return_to_lobby))
	_page.add_child(_button("退出游戏",_exit_game))

func _abandon_round() -> void:
	if not _last_record.is_empty():
		_landing_pending = false
		scenery.cancel_landing()
		_show_result()
		return
	store.abandon_session(session.session_id)
	session.reset()
	_close_page()

func _exit_game() -> void:
	if _mode == "whale": _pause_whale(); return
	if not _last_record.is_empty() and not _save_ok:
		_show_result()
		return
	if not store.read_only and not _save_selection():
		_show_lobby_exit("进度暂时未能保存。请重试，或返回游戏继续保留当前进度。")
		return
	get_tree().quit()

func _show_travel() -> void:
	if _mode == "whale": return
	_open_page("travel","旅行")
	menu_pages.populate_travel(self,_page)

func _unlock_region(id: String) -> void:
	if _mode == "whale": return
	if catalog.region(id).is_empty(): return
	var region: Dictionary = catalog.region(id)
	var candidate: Dictionary = store.state.duplicate(true)
	if id in candidate.unlocked_regions or store.discovered_count()<int(region.unlock_count) or int(candidate.currency)<int(region.unlock_cost): return
	candidate.currency = int(candidate.currency)-int(region.unlock_cost)
	candidate.unlocked_regions.append(id)
	if _commit(candidate): _show_travel()

func _can_use_spot(sid: String) -> bool:
	if not catalog.spots.has(sid): return false
	var spot: Dictionary = catalog.spots[sid]
	var gear: Dictionary = catalog.gear[_effective_gear_id()]
	return _effective_gear_id() >= int(spot.min_gear) and float(gear.max_depth_m) >= float(spot.depth_min_m)

func _choose_spot(rid: String,sid: String) -> void:
	# A deferred ordinary travel callback cannot change the independent challenge.
	if _mode == "whale": return
	# Travel buttons can have queued callbacks after CAUGHT, which is not an
	# active round. Neither landing nor an unresolved result may change location.
	if _landing_pending or not _last_record.is_empty():
		_toast_message("请先完成起鱼并处理这次钓获，再选择钓点")
		if _landing_pending: _show_pause()
		else: _show_result()
		return
	if not catalog.spots.has(sid) or str(catalog.spots[sid].region_id) != rid or rid not in store.state.get("unlocked_regions",[]) or not _can_use_spot(sid):
		_toast_message("请先解锁水域，并选择适合钓点的装备")
		return
	if _active_round():
		_toast_message("这一竿还在进行。先继续钓鱼，或在暂停页结束这一竿")
		_show_pause()
		return
	var previous_region: String = region_id
	var previous_spot: String = spot_id
	# Load first, synchronously, before committing the save or changing labels.
	# Stage guarantees that a rejected load retains its previous scene/location.
	if not scenery.set_location(rid,sid):
		_toast_message("这个3D钓点暂时无法进入，已保留原钓点")
		return
	region_id = rid
	spot_id = sid
	if not _save_selection():
		region_id = previous_region
		spot_id = previous_spot
		if not scenery.set_location(previous_region,previous_spot):
			_content_ok = false
			_toast_message("保存失败且原钓点无法恢复，请重新启动游戏")
		return
	_refresh_location_labels()
	if _mode == "lobby": _show_prepare()
	else: _close_page()
	_toast_message(str(catalog.spots[sid].cast_hint))

func _active_round() -> bool:
	var value: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	return value not in [Session.State.IDLE,Session.State.CAUGHT,Session.State.ESCAPED]

func _show_gear() -> void:
	if _mode == "whale": return
	if _screen == "gear": _gear_scroll = _current_scroll()
	else: _gear_scroll = 0
	_open_page("gear","行囊")
	menu_pages.populate_gear(self,_page)
	_restore_page_scroll(_overlay,_gear_scroll)

func _effective_gear_id() -> int:
	if _trial_gear_id >= 0 and _trial_gear_id < catalog.gear.size(): return _trial_gear_id
	# Unsupported future IDs are never overwritten. Startup validation blocks play;
	# use a safe preview index solely to keep the protected archive readable.
	return clampi(int(store.state.get("gear",0)),0,maxi(0,catalog.gear.size()-1))

func _current_rod_icon() -> String:
	return str(catalog.gear[_effective_gear_id()].get("icon","rod"))

func _borrow_gear(id: int) -> void:
	if _mode == "whale": return
	if id < 0 or id >= catalog.gear.size() or _active_round(): return
	_trial_gear_id = id
	_refresh_location()
	_show_gear()

func _clear_trial_gear() -> void:
	if _mode == "whale": return
	if _active_round(): return
	_trial_gear_id = -1
	_refresh_location()
	_show_prepare()

func _equip(id: int) -> void:
	if _mode == "whale": return
	if id < 0 or id >= catalog.gear.size(): return
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
	if _commit(candidate):
		_trial_gear_id = -1
		_refresh_location()
		_show_gear()

func _set_bait(id: String) -> void:
	if _mode == "whale": return
	if catalog.bait_definition(id).is_empty(): return
	if _active_round():
		_toast_message("这一竿的鱼饵与鱼已经确定，下次抛竿前再换")
		return
	var previous_bait: String = bait_id
	bait_id = id
	if _save_selection(): _show_gear()
	else: bait_id = previous_bait
	_bait_control.icon_kind=bait_id
	_bait_control.text=catalog.bait_name(bait_id)

func _show_catalog() -> void:
	if _mode == "whale": return
	_open_page("catalog","图鉴")
	var whale: Dictionary = store.state.get("whale_challenge",{})
	var whale_entry: Button = _button("海洋巨兽 · 蓝鲸" + (" · 已解锁" if bool(whale.get("notebook_unlocked",false)) else " · 挑战后解锁"),_show_whale_notebook)
	whale_entry.name = "WhaleNotebookEntry"
	_page.add_child(whale_entry)
	_list = notebook.populate_catalog(self,_page,_fill_catalog)
	_fill_catalog()
	_restore_page_scroll(_overlay,_catalog_scroll)

func _fill_catalog() -> void:
	if not is_instance_valid(_list): return
	notebook.fill_catalog(self,_list,_open_fish_details)

func _count(id: String) -> int:
	var stats: Dictionary = store.state.get("species_stats",{}).get(id,{})
	return int(stats.get("catch_count",0))

func _show_species(id: String) -> void:
	if _mode == "whale" and id != "blue_whale": return
	if id == "blue_whale": _show_whale_notebook(); return
	if not catalog.fish.has(id): return
	_active_species_id = id
	_open_page("species",catalog.fish[id].name,_return_to_fish_list)
	notebook.populate_species(self,_page,id,_show_zoom,_favorite)

func _show_zoom(id: String) -> void:
	if _mode == "whale": return
	var fish: FishDefinition=catalog.fish[id]
	_open_page("zoom",fish.name+" · 细看",_show_species.bind(id))
	var plate: PanelContainer=_card(Color("e8ecd9"),18)
	_page.add_child(plate)
	plate.add_child(_fish_image(fish,false,false,590))
	_page.add_child(_text(_scientific_name(fish),23,TEAL))
	_page.add_child(_text(fish.morphology,26))

func _fish_image(fish: FishDefinition, thumbnail: bool, silhouette: bool, height: float) -> TextureRect:
	var rect: FishArtView = FishArtViewScript.new()
	rect.configure(fish.species_id,fish_art.texture_for(fish,thumbnail),fish_art.info_for(fish.species_id),silhouette)
	rect.custom_minimum_size.y = height
	if not thumbnail: rect.fit_width(height,600.0)
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
	return "%s · %s\n%s\n%s" % [_length(int(record.get("length_mm",0))),_weight(int(record.get("weight_g",0))),Trial.record_location(record,catalog),str(record.get("caught_at",""))]

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
	notebook.populate_favorites(self,_page,_show_catalog,_open_fish_details)
	_restore_page_scroll(_overlay,_favorites_scroll)

func _show_result() -> void:
	if _last_record.is_empty(): return
	if _landing_pending:
		_show_pause()
		return
	_result_waiting = false
	var id: String=str(_last_record.get("species_id",""))
	if not catalog.fish.has(id): return
	var fish: FishDefinition=catalog.fish[id]
	var protected: bool=bool(_last_record.get("release_only",fish.raw.get("release_only",false)))
	_open_page("result","保护观察" if protected else "钓获")
	var flags: Array[String]=[]
	if bool(_last_settlement.get("new_species",false)): flags.append("首次发现")
	if bool(_last_settlement.get("new_length",false)): flags.append("个人长度新纪录")
	if bool(_last_settlement.get("new_weight",false)): flags.append("个人重量新纪录")
	if not flags.is_empty():
		var ribbon: Label=_text("  ·  ".join(flags),22,GOLD)
		ribbon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		ribbon.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		_page.add_child(ribbon)
	var fish_name: Label=_text(fish.name,43,INK)
	fish_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(fish_name)
	var latin: Label=_text(_scientific_name(fish),21,MUTED)
	latin.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(latin)
	var plate: PanelContainer=_card(Color("e8ecd9"),20)
	_page.add_child(plate)
	var specimen: VBoxContainer=VBoxContainer.new()
	specimen.add_theme_constant_override("separation",4)
	plate.add_child(specimen)
	var image: FishArtView=_fish_image(fish,false,false,325) as FishArtView
	var center: CenterContainer=CenterContainer.new()
	center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	specimen.add_child(center)
	image.custom_minimum_size.x=595.0
	image.fit_width(325,image.custom_minimum_size.x)
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
	var place: Label=_text(str(_last_record.get("size_class","标准")).trim_suffix("个体")+"个体  /  "+Trial.record_location(_last_record,catalog),21,MUTED)
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
	var inspect: Button = _button("查看鱼种资料与纪录",_open_fish_details.bind(id))
	inspect.icon_kind = "book"
	inspect.icon_extent = 38
	_page.add_child(inspect)
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
	# Result actions follow the specimen and records. They remain inside the same
	# touch scroll when space is tight, rather than isolated at the screen bottom.
	var result_footer: VBoxContainer = _page_footer
	result_footer.get_parent().remove_child(result_footer)
	_page.add_child(result_footer)

func _dispose_result(action: String) -> void:
	if _last_record.is_empty() or not _save_ok: return
	var result: Dictionary = store.dispose_catch(str(_last_record.catch_id),action)
	if bool(result.get("ok",false)):
		_finish_result()
		if action=="released":sound.cue("release")
		_toast_message("钓获已处理，图鉴纪录已保留")
	else:
		_page.add_child(_text("保存处理结果失败："+str(result.get("error",store.error_message))+"。请再次点击重试。",23,CORAL))

func _finish_result() -> void:
	_landing_pending = false
	_result_waiting = false
	scenery.cancel_landing()
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
	if _mode == "whale": return
	if _screen == "pause": _settings_back = _show_pause
	elif _screen not in ["settings","about","licenses","float_guide","backup","backup_confirm"]: _settings_back = _close_page
	if not _settings_back.is_valid(): _settings_back = _close_page
	_open_page("settings","设置",_settings_back)
	menu_pages.populate_settings(self,_page)

func _show_float_guide() -> void:
	var back: Callable = _show_prepare if _screen == "prepare" else _show_settings
	_open_page("float_guide","读漂与提竿",back)
	menu_pages.populate_float_guide(self,_page)

func _show_licenses() -> void:
	_open_page("licenses","开源许可",_show_settings)
	for path: String in ["res://data/GODOT_LICENSE.txt","res://data/FONT_LICENSE.txt","res://data/THIRD_PARTY_ART.txt"]:
		if FileAccess.file_exists(path): _page.add_child(_text(FileAccess.get_file_as_string(path),17,MUTED))

func _toggle_setting(key: String) -> void:
	var candidate: Dictionary=store.state.duplicate(true)
	candidate.settings[key]=not bool(candidate.settings.get(key,false if key=="reduce_motion" else true))
	_settings_scroll=_current_scroll()
	if _commit(candidate):
		_apply_preferences()
		_show_settings()
		_restore_page_scroll(_overlay,_settings_scroll)

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
	if not _startup_complete: return
	if not is_node_ready(): return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		if _mode == "whale":
			_pause_whale()
			_save_selection()
			return
		session.cancel_input()
		session.pause()
		sound.suspend(true)
		scenery.suspend(true)
		_save_selection()
		if _overlay==null: call_deferred("_show_pause")
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:
		if _mode == "whale" and not whale_challenge.is_active():
			_resume_whale()
			return
		if _mode == "lobby" and _screen == "home":
			scenery.suspend(false)
			sound.suspend(false)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _mode == "whale": _pause_whale(); return
		if _screen == "result": _show_result()
		elif _screen == "home": _show_lobby_exit()
		else: _show_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()

func _handle_back() -> void:
	if not _startup_complete: return
	if _mode == "whale":
		if whale_challenge.is_active() and whale_challenge.state != WhaleChallenge.State.PAUSED: _pause_whale()
		else: _leave_whale_challenge()
		return
	match _screen:
		"": _show_pause()
		"result": _show_result()
		"escape","lobby_exit":
			if _overlay is FishingFailureModal: _overlay.request_dismiss()
		"home": _show_lobby_exit()
		_:
			if _page_back.is_valid(): _page_back.call()
			else: _close_page()

func _show_about() -> void:
	_open_page("about","关于游戏",_show_settings)
	menu_pages.populate_about(self,_page)

func _show_failure_modal(reason: String) -> void:
	_remove_overlay()
	session.cancel_input()
	session.pause()
	scenery.suspend(true)
	sound.suspend(true,true)
	_safe.visible = false
	_screen = "escape"
	var modal: FishingFailureModal = FailureModal.new()
	modal.configure(reason,Vector4(_safe.get_theme_constant("margin_left"),_safe.get_theme_constant("margin_top"),_safe.get_theme_constant("margin_right"),_safe.get_theme_constant("margin_bottom")))
	modal.retry_requested.connect(_finish_result)
	modal.dismiss_requested.connect(_finish_result)
	_overlay = modal
	add_child(modal)

func _current_scroll() -> int:
	if not is_instance_valid(_overlay): return 0
	var scroll: ScrollContainer = _overlay.find_child("PageScroll",true,false) as ScrollContainer
	return scroll.scroll_vertical if scroll != null else 0

func _restore_page_scroll(expected: Control, value: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(expected) or expected != _overlay: return
	var scroll: ScrollContainer = expected.find_child("PageScroll",true,false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = value

func _scientific_name(fish: FishDefinition) -> String:
	return natural_history.scientific_name(fish.species_id, fish.scientific_name)

func _open_species_source(url: String) -> void:
	# Sources are optional explicit browser actions. All fish facts remain local;
	# the paused notebook/session stays open when the user comes back.
	if not NaturalHistory.safe_source_url(url):
		_toast_message("这条资料链接无法打开")
		return
	session.cancel_input()
	if OS.shell_open(url) != OK: _toast_message("无法打开浏览器，请稍后再试")

func _scroll_to_section(section_name: String) -> void:
	if not is_instance_valid(_page): return
	var target: Control = _page.find_child(section_name,true,false) as Control
	var scroll: ScrollContainer = _page.get_parent() as ScrollContainer
	if target != null and scroll != null:
		scroll.stop_gesture()
		scroll.scroll_vertical = maxi(0,roundi(target.position.y)-8)

func _open_fish_details(id: String) -> void:
	if not catalog.fish.has(id): return
	if _screen == "catalog":
		_catalog_scroll = _current_scroll()
		_notebook_origin = "catalog"
	elif _screen == "favorites":
		_favorites_scroll = _current_scroll()
		_notebook_origin = "favorites"
	elif _screen == "result": _notebook_origin = "result"
	else: _notebook_origin = "catalog"
	_show_species(id)

func _return_to_fish_list() -> void:
	match _notebook_origin:
		"favorites": _show_favorites()
		"result":
			if not _last_record.is_empty(): _show_result()
			else: _show_catalog()
		_: _show_catalog()

func _add_reading_backdrop(parent: Control) -> void:
	var scene: ColorRect=ColorRect.new()
	scene.name="DefocusedLandscape"
	scene.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders3d/menu_defocus.gdshader")
	scene.material=material
	parent.add_child(scene)

func _style_choice_popup(choice: OptionButton) -> void:
	var popup: PopupMenu=choice.get_popup()
	popup.transparent_bg=true
	popup.transparent=true
	# The popup has its own viewport; suppress underlying page text while its
	# clear choices are open so two lists cannot overlap visually.
	popup.about_to_popup.connect(func() -> void:
		if is_instance_valid(_overlay):
			var content: Control=_overlay.find_child("OverlayMargin",true,false)
			if content: content.modulate.a=0.0)
	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(_overlay):
			var content: Control=_overlay.find_child("OverlayMargin",true,false)
			if content: content.modulate.a=1.0)

func _add_gradient(parent: Control, colors: Array, offsets: Array) -> void:
	var gradient: Gradient=Gradient.new()
	gradient.colors=PackedColorArray(colors)
	gradient.offsets=PackedFloat32Array(offsets)
	var texture: GradientTexture2D=GradientTexture2D.new()
	texture.gradient=gradient
	texture.width=8
	texture.height=256
	texture.fill_from=Vector2(0,0)
	texture.fill_to=Vector2(0,1)
	var veil: TextureRect=TextureRect.new()
	veil.texture=texture
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(veil)

func _show_boot() -> void:
	_boot=Control.new()
	_boot.name="LoadingScreen"
	_boot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_boot)
	_add_gradient(_boot,[Color("0e2934"),Color("305b5b"),Color("879c85")],[0.0,0.65,1.0])
	var center: CenterContainer=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boot.add_child(center)
	var content: VBoxContainer=VBoxContainer.new()
	content.custom_minimum_size.x=420
	content.add_theme_constant_override("separation",24)
	center.add_child(content)
	content.add_child(_icon("compass",100))
	for entry: Array in [["远岸钓记",52,Color("f6f0dd")],["循着水声，赴一场相遇",23,Color("d3e1d4")]]:
		var label: Label=_text(str(entry[0]),int(entry[1]),entry[2])
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(label)
	var space: Control=Control.new()
	space.custom_minimum_size.y=44
	content.add_child(space)
	_boot_progress=_bar(Color("d5b673"))
	_boot_progress.custom_minimum_size.y=5
	content.add_child(_boot_progress)
	_boot_status=_text("准备出发",20,Color("e1eadd"))
	_boot_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_boot_status)

func _loading_stage(message: String, progress: float) -> void:
	_boot_status.text=message
	_boot_progress.value=progress
	# Let native frames paint between validation stages; headless callers stay synchronous.
	if DisplayServer.get_name()!="headless":
		await get_tree().process_frame
		await get_tree().process_frame

func _animate_page(page: Control) -> void:
	if DisplayServer.get_name()=="headless" or bool(store.state.get("settings",{}).get("reduce_motion",false)):return
	page.modulate.a=0.0
	_page_tween=create_tween()
	_page_tween.tween_property(page,"modulate:a",1.0,0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _apply_preferences() -> void:
	var settings: Dictionary=store.state.get("settings",{})
	var quality: String=str(settings.get("visual_quality","balanced"))
	if quality not in ["low","balanced","high"]:quality="balanced"
	var reduce_motion: bool=bool(settings.get("reduce_motion",false))
	sound.apply(settings)
	sound.set_low_power(quality=="low")
	scenery.set_visual_quality(quality)
	scenery.set_reduce_motion(reduce_motion)
	Engine.max_fps=30 if quality=="low" else 60
	_apply_button_motion(self,not reduce_motion)

func _apply_button_motion(node: Node, enabled: bool) -> void:
	if node is IconAction: node.animate_press=enabled
	for child: Node in node.get_children(): _apply_button_motion(child,enabled)

func _set_quality(value: String) -> void:
	if value not in ["low","balanced","high"]:return
	var candidate: Dictionary=store.state.duplicate(true)
	candidate.settings["visual_quality"]=value
	_settings_scroll=_current_scroll()
	if _commit(candidate):
		_apply_preferences()
		_show_settings()
		_restore_page_scroll(_overlay,_settings_scroll)

func _show_backup() -> void:
	if _mode == "whale": return
	_backup_candidate=""
	_backup_revision=-1
	_open_page("backup","存档备份与恢复",_show_settings)
	_page.add_child(_text("把旅途带在身边",30,INK))
	_page.add_child(_text("覆盖更新会沿用原存档。若需要卸载或换设备，请先复制备份全文，保存到你自己的笔记或文件中。",22,MUTED))
	_page.add_child(_text("备份包含鱼种数量、尺寸纪录、装备、旅币与待处理钓获。恢复会替换当前进度，确认前会显示预览，并保留一次恢复前快照。",21,MUTED))
	var export_button: Button=_button("生成当前进度备份",_export_backup,true)
	_page.add_child(export_button)
	_backup_edit=TextEdit.new()
	_backup_edit.name="SaveBackupText"
	_backup_edit.custom_minimum_size.y=300
	_backup_edit.placeholder_text="在此粘贴备份全文，或点击上方生成备份"
	_backup_edit.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	_backup_edit.add_theme_font_size_override("font_size",19)
	_backup_edit.add_theme_stylebox_override("normal",Clear.surface(false,12))
	_page.add_child(_backup_edit)
	var actions: HBoxContainer=HBoxContainer.new()
	_page.add_child(actions)
	actions.add_child(_button("复制全文",_copy_backup))
	actions.add_child(_button("粘贴备份",_paste_backup))
	var restore: Button=_button("检查并预览恢复",_preview_backup)
	restore.disabled=_active_round() or _landing_pending or _result_waiting or (not _last_record.is_empty() and not _save_ok)
	_page.add_child(restore)
	if restore.disabled:_page.add_child(_text("请先结束当前一竿并处理钓获，再恢复备份。",21,GOLD))
	var previous: Dictionary=store.export_previous_save_text() if store.has_previous_save() else {}
	if bool(previous.get("ok",false)):
		_page.add_child(_button("查看恢复前的进度",func() -> void:
			_backup_edit.text=str(previous.get("text",""))
			_preview_backup()))

func _export_backup() -> void:
	if not _save_selection():return
	var result: Dictionary=store.export_save_text()
	if not bool(result.get("ok",false)):
		_toast_message(str(result.get("error","备份未能生成")))
		return
	_backup_edit.text=str(result.text)
	_toast_message("已生成备份，请复制全文并保存到游戏以外")

func _copy_backup() -> void:
	if not is_instance_valid(_backup_edit) or _backup_edit.text.is_empty():
		_toast_message("请先生成或粘贴备份")
		return
	DisplayServer.clipboard_set(_backup_edit.text)
	_toast_message("已复制；请粘贴到你的笔记或文件中保存")

func _paste_backup() -> void:
	var value: String=DisplayServer.clipboard_get()
	if value.length()>Store.MAX_TRANSFER_BYTES or value.to_utf8_buffer().size()>Store.MAX_TRANSFER_BYTES:
		_toast_message("备份文本过大，未粘贴")
		return
	_backup_edit.text=value

func _preview_backup() -> void:
	if _active_round() or _landing_pending or _result_waiting:
		_toast_message("请先结束当前一竿再恢复")
		return
	if not _save_selection():return
	var result: Dictionary=store.inspect_save_text(_backup_edit.text)
	if not bool(result.get("ok",false)):
		_toast_message(str(result.get("error","备份无法读取")))
		return
	var compatible: String=_backup_content_error(result.get("state",{}))
	if not compatible.is_empty():
		_toast_message(compatible)
		return
	_backup_candidate=_backup_edit.text
	_backup_revision=int(store.state.get("save_revision",0))
	_open_page("backup_confirm","确认恢复",_show_backup)
	_page.add_child(_text("恢复后将使用这份进度",30,INK))
	var state: Dictionary=result.get("state",{})
	_page.add_child(_text("发现鱼种  %d\n累计钓获  %d 条\n旅币  %d\n待处理钓获  %d 条" % [int(result.discovered_count),int(result.catch_count),int(state.get("currency",0)),state.get("pending_catches",{}).size()],27,TEAL))
	_page.add_child(_text("备份完整性校验通过" if bool(result.get("checksum_verified",false)) else "这是旧版原始存档，未包含完整性校验。请确认内容来自你自己的备份。",21,TEAL if bool(result.get("checksum_verified",false)) else GOLD))
	_page.add_child(_text("当前进度会先保存为恢复前快照。恢复成功后可回到本页找回。",23,MUTED))
	_page.add_child(_button("确认替换当前进度",_confirm_backup,true))
	_page.add_child(_button("取消，保留当前进度",_show_backup))

func _backup_content_error(candidate: Dictionary) -> String:
	if candidate.is_empty():return "备份未包含有效进度"
	var selection: Dictionary=candidate.get("selection",{})
	var rid: String=str(selection.get("region_id","lake"))
	var sid: String=str(selection.get("spot_id","lake_shore"))
	if not catalog.spots.has(sid) or str(catalog.spots[sid].region_id)!=rid:return "备份中的水域不在本版中，请使用匹配版本恢复"
	for id: Variant in candidate.get("species_stats",{}):
		if not catalog.fish.has(str(id)):return "备份含本版未收录的鱼种，原进度未改动"
	for id: Variant in candidate.get("owned_gear",[]):
		if int(id)<0 or int(id)>=catalog.gear.size():return "备份含本版未收录的装备"
	if int(candidate.get("gear",0))>=catalog.gear.size():return "备份含本版未收录的装备"
	var regions: Array[String]=[]
	for region: Dictionary in catalog.regions:regions.append(str(region.region_id))
	for region: Variant in candidate.get("unlocked_regions",[]):
		if str(region) not in regions:return "备份含本版未收录的水域"
	if rid not in candidate.get("unlocked_regions",[]):return "备份选中的水域尚未解锁"
	var baits: Array[String]=[]
	for bait: Dictionary in catalog.baits:baits.append(str(bait.bait_id))
	if str(selection.get("bait_id","worm")) not in baits:return "备份含本版未收录的鱼饵"
	for id: Variant in candidate.get("favorites",[]):
		if not catalog.fish.has(str(id)):return "备份收藏了本版未收录的鱼种"
	for record: Dictionary in candidate.get("pending_catches",{}).values():
		if not catalog.fish.has(str(record.get("species_id",""))):return "备份中的待处理钓获不在本版中"
	return ""

func _confirm_backup() -> void:
	if _mode == "whale": return
	if _screen!="backup_confirm" or _backup_candidate.is_empty():return
	if _active_round() or _landing_pending or _result_waiting:return
	var result: Dictionary=store.import_save_text(_backup_candidate,_backup_revision)
	if not bool(result.get("ok",false)):
		_toast_message(str(result.get("error","恢复未能完成，当前进度保持不变")))
		return
	_backup_candidate=""
	session.reset()
	_trial_gear_id=-1
	var selection: Dictionary=store.state.get("selection",{})
	region_id=str(selection.get("region_id","lake"))
	spot_id=str(selection.get("spot_id","lake_shore"))
	bait_id=str(selection.get("bait_id","worm"))
	game_clock=float(store.state.get("game_clock",0.0))
	var restored_location: bool=_refresh_location()
	_content_ok=_resources_ok and restored_location
	_condition_key=""
	_update_conditions()
	_apply_preferences()
	_last_record={}
	_show_home()
	_toast_message("进度已恢复" if _content_ok else "进度已恢复，但当前游戏资源无法载入，请保留存档并检查游戏文件")

func _whale_location_available() -> bool:
	return region_id == "pacific_ocean" and spot_id == "pacific_bluewater" and region_id in store.state.get("unlocked_regions",[])

func _show_whale_briefing() -> void:
	if _mode == "whale": return
	if _landing_pending or not _last_record.is_empty():
		_toast_message("请先处理当前钓获，再进入鲸影挑战")
		return
	if _active_round():
		_toast_message("请先结束这一竿，再进入鲸影挑战")
		return
	_open_page("whale_briefing","鲸影共鸣",_show_prepare if _mode == "lobby" else _close_page)
	if catalog.fish.has("blue_whale"):
		_page.add_child(_fish_image(catalog.fish["blue_whale"],false,false,240))
	_page.add_child(_text("26 米鲸影 · 可以完成的幻想巨物挑战",28,TEAL))
	_page.add_child(_text("你挑战的是幻海中的蓝鲸影。光线连接鲸影前方的光环，依次完成调谐、跟流与控线，随后在水中见证全身共鸣。",24))
	_section("三个操作阶段")
	_page.add_child(_text("1. 按住 / 松手：把光脉冲留在绿带，连起三道光环。\n2. 按住左 / 右：跟随移动绿带，累计同步 10 秒。\n3. 按住 / 松手：把能量张力留在绿带，累计共鸣 8 秒。",23))
	_page.add_child(_text("每阶段显示绿带、进度和剩余时间；幻线失稳可以重试，也可随时退出。挑战不消耗鱼饵或金币，完成纪录独立保存。",21,MUTED))
	_section("真实蓝鲸 · 哺乳动物")
	_page.add_child(_text("蓝鲸（Balaenoptera musculus）是须鲸，主要滤食磷虾，需要到水面呼吸。NOAA列其受保护；现实观鲸应保持距离，不喂食、不触摸或追逐。近距离船侧画面与能量连线均属于游戏幻想。",21,MUTED))
	_page.add_child(_button("蓝鲸自然图鉴",_show_whale_notebook))
	var start: Button = _button("开始鲸影挑战",_start_whale_challenge,true)
	start.name = "StartWhaleChallenge"
	start.disabled = not _whale_location_available() or store.read_only or not _content_ok or not WhaleStage.model_available()
	_page_footer.add_child(start)
	_page_footer.visible = true
	if not _whale_location_available(): _page.add_child(_text("前往太平洋 · 远洋蓝水航线后可开始。",22,GOLD))
	elif not WhaleStage.model_available(): _page.add_child(_text("蓝鲸专用模型尚未就绪，暂不能开始。",22,GOLD))

func _start_whale_challenge() -> void:
	# Reject queued or repeated start/retry callbacks before touching the current
	# transaction. PAUSED also retains an active challenge and its exact save id.
	if whale_challenge.is_active(): return
	if not _whale_location_available() or store.read_only or not _content_ok or not WhaleStage.model_available(): return
	if _active_round() or _landing_pending or not _last_record.is_empty(): return
	if not _whale_record.is_empty() and not _whale_save_ok:
		_toast_message("请先重试保存或明确放弃本次鲸影纪录")
		return
	if _mode != "whale": _whale_origin_mode = _mode
	store.abandon_whale_challenge(whale_challenge.challenge_id)
	if not whale_challenge.start(game_clock): return
	if not store.begin_whale_challenge(whale_challenge.challenge_id):
		whale_challenge.cancel()
		_toast_message(store.error_message)
		return
	_remove_overlay()
	if is_instance_valid(_whale_view):
		remove_child(_whale_view)
		_whale_view.queue_free()
	_whale_record = {}
	_whale_save_ok = false
	_whale_new_best = false
	_mode = "whale"
	_screen = "whale_challenge"
	_safe.visible = false
	session.cancel_input()
	session.pause()
	scenery.suspend(true)
	scenery.visible = false
	sound.suspend(false)
	_whale_view = WhaleUI.new()
	_whale_view.configure(whale_challenge,Vector4(_safe.get_theme_constant("margin_left"),_safe.get_theme_constant("margin_top"),_safe.get_theme_constant("margin_right"),_safe.get_theme_constant("margin_bottom")))
	_whale_view.exit_requested.connect(_leave_whale_challenge)
	_whale_view.retry_requested.connect(_start_whale_challenge)
	_whale_view.save_retry_requested.connect(_settle_whale_challenge)
	_whale_view.discard_requested.connect(_discard_whale_result)
	_whale_view.notebook_requested.connect(_open_completed_whale_notebook)
	_whale_view.pause_requested.connect(_pause_whale)
	_whale_view.resume_requested.connect(_resume_whale)
	add_child(_whale_view)

func _whale_ended(success: bool, record: Dictionary) -> void:
	if _mode != "whale" or bool(record.get("cancelled",false)): return
	if str(record.get("challenge_id","")) != whale_challenge.challenge_id: return
	if success:
		_whale_record = record.duplicate(true)
		_settle_whale_challenge()
	else:
		store.abandon_whale_challenge(whale_challenge.challenge_id)

func _settle_whale_challenge() -> void:
	if _whale_record.is_empty(): return
	if not _whale_save_ok:
		var result: Dictionary = store.settle_whale_challenge(_whale_record)
		_whale_save_ok = bool(result.get("ok",false))
		_whale_new_best = bool(result.get("new_best",false))
	if is_instance_valid(_whale_view): _whale_view.set_settlement(_whale_save_ok,store.error_message,_whale_new_best)
	if _whale_save_ok: _update_wallet()

func _pause_whale() -> void:
	whale_challenge.pause()
	if is_instance_valid(_whale_view): _whale_view.stage.suspend(true)
	sound.suspend(true)

func _resume_whale() -> void:
	if _mode != "whale": return
	whale_challenge.resume()
	if is_instance_valid(_whale_view): _whale_view.stage.suspend(false)
	sound.suspend(false)

func _discard_whale_result() -> void:
	store.abandon_whale_challenge(whale_challenge.challenge_id)
	_whale_record = {}
	_leave_whale_challenge()

func _leave_whale_challenge() -> void:
	if not _whale_record.is_empty() and not _whale_save_ok:
		if is_instance_valid(_whale_view): _whale_view.set_settlement(false,"先重试保存，或点击明确放弃未保存纪录")
		return
	whale_challenge.cancel()
	store.abandon_whale_challenge(whale_challenge.challenge_id)
	_whale_record = {}
	if is_instance_valid(_whale_view):
		remove_child(_whale_view)
		_whale_view.queue_free()
	_whale_view = null
	_mode = _whale_origin_mode
	_screen = ""
	scenery.visible = true
	if _mode == "lobby":
		_show_prepare()
	else:
		session.reset()
		_safe.visible = true
		scenery.set_mode("fishing")
		scenery.suspend(false)
		sound.suspend(false)
	_update_wallet()
	_save_selection()

func _open_completed_whale_notebook() -> void:
	if not _whale_save_ok: return
	_leave_whale_challenge()
	_show_whale_notebook()

func _show_whale_notebook() -> void:
	if _mode == "whale":
		if not _whale_save_ok: return
		_leave_whale_challenge()
	_open_page("whale_notebook","海洋巨兽 · 蓝鲸")
	_page.name = "WhaleNaturalHistory"
	var whale: Dictionary = store.state.get("whale_challenge",{})
	var known: bool = bool(whale.get("notebook_unlocked",false))
	_page.add_child(_text("Balaenoptera musculus · 哺乳纲 · 须鲸科",22,TEAL))
	if catalog.fish.has("blue_whale"):
		_page.add_child(_fish_image(catalog.fish["blue_whale"],false,not known,280))
	_page.add_child(_text("鲸影共鸣已解锁 · 独立鲸类纪录" if known else "完成鲸影共鸣后解锁完整插画与鲸类纪录",22,TEAL if known else GOLD))
	if known:
		_section("我的鲸影挑战纪录","完成 %d 次" % int(whale.get("completion_count",0)))
		for pair: Array in [["最快完成","best"],["首次完成","first"],["最近完成","last"]]:
			var record: Dictionary = whale.get(pair[1],{})
			if not record.is_empty(): _page.add_child(_text("%s · %.1f 秒 · %s" % [pair[0],float(record.get("duration_ms",0))/1000.0,str(record.get("completed_at","")).replace("T"," ")],21))
		_page.add_child(_text("挑战体长 26 米是固定的游戏展示尺度；最快完成计时不是野生鲸类测量纪录。鲸类完成次数不计入鱼类发现、钓获数量或出售库存。",20,MUTED))
	var biology: Dictionary = natural_history.get_entry("blue_whale")
	for pair: Array in [["分类与身份","taxonomy"],["常见尺度","typical_size"],["资料长度上限","max_length"],["资料体重上限","max_weight"],["生境与水层","habitat"],["现实分布","distribution"],["生活习性","behavior"],["真实食性","diet"],["保护与观察","conservation"]]:
		var field: Dictionary = biology.get(pair[1],{})
		var text: String = str(field.get("text",field.get("note","")))
		if not text.is_empty():
			_section(str(pair[0]))
			_page.add_child(_text(text,22))
	var story: Dictionary = biology.get("story",{})
	if not story.is_empty():
		_section(str(story.get("title","鲸类故事")))
		_page.add_child(_text(str(story.get("text","")),22))
	_section("游戏幻想说明")
	_page.add_child(_text("鲸影不使用鱼饵，不钩刺嘴部，不拉上岸；你操控的是外侧光环与能量线。近距离并行、三阶段共鸣和固定 26 米模型都是美术与玩法改编。真实蓝鲸应保持距离，遵守当地观鲸规则。",21,MUTED))
	_section("资料来源")
	for source: Dictionary in biology.get("sources",[]):
		var url: String = str(source.get("url",""))
		_page.add_child(_button(str(source.get("publisher",""))+" · "+str(source.get("title","")),_open_species_source.bind(url)))
	if _whale_location_available(): _page.add_child(_button("前往鲸影挑战",_show_whale_briefing,true))
	else: _page.add_child(_text("挑战地点 · 太平洋 / 远洋蓝水航线",21,GOLD))
