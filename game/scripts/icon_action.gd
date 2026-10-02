class_name IconAction
extends Button
# Transparent hit target. The visual is always an illustration plus a label, never a plate.
const Art=preload("res://scripts/ui_art.gd")
var icon_kind: String="arrow"
var stacked: bool=false
var icon_extent: float=58.0
var label_color: Color=Color("244449")
var light_label: bool=false
var _art: Control
var _caption: Label
var _last_text: String="\u0001"
func _ready() -> void:
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_focus_color","font_outline_color"]:
		add_theme_color_override(state,Color.TRANSPARENT)
	_art=Art.new()
	_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_caption=Label.new()
	_caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_color_override("font_outline_color",Color("173b42") if light_label else Color(0.96,0.98,0.91,0.90))
	_caption.add_theme_constant_override("outline_size",6 if light_label else 2)
	if light_label:
		_caption.add_theme_color_override("font_shadow_color",Color("102c34"))
		_caption.add_theme_constant_override("shadow_offset_x",1)
		_caption.add_theme_constant_override("shadow_offset_y",2)
	add_child(_caption)
	resized.connect(_layout)
	_layout()
func _process(_delta: float) -> void:
	if _caption==null:return
	if _last_text!=text:
		_last_text=text
		_caption.text=text
		_layout()
	var active: bool=is_hovered() or button_pressed
	_caption.add_theme_color_override("font_color",label_color.lightened(0.18) if active else label_color)
	_caption.modulate.a=0.42 if disabled else 1.0
	_art.modulate=Color(1.06,1.06,1.06,0.45 if disabled else 1.0) if active else Color(1,1,1,0.42 if disabled else 1.0)
	_art.kind=icon_kind
func _layout() -> void:
	if _caption==null:return
	_caption.add_theme_font_size_override("font_size",get_theme_font_size("font_size"))
	var extent: float=icon_extent
	if icon_extent<=0:
		_art.size=Vector2.ZERO
		_caption.position=Vector2.ZERO
		_caption.size=size
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif stacked:
		_art.position=Vector2((size.x-extent)*0.5,0)
		_art.size=Vector2(extent,extent)
		_caption.position=Vector2(0,extent-3)
		_caption.size=Vector2(size.x,maxf(36,size.y-extent))
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	else:
		_art.position=Vector2(4,(size.y-extent)*0.5)
		_art.size=Vector2(extent,extent)
		_caption.position=Vector2(extent+14,0)
		_caption.size=Vector2(maxf(0,size.x-extent-16),size.y)
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
