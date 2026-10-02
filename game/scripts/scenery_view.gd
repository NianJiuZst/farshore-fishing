class_name SceneryView
extends Control
var region_id: String = "lake"
var foreground: String = "reeds"
var weather: String = "clear"
var time_of_day: String = "day"
var angler: Texture2D = preload("res://assets/ui/expedition_angler.png")
var art: Texture2D
var front_art: Texture2D
var session: FishingSession
var clock_time: float = 0.0
var tint: Color = Color("4f8588")
var _sparks: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in range(32):
		_sparks.append(Vector2(float((i * 193 + 67) % 720), float((i * 87 + 11) % 460)))

func set_region(region: Dictionary, spot: Dictionary) -> void:
	region_id = str(region.get("region_id", "lake"))
	foreground = str(spot.get("foreground", "reeds"))
	tint = Color(str(region.get("color", "#81aa9a")))
	var path: String = str(region.get("scene", ""))
	art = load(path) as Texture2D if ResourceLoader.exists(path) else null
	var foreground_path: String = "res://assets/scenery/"+region_id+"_foreground.png"
	front_art = load(foreground_path) as Texture2D if ResourceLoader.exists(foreground_path) else null
	queue_redraw()

func _process(delta: float) -> void:
	if session == null or session.state != FishingSession.State.PAUSED:
		clock_time += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var water_top: float = h * 0.43
	draw_rect(Rect2(Vector2.ZERO, size), Color("d2e1d8"))
	if art:
		draw_texture_rect(art, Rect2(0, 0, w, h), false)
	var water: Color = tint.darkened(0.20)
	water.a = 0.16 if art else 1.0
	draw_rect(Rect2(0, water_top, w, h-water_top), water)
	# Blend a static painted shoreline into engine-drawn ripples, no whole-image water scrolling.
	for i: int in range(20):
		var blend: Color = water
		blend.a = float(i)/20.0 * water.a
		draw_rect(Rect2(0, water_top - 35 + i * 2, w, 3), blend)
	for i: int in range(32):
		var p: Vector2 = _sparks[i]
		var x: float = p.x / 720.0 * w + sin(clock_time * 0.4 + i) * 13.0
		var y: float = water_top + p.y / 460.0 * (h-water_top)
		var alpha: float = 0.12 + sin(clock_time * 0.65 + i) * 0.06
		draw_line(Vector2(x,y), Vector2(x + 20.0 + i%4*10,y), Color(0.9,0.96,0.87,alpha), 2.0, true)
	if time_of_day == "dusk":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.50,0.26,0.36,0.18))
		var sun: Vector2 = Vector2(w*0.76, h*0.22)
		draw_circle(sun, 24, Color(1,0.81,0.50,0.65))
	if weather == "rain":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10,0.23,0.30,0.17))
		for i: int in range(48):
			var x: float = fposmod(float(i*137) - clock_time*25.0, w)
			var y: float = fposmod(float(i*97) + clock_time*360.0, h)
			draw_line(Vector2(x,y),Vector2(x-7,y+19),Color(0.9,0.95,1,0.24),1.5,true)
	if front_art:
		draw_texture_rect_region(front_art,Rect2(w*0.5,h*0.39,w*0.5,h*0.39),Rect2(front_art.get_width()*0.5,0,front_art.get_width()*0.5,front_art.get_height()))
	_draw_angler(w,h)
	# A transparent dusk vignette keeps controls legible while the painting stays edge-to-edge.
	for shade: int in range(40):
		var alpha: float = 0.10+float(shade)/40.0*0.80
		draw_rect(Rect2(0,h*0.70+shade*h*0.0075,w,h*0.0075+1),Color(0.025,0.10,0.14,alpha))
	if session == null: return
	var active: int = session.before_pause if session.state == FishingSession.State.PAUSED else session.state
	if active in [FishingSession.State.CASTING,FishingSession.State.WAITING,FishingSession.State.NIBBLE,FishingSession.State.BITE,FishingSession.State.FIGHT]:
		var bx: float = w * (0.48 + sin(clock_time * 0.4) * 0.016)
		var by: float = h * (0.62 - session.charge * 0.08)
		if active == FishingSession.State.CASTING:
			var k: float = clampf(session.elapsed/0.85,0,1)
			by = lerpf(h*0.96, by, k) - sin(k*PI)*h*0.20
		if active in [FishingSession.State.NIBBLE,FishingSession.State.BITE]:
			by += sin(clock_time*(13 if active == FishingSession.State.BITE else 6))*7
		if active == FishingSession.State.FIGHT:
			bx += sin(clock_time*1.8)*w*0.16*(1-session.progress)
			by += sin(clock_time*2.2)*12
		var bob: Vector2 = Vector2(bx,by)
		var base: Vector2 = Vector2(w*0.263,h*0.663)
		var tip: Vector2 = Vector2(w*0.23,h*0.42 + session.tension*25)
		
		draw_line(tip,bob,Color(0.93,0.95,0.85,0.7),1.3,true)
		for ring: int in range(3):
			var radius: float = fposmod(clock_time*14+ring*17,52)
			draw_arc(bob, radius,0,TAU,36,Color(0.93,0.99,0.95,(1-radius/52)*0.45),1.8,true)
		if active == FishingSession.State.FIGHT:
			var scale_f: float = 0.6 + float(session.individual.get("size_fraction",0.3))*1.5
			var fish_pos: Vector2 = bob + Vector2(15,26)
			draw_set_transform(fish_pos, sin(clock_time*1.8)*0.2, Vector2(scale_f,scale_f))
			draw_colored_polygon(PackedVector2Array([Vector2(-32,0),Vector2(-7,-10),Vector2(25,0),Vector2(-7,10)]), Color(0.03,0.20,0.23,0.40))
			draw_colored_polygon(PackedVector2Array([Vector2(-24,0),Vector2(-44,-11),Vector2(-44,11)]), Color(0.03,0.20,0.23,0.40))
			draw_set_transform(Vector2.ZERO)
		draw_line(bob+Vector2(0,-20),bob+Vector2(0,8),Color("f9efcf"),5,true)
		draw_line(bob+Vector2(0,-20),bob+Vector2(0,-5),Color("dc7658"),6,true)
		draw_circle(bob+Vector2(0,2),5,Color("f9efcf"))

func _draw_foreground(w: float, h: float) -> void:
	var low: float = h * 0.98
	if foreground == "boat":
		draw_colored_polygon(PackedVector2Array([Vector2(w*0.20,h),Vector2(w*0.32,h*0.88),Vector2(w*0.75,h*0.88),Vector2(w*0.91,h)]),Color("b99771"))
		draw_polyline(PackedVector2Array([Vector2(w*0.20,h),Vector2(w*0.32,h*0.88),Vector2(w*0.75,h*0.88),Vector2(w*0.91,h)]),Color("e7d0a9"),12,true)
	elif foreground == "pier":
		draw_colored_polygon(PackedVector2Array([Vector2(0,h),Vector2(0,h*0.88),Vector2(w*0.31,h*0.86),Vector2(w*0.46,h)]),Color("8c775c"))
		for i: int in range(5):
			draw_line(Vector2(0,h*0.88+i*22),Vector2(w*(0.32+i*0.02),h*0.86+i*22),Color("b2a084"),3,true)
	elif foreground == "rocks":
		for i: int in range(6):
			draw_circle(Vector2(i*46,low+12-(i%2)*12),47,Color("828c86"))
	else:
		for i: int in range(15):
			var x: float = i*14.0
			var sway: float = sin(clock_time+i)*4
			draw_line(Vector2(x,h),Vector2(x+12+sway,low-60-(i%3)*20),Color("4e6f4b"),3,true)
			draw_line(Vector2(x+12+sway,low-65-(i%3)*20),Vector2(x+12+sway,low-85-(i%3)*20),Color("705c40"),7,true)

func _draw_angler(w: float,h: float) -> void:
	var wood: Color=Color("856e50")
	var deck: PackedVector2Array=PackedVector2Array([Vector2(0,h*0.764),Vector2(w*0.61,h*0.754),Vector2(w*0.74,h*0.88),Vector2(0,h*0.92)])
	if foreground=="boat":
		draw_colored_polygon(PackedVector2Array([Vector2(w*0.05,h*0.79),Vector2(w*0.62,h*0.74),Vector2(w*0.72,h*0.84),Vector2(w*0.23,h*0.90)]),Color("aa8560"))
		draw_polyline(PackedVector2Array([Vector2(w*0.05,h*0.79),Vector2(w*0.62,h*0.74),Vector2(w*0.72,h*0.84)]),Color("e4c994"),12,true)
	else:
		draw_colored_polygon(deck,wood)
		for i: int in range(7):
			var k: float=i/7.0
			draw_line(Vector2(0,lerpf(h*0.764,h*0.92,k)),Vector2(lerpf(w*0.61,w*0.74,k),lerpf(h*0.754,h*0.88,k)),Color("b79c72"),3,true)
		draw_line(Vector2(0,h*0.764),Vector2(w*0.61,h*0.754),Color("d7c394"),8,true)
	var sway: float=sin(clock_time*1.4)*1.8
	var bend: float=session.tension*25 if session else 0.0
	var base: Vector2=Vector2(w*0.263,h*0.663)
	var tip: Vector2=Vector2(w*0.23,h*0.42+bend)
	var points: PackedVector2Array=[]
	for i: int in range(17):
		var k: float=i/16.0
		points.append(base.lerp(tip,k)+Vector2(-sin(k*PI)*18,0))
	draw_polyline(points,Color("274844"),6,true)
	draw_polyline(points,Color("d4b477"),2,true)
	draw_texture_rect(angler,Rect2(w*0.12,h*0.49+sway,w*0.54,w*0.568),false)
