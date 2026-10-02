class_name CatchRuler
extends Control
# Metric endpoints follow the painted snout/tail alpha bounds, not the surrounding specimen card.
var length_mm: int=1000
var specimen: TextureRect
var _used: Rect2i
var _texture_size: Vector2=Vector2.ONE
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=50
	resized.connect(queue_redraw)
	if is_instance_valid(specimen) and specimen.texture:
		var source: Image=specimen.texture.get_image()
		if source==null: return
		if source.is_compressed(): source.decompress()
		_used=source.get_used_rect()
		_texture_size=Vector2(source.get_width(),source.get_height())
		specimen.resized.connect(queue_redraw)
		call_deferred("queue_redraw")
func _draw() -> void:
	if not is_instance_valid(specimen) or _used.size.x<=0: return
	var fit: float=minf(specimen.size.x/_texture_size.x,specimen.size.y/_texture_size.y)
	var texture_origin: Vector2=specimen.global_position+(specimen.size-_texture_size*fit)*0.5
	var start: float=texture_origin.x+_used.position.x*fit-global_position.x
	var width: float=_used.size.x*fit
	var col: Color=Color("829887")
	draw_line(Vector2(start,8),Vector2(start+width,8),col,1.5,true)
	for i: int in range(41):
		var x: float=start+width*i/40.0
		draw_line(Vector2(x,8),Vector2(x,27 if i%10==0 else (20 if i%5==0 else 14)),col,1.5,true)
	var font: Font=ThemeDB.fallback_font
	for i: int in range(5):
		var text: String="%.1f" % (length_mm/10.0*i/4.0)
		var text_width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var x: float=clampf(start+width*i/4.0-text_width*0.5,0,size.x-text_width)
		draw_string(font,Vector2(x,47),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("567563"))
