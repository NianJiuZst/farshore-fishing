class_name FishingMenuPages
extends RefCounted
## Read-only page construction. Main retains navigation, transactions and input.
const INK: Color = Color("213c41")
const MUTED: Color = Color("4d6965")
const GOLD: Color = Color("95601e")
const TEAL: Color = Color("256b63")

func populate_prepare(app: Control, page: VBoxContainer) -> void:
	var region: Dictionary = app.catalog.region(app.region_id)
	var spot: Dictionary = app.catalog.spots.get(app.spot_id,{})
	page.add_child(_hero(app,region,190,false))
	page.add_child(app._text(str(spot.get("name",app.spot_id)),30,INK))
	page.add_child(app._text(str(spot.get("habitat","")),22,MUTED))
	page.add_child(app._button("更换水域与钓点",app._show_travel))
	page.add_child(_rule())
	_section(app,page,"本次装备")
	var loadout: HBoxContainer = HBoxContainer.new()
	page.add_child(loadout)
	loadout.add_child(app._icon(app._current_rod_icon(),80))
	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout.add_child(detail)
	detail.add_child(app._text(str(app.catalog.gear[app._effective_gear_id()].name),27,INK))
	detail.add_child(app._text(app.catalog.bait_name(app.bait_id)+( " · 试钓借用" if app._trial_gear_id >= 0 else ""),22,TEAL))
	loadout.add_child(app._icon(app.bait_id,70))
	page.add_child(app._button("调整钓竿与鱼饵",app._show_gear))
	if app._trial_gear_id >= 0: page.add_child(app._button("使用已装备钓竿",app._clear_trial_gear))
	page.add_child(_rule())
	var fish_here: Array[FishDefinition] = app.catalog.fish_at(app.spot_id)
	_section(app,page,"可遇见的鱼","%d 种" % fish_here.size())
	var names: Array[String] = []
	for fish: FishDefinition in fish_here: names.append(fish.name)
	page.add_child(app._text("、".join(names),22,MUTED))
	page.add_child(app._button("读漂与提竿",app._show_float_guide))
	if not app._can_use_spot(app.spot_id): page.add_child(app._text("当前钓竿无法触及此钓点，请更换装备或钓点",22,GOLD))
	var enter: Button = app._button("进入钓点",app._enter_fishery,true)
	enter.icon_kind = "compass"
	enter.disabled = app.store.read_only or not app._content_ok or not app._can_use_spot(app.spot_id) or app.region_id not in app.store.state.get("unlocked_regions",[])
	app._page_footer.add_child(_rule())
	app._page_footer.add_child(enter)
	app._page_footer.visible = true

func populate_travel(app: Control, page: VBoxContainer) -> void:
	page.add_child(app._text("当前 · "+str(app.catalog.region(app.region_id).name)+" / "+str(app.catalog.spots[app.spot_id].name),22,TEAL))
	for region: Dictionary in app.catalog.regions:
		var rid: String = str(region.region_id)
		var unlocked: bool = rid in app.store.state.get("unlocked_regions",[])
		page.add_child(_hero(app,region,205,not unlocked))
		var total: int = 0
		var discovered: int = 0
		for fish: FishDefinition in app.catalog.fish.values():
			if rid in fish.regions():
				total += 1
				if app._count(fish.species_id)>0: discovered += 1
		_section(app,page,str(region.name),"已发现 %d / %d" % [discovered,total])
		if unlocked:
			var choices: HBoxContainer = HBoxContainer.new()
			choices.add_theme_constant_override("separation",20)
			page.add_child(choices)
			for sid: String in region.spots:
				var spot: Dictionary = app.catalog.spots[sid]
				var column: VBoxContainer = VBoxContainer.new()
				column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				choices.add_child(column)
				var label: String = ("当前 · " if sid==app.spot_id else "")+str(spot.name)
				var go: Button = app._button(label,app._choose_spot.bind(rid,sid),sid==app.spot_id)
				go.icon_kind = "compass" if sid==app.spot_id else "arrow"
				go.icon_extent = 36
				go.add_theme_font_size_override("font_size",22)
				go.disabled = not app._can_use_spot(sid)
				column.add_child(go)
				column.add_child(app._text("水深 %s–%s m" % [str(spot.depth_min_m),str(spot.depth_max_m)],19,MUTED))
				if go.disabled: column.add_child(app._text("需要更强钓竿",18,GOLD))
		else:
			var need: int = int(region.unlock_count)
			var cost: int = int(region.unlock_cost)
			page.add_child(app._text("解锁条件 · 发现 %d 种鱼，花费 %d 旅币" % [need,cost],21,MUTED))
			var unlock: Button = app._button("解锁水域 · %d 旅币" % cost,app._unlock_region.bind(rid),true)
			unlock.icon_kind = "compass"
			unlock.disabled = app.store.discovered_count()<need or int(app.store.state.currency)<cost
			page.add_child(unlock)
		page.add_child(_rule())

func populate_gear(app: Control, page: VBoxContainer) -> void:
	var current: Dictionary = app.catalog.gear[app._effective_gear_id()]
	_section(app,page,"当前搭配","%d 旅币" % int(app.store.state.currency))
	page.add_child(app._text(str(current.name)+" · "+app.catalog.bait_name(app.bait_id),25,TEAL))
	var jump: HBoxContainer = HBoxContainer.new()
	page.add_child(jump)
	for pair: Array in [["钓竿","rod","RodSection"],["鱼饵","lure","BaitSection"]]:
		var button: Button = app._button(str(pair[0]),app._scroll_to_section.bind(str(pair[2])))
		button.icon_kind = str(pair[1])
		button.icon_extent = 40
		jump.add_child(button)
	page.add_child(_rule())
	var rods: HBoxContainer = _section(app,page,"我的钓竿","共 %d 款" % app.catalog.gear.size())
	rods.name = "RodSection"
	for item: Dictionary in app.catalog.gear:
		var id: int = int(item.id)
		var owned: bool = id in app.store.state.owned_gear
		var equipped: bool = int(app.store.state.gear)==id and app._trial_gear_id<0
		var selected: bool = app._effective_gear_id()==id
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation",10)
		page.add_child(box)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation",20)
		box.add_child(row)
		row.add_child(app._icon(str(item.get("icon","rod")),100))
		var detail: VBoxContainer = VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(detail)
		detail.add_child(app._text(str(item.name),27,GOLD if selected else INK))
		detail.add_child(app._text(str(item.description),21,MUTED))
		detail.add_child(app._text("收线 ×%.2f   容错 ×%.2f" % [float(item.power),float(item.tolerance)],20,TEAL))
		detail.add_child(app._text("抛投 %d%%   探深 %d m" % [roundi(float(item.reach)*100),int(item.max_depth_m)],20,MUTED))
		var actions: HBoxContainer = HBoxContainer.new()
		box.add_child(actions)
		var label: String = "已装备" if equipped else ("装备" if owned else "购买 · %d 旅币" % int(item.price))
		var action: Button = app._button(label,app._equip.bind(id),not owned)
		action.icon_extent = 38
		action.disabled = equipped or (not owned and int(app.store.state.currency)<int(item.price))
		actions.add_child(action)
		if not owned:
			var borrow: Button = app._button("试钓借用中" if app._trial_gear_id==id else "试钓借用",app._borrow_gear.bind(id))
			borrow.icon_kind = str(item.get("icon","rod"))
			borrow.icon_extent = 40
			borrow.disabled = app._trial_gear_id==id
			actions.add_child(borrow)
		box.add_child(_rule())
	page.add_child(app._text("借用仅本次有效，购买后永久加入行囊",20,MUTED))
	var bait_title: HBoxContainer = _section(app,page,"鱼饵","无限补给 · 不消耗旅币")
	bait_title.name = "BaitSection"
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",24)
	grid.add_theme_constant_override("v_separation",24)
	page.add_child(grid)
	for bait: Dictionary in app.catalog.baits:
		var box: VBoxContainer = VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.custom_minimum_size.x = 280
		grid.add_child(box)
		var selected: bool = str(bait.bait_id)==app.bait_id
		var action: Button = app._button(("已选 · " if selected else "")+str(bait.name),app._set_bait.bind(str(bait.bait_id)),selected)
		action.icon_kind = str(bait.bait_id)
		action.stacked = true
		action.icon_extent = 78
		action.custom_minimum_size.y = 144
		box.add_child(action)
		box.add_child(app._text(str(bait.hint),20,MUTED))
		box.add_child(_rule())

func populate_settings(app: Control, page: VBoxContainer) -> void:
	var settings: Dictionary = app.store.state.get("settings",{})
	_section(app,page,"声音与反馈")
	for pair: Array in [["sound","声音"],["vibration","震动"]]:
		page.add_child(app._button(str(pair[1])+"："+("开" if bool(settings.get(pair[0],true)) else "关"),app._toggle_setting.bind(str(pair[0]))))
	var volume_head: HBoxContainer = HBoxContainer.new()
	page.add_child(volume_head)
	volume_head.add_child(app._text("总音量",24,INK))
	var value: Label = app._text("%d%%" % roundi(float(settings.get("volume",0.6))*100),22,TEAL)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_head.add_child(value)
	var volume: HSlider = HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(settings.get("volume",0.6))
	volume.custom_minimum_size.y = 96
	volume.value_changed.connect(func(number: float) -> void: value.text="%d%%" % roundi(number*100))
	volume.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			var candidate: Dictionary = app.store.state.duplicate(true)
			candidate.settings.volume = volume.value
			if app._commit(candidate): app.sound.apply(candidate.settings))
	page.add_child(volume)
	page.add_child(_rule())
	_section(app,page,"本地存档")
	page.add_child(app._text("钓获与操作自动保存。卸载或清除应用数据会丢失进度，请保留当前应用。",22,MUTED))
	var pending: int = app.store.state.get("pending_catches",{}).size()
	page.add_child(app._button("待处理钓获 · %d 条" % pending,app._show_pending))
	page.add_child(_rule())
	_section(app,page,"游玩说明")
	page.add_child(app._button("读漂与提竿",app._show_float_guide))
	page.add_child(app._text("日间与黄昏每 2 分 30 秒切换，晴与微雨每 4 分钟切换。暂停时停止流转。",22,MUTED))
	page.add_child(app._button("关于游戏与开源许可",app._show_about))
	page.add_child(app._text("版本 "+str(ProjectSettings.get_setting("application/config/version","")),19,MUTED))

func populate_float_guide(app: Control, page: VBoxContainer) -> void:
	page.add_child(app._text("先看水线，再看变化",30,INK))
	page.add_child(app._text("浮漂的彩色漂目是水线的参照。水波会托着浮漂一起起伏；鱼改变线组受力时，露出的漂目和运动方向才会改变。",24,MUTED))
	page.add_child(_rule())
	for pair: Array in [
		["轻点后回位", "可能只是试探或碰线。留意后续变化，鱼也可能离开后再来。"],
		["送漂、顿沉、定向横移", "含饵托起配重会送漂，带饵移动会下沉或横移。动作连贯并偏离水波节奏时，及时提竿。"],
		["小动作也可能是真口", "漂目只变化一点、却停留在新水线，也可能值得提竿。不必等整支漂消失。"],
		["回到原水线", "可能已经吐饵。继续观察或收回重抛；等得更久并不保证上钩。"]]:
		page.add_child(app._text(str(pair[0]),27,INK))
		page.add_child(app._text(str(pair[1]),23,MUTED))
		page.add_child(_rule())
	page.add_child(app._text("点按收线提竿，上鱼后按住收线、松手卸力。提竿只在钩饵仍被鱼含住时有效，不按固定秒数判定。",23,TEAL))
	page.add_child(app._text("本游戏自动搭配并简化了水深、配重与钓组。现实漂相还受调漂、流水和饵料影响，没有一种动作能保证中鱼。",20,MUTED))

func populate_about(app: Control, page: VBoxContainer) -> void:
	_section(app,page,"远岸钓记",str(ProjectSettings.get_setting("application/config/version","")))
	page.add_child(app._text("离线单机 · 44 种鱼 · 12 处钓点",25,INK))
	page.add_child(app._text("角色、鱼与场景几何及骨骼动画：本项目制作\n天空、木材与岩石纹理：Poly Haven，CC0\n高清鱼类插画与界面图标：图像生成模型制作并校对\n字体：Noto Sans CJK，SIL Open Font License\n音效：本项目程序合成\n引擎：Godot 4.6.3，MIT License",22,MUTED))
	page.add_child(app._button("查看引擎、字体与素材许可",app._show_licenses))

func _hero(app: Control, region: Dictionary, height: float, locked: bool) -> Control:
	var hero: Control = Control.new()
	hero.custom_minimum_size.y = height
	hero.clip_contents = true
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture: TextureRect = app._scene_picture(str(region.scene),0)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked: picture.modulate = Color(0.80,0.86,0.83,1)
	hero.add_child(picture)
	return hero

func _section(app: Control, page: VBoxContainer, title: String, detail: String = "") -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(app._text(title,28,INK))
	if not detail.is_empty():
		var label: Label = app._text(detail,20,MUTED)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(label)
	page.add_child(row)
	return row

func _rule() -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = Color(0.3,0.47,0.44,0.22)
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
