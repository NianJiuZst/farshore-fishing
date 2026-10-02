class_name SceneryView
extends Control
var region_id: String = "lake"
var foreground: String = "reeds"
var weather: String = "clear"
var time_of_day: String = "day"
var angler: Texture2D = preload("res://assets/ui/expedition_angler.png")
var rowboat: Texture2D = preload("res://assets/ui/expedition_rowboat.png")
var art: Texture2D
var front_art: Texture2D
var session: FishingSession
var clock_time: float = 0.0
var tint: Color = Color("4f8588")
var _sparks: Array[Vector2] = []
var _bottom_shade: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient: Gradient=Gradient.new()
	gradient.set_color(0,Color(0.025,0.10,0.14,0.04))
	gradient.set_color(1,Color(0.025,0.10,0.14,0.93))
	_bottom_shade=GradientTexture2D.new()
	_bottom_shade.gradient=gradient
	_bottom_shade.fill_from=Vector2(0,0)
	_bottom_shade.fill_to=Vector2(0,1)
	for i: int in range(32):
		_sparks.append(Vector2(float((i * 193 + 67) % 720), float((i * 87 + 11) % 460)))

func set_region(region: Dictionary, spot: Dictionary) -> void:
	region_id = str(region.get("region_id", "lake"))
	foreground = str(spot.get("foreground", "reeds"))
	tint = Color(str(region.get("color", "#81aa9a")))
	var path: String = str(spot.get("scene",region.get("scene", "")))
	art = load(path) as Texture2D if ResourceLoader.exists(path) else null
	var foreground_path: String = "res://assets/scenery/"+region_id+"_foreground.png"
	front_art = load(foreground_path) as Texture2D if ResourceLoader.exists(foreground_path) and not bool(spot.get("hide_region_foreground",false)) else null
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
		draw_texture_rect_region(front_art,Rect2(w*0.55,h*0.40,w*0.45,h*0.60),Rect2(front_art.get_width()*0.5,0,front_art.get_width()*0.5,front_art.get_height()))
	_draw_angler(w,h)
	# A transparent dusk vignette keeps controls legible while the painting stays edge-to-edge.

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

func _draw_angler(w: float,h: float) -> void:
	if foreground=="boat":
		draw_texture_rect(rowboat,Rect2(-w*0.04,h*0.70+sin(clock_time*1.4)*1.8,w*0.94,w*0.627),false)
	else:
		var support: Texture2D=front_art if front_art!=null else load("res://assets/scenery/japan_foreground.png")
		if region_id=="bayou":support=load("res://assets/scenery/lake_foreground.png")
		# Reuse original painted stones/wood as grounded shore support. No flat polygon deck.
		var y: float=0.33 if region_id in ["lake","bayou"] else (0.285 if region_id in ["japan","yangtze"] else 0.31)
		draw_texture_rect_region(support,Rect2(0,h*y,w*1.25,h*0.65),Rect2(0,0,support.get_width()*0.5,support.get_height()))
	# Soft contact shadows sit directly below boot, stool feet and bag.
	for contact: Vector2 in [Vector2(w*0.235,h*0.782),Vector2(w*0.485,h*0.798),Vector2(w*0.605,h*0.799)]:
		for ring: int in range(4,0,-1):
			draw_set_transform(contact,0,Vector2(2.0,0.33))
			draw_circle(Vector2.ZERO,8+ring*3,Color(0.07,0.15,0.13,0.022))
	draw_set_transform(Vector2.ZERO)
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
