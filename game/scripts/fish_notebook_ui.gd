class_name FishNotebookUI
extends RefCounted
## Native, read-only notebook presentation. Main owns navigation and writes.
## One BaseButton owns each whole specimen tile; its art and labels ignore input.
const INK: Color = Color("213c41")
const MUTED: Color = Color("4d6965")
const TEAL: Color = Color("256b63")
const GOLD: Color = Color("95601e")
const RULE: Color = Color(0.30, 0.47, 0.44, 0.24)
const Trial = preload("res://scripts/trial_fishery.gd")

func populate_catalog(app: Control, page: VBoxContainer, refill: Callable) -> GridContainer:
	page.name = "FishNotebookCatalog"
	page.add_theme_constant_override("separation", 16)
	var totals: HBoxContainer = HBoxContainer.new()
	page.add_child(totals)
	totals.add_child(_label(app, "已发现 %d / %d 种" % [app.store.discovered_count(), app.catalog.fish.size()], 24, INK))
	var count: Label = _label(app, "累计 %d 条" % app.store.total_count(), 21, MUTED)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	totals.add_child(count)
	page.add_child(_label(app, "点击鱼身查看详情", 19, MUTED))
	var search_row: HBoxContainer = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 10)
	page.add_child(search_row)
	search_row.add_child(app._icon("search", 30))
	var search: LineEdit = LineEdit.new()
	search.name = "NotebookSearch"
	search.placeholder_text = "搜索中文名或学名"
	search.text = app._search
	search.custom_minimum_size.y = 96
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size", 23)
	search.text_changed.connect(func(value: String) -> void:
		app._search = value
		refill.call())
	search_row.add_child(search)
	page.add_child(_rule())
	var filters: HBoxContainer = HBoxContainer.new()
	filters.add_theme_constant_override("separation", 12)
	page.add_child(filters)
	var regions: OptionButton = OptionButton.new()
	regions.name = "NotebookRegionFilter"
	regions.custom_minimum_size = Vector2(210, 96)
	regions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regions.add_theme_font_size_override("font_size", 21)
	regions.add_item("全部水域")
	for region: Dictionary in app.catalog.regions: regions.add_item(str(region.name))
	for i: int in range(app.catalog.regions.size()):
		if str(app.catalog.regions[i].region_id) == app._region_filter: regions.select(i + 1)
	regions.item_selected.connect(func(index: int) -> void:
		app._region_filter = "all" if index == 0 else str(app.catalog.regions[index - 1].region_id)
		refill.call())
	filters.add_child(regions)
	var discovery: OptionButton = OptionButton.new()
	discovery.name = "NotebookDiscoveryFilter"
	discovery.custom_minimum_size = Vector2(166, 96)
	discovery.add_theme_font_size_override("font_size", 21)
	for value: String in ["全部鱼种", "已发现", "待发现"]: discovery.add_item(value)
	discovery.select(app._discovery_filter)
	discovery.item_selected.connect(func(index: int) -> void:
		app._discovery_filter = index
		refill.call())
	filters.add_child(discovery)
	var sort: Button = app._button("按数量" if app._sort_count else "按名称", func() -> void:
		app._sort_count = not app._sort_count
		refill.call())
	sort.name = "NotebookSort"
	sort.custom_minimum_size = Vector2(144, 96)
	sort.icon_kind = "sort"
	sort.icon_extent = 28
	sort.add_theme_font_size_override("font_size", 21)
	filters.add_child(sort)
	var grid: GridContainer = _grid()
	grid.name = "NotebookSpeciesGrid"
	page.add_child(grid)
	if app.store.read_only:
		page.add_child(_label(app, "存档保护模式 · 现有资料与纪录仍可阅读", 19, MUTED))
	return grid

func fill_catalog(app: Control, grid: GridContainer, open_species: Callable) -> void:
	if not is_instance_valid(grid): return
	for child: Node in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var state: Dictionary = app.store.state
	var values: Array = app.catalog.fish.values()
	values.sort_custom(func(a: FishDefinition, b: FishDefinition) -> bool:
		if app._sort_count:
			var ac: int = _count(state, a.species_id)
			var bc: int = _count(state, b.species_id)
			if ac != bc: return ac > bc
		return a.name.naturalnocasecmp_to(b.name) < 0)
	var sort: Button = grid.get_parent().find_child("NotebookSort", false, false) as Button
	if sort == null: sort = grid.get_parent().find_child("NotebookSort", true, false) as Button
	if sort != null: sort.text = "按数量" if app._sort_count else "按名称"
	for fish: FishDefinition in values:
		var known: bool = _count(state, fish.species_id) > 0
		if app._region_filter != "all" and app._region_filter not in fish.regions(): continue
		if app._discovery_filter == 1 and not known: continue
		if app._discovery_filter == 2 and known: continue
		var query: String = str(app._search).strip_edges().to_lower()
		if not query.is_empty() and not (query in fish.name.to_lower() or query in fish.scientific_name.to_lower()): continue
		grid.add_child(_species_tile(app, fish, state, open_species))
	if grid.get_child_count() == 0:
		var empty: VBoxContainer = VBoxContainer.new()
		empty.custom_minimum_size = Vector2(300, 190)
		empty.add_child(_label(app, "这一页暂时没有鱼", 27, INK))
		empty.add_child(_label(app, "试试其他名字、水域或发现状态", 21, MUTED))
		grid.add_child(empty)

func populate_species(app: Control, page: VBoxContainer, id: String, open_zoom: Callable, favorite: Callable) -> void:
	if not app.catalog.fish.has(id): return
	page.name = "FishNotebookDetail"
	page.add_theme_constant_override("separation", 18)
	var fish: FishDefinition = app.catalog.fish[id]
	var state: Dictionary = app.store.state
	var stats: Dictionary = state.get("species_stats", {}).get(id, {})
	var count: int = int(stats.get("catch_count", 0))
	var known: bool = count > 0
	var latin: Label = _label(app, fish.scientific_name, 22, MUTED)
	latin.name = "SpeciesScientificName"
	page.add_child(latin)
	var image: TextureRect = app._fish_image(fish, false, false, 242)
	page.add_child(image)
	var status: HBoxContainer = HBoxContainer.new()
	page.add_child(status)
	status.add_child(_label(app, "我的钓获" if known else "尚未发现 · 资料预览", 22, TEAL))
	var rarity: Label = _label(app, str(fish.raw.get("rarity", "")), 18, MUTED)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(rarity)
	var summary: HBoxContainer = HBoxContainer.new()
	summary.name = "CatchRecordSummary"
	summary.add_theme_constant_override("separation", 18)
	page.add_child(summary)
	var longest: Dictionary = stats.get("max_length", {})
	var heaviest: Dictionary = stats.get("max_weight", {})
	summary.add_child(_metric(app, "累计钓获", "%d 条" % count, "CatchCount"))
	summary.add_child(_metric(app, "最长个体", app._length(int(longest.length_mm)) if not longest.is_empty() else "—", "MaxLength"))
	summary.add_child(_metric(app, "最重个体", app._weight(int(heaviest.weight_g)) if not heaviest.is_empty() else "—", "MaxWeight"))
	if not known:
		page.add_child(_label(app, "尚无钓获纪录。第一次相遇后，这里会留下你的尺寸与水域记录。", 20, MUTED))
	elif count == 1:
		page.add_child(_label(app, "已记录第一次相遇", 19, MUTED))
	else:
		page.add_child(_label(app, "最长与最重分别保留各自的真实个体记录", 19, MUTED))
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 24)
	page.add_child(actions)
	var zoom: Button = app._button("查看大图", open_zoom.bind(id))
	zoom.name = "NotebookZoom"
	zoom.icon_kind = "search"
	zoom.icon_extent = 30
	zoom.custom_minimum_size.y = 96
	actions.add_child(zoom)
	if known:
		var saved: bool = id in state.get("favorites", [])
		var favorite_button: Button = app._button("移出收藏" if saved else "加入收藏", favorite.bind(id), not saved)
		favorite_button.name = "NotebookFavorite"
		favorite_button.icon_extent = 30
		favorite_button.custom_minimum_size.y = 96
		favorite_button.disabled = app.store.read_only
		actions.add_child(favorite_button)
	page.add_child(_rule())
	_section(app, page, "认识这种鱼")
	page.add_child(_label(app, fish.description, 24, INK))
	if fish.release_only:
		page.add_child(_label(app, "保护观察 · 仅在游戏中虚拟相遇，记录后即刻放归水中", 21, GOLD))
	_section(app, page, "形态特征")
	page.add_child(_label(app, fish.morphology, 22, MUTED))
	_section(app, page, "栖息水域与钓点")
	for sid: String in fish.spots():
		var spot: Dictionary = app.catalog.spots.get(sid, {})
		var region: Dictionary = app.catalog.region(str(spot.get("region_id", "")))
		page.add_child(_label(app, str(region.get("name", "")) + " · " + str(spot.get("name", sid)), 22, INK))
	_section(app, page, "鱼饵线索")
	var preferred: String = "worm"
	var best: float = -1.0
	for bait: Dictionary in app.catalog.baits:
		var weight: float = app.catalog.bait_weight(fish, str(bait.bait_id))
		if weight > best:
			preferred = str(bait.bait_id)
			best = weight
	page.add_child(_label(app, app.catalog.bait_name(preferred), 26, TEAL))
	var bait_info: Dictionary = app.catalog.bait_definition(preferred)
	if not str(bait_info.get("hint", "")).is_empty(): page.add_child(_label(app, str(bait_info.hint), 21, MUTED))
	page.add_child(_label(app, "此线索用于游戏；尺寸、行为与出现倍率含游戏调校", 18, MUTED))
	page.add_child(_rule())
	_section(app, page, "个人钓获纪录", "%d 条" % count)
	if known:
		for pair: Array in [["最长个体", "max_length"], ["最重个体", "max_weight"], ["首次钓获", "first"], ["最近钓获", "last"]]:
			_record(app, page, str(pair[0]), stats.get(pair[1], {}), str(pair[1]))
		_section(app, page, "各水域钓获")
		var regions: Dictionary = stats.get("regions", {})
		if regions.is_empty(): page.add_child(_label(app, "早期存档未记录水域数量", 20, MUTED))
		for region_id: String in regions:
			var region: Dictionary = app.catalog.region(region_id)
			var row: HBoxContainer = HBoxContainer.new()
			row.name = "CatchRegion_" + region_id
			row.add_child(_label(app, str(region.get("name", region_id)), 22, INK))
			var number: Label = _label(app, "%d 条" % int(regions[region_id]), 22, TEAL)
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(number)
			page.add_child(row)
	else:
		page.add_child(_label(app, "第一次钓获后，将记录时间、地点与尺寸", 20, MUTED))
	if app.store.read_only: page.add_child(_label(app, "存档保护模式 · 当前纪录只读", 19, MUTED))
	_section(app, page, "资料参考")
	for source: Dictionary in fish.raw.get("sources", []):
		page.add_child(_label(app, str(source.get("title", "")), 19, MUTED))
		page.add_child(_label(app, str(source.get("url", "")), 16, MUTED))

func populate_favorites(app: Control, page: VBoxContainer, open_catalog: Callable, open_species: Callable) -> void:
	page.name = "FishNotebookFavorites"
	page.add_theme_constant_override("separation", 20)
	var state: Dictionary = app.store.state
	var favorites: Array = state.get("favorites", [])
	page.add_child(_label(app, "我的收藏 · %d / 6 种" % favorites.size(), 24, INK))
	page.add_child(_label(app, "留下喜欢的鱼，每次相遇的纪录都在这里", 20, MUTED))
	page.add_child(_rule())
	var grid: GridContainer = _grid()
	page.add_child(grid)
	for id: String in favorites:
		if app.catalog.fish.has(id): grid.add_child(_species_tile(app, app.catalog.fish[id], state, open_species, true))
	if favorites.is_empty():
		var empty: VBoxContainer = VBoxContainer.new()
		empty.add_theme_constant_override("separation", 24)
		empty.custom_minimum_size.y = 330
		page.add_child(empty)
		empty.add_child(app._icon("heart", 80))
		var title: Label = _label(app, "收藏第一种喜欢的鱼", 29, INK)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(title)
		var hint: Label = _label(app, "钓获后，在鱼种详情中加入收藏。\n这里会保留鱼的模样和你的真实纪录。", 22, MUTED)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(hint)
	var browse: Button = app._button("去图鉴看看" if favorites.is_empty() else "继续挑选收藏", open_catalog)
	browse.name = "NotebookBrowseCatalog"
	page.add_child(browse)

func _species_tile(app: Control, fish: FishDefinition, state: Dictionary, open_species: Callable, favorite: bool = false) -> Button:
	var count: int = _count(state, fish.species_id)
	var tile: Button = Button.new()
	tile.name = "FishTile_" + fish.species_id
	tile.set_meta("species_id", fish.species_id)
	tile.set_meta("fish_species_id", fish.species_id)
	tile.text = fish.name
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]:
		tile.add_theme_color_override(color_name, Color.TRANSPARENT)
	tile.set_meta("notebook_tile", true)
	tile.tooltip_text = fish.name + " · " + fish.scientific_name
	tile.custom_minimum_size = Vector2(288, 324)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name: String in ["normal", "disabled", "hover", "pressed", "hover_pressed", "focus"]:
		tile.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	tile.pressed.connect(open_species.bind(fish.species_id))
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	tile.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var image: TextureRect = app._fish_image(fish, true, count == 0, 165)
	box.add_child(image)
	var title: Label = _label(app, fish.name, 27, INK)
	title.name = "FishTileName"
	tile.mouse_entered.connect(func() -> void: title.add_theme_color_override("font_color", TEAL))
	tile.mouse_exited.connect(func() -> void: title.add_theme_color_override("font_color", TEAL if tile.has_focus() else INK))
	tile.focus_entered.connect(func() -> void: title.add_theme_color_override("font_color", TEAL))
	tile.focus_exited.connect(func() -> void: title.add_theme_color_override("font_color", INK))
	tile.button_down.connect(func() -> void: title.add_theme_color_override("font_color", GOLD))
	tile.button_up.connect(func() -> void: title.add_theme_color_override("font_color", TEAL if tile.has_focus() else INK))
	box.add_child(title)
	var latin: Label = _label(app, fish.scientific_name, 16, MUTED)
	latin.max_lines_visible = 1
	latin.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(latin)
	var detail: String = "累计 %d 条" % count if count > 0 else "待发现 · 点击查看资料"
	if favorite:
		var stats: Dictionary = state.get("species_stats", {}).get(fish.species_id, {})
		var longest: Dictionary = stats.get("max_length", {})
		if not longest.is_empty(): detail = "%d 条 · 最长 %s" % [count, app._length(int(longest.length_mm))]
	box.add_child(_label(app, detail, 18, TEAL if count > 0 else MUTED))
	box.add_child(_rule())
	_ignore_input(margin)
	return tile

func _metric(app: Control, title: String, value: String, node_name: String) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.name = node_name
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_stretch_ratio = 1.0
	box.add_theme_constant_override("separation", 4)
	box.add_child(_label(app, title, 18, MUTED))
	box.add_child(_label(app, value, 31, INK))
	return box

func _record(app: Control, page: VBoxContainer, title: String, snapshot: Dictionary, key: String) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "CatchSnapshot_" + key
	box.set_meta("snapshot", snapshot.duplicate(true))
	box.add_theme_constant_override("separation", 5)
	page.add_child(box)
	box.add_child(_label(app, title, 21, TEAL))
	if snapshot.is_empty():
		box.add_child(_label(app, "早期存档未保留此项详情", 20, MUTED))
		return
	box.add_child(_label(app, app._length(int(snapshot.get("length_mm", 0))) + "  ·  " + app._weight(int(snapshot.get("weight_g", 0))), 28, INK))
	var location: String = Trial.record_location(snapshot, app.catalog)
	box.add_child(_label(app, location if not location.strip_edges().replace("/", "").strip_edges().is_empty() else "地点未记录", 20, MUTED))
	box.add_child(_label(app, str(snapshot.get("caught_at", "时间未记录")), 18, MUTED))
	box.add_child(_rule())

func _section(app: Control, page: VBoxContainer, title: String, detail: String = "") -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 48
	row.add_child(_label(app, title, 27, INK))
	if not detail.is_empty():
		var note: Label = _label(app, detail, 20, MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(note)
	page.add_child(row)

func _grid() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 22)
	return grid

func _label(app: Control, value: String, font_size: int, color: Color) -> Label:
	var label: Label = app._text(value, font_size, color)
	label.add_theme_constant_override("outline_size", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _rule() -> ColorRect:
	var rule: ColorRect = ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _ignore_input(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children(): _ignore_input(child)

func _count(state: Dictionary, id: String) -> int:
	return int(state.get("species_stats", {}).get(id, {}).get("catch_count", 0))
