class_name ExpeditionArt
extends Control
# Original native-vector artwork: crisp at any Android density, no icon font dependency.
var kind: String = "compass"
var accent: Color = Color("f2c864")
var ink: Color = Color("183e46")
var progress: float = 0.0
var ticks: int = 20
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var s: float = minf(size.x,size.y)
	var c: Vector2 = size*0.5
	draw_set_transform(c,0,Vector2(s/100.0,s/100.0))
	match kind:
		"compass":
			draw_circle(Vector2.ZERO,34,Color("c39242"))
			draw_circle(Vector2.ZERO,29,Color("f5dfa4"))
			draw_circle(Vector2.ZERO,23,ink)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-26),Vector2(11,10),Vector2(-3,3)]),accent)
			draw_colored_polygon(PackedVector2Array([Vector2(0,26),Vector2(-11,-10),Vector2(3,-3)]),Color("e8f3e5"))
			draw_arc(Vector2.ZERO,39,0,TAU,48,Color("dcebd5"),2,true)
		"book":
			draw_style_box(_panel(Color("ad7445"),8),Rect2(-33,-29,66,64))
			draw_style_box(_panel(Color("efe7c8"),5),Rect2(-29,-34,60,60))
			draw_line(Vector2(-20,-25),Vector2(-20,21),Color("b79764"),3,true)
			draw_ellipse_fish(Vector2(7,-3),Color("529e9a"))
			draw_line(Vector2(-12,16),Vector2(20,16),Color("c5b994"),2,true)
		"heart":
			draw_colored_polygon(PackedVector2Array([Vector2(-29,-6),Vector2(-28,-23),Vector2(-15,-31),Vector2(0,-21),Vector2(15,-31),Vector2(28,-23),Vector2(29,-6),Vector2(0,29)]),Color("de9677"))
			draw_arc(Vector2.ZERO,39,0,TAU,48,accent,3,true)
			draw_line(Vector2(-17,-18),Vector2(-22,-8),Color("f9d2a9"),4,true)
		"bag":
			draw_arc(Vector2(0,-21),15,PI,TAU,16,Color("d7ad68"),8,true)
			draw_style_box(_panel(Color("bd8046"),10),Rect2(-30,-24,60,57))
			draw_style_box(_panel(Color("e2b873"),8),Rect2(-32,-28,64,26))
			draw_rect(Rect2(-5,-7,10,20),ink)
			draw_rect(Rect2(-3,-4,6,8),accent)
		"coin":
			draw_circle(Vector2.ZERO,32,Color("b77b29"))
			draw_circle(Vector2(0,-3),29,accent)
			draw_arc(Vector2(0,-3),21,0,TAU,32,Color("fff0a1"),3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(0,-17),Vector2(8,-3),Vector2(0,11),Vector2(-8,-3)]),Color("ae7b30"))
		"sun":
			draw_circle(Vector2.ZERO,16,accent)
			for i: int in range(8):
				var a: float = i*TAU/8.0
				draw_line(Vector2.from_angle(a)*23,Vector2.from_angle(a)*32,accent,4,true)
		"rod":
			draw_line(Vector2(-30,30),Vector2(22,-32),Color("c3935b"),7,true)
			draw_line(Vector2(-9,4),Vector2(24,-35),Color("f4d78b"),3,true)
			draw_circle(Vector2(-12,16),11,ink)
			draw_arc(Vector2(-12,16),8,0,TAU,20,accent,3,true)
			draw_line(Vector2(24,-35),Vector2(32,20),Color("d6e6df"),1.5,true)
			draw_circle(Vector2(32,21),5,Color("da836c"))
		"lure","shrimp","worm","grain":
			if kind == "grain":
				for i: int in range(5): draw_circle(Vector2((i%2)*19-10,(i/2)*15-15),11,accent)
			elif kind == "worm":
				var points: PackedVector2Array=[]
				for i: int in range(26): points.append(Vector2(i*2-25,sin(i*0.28)*16))
				draw_polyline(points,Color("ecaa86"),13,true)
				draw_circle(Vector2(-25,0),7,Color("f2c3a0"))
			else:
				draw_ellipse_fish(Vector2.ZERO,Color("f0c66a") if kind=="lure" else Color("e99b7c"))
				draw_arc(Vector2(8,20),13,0,PI,18,Color("c6e4dc"),3,true)
		"ruler":
			draw_line(Vector2(-45,0),Vector2(45,0),Color("a4b6a5"),1.5,true)
			for i: int in range(19):
				var x: float = -45+i*5
				draw_line(Vector2(x,0),Vector2(x,14 if i%3==0 else 8),Color("8b9c8f"),1.2,true)
		"badge":
			draw_circle(Vector2.ZERO,32,accent)
			draw_circle(Vector2.ZERO,25,ink)
			draw_ellipse_fish(Vector2.ZERO,accent)
	draw_set_transform(Vector2.ZERO)
func draw_ellipse_fish(center: Vector2,color: Color) -> void:
	var points: PackedVector2Array=[]
	for i: int in range(25):
		var a: float=i*TAU/24
		points.append(center+Vector2(cos(a)*24,sin(a)*12))
	draw_colored_polygon(points,color)
	draw_colored_polygon(PackedVector2Array([center+Vector2(15,0),center+Vector2(34,-16),center+Vector2(34,16)]),color)
	draw_circle(center+Vector2(-14,-2),2.5,ink)
func _panel(color: Color,radius: int) -> StyleBoxFlat:
	var p: StyleBoxFlat=StyleBoxFlat.new()
	p.bg_color=color
	p.set_corner_radius_all(radius)
	return p
