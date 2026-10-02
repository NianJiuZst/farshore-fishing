class_name CatchRuler
extends Control
var length_mm: int=1000
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y=50
	resized.connect(queue_redraw)
func _draw() -> void:
	var width: float=size.x-24
	var col: Color=Color("829887")
	draw_line(Vector2(12,8),Vector2(width+12,8),col,1.5,true)
	for i: int in range(41):
		var x: float=12+width*i/40.0
		draw_line(Vector2(x,8),Vector2(x,27 if i%10==0 else (20 if i%5==0 else 14)),col,1.5,true)
	var font: Font=ThemeDB.fallback_font
	for i: int in range(5):
		var text: String="%g" % (length_mm/10.0*i/4.0)
		var x: float=12+width*i/4.0-8
		draw_string(font,Vector2(x,47),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("567563"))
