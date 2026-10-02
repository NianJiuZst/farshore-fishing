class_name FishingStage3D
extends Node3D
## Presentation-only 3D fishery. Never changes inventory, rewards, or session outcomes.
signal cast_presentation_finished
signal landing_finished(record: Dictionary)

const WATER_SHADER = preload("res://assets/shaders3d/river_water.gdshader")
const FOLIAGE_SHADER = preload("res://assets/shaders3d/foliage.gdshader")
const RIPPLE_SHADER = preload("res://assets/shaders3d/ripple.gdshader")
const WOOD_SHADER = preload("res://assets/shaders3d/weathered_wood.gdshader")
const GROUND_SHADER = preload("res://assets/shaders3d/riverbank.gdshader")
const ANGLER_POS := Vector3(-0.92, 0.584, 0.77)
const CAST_DURATION: float = 2.20
const RELEASE_TIME: float = 1.20
const LANDING_DURATION: float = 3.35
const Session = preload("res://scripts/fishing_session.gd")

var session: FishingSession
var camera: Camera3D
var presentation_state: String = "lobby"
var cast_in_progress: bool = false
var weather: String = "clear"
var time_of_day: String = "day"
var mode: String = "lobby"
var _built: bool = false
var _suspended: bool = false
var _time: float = 0.0
var _state: int = Session.State.IDLE
var _before_pause: int = Session.State.IDLE
var _cast_time: float = 0.0
var _landing_time: float = -1.0
var _landing_record: Dictionary = {}
var _landed_catch_id: String = ""
var _water_material: ShaderMaterial
var _foliage_materials: Array[ShaderMaterial] = []
var _world: WorldEnvironment
var _sun: DirectionalLight3D
var _sky: ProceduralSkyMaterial
var _environment_root: Node3D
var _angler: Node3D
var _animator: AnimationPlayer
var _rod_socket: Node3D
var _rod: Node3D
var _rod_mesh: MeshInstance3D
var _rod_tip: Vector3 = Vector3.ZERO
var _line: MeshInstance3D
var _line_material: StandardMaterial3D
var _bobber: Node3D
var _bobber_target: Vector3 = Vector3(-0.9, 0.04, -9.0)
var _cast_origin: Vector3
var _fish_root: Node3D
var _fish: Node3D
var _fish_animator: AnimationPlayer
var _fish_id: String = ""
var _fish_length: float = 0.72
var _ripple_pool: Array[Dictionary] = []
var _spray_pool: Array[Dictionary] = []
var _last_ripple: float = -9.0
var _impact_index: int = 0
var _camera_target: Vector3 = Vector3(-1.5, 0.85, -2.5)
var _last_anim: String = ""
var _last_loop: bool = true
var _cast_finished_emitted: bool = false
var _fishery_label: Label3D

func _ready() -> void:
	_build_world()
	_built = true
	set_time_of_day(time_of_day)
	set_mode(mode)
	if session != null: bind_session(session)

func bind_session(value: FishingSession) -> void:
	if session != null and session.changed.is_connected(_session_changed):
		session.changed.disconnect(_session_changed)
	session = value
	if session != null:
		session.changed.connect(_session_changed)
		if _built: _session_changed(session.state)

func set_region(_region: Variant, _spot: Variant = null) -> void:
	# A single authored managed habitat is intentional for this vertical slice.
	pass

func set_mode(value: String) -> void:
	mode = value
	if not _built: return
	if value == "lobby":
		cancel_landing()
		presentation_state = "lobby"
		cast_in_progress = false
		_bobber.visible = false
		_line.visible = false
		if _fish_root: _fish_root.visible = false
		_play_character("idle")
	elif not cast_in_progress and _landing_time < 0.0:
		presentation_state = "ready"
		_play_character("idle")

func set_weather(value: String) -> void:
	weather = value
	if not _built: return
	var wind: float = 1.45 if value in ["rain", "wind", "storm"] else 0.7
	_water_material.set_shader_parameter("wind_strength", wind)
	for material: ShaderMaterial in _foliage_materials:
		material.set_shader_parameter("wind_strength", wind)
	set_time_of_day(time_of_day)

func set_time_of_day(value: String) -> void:
	time_of_day = value
	if not _built: return
	var night: bool = value in ["night", "夜晚"]
	var dusk: bool = value in ["dusk", "evening", "黄昏"]
	var overcast: bool = weather in ["rain", "storm"]
	_sky.sky_top_color = Color("223b52") if night else Color("6fa0ab")
	_sky.sky_horizon_color = Color("668483") if night else Color("d6d9b6")
	_sky.ground_bottom_color = Color("183834")
	_sky.ground_horizon_color = _sky.sky_horizon_color
	_sun.light_color = Color("b2ccdd") if night else (Color("ffc488") if dusk else Color("ffe0ac"))
	_sun.light_energy = 0.45 if night else (0.7 if overcast else 1.0)
	_sun.rotation_degrees = Vector3(-28 if dusk else -39, -38, 0)
	_world.environment.ambient_light_color = Color("829a99") if not night else Color("547c91")
	_world.environment.ambient_light_energy = 0.24 if not night else 0.20
	_world.environment.fog_light_color = Color("aabaaa") if not night else Color("3a5b63")
	_world.environment.fog_density = 0.0058 if not overcast else 0.009

func suspend(value: bool) -> void:
	_suspended = value
	if _animator:
		if value: _animator.pause()
		elif not _animator.assigned_animation.is_empty(): _animator.play()
	if _fish_animator:
		if value: _fish_animator.pause()
		elif not _fish_animator.assigned_animation.is_empty(): _fish_animator.play()

func play_landing(record: Dictionary) -> void:
	if not _built: return
	var catch_id: String = str(record.get("catch_id", record.get("session_id", "")))
	if _landing_time >= 0.0 or (not catch_id.is_empty() and catch_id == _landed_catch_id): return
	_landed_catch_id = catch_id
	_landing_record = record.duplicate(true)
	_landing_time = 0.0
	cast_in_progress = false
	presentation_state = "landing"
	_ensure_fish(record)
	_fish_root.visible = true
	_fish_root.position = Vector3(-0.15, -0.28, -3.15)
	_play_character("lift", false)
	_play_fish("struggle")
	_splash(_fish_root.position, 1.25)

func cancel_landing() -> void:
	_landing_time = -1.0
	_landing_record.clear()
	if _fish_root: _fish_root.visible = false
	if _bobber: _bobber.scale = Vector3.ONE
	if presentation_state == "landing": presentation_state = "ready"

func _session_changed(value: int) -> void:
	if not _built: return
	if value == Session.State.PAUSED:
		_before_pause = _state
		suspend(true)
		return
	if _suspended:
		suspend(false)
		if value == _before_pause: return
	_state = value
	match value:
		Session.State.IDLE:
			if _landing_time >= 0.0: return
			cast_in_progress = false
			presentation_state = "lobby" if mode == "lobby" else "ready"
			_bobber.visible = false
			_line.visible = false
			_fish_root.visible = false
			_play_character("idle")
		Session.State.CHARGING:
			presentation_state = "charging"
			_play_character("idle")
		Session.State.CASTING:
			_begin_cast()
		Session.State.WAITING:
			if not cast_in_progress:
				presentation_state = "waiting"
				_play_character("wait")
		Session.State.NIBBLE, Session.State.BITE:
			if session: _ensure_fish(session.individual)
			presentation_state = "bite" if value == Session.State.BITE else "nibble"
			_fish_root.visible = true
			_play_fish("swim")
			_splash(_bobber_target, 0.36 if value == Session.State.BITE else 0.15)
		Session.State.FIGHT:
			presentation_state = "fight"
			if session: _ensure_fish(session.individual)
			_fish_root.visible = true
			_play_character("reel")
			_play_fish("struggle")
		Session.State.ESCAPED:
			presentation_state = "escaped"
			_bobber.visible = false
			_line.visible = false
			_fish_root.visible = false
			_play_character("idle")

func _begin_cast() -> void:
	cancel_landing()
	_landed_catch_id = ""
	cast_in_progress = true
	_cast_time = 0.0
	_cast_finished_emitted = false
	presentation_state = "casting"
	var charge: float = clampf(session.charge, 0.0, 1.0) if session else 0.5
	_bobber_target = Vector3(-0.72 + charge * 0.5, 0.035, -7.0 - charge * 5.0)
	_bobber.visible = false
	_line.visible = false
	_fish_root.visible = false
	_play_character("cast", false)

func _process(delta: float) -> void:
	if not _built or _suspended: return
	delta = minf(delta, 0.05)
	_time += delta
	_water_material.set_shader_parameter("motion_time", _time)
	for material: ShaderMaterial in _foliage_materials: material.set_shader_parameter("motion_time", _time)
	_update_effects(delta)
	_update_rod()
	if cast_in_progress: _update_cast(delta)
	elif _landing_time >= 0.0: _update_landing(delta)
	elif mode == "fishing": _update_fishing(delta)
	_update_camera(delta)
	if _line.visible and _bobber.visible: _update_line()

func _update_cast(delta: float) -> void:
	_cast_time += delta
	if _cast_time >= RELEASE_TIME and not _bobber.visible:
		_bobber.visible = true
		_line.visible = true
		_cast_origin = _rod_tip
	if _cast_time >= RELEASE_TIME:
		var p: float = clampf((_cast_time - RELEASE_TIME) / (CAST_DURATION - RELEASE_TIME - 0.17), 0.0, 1.0)
		_bobber.position = _cast_origin.lerp(_bobber_target, p) + Vector3.UP * sin(p * PI) * 2.6
		_bobber.rotation.z = sin(p * PI) * -0.55
		if p >= 1.0 and _last_ripple < _time - 0.25: _splash(_bobber_target, 0.55)
	if _cast_time >= CAST_DURATION:
		cast_in_progress = false
		presentation_state = "waiting"
		_play_character("wait")
		if not _cast_finished_emitted:
			_cast_finished_emitted = true
			cast_presentation_finished.emit()

func _update_fishing(_delta: float) -> void:
	if _state in [Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.CASTING]:
		_bobber.visible = true
		_line.visible = true
		_bobber.position = _bobber_target + Vector3(sin(_time * 1.0) * 0.04, sin(_time * 2.3) * 0.02, 0)
		_bobber.rotation.z = sin(_time * 2.2) * 0.07
		if _state == Session.State.NIBBLE:
			_bobber.position.y -= absf(sin(_time * 5.7)) * 0.11
			_bobber.rotation.z += sin(_time * 5.7) * 0.24
		elif _state == Session.State.BITE:
			_bobber.position.y -= 0.11 + sin(_time * 8) * 0.025
			_bobber.rotation.z = 0.75
		if _state in [Session.State.NIBBLE, Session.State.BITE]:
			var a: float = _time * 1.35
			_fish_root.position = _bobber_target + Vector3(sin(a) * 0.9, -0.33, cos(a) * 0.42)
			_fish_root.rotation = Vector3(0, -a, 0)
			if _time - _last_ripple > 0.58: _spawn_ripple(_bobber_target, 0.36, 1.25)
	elif _state == Session.State.FIGHT and session:
		var p: float = clampf(session.progress, 0.0, 1.0)
		var burst: float = 1.2 if str(session.individual.get("behavior", "")) == "burst" else 0.7
		var swing: float = sin(session.fight_time * 2.25) * (0.35 + session.tension * burst)
		var target: Vector3 = _bobber_target.lerp(Vector3(-0.1, 0.035, -2.7), p)
		_bobber.position = target + Vector3(swing, sin(_time * 8) * 0.035 - 0.05, cos(_time * 2) * 0.25)
		_bobber.rotation.z = swing * 0.55
		_fish_root.position = _bobber.position + Vector3(0, -0.27, 0.1)
		_fish_root.rotation = Vector3(sin(_time * 4) * 0.07, PI * 0.5 + swing * 0.55, 0.02)
		if _time - _last_ripple > 0.30 + (1.0 - session.tension) * 0.5:
			_spawn_ripple(_bobber.position, 0.4 + session.tension * 0.45, 1.2)
		# Brief, physically continuous surfacing on high-tension surges.
		if session.tension > 0.75 and fmod(session.fight_time, 5.4) < 0.45:
			_fish_root.position.y += sin(fmod(session.fight_time, 5.4) / 0.45 * PI) * 0.35
			if _time - _last_ripple > 0.25: _splash(_fish_root.position, 0.35)

func _update_landing(delta: float) -> void:
	_landing_time += delta
	var t: float = _landing_time
	if t < 1.15:
		var p: float = t / 1.15
		_fish_root.position = Vector3(-0.2, -0.24, -3.2).lerp(Vector3(-0.05, 0.9, -1.75), p)
		_fish_root.position.y += sin(p * PI) * 0.68
		_fish_root.rotation = Vector3(sin(p * PI) * -0.25, 0.38 + p * 0.8, sin(p * PI) * 0.35)
		if t > 0.08 and t - delta <= 0.08: _splash(Vector3(-0.2, 0, -3.2), 1.3)
	else:
		var p: float = smoothstep(0.0, 1.0, (t - 1.15) / 1.1)
		_fish_root.position = Vector3(-0.05, 0.9, -1.75).lerp(Vector3(-0.3, 1.28, -0.58), p)
		_fish_root.position.y += sin(_time * 8) * 0.025 * (1.0 - p * 0.7)
		_fish_root.rotation = Vector3(0, lerpf(1.18, -0.20, p), 0.10 + sin(_time * 5) * 0.04)
	_bobber.visible = true
	_line.visible = true
	_bobber.position = _fish_root.position + _fish_root.basis * Vector3(_fish_length * 0.49, 0.03, 0.0)
	_bobber.scale = Vector3.ONE * 0.55
	if t >= LANDING_DURATION:
		var result: Dictionary = _landing_record.duplicate(true)
		_landing_time = -1.0
		_landing_record.clear()
		presentation_state = "landed"
		_bobber.scale = Vector3.ONE
		landing_finished.emit(result)

func _update_camera(delta: float) -> void:
	var position_goal: Vector3 = Vector3(1.1, 3.0, 5.3)
	var target_goal: Vector3 = Vector3(-1.5, 0.85, -2.5)
	var fov_goal: float = 54.0
	if mode == "fishing":
		position_goal = Vector3(1.1, 3.7, 6.2)
		target_goal = Vector3(-1.3, 0.55, -4.5)
		fov_goal = 51.0
	if presentation_state in ["nibble", "bite"]:
		# Camera approaches the actual surface, revealing real underwater fish geometry.
		position_goal = Vector3(1.7, 2.55, 3.7)
		target_goal = _bobber_target + Vector3(0, -0.10, 0)
		fov_goal = 42.0
	elif presentation_state == "fight" and session:
		var p: float = clampf(session.progress, 0.0, 1.0)
		position_goal = Vector3(2.7, 3.3, 5.8)
		target_goal = Vector3(-0.25, 0.55, -5.6 + p * 2.3)
		fov_goal = 46.0
	elif presentation_state in ["landing", "landed"]:
		var p: float = clampf(_landing_time / 2.5, 0.0, 1.0) if _landing_time >= 0 else 1.0
		position_goal = Vector3(0.30, 2.05, 3.65)
		target_goal = Vector3(-0.65, 0.95 + p * 0.29, -0.10)
		fov_goal = 43.0
	var blend: float = 1.0 - exp(-delta * (2.3 if presentation_state in ["landing", "bite"] else 1.5))
	camera.position = camera.position.lerp(position_goal, blend)
	_camera_target = _camera_target.lerp(target_goal, blend)
	camera.fov = lerpf(camera.fov, fov_goal, blend)
	camera.look_at(_camera_target)

func _build_world() -> void:
	_world = WorldEnvironment.new()
	_world.name = "RiverAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_curve = 0.2
	_sky.ground_curve = 0.35
	_sky.sun_angle_max = 8.0
	_sky.sun_curve = 0.09
	sky.sky_material = _sky
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_height = 0.0
	env.fog_height_density = 0.035
	_world.environment = env
	add_child(_world)
	_sun = DirectionalLight3D.new()
	_sun.name = "LateAfternoonSun"
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_max_distance = 65.0
	_sun.shadow_bias = 0.05
	_sun.shadow_normal_bias = 1.2
	add_child(_sun)
	var packed: PackedScene = load("res://assets/3d/environment/managed_oxbow.glb") as PackedScene
	if packed:
		_environment_root = packed.instantiate() as Node3D
		_environment_root.name = "AuthoredOxbow"
		add_child(_environment_root)
		_apply_foliage(_environment_root)
	else: push_error("Missing authored 3D environment. This is not a release-ready stage.")
	_build_water()
	var probe := ReflectionProbe.new()
	probe.name = "RiverbankReflection"
	probe.position = Vector3(0, 2.0, -18)
	probe.size = Vector3(92, 35, 138)
	probe.origin_offset = Vector3(0, 0, 0)
	probe.cull_mask = 1
	probe.intensity = 0.60
	probe.max_distance = 120.0
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.box_projection = true
	add_child(probe)
	camera = Camera3D.new()
	camera.name = "FishingCamera"
	camera.position = Vector3(1.1, 3.0, 5.3)
	camera.fov = 54.0
	camera.near = 0.08
	camera.far = 200.0
	add_child(camera)
	camera.current = true
	camera.look_at(_camera_target)
	_load_character()
	_build_rod()
	_build_bobber()
	_build_line()
	_fish_root = Node3D.new()
	_fish_root.name = "LiveFishPresentation"
	add_child(_fish_root)
	_build_effects()
	_fishery_label = Label3D.new()
	_fishery_label.text = "RIVERBEND\nMANAGED FISHERY"
	_fishery_label.font_size = 48
	_fishery_label.pixel_size = 0.0017
	_fishery_label.position = Vector3(3.55, 1.56, 5.652)
	_fishery_label.rotation.y = PI
	_fishery_label.modulate = Color("e4dfb2")
	_fishery_label.outline_size = 0
	add_child(_fishery_label)

func _apply_foliage(node: Node) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("Foliage"):
		var mesh_node := node as MeshInstance3D
		var color := Color("53702e")
		if str(node.name).contains("Deep"): color = Color("264937")
		elif str(node.name).contains("Green"): color = Color("446a34")
		elif str(node.name).contains("Gold"): color = Color("81924a")
		var shader := ShaderMaterial.new()
		shader.shader = FOLIAGE_SHADER
		shader.set_shader_parameter("leaf_color", color)
		mesh_node.material_override = shader
		_foliage_materials.append(shader)
	elif node is MeshInstance3D and str(node.name) in ["DockHoney", "DockPale", "DockWeathered", "WoodEndgrain", "Bark", "BarkLight", "Grass", "Mud", "Soil", "Sand"]:
		var mesh_node := node as MeshInstance3D
		var is_ground: bool = str(node.name) in ["Grass", "Mud", "Soil", "Sand"]
		var colors: Dictionary = {"DockHoney": Color("786044"), "DockPale": Color("977b52"), "DockWeathered": Color("685541"), "WoodEndgrain": Color("493d2c"), "Bark": Color("544b34"), "BarkLight": Color("695a3c"), "Grass": Color("617345"), "Mud": Color("414e3b"), "Soil": Color("716146"), "Sand": Color("9b8b61")}
		var shader := ShaderMaterial.new()
		shader.shader = GROUND_SHADER if is_ground else WOOD_SHADER
		shader.set_shader_parameter("ground_color" if is_ground else "wood_color", colors[str(node.name)])
		mesh_node.material_override = shader
	for child: Node in node.get_children(): _apply_foliage(child)

func _build_water() -> void:
	var surface := MeshInstance3D.new()
	surface.name = "VolumetricRiverSurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(155, 180)
	plane.subdivide_width = 154
	plane.subdivide_depth = 179
	surface.mesh = plane
	surface.position = Vector3(0, 0, -58)
	surface.layers = 2
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_SHADER
	surface.material_override = _water_material
	add_child(surface)

func _load_character() -> void:
	if ResourceLoader.exists("res://assets/3d/angler.glb"):
		var packed := load("res://assets/3d/angler.glb") as PackedScene
		_angler = packed.instantiate() as Node3D
		_angler.name = "RiggedAngler"
		_angler.position = ANGLER_POS
		add_child(_angler)
		_animator = _find_animator(_angler)
		_rod_socket = _find_named(_angler, "RodSocket") as Node3D
	else:
		_angler = Node3D.new()
		_angler.name = "MissingAnglerAsset"
		_angler.position = ANGLER_POS
		add_child(_angler)
		push_warning("Angler GLB is still in authoring; no substitute character is rendered.")
	if _rod_socket == null:
		_rod_socket = Node3D.new()
		_rod_socket.name = "TemporarySocketUntilAssetImport"
		_rod_socket.position = Vector3(0.32, 1.04, -0.40)
		_rod_socket.rotation.x = -0.32
		_angler.add_child(_rod_socket)

func _build_rod() -> void:
	_rod = Node3D.new()
	_rod.name = "GraphiteFishingRod"
	_rod_socket.add_child(_rod)
	_rod_mesh = MeshInstance3D.new()
	_rod_mesh.name = "TaperedFlexibleBlank"
	_rod_mesh.material_override = _material(Color("273b36"), 0.3, 0.2)
	_rod.add_child(_rod_mesh)
	var grip := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.024
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.34
	cylinder.radial_segments = 10
	grip.mesh = cylinder
	grip.rotation.x = PI * 0.5
	grip.position.z = 0.08
	grip.material_override = _material(Color("a68950"), 0.85)
	_rod.add_child(grip)
	var reel := MeshInstance3D.new()
	var reel_mesh := CylinderMesh.new()
	reel_mesh.top_radius = 0.065
	reel_mesh.bottom_radius = 0.065
	reel_mesh.height = 0.055
	reel_mesh.radial_segments = 14
	reel.mesh = reel_mesh
	reel.position = Vector3(0, -0.075, 0.05)
	reel.rotation.z = PI * 0.5
	reel.material_override = _material(Color("aeb5a0"), 0.3, 0.75)
	_rod.add_child(reel)

func _update_rod() -> void:
	var flex: float = 0.025
	if presentation_state == "fight" and session: flex = 0.14 + session.tension * 0.55
	elif cast_in_progress: flex = sin(clampf(_cast_time / CAST_DURATION, 0, 1) * PI) * 0.23
	elif presentation_state == "landing": flex = 0.30
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(19):
		var u: float = float(i) / 18.0
		points.append(Vector3(0, -flex * pow(u, 2.4), -u * 2.04))
		radii.append(lerpf(0.013, 0.004, u))
	_rod_mesh.mesh = _tube_mesh(points, radii, 6)
	_rod_tip = _rod.to_global(points[18])

func _build_line() -> void:
	_line = MeshInstance3D.new()
	_line.name = "PhysicalCurvedFishingLine"
	_line_material = _material(Color(0.73, 0.77, 0.62, 0.84), 0.7)
	_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = _line_material
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.visible = false
	add_child(_line)

func _update_line() -> void:
	var end: Vector3 = _bobber.position + Vector3.UP * 0.11
	var sag: float = 0.11 if presentation_state in ["fight", "landing", "landed"] else 0.6
	if cast_in_progress: sag = 0.30 + sin(_cast_time * 3.5) * 0.12
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(33):
		var p: float = float(i) / 32.0
		points.append(_rod_tip.lerp(end, p) + Vector3.DOWN * sin(p * PI) * sag)
		radii.append(0.007 if camera.position.distance_to(end) > 8 else 0.0045)
	_line.mesh = _tube_mesh(points, radii, 4)

func _build_bobber() -> void:
	_bobber = Node3D.new()
	_bobber.name = "BuoyantFloat"
	add_child(_bobber)
	for i in range(3):
		var part := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 0.055 if i < 2 else 0.019
		shape.height = 0.10 if i < 2 else 0.15
		shape.radial_segments = 10
		shape.rings = 6
		part.mesh = shape
		part.position.y = 0.02 + i * 0.066
		part.material_override = _material(Color("c45436") if i != 1 else Color("fff1c4"), 0.4)
		_bobber.add_child(part)
	_bobber.visible = false

func _ensure_fish(record: Dictionary) -> void:
	var id: String = str(record.get("species_id", record.get("id", "common_carp")))
	if id not in ["common_carp", "alligator_gar"]: id = "common_carp"
	_fish_length = clampf(float(record.get("length_cm", record.get("length", 72.0))) / 100.0, 0.35, 1.60)
	if id != _fish_id or _fish == null:
		if _fish: _fish.queue_free()
		_fish_id = id
		var path: String = "res://assets/3d/" + id + ".glb"
		if not ResourceLoader.exists(path):
			push_warning("Requested final fish model is not imported yet: " + path)
			return
		_fish = (load(path) as PackedScene).instantiate() as Node3D
		_fish.name = "Fish_" + id
		_fish_root.add_child(_fish)
		_fish_animator = _find_animator(_fish)
	# Authored fish use +X nose, +Y dorsal, 1m rest length.
	if _fish: _fish.scale = Vector3.ONE * _fish_length

func _play_character(clip: String, loop: bool = true) -> void:
	if not _animator: return
	var found: String = _resolve_animation(_animator, clip)
	if found.is_empty(): return
	if _last_anim == found and loop == _last_loop and _animator.is_playing(): return
	_last_anim = found
	_last_loop = loop
	_animator.get_animation(found).loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_animator.play(found, 0.18)

func _play_fish(clip: String) -> void:
	if not _fish_animator: return
	var found: String = _resolve_animation(_fish_animator, clip)
	if found.is_empty(): found = _resolve_animation(_fish_animator, "swim")
	if not found.is_empty():
		_fish_animator.get_animation(found).loop_mode = Animation.LOOP_LINEAR
		_fish_animator.play(found, 0.15)

func _resolve_animation(player: AnimationPlayer, clip: String) -> String:
	for candidate: StringName in player.get_animation_list():
		if str(candidate).to_lower() == clip or str(candidate).to_lower().ends_with("/" + clip): return str(candidate)
	return ""

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animator(child)
		if found: return found
	return null

func _find_named(node: Node, wanted: String) -> Node:
	if str(node.name) == wanted: return node
	for child: Node in node.get_children():
		var found := _find_named(child, wanted)
		if found: return found
	return null

func _build_effects() -> void:
	for i in range(12):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.47
		torus.outer_radius = 0.50
		torus.rings = 36
		torus.ring_segments = 4
		ring.mesh = torus
		var material := ShaderMaterial.new()
		material.shader = RIPPLE_SHADER
		ring.material_override = material
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.visible = false
		add_child(ring)
		_ripple_pool.append({"node": ring, "material": material, "age": 99.0, "duration": 1.5, "power": 1.0})
	var droplet_mesh := SphereMesh.new()
	droplet_mesh.radius = 0.035
	droplet_mesh.height = 0.07
	droplet_mesh.radial_segments = 6
	droplet_mesh.rings = 4
	var spray_material: StandardMaterial3D = _material(Color("b2d6c4"), 0.28)
	for i in range(30):
		var drop := MeshInstance3D.new()
		drop.mesh = droplet_mesh
		drop.material_override = spray_material
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drop.visible = false
		add_child(drop)
		_spray_pool.append({"node": drop, "velocity": Vector3.ZERO, "age": 99.0})

func _spawn_ripple(at: Vector3, power: float, duration: float) -> void:
	_last_ripple = _time
	for effect: Dictionary in _ripple_pool:
		if float(effect.age) < float(effect.duration): continue
		var ring: MeshInstance3D = effect.node
		ring.position = Vector3(at.x, 0.028, at.z)
		ring.visible = true
		effect.age = 0.0
		effect.duration = duration
		effect.power = power
		break

func _splash(at: Vector3, power: float) -> void:
	_spawn_ripple(at, power, 2.0)
	var impact_key: String = "impact_a" if _impact_index % 2 == 0 else "impact_b"
	_impact_index += 1
	_water_material.set_shader_parameter(impact_key, Vector4(at.x, at.z, _time, power * 0.06))
	var amount: int = int(10 + power * 12)
	var spawned: int = 0
	for effect: Dictionary in _spray_pool:
		if float(effect.age) < 1.0: continue
		var drop: MeshInstance3D = effect.node
		drop.position = Vector3(at.x, 0.04, at.z)
		drop.visible = true
		var angle: float = float(spawned) * 2.39996
		effect.velocity = Vector3(cos(angle) * power * 0.85, (1.15 + fmod(float(spawned) * 0.37, 0.9)) * power, sin(angle) * power * 0.85)
		effect.age = 0.0
		spawned += 1
		if spawned >= amount: break

func _update_effects(delta: float) -> void:
	for effect: Dictionary in _ripple_pool:
		effect.age = float(effect.age) + delta
		var ring: MeshInstance3D = effect.node
		var ratio: float = float(effect.age) / float(effect.duration)
		if ratio >= 1.0:
			ring.visible = false
			continue
		var radius: float = 0.2 + ratio * (1.6 + float(effect.power))
		ring.scale = Vector3(radius, 0.10, radius)
		(effect.material as ShaderMaterial).set_shader_parameter("ripple_color", Color(0.66, 0.78, 0.66, (1.0 - ratio) * 0.62))
	for effect: Dictionary in _spray_pool:
		effect.age = float(effect.age) + delta
		var drop: MeshInstance3D = effect.node
		if float(effect.age) > 1.0 or drop.position.y < 0:
			drop.visible = false
			continue
		var velocity: Vector3 = effect.velocity
		velocity.y -= 5.5 * delta
		effect.velocity = velocity
		drop.position += velocity * delta
		drop.scale = Vector3(0.6, 1.7, 0.6) * maxf(0.1, 1.0 - float(effect.age) * 0.4)

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result

func _tube_mesh(points: PackedVector3Array, radii: PackedFloat32Array, sides: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in range(points.size()):
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]).normalized()
		var normal: Vector3 = tangent.cross(Vector3.UP).normalized()
		if normal.length_squared() < 0.01: normal = tangent.cross(Vector3.RIGHT).normalized()
		var binormal: Vector3 = tangent.cross(normal).normalized()
		for j in range(sides):
			var angle: float = TAU * float(j) / float(sides)
			var direction: Vector3 = normal * cos(angle) + binormal * sin(angle)
			vertices.append(points[i] + direction * radii[i])
			normals.append(direction)
			if i > 0:
				var a: int = (i - 1) * sides + j
				var b: int = (i - 1) * sides + (j + 1) % sides
				var c: int = i * sides + j
				var d: int = i * sides + (j + 1) % sides
				indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func debug_snapshot() -> Dictionary:
	return {"state": presentation_state, "mode": mode, "suspended": _suspended, "cast_in_progress": cast_in_progress, "landing_time": _landing_time, "camera_position": camera.position if camera else Vector3.ZERO, "angler_loaded": _animator != null, "fish_loaded": _fish != null, "fish_id": _fish_id, "renderer": RenderingServer.get_current_rendering_method(), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "rendered_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
