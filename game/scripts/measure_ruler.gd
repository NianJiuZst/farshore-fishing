class_name CatchRuler
extends Control
## Photoreal specimens supply anatomical nose/tail landmarks in canvas space.
## The adapter also supports historical projected-3D and plain TextureRect callers.
var length_mm: int=1000
var specimen: Control
var _used: Rect2i
var _texture_size: Vector2=Vector2.ONE
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=50
	resized.connect(queue_redraw)
	if not is_instance_valid(specimen): return
	specimen.resized.connect(queue_redraw)
	specimen.item_rect_changed.connect(queue_redraw)
	# Static photos do not need a per-frame projection/redraw loop.
	set_process(not specimen is TextureRect)
	if specimen is TextureRect and specimen.texture and not specimen.has_method("measurement_endpoints"):
		var source: Image=specimen.texture.get_image()
		if source==null: return
		if source.is_compressed(): source.decompress()
		_used=source.get_used_rect()
		_texture_size=Vector2(source.get_width(),source.get_height())
	call_deferred("queue_redraw")
func _process(_delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(specimen) and specimen.has_method("measurement_endpoints"): queue_redraw()
func _draw() -> void:
	if not is_instance_valid(specimen): return
	var start: float
	var width: float
	var nose_on_left: bool = true
	if specimen.has_method("measurement_endpoints"):
		var endpoints: Array[Vector2]=specimen.measurement_endpoints()
		if endpoints.size()!=2: return
		nose_on_left = endpoints[0].x <= endpoints[1].x
		start=minf(endpoints[0].x,endpoints[1].x)-global_position.x
		width=absf(endpoints[1].x-endpoints[0].x)
	elif specimen is TextureRect and _used.size.x>0:
		var fit: float=minf(specimen.size.x/_texture_size.x,specimen.size.y/_texture_size.y)
		var texture_origin: Vector2=specimen.global_position+(specimen.size-_texture_size*fit)*0.5
		start=texture_origin.x+_used.position.x*fit-global_position.x
		width=_used.size.x*fit
	else: return
	if width<=0.0: return
	var col: Color=Color("829887")
	draw_line(Vector2(start,8),Vector2(start+width,8),col,1.5,true)
	for i: int in range(41):
		var x: float=start+width*i/40.0
		draw_line(Vector2(x,8),Vector2(x,27 if i%10==0 else (20 if i%5==0 else 14)),col,1.5,true)
	var font: Font=ThemeDB.fallback_font
	for i: int in range(5):
		var fraction: float = i/4.0 if nose_on_left else (1.0-i/4.0)
		var text: String="%.1f" % (length_mm/10.0*fraction)
		var text_width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var x: float=clampf(start+width*i/4.0-text_width*0.5,0,size.x-text_width)
		draw_string(font,Vector2(x,47),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("567563"))
