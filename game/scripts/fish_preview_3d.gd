class_name FishModelPreview
extends SubViewportContainer
## A transparent, genuinely animated 3D fish for detail/catch pages. No input is
## captured here: the containing page retains ownership of touchscreen scrolling.
const Registry = preload("res://scripts/fish_3d_registry.gd")
signal model_unavailable(species_id: String)
var species_id: String = ""
var model: Node3D
var animator: AnimationPlayer
var _viewport: SubViewport
var _pivot: Node3D
var _camera: Camera3D
var _clock: float = 0.0
var _flatfish: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_viewport = SubViewport.new()
	_viewport.name = "FishPreviewViewport"
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.gui_disable_input = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_viewport.size = Vector2i(640, 400)
	add_child(_viewport)
	var world: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.87, 1.0)
	environment.ambient_light_energy = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.environment = environment
	_viewport.add_child(world)
	_add_light(Vector3(-32, -25, 0), Color(1.0, 0.89, 0.74), 1.55)
	_add_light(Vector3(18, 150, 0), Color(0.65, 0.82, 1.0), 0.72)
	_add_light(Vector3(-60, 100, 0), Color(0.85, 0.94, 1.0), 0.48)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.near = 0.02
	_camera.far = 10.0
	_viewport.add_child(_camera)
	_camera.current = true
	resized.connect(_fit_camera)
	_fit_camera()
	if not species_id.is_empty(): _load_species()

func _add_light(angles: Vector3, color: Color, energy: float) -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = angles
	light.light_color = color
	light.light_energy = energy
	light.shadow_enabled = false
	_viewport.add_child(light)

func set_species(value: String) -> void:
	if value == species_id and model != null: return
	species_id = value
	if is_node_ready(): _load_species()

func _load_species() -> void:
	if model != null:
		model.free()
		model = null
	animator = null
	_clock = 0.0
	if not Registry.is_available(species_id):
		model_unavailable.emit(species_id)
		return
	model = Registry.instantiate_fish(species_id)
	if model == null:
		model_unavailable.emit(species_id)
		return
	_pivot.add_child(model)
	_flatfish = bool(Registry.model_info(species_id).get("asymmetric_flatfish", false))
	animator = _find_animator(model)
	if animator != null:
		for clip: StringName in animator.get_animation_list():
			if str(clip).to_lower() == "swim" or str(clip).to_lower().ends_with("/swim"):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				animator.play(clip)
				break
	_fit_camera()

func _fit_camera() -> void:
	if _camera == null: return
	var aspect: float = maxf(0.2, size.x / maxf(1.0, size.y))
	_camera.size = maxf(0.72, 1.30 / aspect)
	_camera.position = Vector3(0, 1.6, 1.2) if _flatfish else Vector3(0, 0.17, 1.8)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _pivot == null: return
	_clock += minf(delta, 0.1)
	# A small turn exposes volume while preserving a readable species silhouette.
	_pivot.rotation.y = sin(_clock * 0.33) * 0.20

func measurement_endpoints() -> Array[Vector2]:
	# These are the projected normalized rest-length landmarks, not the width of
	# the transparent viewport. The record supplies physical specimen length;
	# swimming deformations are presentation, not a new length measurement.
	var points: Array[Vector2] = []
	if model == null or _camera == null or _viewport == null: return points
	var extent: Vector2 = Vector2(_viewport.size)
	if extent.x <= 0 or extent.y <= 0: return points
	for x: float in [-0.5, 0.5]:
		var projected: Vector2 = _camera.unproject_position(model.to_global(Vector3(x, 0, 0)))
		var local_point: Vector2 = projected * size / extent
		points.append(get_global_transform_with_canvas() * local_point)
	return points

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node as AnimationPlayer
	for child: Node in node.get_children():
		var found: AnimationPlayer = _find_animator(child)
		if found != null: return found
	return null
