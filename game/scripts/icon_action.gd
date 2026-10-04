class_name IconAction
extends Button
# Consistent touch surfaces, visible focus and restrained press feedback.
const Art=preload("res://scripts/ui_art.gd")
var icon_kind: String="arrow"
var stacked: bool=false
var icon_extent: float=58.0
var label_color: Color=Color("244449")
var light_label: bool=false
var appearance: String="surface"
var animate_press: bool=true
var _art: Control
var _caption: Label
var _last_text: String="\u0001"
var _last_visual: String=""
var _press_tween: Tween
func _ready() -> void:
	_apply_surface()
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
	_caption.add_theme_constant_override("outline_size",0)
	add_child(_caption)
	resized.connect(_layout)
	button_down.connect(_press_feedback.bind(true))
	button_up.connect(_press_feedback.bind(false))
	mouse_exited.connect(_press_feedback.bind(false))
	_layout()
func _apply_surface() -> void:
	var base: Color=Color("e8eeea")
	if appearance=="primary": base=Color("28675e")
	elif appearance=="glass" or light_label: base=Color(0.035,0.12,0.15,0.82)
	elif appearance=="subtle": base=Color(0.85,0.90,0.86,0.35)
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var box: StyleBoxFlat=StyleBoxFlat.new()
		box.bg_color=base
		if state=="hover": box.bg_color=base.lightened(0.06)
		if state in ["pressed","hover_pressed"]: box.bg_color=base.darkened(0.12)
		if state=="disabled": box.bg_color=Color(base,0.25)
		box.set_corner_radius_all(22 if appearance=="primary" else 18)
		box.border_color=Color(0.75,0.88,0.80,0.20) if light_label or appearance=="primary" else Color(0.17,0.34,0.31,0.12)
		box.set_border_width_all(1)
		if state=="focus":
			box.bg_color=Color.TRANSPARENT
			box.border_color=Color("d0ad64")
			box.set_border_width_all(3)
		add_theme_stylebox_override(state,box)
func _press_feedback(down: bool) -> void:
	if _press_tween: _press_tween.kill()
	if not animate_press or disabled:
		scale=Vector2.ONE
		return
	pivot_offset=size*0.5
	_press_tween=create_tween()
	_press_tween.tween_property(self,"scale",Vector2.ONE*0.965 if down else Vector2.ONE,0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func _process(_delta: float) -> void:
	if _caption==null:return
	if _last_text!=text:
		_last_text=text
		_caption.text=text
		_layout()
	var active: bool=is_hovered() or button_pressed
	var visual: String="%s:%s:%s:%s:%s:%s" % [active,disabled,icon_kind,label_color,light_label,appearance]
	if visual==_last_visual:return
	_last_visual=visual
	_apply_surface()
	_caption.add_theme_color_override("font_color",(label_color.lightened(0.08) if light_label else label_color.darkened(0.08)) if active else label_color)
	_caption.modulate.a=0.42 if disabled else 1.0
	_art.modulate=Color(1.06,1.06,1.06,0.45 if disabled else 1.0) if active else Color(1,1,1,0.42 if disabled else 1.0)
	_art.kind=icon_kind
func _layout() -> void:
	if _caption==null:return
	_caption.add_theme_font_size_override("font_size",get_theme_font_size("font_size"))
	var extent: float=icon_extent
	pivot_offset=size*0.5
	if icon_extent<=0:
		_art.size=Vector2.ZERO
		_caption.position=Vector2.ZERO
		_caption.size=size
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	elif stacked:
		var top: float=maxf(6,(size.y-extent-34)*0.5)
		_art.position=Vector2((size.x-extent)*0.5,top)
		_art.size=Vector2(extent,extent)
		_caption.position=Vector2(6,top+extent-2)
		_caption.size=Vector2(size.x-12,maxf(34,size.y-top-extent-6))
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	else:
		_art.position=Vector2(16,(size.y-extent)*0.5)
		_art.size=Vector2(extent,extent)
		_caption.position=Vector2(extent+28,4)
		_caption.size=Vector2(maxf(0,size.x-extent-44),size.y-8)
		_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
