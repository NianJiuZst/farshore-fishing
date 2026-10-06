class_name IconAction
extends Button
# Transparent touch targets, visible focus and restrained icon feedback.
const Clear = preload("res://scripts/clear_ui.gd")
const Art=preload("res://scripts/ui_art.gd")
var icon_kind: String="arrow"
var stacked: bool=false
var icon_only: bool=false
var icon_extent: float=58.0
var label_color: Color=Clear.INK
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
	Clear.style_text(_caption)
	add_child(_caption)
	resized.connect(_layout)
	button_down.connect(_press_feedback.bind(true))
	button_up.connect(_press_feedback.bind(false))
	mouse_exited.connect(_press_feedback.bind(false))
	_layout()
func _apply_surface() -> void:
	Clear.style_button(self)
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
		accessibility_name=text
		tooltip_text=text
		_layout()
	var active: bool=is_hovered() or button_pressed or has_focus()
	var visual: String="%s:%s:%s:%s:%s:%s:%s" % [active,disabled,icon_kind,label_color,light_label,appearance,icon_only]
	if visual==_last_visual:return
	_last_visual=visual
	_apply_surface()
	_caption.add_theme_color_override("font_color",(label_color.lightened(0.08) if light_label else label_color.darkened(0.08)) if active else label_color)
	_caption.modulate.a=0.42 if disabled else 1.0
	_art.modulate=Color(1.06,1.06,1.06,0.45 if disabled else 1.0) if active else Color(1,1,1,0.42 if disabled else 1.0)
	_art.kind=icon_kind
	_layout()
func _layout() -> void:
	if _caption==null:return
	_caption.add_theme_font_size_override("font_size",get_theme_font_size("font_size"))
	var extent: float=icon_extent
	pivot_offset=size*0.5
	_caption.visible=not icon_only
	if icon_only:
		extent=minf(maxf(icon_extent,48.0),minf(size.x,size.y)-12.0)
		_art.position=(size-Vector2.ONE*extent)*0.5
		_art.size=Vector2.ONE*extent
	elif icon_extent<=0:
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
