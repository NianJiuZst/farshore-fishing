extends SceneTree
## Regression against the imported GLB triangles, all 21 stations, all six rods,
## near/mid/far charge, rotated headings, drift footprints and portrait/tablet views.
const Stage=preload("res://scripts/fishing_stage_3d.gd")
const Catalog=preload("res://scripts/catalog.gd")
const Session=preload("res://scripts/fishing_session.gd")
var checks: int=0
var failures: int=0
var cases: int=0
var stage: Node3D
var solids: Array[Dictionary]=[]
var rows: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL WATER_DOMAIN ",label)
func run() -> void:
	var catalog=Catalog.new()
	catalog.load_all()
	check(catalog.errors.is_empty(),"catalog valid")
	stage=Stage.new()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	var started: int=Time.get_ticks_msec()
	for spot: Dictionary in catalog.spots.values():
		var sid: String=str(spot.spot_id)
		check(stage.set_location(str(spot.region_id),sid),"load "+sid)
		solids.clear()
		collect(stage._environment_root)
		collect(stage._station_root)
		var adjusted: int=0
		var count: int=0
		for gear: Dictionary in catalog.gear:
			stage.set_gear_profile(gear)
			for power: float in [0.0,0.05,0.25,0.5,0.75,1.0]:
				for heading: float in [-30.0,0.0,30.0]:
					var at: Vector3=stage.cast_target_for_charge(power,deg_to_rad(heading))
					var label: String="%s rod%d power%.2f heading%.0f" % [sid,int(gear.id),power,heading]
					check(at.is_finite(),label+" resolves")
					if not at.is_finite(): continue
					cases+=1
					count+=1
					var expected: Vector3=Vector3(-0.72+minf(power,gear.reach)*0.5,0,-7-minf(power,gear.reach)*5).rotated(Vector3.UP,deg_to_rad(heading))
					if not at.is_equal_approx(expected): adjusted+=1
					# Independent probes use the GLBs, not the production resolver's
					# boolean. Sweep an offset grid over the actual drift footprint.
					for x: float in [-0.9,-0.3,0.3,0.9]:
						for z: float in [-0.9,-0.3,0.3,0.9]:
							var p:=at+Vector3(x,0,z)
							check(hit(Vector3(p.x,160,p.z),Vector3(p.x,-0.30,p.z),false).is_empty(),label+" submerged float clear "+str(p))
					for offset: Vector3 in [Vector3.ZERO,Vector3(-0.55,0,-0.55),Vector3(0.55,0,0.55)]:
						check(hit(at+Stage.FLOAT_VIEW_OFFSET,at+offset+Vector3.UP*0.08,true).is_empty(),label+" visible float "+str(offset))
		# Full camera path is the same for every aspect, but the projected float
		# must remain in the central reading area on each supported shape.
		stage.set_mode("fishing")
		for power: float in [0.0,0.5,1.0]:
			stage._bobber_target=stage.cast_target_for_charge(power)
			stage.presentation_state="waiting"
			for dims: Vector2i in [Vector2i(720,1280),Vector2i(720,1584),Vector2i(1080,2400),Vector2i(1024,768)]:
				root.size=dims
				await process_frame
				stage._update_camera(100)
				var screen: Vector2=stage.camera.unproject_position(stage._bobber_target+Vector3.UP*0.08)/root.get_visible_rect().size
				check(screen.x>0.30 and screen.x<0.70 and screen.y>0.30 and screen.y<0.70,sid+" central projection "+str(dims)+" "+str(screen))
		rows.append({"spot":sid,"casts":count,"adjusted":adjusted})
		print("WATER_DOMAIN_SPOT ",sid," casts=",count," adjusted=",adjusted)
	# Old estuary coordinates remain dry even after the station relocation.
	stage.set_location("yangtze","yangtze_estuary")
	var old_cast: Vector3=stage._station_frame().affine_inverse()*Vector3(-0.47,0,-49.5)
	check(not stage._water_domain.is_open_water(old_cast),"reject exact old sandbar target")
	var recovered: Vector3=stage._water_domain.resolve_cast(old_cast)
	check(recovered.is_finite() and not recovered.is_equal_approx(old_cast),"dry requested cast resolves to different water")
	solids.clear()
	collect(stage._environment_root)
	collect(stage._station_root)
	check(hit(recovered+Vector3.UP*160,recovered-Vector3.UP*0.30,false).is_empty(),"resolved sandbar request reaches actual wet geometry")
	# Exercise the real animation/rod tip/cast trajectory, not just the target
	# formula. Both Yangtze locations must clear shore geometry in flight and
	# contact the moving surface for every rod and near/mid/far cast.
	var session=Session.new()
	stage.bind_session(session)
	stage._animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for sid: String in ["yangtze_river","yangtze_estuary"]:
		stage.set_location("yangtze",sid)
		stage.set_mode("fishing")
		solids.clear()
		collect(stage._environment_root)
		collect(stage._station_root)
		for gear: Dictionary in catalog.gear:
			stage.set_gear_profile(gear)
			for power: float in [0.0,0.5,1.0]:
				session.reset()
				session.start_charge()
				session.charge=power
				check(session.cast({"species_id":"common_carp","length_mm":700,"difficulty":0.4,"behavior":"steady"},gear),"trajectory begins "+sid)
				var previous:=Vector3.ZERO
				var released: bool=false
				var contacted: bool=false
				for tick: int in 300:
					stage._animator.advance(1.0/120.0)
					stage._process(1.0/120.0)
					if stage._bobber.visible:
						if released and previous.distance_to(stage._bobber.position)>0.00001:
							check(hit(previous,stage._bobber.position,true).is_empty(),"unobstructed cast trajectory "+sid+" rod"+str(gear.id)+" power"+str(power))
						previous=stage._bobber.position
						released=true
					if stage._cast_impact_emitted:
						var at: Vector3=stage._bobber.position
						check(Vector2(at.x,at.z).distance_to(Vector2(stage._bobber_target.x,stage._bobber_target.z))<0.0001,"trajectory reaches resolved target "+sid)
						check(absf(at.y-stage._water_surface_height(Vector2(at.x,at.z),stage._time))<0.0001,"impact touches current wave "+sid)
						contacted=true
						break
				check(contacted,"trajectory actually contacts water "+sid)
	stage.bind_session(null)
	stage.set_location("yangtze","yangtze_river")
	solids.clear()
	collect(stage._environment_root)
	collect(stage._station_root)
	for progress: float in [0.0,0.5,0.85,0.95,1.0]:
		for sway: float in [-0.9,0.0,0.9]:
			var target: Vector3=Vector3(-0.395,0,-10.25).lerp(Vector3(-0.1,0.035,-2.7),progress)+Vector3(sway,0,0)
			check(hit(Vector3(-0.48,2.12,1.48),target+Vector3.UP*0.06,true).is_empty(),"river late fight apron clearance "+str(progress)+" "+str(sway))
	# Shader and float share this independent analytic water formula at different
	# positions/times, including rain. No second surface displacement is added.
	for weather: String in ["clear","rain"]:
		stage.set_weather(weather)
		for clock: float in [0.0,0.2,1.8,12.3]:
			var p:=Vector2(-0.43,-10.2)
			var warp: float=sin(p.x*0.47-p.y*0.29+clock*0.22)*0.85+sin(p.y*0.71+p.x*0.12)*0.31
			var height: float=sin(p.dot(Vector2(0.87,0.38))*2.1+clock*1.05+warp)*0.006+sin(p.dot(Vector2(-0.67,0.74))*3.7-clock*1.43+warp*0.72)*0.004+sin(p.dot(Vector2(0.55,-0.81))*7.4+clock*1.73+sin(p.x*1.7)*0.4)*0.002
			check(is_equal_approx(stage._water_surface_height(p,clock),height*(1.45 if weather=="rain" else 0.7)),"wave equation "+weather+" "+str(clock))
	var output: String=OS.get_environment("FARSHORE_WATER_REPORT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"casts":cases,"milliseconds":Time.get_ticks_msec()-started,"spots":rows,"scope":"CPU geometry/visibility and camera projection, not Android device or GPU performance"},"\t")+"\n")
	stage.free()
	await process_frame
	print("WATER_DOMAIN_TESTS ",checks-failures,"/",checks," passed; cases=",cases," failures=",failures)
	quit(0 if failures==0 else 1)
func collect(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var mesh: TriangleMesh=node.mesh.generate_triangle_mesh()
		if mesh:
			var frame: Transform3D=stage.global_transform.affine_inverse()*node.global_transform
			solids.append({"mesh":mesh,"frame":frame,"inverse":frame.affine_inverse(),"name":str(node.name)})
	for child: Node in node.get_children(): collect(child)
func hit(begin: Vector3,end: Vector3,plants: bool) -> Dictionary:
	for item: Dictionary in solids:
		var leaf: bool=str(item.name).begins_with("Foliage")
		var reed: bool=item.name in ["Reed","Cattail"]
		if not plants and (leaf or reed): continue
		var from: Vector3=begin
		for attempt: int in 64:
			var found: Dictionary=item.mesh.intersect_segment(item.inverse*from,item.inverse*end)
			if found.is_empty(): break
			var at: Vector3=item.frame*found.position
			var cleared: bool=false
			if stage._station_kind(str(stage._spot_definition.foreground))=="rock":
				cleared=(leaf and Vector2(at.x+0.3,at.z-3).length()<7.0) or (reed and absf(at.x)<3 and at.z>-2.5 and at.z<6.5)
			if not cleared: return {"name":item.name,"position":at}
			from=at+from.direction_to(end)*0.002
	return {}
