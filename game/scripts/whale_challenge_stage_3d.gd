class_name WhaleChallengeStage3D
extends SubViewportContainer
## A dedicated meter-scale ocean scene, camera and waterborne completion. It
## never enters the ordinary fishing stage's landing, mouth hook or fish rig.
const Challenge = preload("res://scripts/blue_whale_challenge.gd")
const MODEL_PATH: String = "res://assets/3d/blue_whale.glb"
const BODY_LENGTH_M: float = 26.0
const BOAT_LENGTH_M: float = 5.6
const OCEAN_SHADER = preload("res://assets/shaders3d/whale_ocean.gdshader")

var model: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var viewport: SubViewport
var challenge: BlueWhaleChallenge
var body_length_m: float = BODY_LENGTH_M
var success_view: bool = false
var _whale_root: Node3D
var _boat: Node3D
var _echo_ring: Node3D
var _rings: Array[MeshInstance3D] = []
var _line: MeshInstance3D
var _line_material: StandardMaterial3D
var _water_material: ShaderMaterial
var _clock: float = 0.0
var _suspended: bool = false
var _model_error: Label

static func model_available() -> bool:
	return ResourceLoader.exists(MODEL_PATH, "PackedScene")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport = SubViewport.new()
	viewport.name = "WhaleOceanViewport"
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(720, 1280)
	add_child(viewport)
	_build_environment()
	_build_boat()
	_build_whale()
	_build_echo()
	camera = Camera3D.new()
	camera.name = "WholeWhaleCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.1
	camera.far = 700.0
	viewport.add_child(camera)
	camera.current = true
	resized.connect(_fit_camera)
	_fit_camera()

func bind_challenge(value: BlueWhaleChallenge) -> void:
	challenge = value

func suspend(value: bool) -> void:
	_suspended = value
	if animator != null:
		if value: animator.pause()
		elif animator.has_animation("swim"): animator.play("swim")

func show_success() -> void:
	success_view = true
	_fit_camera()

func _build_environment() -> void:
	var world: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("31778d")
	sky_material.sky_horizon_color = Color("b5d5cf")
	sky_material.ground_horizon_color = Color("b5d5cf")
	sky_material.ground_bottom_color = Color("143b4d")
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8dc9d8")
	environment.ambient_light_energy = 0.8
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	viewport.add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -25.0, 0.0)
	sun.light_color = Color("fff2d4")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	viewport.add_child(sun)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, 140.0, 0.0)
	fill.light_color = Color("72b9df")
	fill.light_energy = 0.5
	viewport.add_child(fill)
	var bottom: MeshInstance3D = MeshInstance3D.new()
	var bottom_mesh: PlaneMesh = PlaneMesh.new()
	bottom_mesh.size = Vector2(600.0, 600.0)
	bottom.mesh = bottom_mesh
	bottom.position.y = -18.0
	var depth_material: StandardMaterial3D = StandardMaterial3D.new()
	depth_material.albedo_color = Color("073448")
	depth_material.roughness = 1.0
	bottom.material_override = depth_material
	viewport.add_child(bottom)
	var water: MeshInstance3D = MeshInstance3D.new()
	water.name = "OpenOceanSurface"
	var water_mesh: PlaneMesh = PlaneMesh.new()
	water_mesh.size = Vector2(600.0, 600.0)
	water_mesh.subdivide_width = 80
	water_mesh.subdivide_depth = 80
	water.mesh = water_mesh
	_water_material = ShaderMaterial.new()
	_water_material.shader = OCEAN_SHADER
	water.material_override = _water_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(water)

func _build_boat() -> void:
	_boat = Node3D.new()
	_boat.name = "FiveMeterBoatForScale"
	_boat.position = Vector3(0.0, 0.0, 10.5)
	viewport.add_child(_boat)
	var packed: PackedScene = load("res://assets/3d/environment/station_boat.glb") as PackedScene
	if packed != null:
		var hull: Node3D = packed.instantiate() as Node3D
		_boat.add_child(hull)
		var bounds: AABB = _bounds(hull)
		var length: float = maxf(bounds.size.x, bounds.size.z)
		if length > 0.001: hull.scale = Vector3.ONE * BOAT_LENGTH_M / length
		hull.position.y = -0.25
		hull.rotation.y = PI / 2.0
	# A visible fantasy receiver on the boat, rather than a rod/hook rig.
	var receiver: MeshInstance3D = MeshInstance3D.new()
	var receiver_mesh: SphereMesh = SphereMesh.new()
	receiver_mesh.radius = 0.18
	receiver_mesh.height = 0.36
	receiver.mesh = receiver_mesh
	receiver.position = Vector3(0.0, 1.35, -0.4)
	receiver.material_override = _glow_material(Color("69f1de"), 2.0)
	_boat.add_child(receiver)

func _build_whale() -> void:
	_whale_root = Node3D.new()
	_whale_root.name = "Whale26MeterRoot"
	_whale_root.position = Vector3(0.0, -2.9, -3.0)
	viewport.add_child(_whale_root)
	if not model_available():
		_model_error = Label.new()
		_model_error.text = "蓝鲸专用模型尚未就绪"
		_model_error.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_model_error.add_theme_font_size_override("font_size", 26)
		add_child(_model_error)
		return
	var packed: PackedScene = load(MODEL_PATH) as PackedScene
	model = packed.instantiate() as Node3D if packed != null else null
	if model == null: return
	_whale_root.add_child(model)
	# The model authoring convention is a one-meter rest length. This scene maps
	# that coordinate to 26 actual meters and independently fits its full bounds.
	model.scale = Vector3.ONE * BODY_LENGTH_M
	animator = _find_animator(model)
	if animator != null:
		for clip: StringName in animator.get_animation_list():
			if str(clip).to_lower() == "swim" or str(clip).to_lower().ends_with("/swim"):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				animator.play(clip)
				break

func _build_echo() -> void:
	_echo_ring = Node3D.new()
	_echo_ring.name = "UnattachedFantasyEchoRings"
	_echo_ring.position = Vector3(16.4, -1.5, -3.0)
	viewport.add_child(_echo_ring)
	for i: int in range(3):
		var ring: MeshInstance3D = MeshInstance3D.new()
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = 0.85 + float(i) * 0.17
		torus.outer_radius = 0.91 + float(i) * 0.17
		ring.mesh = torus
		ring.rotation.z = PI / 2.0
		ring.position.x = float(i) * 0.55
		ring.material_override = _glow_material(Color("75b9d0"), 0.6)
		_echo_ring.add_child(ring)
		_rings.append(ring)
	_line = MeshInstance3D.new()
	_line.name = "EnergyTetherToEchoOnly"
	_line_material = _glow_material(Color("baffce"), 1.8)
	_line_material.no_depth_test = true
	_line_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_line.material_override = _line_material
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(_line)

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _fit_camera() -> void:
	if camera == null or not camera.is_inside_tree(): return
	var aspect: float = maxf(0.25, size.x / maxf(1.0, size.y))
	# Width controls this unusually wide animal. Include animated fins, the boat,
	# the external echo ring, and a 12% margin at portrait and landscape aspects.
	camera.size = maxf(27.0, 43.0 / aspect)
	camera.position = Vector3(3.0, 23.0, 36.0)
	camera.look_at(Vector3(1.0, -1.2, 1.7), Vector3.UP)

func _process(delta: float) -> void:
	if _suspended or not is_visible_in_tree(): return
	_clock += delta
	_water_material.set_shader_parameter("wave_clock", _clock)
	_boat.position.y = sin(_clock * 0.68) * 0.075
	_boat.rotation.x = sin(_clock * 0.61) * 0.012
	_whale_root.position.y = -2.9 + sin(_clock * 0.36) * 0.22
	_whale_root.position.x = sin(_clock * 0.17) * (1.5 if success_view else 0.45)
	_whale_root.rotation.y = sin(_clock * 0.23) * 0.025
	if challenge != null and challenge.state == Challenge.State.CURRENT:
		_whale_root.rotation.y += (challenge.route_target - 0.5) * 0.14
	for i: int in range(_rings.size()):
		var lit: bool = challenge != null and challenge.links > i
		(_rings[i].material_override as StandardMaterial3D).albedo_color = Color("80ffe0") if lit else Color("75b9d0")
		_rings[i].rotation.x = _clock * (0.25 + float(i) * 0.07)
	_line.visible = not success_view and challenge != null and challenge.is_active()
	if _line.visible: _draw_energy_line()

func _draw_energy_line() -> void:
	var start: Vector3 = _boat.position + Vector3(0.0, 1.35, -0.4)
	var end: Vector3 = _echo_ring.position
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var energy: float = challenge.pulse if challenge.state == Challenge.State.LINK else challenge.tension
	var perpendicular: Vector3 = (end - start).cross(Vector3.UP).normalized() * (0.07 + energy * 0.045)
	var arc_height: float = 1.8
	if challenge.state == Challenge.State.RESONANCE: arc_height = 0.7 + (1.0 - challenge.tension) * 2.4
	_line_material.albedo_color = Color("ffc398") if challenge.danger_time > 0.5 else Color("baffce")
	_line_material.emission = _line_material.albedo_color
	for i: int in range(25):
		var ratio: float = float(i) / 24.0
		var point: Vector3 = start.lerp(end, ratio)
		point.y += sin(ratio * PI) * (arc_height + sin(_clock * 1.4 + ratio * 6.0) * 0.3)
		mesh.surface_add_vertex(point - perpendicular)
		mesh.surface_add_vertex(point + perpendicular)
	mesh.surface_end()
	_line.mesh = mesh

func framing_endpoints() -> Array[Vector2]:
	var result: Array[Vector2] = []
	if camera == null or _whale_root == null: return result
	for point: Vector3 in [Vector3(-13.8, -4.6, -6.2), Vector3(13.8, -0.8, 0.2), Vector3(-13.8, -4.6, 0.2), Vector3(13.8, -0.8, -6.2)]:
		result.append(camera.unproject_position(point))
	return result

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node as AnimationPlayer
	for child: Node in node.get_children():
		var found: AnimationPlayer = _find_animator(child)
		if found != null: return found
	return null

func _bounds(node: Node3D, parent_transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var transform: Transform3D = parent_transform * node.transform
	var result: AABB = AABB()
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		result = transform * (node as MeshInstance3D).mesh.get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_bounds: AABB = _bounds(child, transform)
			if child_bounds.size.length_squared() > 0.0:
				result = child_bounds if result.size.length_squared() == 0.0 else result.merge(child_bounds)
	return result
