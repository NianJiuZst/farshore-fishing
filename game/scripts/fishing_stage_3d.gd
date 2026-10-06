class_name FishingStage3D
extends Node3D
## Presentation-only 3D fishery. Never changes inventory, rewards, or session outcomes.
signal cast_presentation_finished
signal cast_water_contact
signal landing_finished(record: Dictionary)
signal model_error(species_id: String, message: String)
signal location_changed(region_id: String, spot_id: String)
signal location_error(region_id: String, spot_id: String, message: String)

const WaterDomain=preload("res://scripts/fishing_water_domain.gd")
const WATER_SHADER = preload("res://assets/shaders3d/river_water.gdshader")
const FOLIAGE_SHADER = preload("res://assets/shaders3d/foliage.gdshader")
const RIPPLE_SHADER = preload("res://assets/shaders3d/ripple.gdshader")
const FLOAT_SHADER = preload("res://assets/shaders3d/float_lacquer.gdshader")
const REED_SHADER = preload("res://assets/shaders3d/shore_reeds.gdshader")
const ROCK_SHADER = preload("res://assets/shaders3d/rock_surface.gdshader")
const HDR_SKY_SHADER = preload("res://assets/shaders3d/hdr_sky.gdshader")
const WOOD_SHADER = preload("res://assets/shaders3d/weathered_wood.gdshader")
const GROUND_SHADER = preload("res://assets/shaders3d/riverbank.gdshader")
const ANGLER_POS := Vector3(-0.92, 0.584, 0.77)
const CAST_DURATION: float = 2.20
const RELEASE_TIME: float = 1.20
const LANDING_DURATION: float = 3.35
const REFERENCE_CAMERA_ASPECT: float = 720.0 / 1280.0
const FISHING_CAMERA_POSITION := Vector3(1.1, 3.7, 6.2)
const FISHING_CAMERA_TARGET := Vector3(-1.3, 0.55, -4.5)
const FISHING_CAMERA_FOV: float = 51.0
const FLOAT_VIEW_OFFSET := Vector3(0.34, 1.16, 3.05)
const FLOAT_VIEW_FOV: float = 43.0
# All float dimensions are metres. Local y=0 is the shotted neutral waterline.
# The 11.4cm sight tip projects to about 53px in the fixed 720px-wide water view.
const FLOAT_TIP_TOP: float = 0.114
const FLOAT_SIGHT_RADIUS: float = 0.0056
const FLOAT_DIP_TRAVEL: float = 0.18
const FLOAT_LIFT_TRAVEL: float = 0.09
const FLOAT_LINE_EYE := Vector3(0, -0.161, 0.0015)
const FishModels = preload("res://scripts/fish_3d_registry.gd")
const Session = preload("res://scripts/fishing_session.gd")
const GEAR_VISUALS: Array[Dictionary] = [
	{"rod_length":2.04, "rod_radius":0.013, "rod_color":"273b36", "reel_color":"aeb5a0", "grip_color":"a68950", "flex_scale":1.0},
	{"rod_length":2.22, "rod_radius":0.014, "rod_color":"315875", "reel_color":"c0a566", "grip_color":"876a3e", "flex_scale":0.95},
	{"rod_length":2.42, "rod_radius":0.016, "rod_color":"273744", "reel_color":"96b8be", "grip_color":"66513c", "flex_scale":0.85},
	{"rod_length":1.86, "rod_radius":0.0105, "rod_color":"315b83", "reel_color":"c5cdd0", "grip_color":"c2a77a", "flex_scale":1.13},
	{"rod_length":2.58, "rod_radius":0.018, "rod_color":"632b38", "reel_color":"bb9452", "grip_color":"362c29", "flex_scale":0.72},
	{"rod_length":2.30, "rod_radius":0.017, "rod_color":"174f67", "reel_color":"a8b9c5", "grip_color":"283d4b", "flex_scale":0.86},
]

# Rest-pose mouth landmarks measured from final normalized rigs. Godot +X
# faces the snout, +Y is dorsal. Most fish use the terminal-mouth default.
const FISH_MOUTH_OFFSETS: Dictionary = {
	"chinese_sturgeon":Vector3(0.321118, -0.025555, 0.0),
	"olive_flounder":Vector3(0.495556, -0.001024, -0.001024),
	"european_plaice":Vector3(0.496836, -0.001030, 0.003089),
}

const BIOME_VISUALS: Dictionary = {
	"lake":{"deep":"123f49","shallow":"3a7061","bed":"263d2e","leaf":"426a39","gold":"75834a","rock":"c2c7bd","ground":"617345","width":17.0,"widen":0.005,"fog":0.0018},
	"japan":{"deep":"123647","shallow":"397277","bed":"3a453c","leaf":"254c3c","gold":"4d7050","rock":"bdc1be","ground":"696b58","width":11.5,"widen":0.24,"fog":0.0011},
	"norway":{"deep":"0d293d","shallow":"315665","bed":"202d30","leaf":"274b40","gold":"57735c","rock":"a6b6c8","ground":"4c6153","width":13.0,"widen":0.035,"fog":0.0017},
	"med":{"deep":"0d4c61","shallow":"4ba298","bed":"797557","leaf":"516951","gold":"829071","rock":"f1d6a6","ground":"9a9365","width":15.0,"widen":0.26,"fog":0.0009},
	"bayou":{"deep":"163e35","shallow":"4a7350","bed":"233a32","leaf":"355c37","gold":"637b42","rock":"b7bea6","ground":"617345","width":9.8,"widen":0.0,"fog":0.0020},
	"yangtze":{"deep":"3d5448","shallow":"76846a","bed":"4b4b32","leaf":"496f40","gold":"84925b","rock":"cac5ac","ground":"79825a","width":26.0,"widen":0.12,"fog":0.0019},
	"pacific_ocean":{"deep":"073d63","shallow":"28a6a6","bed":"516965","leaf":"255b42","gold":"799752","rock":"abc1ba","ground":"aaae87","width":2000.0,"widen":0.0,"fog":0.00042},
	"atlantic_ocean":{"deep":"102f50","shallow":"497f91","bed":"354858","leaf":"52675c","gold":"7b8765","rock":"a2b2bd","ground":"818d7c","width":2000.0,"widen":0.0,"fog":0.00070},
	"indian_ocean":{"deep":"066d80","shallow":"43c3bc","bed":"909577","leaf":"376c42","gold":"9ba863","rock":"e1d6b1","ground":"d1ca9e","width":2000.0,"widen":0.0,"fog":0.00034},
	"red_sea":{"deep":"074c79","shallow":"32b6b9","bed":"b5a777","leaf":"b18c67","gold":"cfb480","rock":"dbad81","ground":"c6ad80","width":2000.0,"widen":0.0,"fog":0.00032},
}

# A shared daylight model, with regional atmosphere and water readability.
const BIOME_ATMOSPHERE: Dictionary = {
	"lake": {"horizon":"bad0c8", "fog":"a3bfb6", "sky":"e2f0ee", "clarity":0.56, "roughness":0.22},
	"japan": {"horizon":"c0d3db", "fog":"a6c1ce", "sky":"e8f1ff", "clarity":0.65, "roughness":0.20},
	"norway": {"horizon":"b5c8dc", "fog":"9cb6cf", "sky":"dce8ff", "clarity":0.73, "roughness":0.24},
	"med": {"horizon":"d4e1d4", "fog":"bccfc6", "sky":"fff3dc", "clarity":0.86, "roughness":0.19},
	"bayou": {"horizon":"bbc9b1", "fog":"a4b59a", "sky":"eff0dc", "clarity":0.30, "roughness":0.25},
	"yangtze": {"horizon":"d0cbbb", "fog":"bcb9a6", "sky":"f0eadb", "clarity":0.22, "roughness":0.27},
	"pacific_ocean": {"horizon":"b6d6df", "fog":"8db7c9", "sky":"d7edff", "clarity":0.80, "roughness":0.23},
	"atlantic_ocean": {"horizon":"b4c5d4", "fog":"91adbf", "sky":"dfe8f7", "clarity":0.72, "roughness":0.25},
	"indian_ocean": {"horizon":"c4e4dc", "fog":"98c9cb", "sky":"e8f5e7", "clarity":0.90, "roughness":0.20},
	"red_sea": {"horizon":"d7d4bb", "fog":"bcdad1", "sky":"f8f1dc", "clarity":0.94, "roughness":0.19},
}

var session: FishingSession
var camera: Camera3D
var presentation_state: String = "lobby"
var cast_in_progress: bool = false
var weather: String = "clear"
var time_of_day: String = "day"
var mode: String = "lobby"
var gear_id: int = 0
var gear_profile: Dictionary = {}
var asset_error: String = ""
var region_id: String = "bayou"
var spot_id: String = "bayou_backwater"
var location_rebuild_count: int = 0
var _location_built_key: String = ""
var _initial_location_error: String = ""
var _world_locations: Dictionary = {}
var _region_definition: Dictionary = {}
var _spot_definition: Dictionary = {}
var _station_root: Node3D
var _water_domain=WaterDomain.new()
var _riverbed: MeshInstance3D
var _ocean_horizon_water: MeshInstance3D
var _built: bool = false
var _suspended: bool = false
var _character_was_playing: bool = false
var _fish_was_playing: bool = false
var _time: float = 0.0
var _state: int = Session.State.IDLE
var _before_pause: int = Session.State.IDLE
var _cast_time: float = 0.0
var _landing_time: float = -1.0
var _landing_record: Dictionary = {}
var _landed_catch_id: String = ""
var _water_material: ShaderMaterial
var _foliage_materials: Array[ShaderMaterial] = []
var _horizon_materials: Array[StandardMaterial3D] = []
var _world: WorldEnvironment
var _sun: DirectionalLight3D
var _panorama: ShaderMaterial
var _sky: ProceduralSkyMaterial
var _reflection_probe: ReflectionProbe
var _last_lighting_key: String = ""
var _environment_root: Node3D
var _angler: Node3D
var _animator: AnimationPlayer
var _rod_socket: Node3D
var _rod: Node3D
var _rod_mesh: MeshInstance3D
var _rod_grip: MeshInstance3D
var _rod_reel: MeshInstance3D
var _rod_accents: Array[MeshInstance3D] = []
var _rod_length: float = 2.04
var _rod_radius: float = 0.013
var _rod_tip_radius: float = 0.004
var _rod_flex_scale: float = 1.0
var _rod_visual_reach: float = 1.0
var _rod_tip: Vector3 = Vector3.ZERO
var _rod_shape_key := Vector4(INF, INF, INF, INF)
var _line: MeshInstance3D
var _line_material: StandardMaterial3D
var _bobber: Node3D
var _float_materials: Dictionary = {}
var _float_meniscus: MeshInstance3D
var _float_wake: MeshInstance3D
var _float_last_surface_position := Vector3.ZERO
var _float_surface_tracking: bool = false
var _bobber_target: Vector3 = Vector3(-0.9, 0.0, -9.0)
var _cast_origin: Vector3
var _cast_camera_origin: Vector3
var _cast_camera_target_origin: Vector3
var _cast_camera_fov_origin: float = 51.0
var _fish_root: Node3D
var _fish: Node3D
var _fish_animator: AnimationPlayer
var _fish_id: String = ""
var _fish_info: Dictionary = {}
var _asset_error_label: Label3D
var _fish_length: float = 0.72
var _ripple_pool: Array[Dictionary] = []
var _spray_pool: Array[Dictionary] = []
var _last_ripple: float = -9.0
var _impact_index: int = 0
var _camera_target: Vector3 = Vector3(-1.5, 1.05, -1.7)
var _camera_base_vertical_fov: float = 54.0
var _last_anim: String = ""
var _last_loop: bool = true
var _cast_finished_emitted: bool = false
var _cast_impact_emitted: bool = false
var _fishery_label: Label3D
var _rain: GPUParticles3D
var _portrait_fill: OmniLight3D
var _reel_handle: Node3D
var _reel_handle_speed: float = 0.0
var _lighting_tween: Tween
var _lighting_paused: bool = false
var visual_quality: String = "balanced"
var reduce_motion: bool = false

func _ready() -> void:
	process_priority = 100
	_build_world()
	_built = true
	set_time_of_day(time_of_day)
	set_weather(weather)
	set_visual_quality(visual_quality)
	set_mode(mode)
	if session != null: bind_session(session)
	RenderingServer.frame_pre_draw.connect(_sync_tackle_transform)

func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync_tackle_transform):
		RenderingServer.frame_pre_draw.disconnect(_sync_tackle_transform)

func _sync_tackle_transform() -> void:
	# Skeleton/BoneAttachment updates have settled immediately before drawing.
	# Keep rod endpoint and world-space line on the same visible animation pose.
	if not _built or _suspended: return
	_update_rod()
	if _line.visible and _bobber.visible: _update_line()

func bind_session(value: FishingSession) -> void:
	if session != null and session.changed.is_connected(_session_changed):
		session.changed.disconnect(_session_changed)
	session = value
	if session != null:
		session.changed.connect(_session_changed)
		if _built: _session_changed(session.state)

func _read_locations() -> void:
	if not _world_locations.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	if parsed is Dictionary: _world_locations = parsed

func _location_definitions(region_value: String, spot_value: String) -> Dictionary:
	_read_locations()
	var region: Dictionary = {}
	var spot: Dictionary = {}
	for candidate: Dictionary in _world_locations.get("regions", []):
		if str(candidate.get("region_id", "")) == region_value: region = candidate
	for candidate: Dictionary in _world_locations.get("spots", []):
		if str(candidate.get("spot_id", "")) == spot_value and str(candidate.get("region_id", "")) == region_value: spot = candidate
	if region.is_empty() or spot.is_empty() or not BIOME_VISUALS.has(region_value): return {}
	return {"region":region, "spot":spot}

func _travel_is_safe() -> bool:
	if cast_in_progress or _landing_time >= 0.0: return false
	if session == null: return true
	var actual_state: int = session.before_pause if session.state == Session.State.PAUSED else session.state
	return actual_state in [Session.State.IDLE, Session.State.ESCAPED]

func set_location(region_value: String, spot_value: String) -> bool:
	var definitions: Dictionary = _location_definitions(region_value, spot_value)
	if definitions.is_empty(): return false
	var key: String = region_value + ":" + spot_value
	if _built and key == _location_built_key: return true
	if _built and not _travel_is_safe(): return false
	var wanted_station: String = _station_kind(str(definitions.spot.get("foreground", "pier")))
	if not ResourceLoader.exists(_region_scene_path(region_value), "PackedScene") or not ResourceLoader.exists("res://assets/3d/environment/station_" + wanted_station + ".glb", "PackedScene"):
		if not _built: _initial_location_error = "3D location is not ready: " + key
		_report_location_error("3D location is not ready: " + key)
		return false
	if not _built:
		region_id = region_value
		spot_id = spot_value
		_region_definition = definitions.region
		_spot_definition = definitions.spot
		_initial_location_error = ""
		return true
	if not _replace_location_geometry(region_value, spot_value): return false
	cancel_landing()
	_bobber.visible = false
	_float_meniscus.visible = false
	_float_wake.visible = false
	_line.visible = false
	presentation_state = "lobby" if mode == "lobby" else "ready"
	_play_character("idle")
	_configure_location_surfaces()
	_last_lighting_key = ""
	set_time_of_day(time_of_day)
	if _asset_error_label: _asset_error_label.visible = false
	asset_error = ""
	location_changed.emit(region_id, spot_id)
	return true

func set_region(region: Variant, spot: Variant = null) -> void:
	var region_value: String = str(region.get("region_id", region_id)) if region is Dictionary else str(region)
	var spot_value: String = str(spot.get("spot_id", spot_id)) if spot is Dictionary else (str(spot) if spot != null else spot_id)
	set_location(region_value, spot_value)

func _station_kind(foreground: String) -> String:
	return "boat" if foreground == "boat" else ("rock" if foreground == "rocks" else "dock")

func _region_scene_path(value: String) -> String:
	return "res://assets/3d/environment/region_" + value + ".glb"

func _station_frame() -> Transform3D:
	var anchor := Vector3.ZERO
	var angle: float = 0.0
	match spot_id:
		"lake_bay": anchor = Vector3(2, 0, -22)
		"norway_boat": anchor = Vector3(0, 0, -33)
		"med_boat": anchor = Vector3(3, 0, -31)
		"bayou_channel": anchor = Vector3(0, 0, -34)
		# The central alluvial island extends x=-11.34..7.34, z=-57.60..-24.88.
		# Moor in the eastern channel; do not place the boat on that island.
		"yangtze_estuary": anchor = Vector3(14, 0, -40)
		"pacific_bluewater", "atlantic_bluewater", "indian_bluewater": anchor = Vector3(0, 0, -420)
		"pacific_reef": anchor = Vector3(-6, 0, -22)
		"atlantic_shelf": anchor = Vector3(7, 0, -15)
		"indian_reef": anchor = Vector3(6, 0, -18)
		"red_sea_lagoon": anchor = Vector3(-9, 0, -24)
		"red_sea_wall": anchor = Vector3(4, 0, -92)
		"red_sea_bluehole": anchor = Vector3(6, 0, -285)
		"japan_reef", "yangtze_river":
			var z: float = -42.0 if region_id == "japan" else -12.0
			var biome: Dictionary = BIOME_VISUALS[region_id]
			var edge: float = float(biome.width) + 1.9 * sin(z * 0.065) + 1.4 * cos(z * 0.14) + maxf(0, -z) * float(biome.widen)
			anchor = Vector3(-edge + (3.0 if region_id == "japan" else 1.1), 0, z)
			angle = -PI * 0.5
	return Transform3D(Basis(Vector3.UP, angle), anchor)

func _replace_location_geometry(region_value: String = "", spot_value: String = "") -> bool:
	if region_value.is_empty(): region_value = region_id
	if spot_value.is_empty(): spot_value = spot_id
	var definitions: Dictionary = _location_definitions(region_value, spot_value)
	if definitions.is_empty():
		_report_location_error("Invalid 3D location: " + region_value + ":" + spot_value)
		return false
	var region_path: String = _region_scene_path(region_value)
	var station_path: String = "res://assets/3d/environment/station_" + _station_kind(str(definitions.spot.get("foreground", "pier"))) + ".glb"
	if not ResourceLoader.exists(region_path, "PackedScene") or not ResourceLoader.exists(station_path, "PackedScene"):
		_report_location_error("3D location assets are not ready: " + region_value + ":" + spot_value)
		return false
	var region_pack := load(region_path) as PackedScene
	var station_pack := load(station_path) as PackedScene
	if region_pack == null or station_pack == null or not region_pack.can_instantiate() or not station_pack.can_instantiate():
		_report_location_error("Unable to load 3D location: " + region_value + ":" + spot_value)
		return false
	# Validate both candidates while off-tree. Rejected loads leave the previous
	# IDs, definitions and live roots untouched; no partial travel can be shown.
	var region_candidate: Node = region_pack.instantiate()
	var station_candidate: Node = station_pack.instantiate()
	if not region_candidate is Node3D or not station_candidate is Node3D:
		if region_candidate: region_candidate.free()
		if station_candidate: station_candidate.free()
		_report_location_error("Invalid 3D root in location: " + region_value + ":" + spot_value)
		return false
	region_id = region_value
	spot_id = spot_value
	_region_definition = definitions.region
	_spot_definition = definitions.spot
	# Commit only after both nodes have been validated. Old roots leave the
	# viewport before the selected replacements enter it.
	if _environment_root:
		remove_child(_environment_root)
		_environment_root.queue_free()
	if _station_root:
		remove_child(_station_root)
		_station_root.queue_free()
	_foliage_materials.clear()
	_horizon_materials.clear()
	_environment_root = region_candidate as Node3D
	_environment_root.name = "ActiveBiome_" + region_id
	_environment_root.transform = _station_frame().affine_inverse()
	add_child(_environment_root)
	_apply_foliage(_environment_root)
	_build_distant_landscape()
	_station_root = station_candidate as Node3D
	_station_root.name = "ActiveStation_" + _station_kind(str(_spot_definition.get("foreground", "pier")))
	# This bank's broad ledge used to cover the near end of the fight corridor.
	# Shorten its water-facing apron while retaining the exact standing height.
	if spot_id=="yangtze_river": _station_root.scale.z=0.60
	add_child(_station_root)
	_apply_foliage(_station_root)
	_water_domain.rebuild(self,[_environment_root,_station_root])
	_location_built_key = region_id + ":" + spot_id
	location_rebuild_count += 1
	return true

func _build_distant_landscape() -> void:
	# Ocean GLBs contain discrete islands; a surrounding mountain ring would
	# turn the open sea into another river or lake.
	if (region_id.ends_with("_ocean") or region_id == "red_sea"): return
	# Two low-cost opaque landforms make the foreground shore read against distance.
	# Heights are regional: low floodplain, lake hills, coastal headlands and fjord peaks.
	var heights: Dictionary = {"lake":24.0, "japan":31.0, "norway":84.0, "med":26.0, "bayou":8.5, "yangtze":30.0}
	var coastal: bool = region_id in ["japan", "norway", "med"]
	for layer: int in range(2):
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		var segments: int = 96
		var radius: float = 143.0 + float(layer) * 66.0
		var phase: float = float(layer) * 1.87 + float(BIOME_VISUALS.keys().find(region_id)) * 0.74
		for ring: int in range(3):
			for step: int in range(segments + 1):
				var angle: float = float(step) / float(segments) * TAU
				var rhythm: float = 0.48 + sin(angle * 3.0 + phase) * 0.19 + cos(angle * 7.0 - phase) * 0.13 + sin(angle * 13.0 + 0.7) * 0.055
				var height: float = float(heights[region_id]) * rhythm * (1.0 + layer * 0.34)
				# Keep the seaward channel open between the coastal headlands.
				if coastal: height *= smoothstep(0.08, 0.66, absf(sin(angle)))
				var ridge: float = height if ring == 1 else (-2.5 if ring == 0 else height * 0.44)
				var distance: float = radius + float(ring) * 19.0
				vertices.append(Vector3(sin(angle) * distance, ridge, -42.0 + cos(angle) * distance))
				var shade: float = 0.87 + rhythm * 0.13 + float(ring) * 0.025
				colors.append(Color(shade, shade, shade, 1.0))
		for ring: int in range(2):
			for step: int in range(segments):
				var a: int = ring * (segments + 1) + step
				var b: int = a + segments + 1
				indices.append_array(PackedInt32Array([a, a + 1, b, b, a + 1, b + 1]))
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var land := MeshInstance3D.new()
		land.name = "DistantLandform_%d" % layer
		land.mesh = mesh
		land.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.vertex_color_use_as_albedo = true
		material.albedo_color = Color(str(BIOME_VISUALS[region_id].leaf)).lerp(Color(str(BIOME_ATMOSPHERE[region_id].fog)), 0.4 + layer * 0.2)
		land.material_override = material
		_horizon_materials.append(material)
		_environment_root.add_child(land)

func _hide_legacy_station(node: Node) -> void:
	if node is MeshInstance3D and str(node.name) in ["DockHoney", "DockPale", "DockWeathered", "WoodEndgrain", "Iron", "Rope", "Enamel", "Canvas", "Paper"]:
		(node as MeshInstance3D).visible = false
	for child: Node in node.get_children(): _hide_legacy_station(child)

func _configure_location_surfaces() -> void:
	if _water_material == null: return
	var biome: Dictionary = BIOME_VISUALS[region_id]
	var ocean: bool = (region_id.ends_with("_ocean") or region_id == "red_sea")
	if camera: camera.far = 12000.0 if ocean else 330.0
	var near_reef: bool = (spot_id.ends_with("_reef") or spot_id in ["red_sea_lagoon", "red_sea_wall"])
	_water_material.set_shader_parameter("deep_color", Color(str(biome.deep)).lerp(Color(str(biome.shallow)),0.24 if near_reef else 0.0))
	_water_material.set_shader_parameter("ocean_mode", ocean)
	if _ocean_horizon_water: _ocean_horizon_water.visible = ocean
	_water_material.set_shader_parameter("shallow_color", Color(str(biome.shallow)))
	_water_material.set_shader_parameter("shore_width", float(biome.width))
	_water_material.set_shader_parameter("shore_widen", float(biome.widen))
	var atmosphere: Dictionary = BIOME_ATMOSPHERE[region_id]
	_water_material.set_shader_parameter("water_clarity", float(atmosphere.clarity))
	_water_material.set_shader_parameter("surface_roughness", float(atmosphere.roughness))
	_water_material.set_shader_parameter("foam_color", Color("d6e6e2") if ocean else (Color("c6d7cd") if region_id in ["norway", "japan", "med"] else Color("b8c4aa")))
	var station: Transform3D = _station_frame()
	var angle: float = station.basis.get_euler().y
	_water_material.set_shader_parameter("shore_transform", Vector4(cos(angle), sin(angle), station.origin.x, station.origin.z))
	if _riverbed:
		_riverbed.position.y = -minf(12.0, maxf(2.8, float(_spot_definition.get("depth_max_m", 8.0)) * 0.3))
		(_riverbed.material_override as ShaderMaterial).set_shader_parameter("ground_color", Color(str(biome.bed)))
	if _reflection_probe:
		# A finite coastal probe causes a visible rectangular reflection edge on
		# open water. Oceans use the continuous native sky reflection instead.
		_reflection_probe.visible = not ocean
		_reflection_probe.size = Vector3(180, 150 if region_id == "norway" else 60, 220)
		_reflection_probe.max_distance = 190.0
		_reflection_probe.position.x = 0.002 if _reflection_probe.position.x < 0.001 else 0.0
	if _sun: _sun.directional_shadow_max_distance = 38.0 if visual_quality == "low" else (90.0 if region_id == "norway" else 65.0)
	if _fishery_label:
		_fishery_label.visible = _station_kind(str(_spot_definition.get("foreground", "pier"))) == "dock"
		_fishery_label.text = str(_region_definition.get("name", region_id)) + "\n" + str(_spot_definition.get("name", spot_id))
	if _built:
		for effect: Dictionary in _ripple_pool:
			effect.age = 99.0
			(effect.node as Node3D).visible = false
		for effect: Dictionary in _spray_pool:
			effect.age = 99.0
			(effect.node as Node3D).visible = false

func _report_location_error(message: String) -> void:
	asset_error = message
	if _asset_error_label:
		_asset_error_label.text = "3D LOCATION NOT READY\n" + message.trim_prefix("3D location is not ready: ")
		_asset_error_label.visible = true
	push_warning(message)
	location_error.emit(region_id, spot_id, message)


func set_gear_profile(gear: Dictionary) -> void:
	# Presentation only: power, tolerance, reach, prices and save values are untouched.
	# Every profile preserves the same right-hand socket, rear grip and reel centers.
	gear_id = clampi(int(gear.get("id", 0)), 0, GEAR_VISUALS.size() - 1)
	var defaults: Dictionary = GEAR_VISUALS[gear_id]
	gear_profile = defaults.duplicate(true)
	for key: String in ["rod_length", "rod_radius", "rod_color", "reel_color", "grip_color"]:
		if gear.has(key): gear_profile[key] = gear[key]
	gear_profile["id"] = gear_id
	_rod_visual_reach = clampf(float(gear.get("reach", 1.0)), 0.05, 1.0)
	gear_profile["reach"] = _rod_visual_reach
	_rod_length = clampf(float(gear_profile.rod_length), 1.60, 2.85)
	_rod_radius = clampf(float(gear_profile.rod_radius), 0.009, 0.020)
	_rod_tip_radius = _rod_radius * (0.004 / 0.013)
	_rod_flex_scale = float(defaults.flex_scale)
	gear_profile.rod_length = _rod_length
	gear_profile.rod_radius = _rod_radius
	if _rod_mesh == null: return
	(_rod_mesh.material_override as StandardMaterial3D).albedo_color = Color.from_string(str(gear_profile.rod_color), Color(str(defaults.rod_color)))
	(_rod_grip.material_override as StandardMaterial3D).albedo_color = Color.from_string(str(gear_profile.grip_color), Color(str(defaults.grip_color)))
	var reel_color: Color = Color.from_string(str(gear_profile.reel_color), Color(str(defaults.reel_color)))
	(_rod_reel.material_override as StandardMaterial3D).albedo_color = reel_color
	for index: int in _rod_accents.size():
		var accent: MeshInstance3D = _rod_accents[index]
		accent.visible = gear_id != 0 or index < 2
		(accent.material_override as StandardMaterial3D).albedo_color = reel_color
	_update_rod()
	if _line != null and _bobber != null and _line.visible and _bobber.visible: _update_line()

func set_mode(value: String) -> void:
	mode = value
	if not _built: return
	if value == "lobby":
		if not _location_built_key.is_empty() and _asset_error_label:
			_asset_error_label.visible = false
			asset_error = ""
		cancel_landing()
		presentation_state = "lobby"
		cast_in_progress = false
		_bobber.visible = false
		_float_meniscus.visible = false
		_float_wake.visible = false
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
	if _rain:
		_rain.visible = value in ["rain", "storm"]
		_rain.emitting = _rain.visible
	set_time_of_day(time_of_day)

func set_time_of_day(value: String) -> void:
	time_of_day = value
	if not _built: return
	var lighting_key: String = value + ":" + weather + ":" + region_id
	if lighting_key == _last_lighting_key: return
	var immediate: bool = _last_lighting_key.is_empty()
	_last_lighting_key = lighting_key
	var night: bool = value in ["night", "夜晚"]
	var dusk: bool = value in ["dusk", "evening", "黄昏"]
	var dawn: bool = value in ["dawn", "morning", "清晨", "早晨"]
	var overcast: bool = weather in ["rain", "storm", "cloudy"]
	var atmosphere: Dictionary = BIOME_ATMOSPHERE[region_id]
	var horizon: Color = Color(str(atmosphere.horizon))
	var fog: Color = Color(str(atmosphere.fog))
	var tint: Color = Color(str(atmosphere.sky))
	var sunlight: Color = Color("fff0d7")
	var sunlight_energy: float = 1.02
	var elevation: float = -54.0
	var sky_energy: float = 0.92
	var exposure: float = 0.96
	var ambient: Color = Color("b8d2d8")
	var ambient_energy: float = 0.38
	var fog_density: float = float(BIOME_VISUALS[region_id].fog) * 1.30
	if dawn or dusk:
		horizon = Color("e6c1a0") if dawn else Color("e8b78d")
		fog = Color("c0bdad") if dawn else Color("bba399")
		tint = tint.lerp(Color("ffd5b5"), 0.30 if dawn else 0.46)
		sunlight = Color("ffd7aa") if dawn else Color("ffbd82")
		sunlight_energy = 0.88 if dawn else 0.91
		elevation = -23.0 if dawn else -19.0
		sky_energy = 0.82 if dawn else 0.76
		ambient = Color("a5bfd2")
		ambient_energy = 0.34
		fog_density *= 1.5 if dawn else 1.25
	elif night:
		horizon = Color("3e596a")
		fog = Color("3e5968")
		sunlight = Color("b2cced")
		sunlight_energy = 0.32
		elevation = -38.0
		ambient = Color("6485a3")
		ambient_energy = 0.26
		exposure = 0.90
	if overcast:
		horizon = horizon.lerp(Color("9aafb8"), 0.60)
		fog = fog.lerp(Color("91a7ac"), 0.65)
		tint = tint.lerp(Color("ccd8de"), 0.62)
		sunlight_energy *= 0.56
		sky_energy *= 0.73
		fog_density = maxf(fog_density, 0.0042)
		ambient_energy *= 1.13
	_sky.sky_top_color = Color("172b48") if night else Color("477c9f")
	_sky.sky_horizon_color = horizon
	_sky.ground_bottom_color = Color("182c31") if night else Color("273b36")
	_sky.ground_horizon_color = horizon
	if _lighting_tween and _lighting_tween.is_valid(): _lighting_tween.kill()
	_lighting_paused = false
	_lighting_tween = create_tween().set_parallel(true)
	var duration: float = 0.0 if immediate else 1.4
	_lighting_tween.tween_property(_sun, "light_color", sunlight, duration)
	_lighting_tween.tween_property(_sun, "light_energy", sunlight_energy, duration)
	_lighting_tween.tween_property(_sun, "rotation_degrees", Vector3(elevation, -36, 0), duration)
	var environment: Environment = _world.environment
	_lighting_tween.tween_property(environment, "ambient_light_color", ambient, duration)
	_lighting_tween.tween_property(environment, "ambient_light_energy", ambient_energy, duration)
	_lighting_tween.tween_property(environment, "fog_light_color", fog, duration)
	_lighting_tween.tween_property(environment, "fog_density", fog_density, duration)
	_lighting_tween.tween_property(environment, "tonemap_exposure", exposure, duration)
	for index: int in _horizon_materials.size():
		var distance_color: Color = Color(str(BIOME_VISUALS[region_id].leaf)).lerp(fog, 0.36 + float(index) * 0.20)
		if night: distance_color = fog * 0.52
		distance_color.a = 1.0
		_lighting_tween.tween_property(_horizon_materials[index], "albedo_color", distance_color, duration)
	if _portrait_fill:
		_lighting_tween.tween_property(_portrait_fill, "light_color", Color("c0d9ee") if night else Color("e9ede6"), duration)
		_lighting_tween.tween_property(_portrait_fill, "light_energy", 0.32 if night else 0.43, duration)
	if _panorama:
		environment.sky.sky_material = _sky if night else _panorama
		_tween_sky_parameter("energy", sky_energy, duration)
		_tween_sky_parameter("horizon_color", horizon, duration)
		_tween_sky_parameter("sky_tint", tint, duration)
		_tween_sky_parameter("cloud_saturation", 0.45 if overcast else 0.92, duration)
		_tween_sky_parameter("horizon_warmth", 0.80 if dusk else (0.45 if dawn else 0.0), duration)
	_lighting_tween.chain().tween_callback(_refresh_reflection)
	if _suspended:
		_lighting_tween.pause()
		_lighting_paused = true

func _tween_sky_parameter(parameter: String, target: Variant, duration: float) -> void:
	var initial: Variant = _panorama.get_shader_parameter(parameter)
	if initial == null or duration <= 0.0:
		_panorama.set_shader_parameter(parameter, target)
		return
	_lighting_tween.tween_method(func(value: Variant) -> void: _panorama.set_shader_parameter(parameter, value), initial, target, duration)

func _refresh_reflection() -> void:
	if _reflection_probe:
		# Refresh only after lighting settles; never render six cubemap faces per frame.
		_reflection_probe.position.x = 0.002 if _reflection_probe.position.x < 0.001 else 0.0

func set_visual_quality(value: String) -> void:
	visual_quality = value if value in ["low", "balanced", "high"] else "balanced"
	if not _built: return
	var economical: bool = visual_quality == "low"
	var detailed: bool = visual_quality == "high"
	# Keep native resolution and at least 2x MSAA: a float tip is a gameplay signal.
	get_viewport().msaa_3d = Viewport.MSAA_2X if economical else Viewport.MSAA_4X
	_water_material.set_shader_parameter("surface_detail", 0.0 if economical else 1.0)
	_sun.directional_shadow_max_distance = 38.0 if economical else (90.0 if region_id == "norway" else 65.0)
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if economical else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_world.environment.glow_enabled = detailed
	_world.environment.glow_intensity = 0.16
	_world.environment.glow_bloom = 0.0
	_world.environment.glow_hdr_threshold = 1.35
	if _rain: _rain.amount_ratio = 0.45 if economical else (1.0 if detailed else 0.72)

func set_reduce_motion(value: bool) -> void:
	reduce_motion = value

func suspend(value: bool) -> void:
	if _suspended == value: return
	_suspended = value
	if _lighting_tween and _lighting_tween.is_valid():
		if value and _lighting_tween.is_running():
			_lighting_tween.pause()
			_lighting_paused = true
		elif not value and _lighting_paused:
			_lighting_tween.play()
			_lighting_paused = false
	if _rain: _rain.speed_scale = 0.0 if value else 1.0
	if _animator:
		if value:
			_character_was_playing = _animator.is_playing()
			_animator.pause()
		elif _character_was_playing and not _animator.assigned_animation.is_empty():
			_animator.play()
	if _fish_animator:
		if value:
			_fish_was_playing = _fish_animator.is_playing()
			_fish_animator.pause()
		elif _fish_was_playing and not _fish_animator.assigned_animation.is_empty():
			_fish_animator.play()

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
	_fish_root.visible = _fish != null
	if _fish_animator: _fish_animator.speed_scale = 1.0
	_fish_root.position = Vector3(-0.15, -0.28, -3.15)
	_play_character("lift", false)
	_play_fish("breach")
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
			_float_meniscus.visible = false
			_float_wake.visible = false
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
			# No reveal, camera cut, animation change or splash announces a hook.
			# Only continuous fish/bait/rig-dependent float motion gives evidence.
			presentation_state = "bite" if value == Session.State.BITE else "nibble"
			_fish_root.visible = false
		Session.State.FIGHT:
			presentation_state = "fight"
			if session: _ensure_fish(session.individual)
			_fish_root.visible = _fish != null
			_play_character("reel")
			_play_fish("struggle")
		Session.State.ESCAPED:
			presentation_state = "escaped"
			_bobber.visible = false
			_float_meniscus.visible = false
			_float_wake.visible = false
			_line.visible = false
			_fish_root.visible = false
			_play_character("idle")

func cast_target_for_charge(charge: float, heading: float = 0.0) -> Vector3:
	var power: float=clampf(charge,0.0,_rod_visual_reach)
	var requested:=Vector3(-0.72+power*0.5,0,-7.0-power*5.0).rotated(Vector3.UP,heading)
	return _water_domain.resolve_cast(requested)

func _begin_cast() -> void:
	cancel_landing()
	_landed_catch_id = ""
	cast_in_progress = true
	_cast_time = 0.0
	_cast_finished_emitted = false
	_cast_impact_emitted = false
	presentation_state = "casting"
	# A player can recast immediately after a failed take or a close landing.
	# Establish the authored windup view at this explicit cast action so a short
	# charge cannot preserve the previous water/landing camera and hide the angler.
	camera.position = FISHING_CAMERA_POSITION
	_camera_target = FISHING_CAMERA_TARGET
	_camera_base_vertical_fov = FISHING_CAMERA_FOV
	camera.fov = _reference_horizontal_fov(FISHING_CAMERA_FOV)
	camera.look_at(_camera_target)
	_cast_camera_origin = camera.position
	_cast_camera_target_origin = _camera_target
	_cast_camera_fov_origin = _camera_base_vertical_fov
	_bobber.scale = Vector3.ONE
	_bobber.rotation = Vector3.ZERO
	_float_surface_tracking = false
	# Old fight impulses use the presentation clock. A new observation clock
	# must never replay them later as false surface activity around this float.
	_water_material.set_shader_parameter("impact_a", Vector4(0, 0, -100, 0))
	_water_material.set_shader_parameter("impact_b", Vector4(0, 0, -100, 0))
	var charge: float = clampf(session.charge, 0.0, _rod_visual_reach) if session else 0.5
	_bobber_target = cast_target_for_charge(charge)
	if not _bobber_target.is_finite():
		cast_in_progress=false
		_report_location_error("This location has no unobstructed casting water")
		return
	_bobber.visible = false
	_float_meniscus.visible = false
	_float_wake.visible = false
	_line.visible = false
	_fish_root.visible = false
	_play_character("cast", false)

func _process(delta: float) -> void:
	if not _built or _suspended: return
	# Presentation and AnimationPlayer share real elapsed time, including slow frames.
	# The core Session preserves elapsed time with independent fixed steps.
	_time += delta
	# The same authoritative clock moves water and the observed float. Rendering
	# cannot add oscillations that suggest a bite while the session is still.
	var observing: bool = session != null and _state in [Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE] and not cast_in_progress
	_water_material.set_shader_parameter("motion_time", session.float_clock if observing else _time)
	_float_meniscus.visible = false
	_float_wake.visible = false
	if not observing: _set_float_water_material(false, 0.0)
	for material: ShaderMaterial in _foliage_materials: material.set_shader_parameter("motion_time", _time)
	_update_effects(delta)
	if _rain and _rain.visible: _rain.position = camera.position + Vector3(0, 5.0, -3.0)
	if _angler:
		var facing: float = PI - 0.25 if mode == "lobby" else 0.0
		_angler.rotation.y = lerp_angle(_angler.rotation.y, facing, 1.0 - exp(-delta * 4.0))
	_update_character_motion(delta)
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
		var contact: Vector3=_bobber_target
		contact.y=_water_surface_height(Vector2(contact.x,contact.z),_time)
		_bobber.position = _cast_origin.lerp(contact, p) + Vector3.UP * sin(p * PI) * 2.6
		if p>=1.0: _set_float_water_material(true,contact.y)
		_bobber.rotation.z = sin(p * PI) * -0.55
		if p >= 1.0 and not _cast_impact_emitted:
			# The narrow float makes a small surface ring, not fish-sized spray.
			# This remains separate from the unchanged breach/surge splashes.
			_cast_impact_emitted = true
			_spawn_ripple(_bobber_target, 0.10, 1.0, 0.28)
			cast_water_contact.emit()
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
		_fish_root.visible = false
		# A weighted antenna float: calm water leaves a vertical calibrated tip;
		# unloaded shot exposes lower bands; a sustained pull takes the tip under.
		# Both fish travel and ambient current come from the encounter model.
		var dip: float = session.float_dip if session else 0.0
		var lift: float = session.float_lift if session else 0.0
		var drag: Vector2 = session.float_drag if session else Vector2.ZERO
		var current: Vector2 = session.float_current if session else Vector2.ZERO
		var tilt: float = session.float_tilt if session else 0.0
		var clock: float = session.float_clock if session else 0.0
		var horizontal: Vector2 = Vector2(_bobber_target.x, _bobber_target.z) + current + drag
		var water_height: float = _water_surface_height(horizontal, clock)
		_bobber.position = Vector3(horizontal.x, water_height + lift * FLOAT_LIFT_TRAVEL - dip * FLOAT_DIP_TRAVEL, horizontal.y)
		var direction: Vector2 = drag.normalized() if drag.length_squared() > 0.00001 else Vector2.ZERO
		_bobber.rotation = Vector3(direction.y * absf(tilt), 0, -direction.x * absf(tilt)) if direction != Vector2.ZERO else Vector3(0, 0, tilt)
		_set_float_water_material(true, water_height)
		_update_float_surface(_delta, water_height)
	elif _state == Session.State.FIGHT and session:
		var p: float = clampf(session.progress, 0.0, 1.0)
		var warning: float = session.surge_warning
		var surge: float = session.surge_strength if session.fight_phase == "surge" else 0.0
		var stamina: float = session.fish_stamina
		var behavior: String = str(session.individual.get("behavior", ""))
		var sweep: float = 0.72 if behavior in ["burst", "runner"] else 0.42
		# Windup loads the rod and turns the fish before the scheduled surge.
		# The phase is supplied by the encounter, never a repeating visual timer.
		var swing: float = sin(session.fight_time * 1.07) * (0.22 + stamina * sweep)
		swing += sin(session.phase_progress * PI) * (warning * 0.28 + surge * 0.86)
		var target: Vector3 = _bobber_target.lerp(Vector3(-0.1, 0.035, -2.7), p)
		_bobber.position = target + Vector3(swing, -0.05, -warning * 0.18 - surge * 0.42)
		var surface_height: float=_water_surface_height(Vector2(_bobber.position.x,_bobber.position.z),_time)
		_bobber.position.y+=surface_height
		_set_float_water_material(true,surface_height)
		_bobber.rotation.z = swing * 0.40 + warning * 0.28
		_fish_root.position = _bobber.position + Vector3(0, -0.24 - warning * 0.07, 0.1)
		_fish_root.rotation = Vector3(sin(_time * 3.0) * 0.04, PI * 0.5 + swing * 0.46 + warning * 0.55, -warning * 0.18)
		if _fish_animator: _fish_animator.speed_scale = lerpf(0.55, 1.25, stamina) + surge * 0.7
		if _time - _last_ripple > 0.75 - surge * 0.40:
			_spawn_ripple(_bobber.position, 0.26 + surge * 0.45, 1.15)
		# Surface once near the beginning of a real surge, after hooking only.
		if surge > 0.0 and session.phase_progress < 0.42:
			_fish_root.position.y += sin(session.phase_progress / 0.42 * PI) * (0.16 + surge * 0.18)
			if _fish_root.position.y > -0.03 and _time - _last_ripple > 0.25: _splash(_fish_root.position, 0.32)

func _update_landing(delta: float) -> void:
	_landing_time += delta
	var t: float = _landing_time
	if t < 1.40:
		var p: float = t / 1.40
		_fish_root.position = Vector3(-0.2, -0.24, -3.2).lerp(Vector3(-0.05, 0.9, -1.75), p)
		_fish_root.position.y += sin(p * PI) * 0.68
		_fish_root.rotation = Vector3(sin(p * PI) * -0.25, 0.38 + p * 0.8, sin(p * PI) * 0.35)
		if t > 0.08 and t - delta <= 0.08: _splash(Vector3(-0.2, 0, -3.2), 1.3)
	else:
		if t - delta < 1.40: _play_fish("landed")
		var p: float = smoothstep(0.0, 1.0, (t - 1.40) / 1.1)
		_fish_root.position = Vector3(-0.05, 0.9, -1.75).lerp(Vector3(-0.3, 1.28, -0.58), p)
		_fish_root.position.y += sin(_time * 8) * 0.025 * (1.0 - p * 0.7)
		_fish_root.rotation = Vector3(0, lerpf(1.18, -0.20, p), 0.10 + sin(_time * 5) * 0.04)
	if bool(_fish_info.get("asymmetric_flatfish", false)):
		_fish_root.rotation.x += 0.52
	if _fish_length > 2.8:
		# True-sized ocean giants are observed alongside the boat, rather than
		# shrinking to fit a hand-held landing pose or intersecting the angler.
		var reveal: float = smoothstep(0.0,1.0,minf(t / 2.5,1.0))
		_fish_root.position = Vector3(-0.3,lerpf(-0.45,0.08,reveal),-3.3-_fish_length*0.25)
		_fish_root.rotation = Vector3(0,lerpf(0.4,-0.16,reveal),sin(_time*2.0)*0.025)
	_bobber.visible = true
	_line.visible = true
	_bobber.rotation = Vector3.ZERO
	_bobber.scale = Vector3.ONE
	_bobber.position = _fish_mouth_world() + Vector3.UP * 0.215
	if _fish_id == "chinese_sturgeon":
		# Route around the rostrum rather than passing through the head on the
		# way to its ventral mouth. Guide scales with the actual specimen.
		_bobber.position = _sturgeon_leader_guide_world() + Vector3.UP * (0.215 + _fish_length * 0.11)
	if t >= LANDING_DURATION:
		var result: Dictionary = _landing_record.duplicate(true)
		_landing_time = -1.0
		_landing_record.clear()
		presentation_state = "landed"
		_bobber.scale = Vector3.ONE
		landing_finished.emit(result)

func _update_camera(delta: float) -> void:
	var position_goal: Vector3 = Vector3(0.7, 2.5, 4.6)
	var target_goal: Vector3 = Vector3(-1.5, 1.05, -1.7)
	var fov_goal: float = 54.0
	if mode == "fishing":
		position_goal = FISHING_CAMERA_POSITION
		target_goal = FISHING_CAMERA_TARGET
		fov_goal = FISHING_CAMERA_FOV
	var observe_float: bool = presentation_state in ["waiting", "nibble", "bite"]
	if observe_float:
		position_goal = _bobber_target + FLOAT_VIEW_OFFSET
		target_goal = _bobber_target + Vector3(0, 0.018, 0)
		fov_goal = FLOAT_VIEW_FOV
	elif cast_in_progress:
		# Move once while the cast travels, and finish before the float lands.
		# WAIT / exploratory taps / committed bite cannot change this framing.
		var settle: float = smoothstep(RELEASE_TIME, CAST_DURATION - 0.17, _cast_time)
		position_goal = _cast_camera_origin.lerp(_bobber_target + FLOAT_VIEW_OFFSET, settle)
		target_goal = _cast_camera_target_origin.lerp(_bobber_target + Vector3(0, 0.018, 0), settle)
		fov_goal = lerpf(_cast_camera_fov_origin, FLOAT_VIEW_FOV, settle)
	elif presentation_state == "fight" and session:
		var p: float = clampf(session.progress, 0.0, 1.0)
		position_goal = Vector3(-0.48, 2.12, 1.48)
		target_goal = _bobber_target.lerp(Vector3(-0.10, 0.12, -2.7), p)
		fov_goal = 55.0
	elif presentation_state in ["landing", "landed"]:
		var p: float = clampf(_landing_time / 2.5, 0.0, 1.0) if _landing_time >= 0 else 1.0
		position_goal = Vector3(0.15, 2.13, 4.7 + maxf(0.0, _fish_length - 1.1) * 1.45)
		target_goal = Vector3(-0.30, 0.95 + p * 0.25, -0.25)
		fov_goal = 46.0
		if _fish_length > 2.8:
			target_goal = _fish_root.position + Vector3(0,0.15,0)
			position_goal = target_goal + Vector3(0.15,2.35,maxf(7.2,_fish_length*2.72))
		# Small individuals keep exact physical scale. A late optical push-in makes
		# them legible without turning every catch into a physically identical fish.
		var small_factor: float = clampf((0.45 - _fish_length) / 0.40, 0.0, 1.0)
		var landing_age: float = _landing_time if _landing_time >= 0.0 else LANDING_DURATION
		var close_mix: float = small_factor * smoothstep(0.9, 2.2, landing_age)
		if close_mix > 0.0 and _fish_root:
			var close_position: Vector3 = _fish_root.position + Vector3(0.12, 0.11, maxf(0.72, _fish_length * 10.0))
			position_goal = position_goal.lerp(close_position, close_mix)
			target_goal = target_goal.lerp(_fish_root.position, close_mix)
			fov_goal = lerpf(fov_goal, 36.0, close_mix)
	if mode == "lobby" and presentation_state == "lobby" and not reduce_motion:
		# A restrained portrait drift only in the lobby; observing a float stays locked.
		position_goal += Vector3(sin(_time * 0.12) * 0.07, sin(_time * 0.16) * 0.025, 0)
	var blend: float = 1.0 if observe_float or cast_in_progress else 1.0 - exp(-delta * (2.3 if presentation_state == "landing" else 1.5))
	camera.position = camera.position.lerp(position_goal, blend)
	_camera_target = _camera_target.lerp(target_goal, blend)
	# Blend the authored16:9 vertical angle exactly as before, then express it
	# as horizontal coverage. KEEP_WIDTH preserves this view on taller screens
	# and reveals extra vertical space instead of cropping large fish sideways.
	_camera_base_vertical_fov = lerpf(_camera_base_vertical_fov, fov_goal, blend)
	camera.fov = _reference_horizontal_fov(_camera_base_vertical_fov)
	camera.look_at(_camera_target)
	if _asset_error_label and _asset_error_label.visible:
		_asset_error_label.position = camera.position - camera.basis.z * 3.2

static func _reference_horizontal_fov(vertical_degrees: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(vertical_degrees) * 0.5) * REFERENCE_CAMERA_ASPECT))

func _build_world() -> void:
	_world = WorldEnvironment.new()
	_world.name = "RiverAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_curve = 0.85
	_sky.ground_curve = 0.35
	_sky.sun_angle_max = 8.0
	_sky.sun_curve = 0.09
	sky.sky_material = _sky
	var panorama_path: String = "res://assets/3d/environment/cc0/cloud_layers_2k.hdr"
	if ResourceLoader.exists(panorama_path):
		_panorama = ShaderMaterial.new()
		_panorama.shader = HDR_SKY_SHADER
		_panorama.set_shader_parameter("panorama", load(panorama_path) as Texture2D)
		sky.sky_material = _panorama
		# HDR sun is near panorama u=.90; 180-degree rotation aligns it with
		# the key at azimuth -36deg / elevation58deg, in front of lobby face.
		env.sky_rotation = Vector3(0, PI, 0)
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.72
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.96
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.07
	env.adjustment_contrast = 1.04
	env.fog_enabled = true
	env.fog_sky_affect = 0.18
	env.fog_height = 0.0
	env.fog_height_density = 0.0
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
	var bounce := OmniLight3D.new()
	_portrait_fill = bounce
	bounce.name = "AnglerPortraitFill"
	bounce.position = Vector3(0.0, 2.5, 3.2)
	bounce.light_color = Color("dce9e8")
	bounce.light_energy = 0.43
	bounce.omni_range = 5.5
	bounce.omni_attenuation = 1.0
	bounce.light_cull_mask = 4
	bounce.shadow_enabled = false
	add_child(bounce)
	if _initial_location_error.is_empty(): _replace_location_geometry()
	_build_water()
	var probe := ReflectionProbe.new()
	_reflection_probe = probe
	probe.name = "RiverbankReflection"
	probe.position = Vector3(0, 2.0, -18)
	probe.size = Vector3(92, 35, 138)
	probe.origin_offset = Vector3(0, 0, 0)
	probe.cull_mask = 1
	probe.intensity = 0.78
	probe.max_distance = 120.0
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.box_projection = true
	add_child(probe)
	camera = Camera3D.new()
	camera.name = "FishingCamera"
	camera.position = Vector3(0.7, 2.5, 4.6)
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = _reference_horizontal_fov(_camera_base_vertical_fov)
	camera.near = 0.08
	camera.far = 330.0
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
	_asset_error_label = Label3D.new()
	_asset_error_label.name = "MissingModelNotice"
	_asset_error_label.position = Vector3(-0.2, 1.7, -2.6)
	_asset_error_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_asset_error_label.font_size = 36
	_asset_error_label.pixel_size = 0.007
	_asset_error_label.modulate = Color("ffbc70")
	_asset_error_label.outline_size = 5
	_asset_error_label.visible = false
	add_child(_asset_error_label)
	_build_effects()
	_build_weather()
	_fishery_label = Label3D.new()
	_fishery_label.text = ""
	_fishery_label.font = load("res://assets/fonts/NotoSansCJK-Regular.ttc") as Font
	_fishery_label.font_size = 48
	_fishery_label.pixel_size = 0.0017
	_fishery_label.position = Vector3(3.55, 1.56, 5.652)
	_fishery_label.rotation.y = PI
	_fishery_label.modulate = Color("e4dfb2")
	_fishery_label.outline_size = 0
	add_child(_fishery_label)
	_configure_location_surfaces()
	if _location_built_key.is_empty(): _report_location_error(_initial_location_error if not _initial_location_error.is_empty() else "3D location assets are not ready: " + region_id + ":" + spot_id)

func _apply_foliage(node: Node) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("Foliage"):
		var mesh_node := node as MeshInstance3D
		var biome: Dictionary = BIOME_VISUALS[region_id]
		var color := Color(str(biome.leaf))
		if str(node.name).contains("Deep"): color = Color("203f32")
		elif str(node.name).contains("Green"): color = Color(str(biome.leaf))
		elif str(node.name).contains("Gold"): color = Color(str(biome.gold))
		var shader := ShaderMaterial.new()
		shader.shader = FOLIAGE_SHADER
		shader.set_shader_parameter("leaf_color", color)
		shader.set_shader_parameter("clear_rock_station", _station_kind(str(_spot_definition.get("foreground", "pier"))) == "rock")
		mesh_node.material_override = shader
		_foliage_materials.append(shader)
	elif node is MeshInstance3D and str(node.name) in ["Reed", "Cattail"]:
		var plant := ShaderMaterial.new()
		plant.shader = REED_SHADER
		var original := (node as MeshInstance3D).get_active_material(0) as StandardMaterial3D
		if original: plant.set_shader_parameter("reed_color", original.albedo_color)
		plant.set_shader_parameter("clear_rock_station", _station_kind(str(_spot_definition.get("foreground", "pier"))) == "rock")
		(node as MeshInstance3D).material_override = plant
		_foliage_materials.append(plant)
	elif node is MeshInstance3D and str(node.name) == "NavyHull":
		var hull := _material(Color("193e51"), 0.34, 0.16)
		hull.cull_mode = BaseMaterial3D.CULL_DISABLED
		(node as MeshInstance3D).material_override = hull
	elif node is MeshInstance3D and str(node.name) in ["Cliff", "Stone", "StoneWarm", "WarmStone", "Roof"]:
		var stone := ShaderMaterial.new()
		stone.shader = ROCK_SHADER
		stone.set_shader_parameter("rock_tint", Color("52656c") if str(node.name) == "Roof" else Color(str(BIOME_VISUALS[region_id].rock)))
		stone.set_shader_parameter("meters_per_tile", 0.9 if str(node.name) == "Roof" else (2.1 if str(node.name) == "Cliff" else 2.7))
		var rock_base: String = "res://assets/3d/environment/cc0/rock_face_03_"
		stone.set_shader_parameter("rock_albedo", load(rock_base + "diff_2k.png"))
		stone.set_shader_parameter("rock_normal", load(rock_base + "nor_gl_2k.png"))
		stone.set_shader_parameter("rock_roughness", load(rock_base + "rough_2k.png"))
		(node as MeshInstance3D).material_override = stone
	elif node is MeshInstance3D and str(node.name) in ["DockHoney", "DockPale", "DockWeathered", "WoodEndgrain", "Bark", "BarkLight", "Grass", "Mud", "Soil", "Sand", "HarborRed"]:
		var mesh_node := node as MeshInstance3D
		var is_ground: bool = str(node.name) in ["Grass", "Mud", "Soil", "Sand"]
		var colors: Dictionary = {"DockHoney": Color("786044"), "DockPale": Color("977b52"), "DockWeathered": Color("685541"), "WoodEndgrain": Color("493d2c"), "Bark": Color("544b34"), "BarkLight": Color("695a3c"), "Grass": Color(str(BIOME_VISUALS[region_id].ground)), "Mud": Color("414e3b"), "Soil": Color("716146"), "Sand": Color("9b8b61"), "HarborRed": Color("aa4030")}
		var shader := ShaderMaterial.new()
		shader.shader = GROUND_SHADER if is_ground else WOOD_SHADER
		shader.set_shader_parameter("ground_color" if is_ground else "wood_color", colors[str(node.name)])
		if str(node.name) in ["DockHoney", "DockPale", "DockWeathered", "WoodEndgrain", "HarborRed"]:
			var pbr_base: String = "res://assets/3d/environment/cc0/brown_planks_03_"
			if ResourceLoader.exists(pbr_base + "diff_2k.png"):
				shader.set_shader_parameter("use_pbr", true)
				if str(node.name) == "HarborRed":
					shader.set_shader_parameter("vertical_timber", true)
					shader.set_shader_parameter("paint_strength", 0.85)
				shader.set_shader_parameter("timber_albedo", load(pbr_base + "diff_2k.png"))
				shader.set_shader_parameter("timber_normal", load(pbr_base + "nor_gl_2k.png"))
				shader.set_shader_parameter("timber_roughness", load(pbr_base + "rough_2k.png"))
		mesh_node.material_override = shader
	for child: Node in node.get_children(): _apply_foliage(child)

func _build_water() -> void:
	# Transparent water sees a modeled bed rather than the HDR panorama's ground.
	var bed := MeshInstance3D.new()
	_riverbed = bed
	bed.name = "SubmergedRiverbed"
	var bed_mesh := PlaneMesh.new()
	bed_mesh.size = Vector2(155, 180)
	bed.mesh = bed_mesh
	bed.position = Vector3(0, -2.8, -58)
	var bed_material := ShaderMaterial.new()
	bed_material.shader = GROUND_SHADER
	bed_material.set_shader_parameter("ground_color", Color("233a32"))
	bed.material_override = bed_material
	bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bed)
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
	surface.extra_cull_margin = 0.5
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_SHADER
	var noise := FastNoiseLite.new()
	noise.seed = 81207
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var normal_texture := NoiseTexture2D.new()
	normal_texture.width = 512
	normal_texture.height = 512
	normal_texture.seamless = true
	normal_texture.as_normal_map = true
	normal_texture.bump_strength = 2.6
	normal_texture.noise = noise
	_water_material.set_shader_parameter("normal_texture", normal_texture)
	surface.material_override = _water_material
	add_child(surface)
	# Low-cost distant ocean ring preserves the finely subdivided near water
	# and float motion while extending the horizon beyond the coastal patch.
	_ocean_horizon_water = MeshInstance3D.new()
	_ocean_horizon_water.name = "OpenOceanHorizonWater"
	var ring_arrays: Array = []
	ring_arrays.resize(Mesh.ARRAY_MAX)
	var ring_vertices := PackedVector3Array()
	var ring_normals := PackedVector3Array()
	var ring_uvs := PackedVector2Array()
	var ring_indices := PackedInt32Array()
	var inner: Array[Vector3] = [Vector3(-77.5,0,-148),Vector3(77.5,0,-148),Vector3(77.5,0,32),Vector3(-77.5,0,32)]
	var outer: Array[Vector3] = [Vector3(-4000,0,-4000),Vector3(4000,0,-4000),Vector3(4000,0,4000),Vector3(-4000,0,4000)]
	for corner: int in range(4):
		ring_vertices.append(inner[corner]); ring_vertices.append(outer[corner])
		ring_normals.append(Vector3.UP); ring_normals.append(Vector3.UP)
		ring_uvs.append(Vector2.ZERO); ring_uvs.append(Vector2.ONE)
		var following: int = ((corner+1)%4)*2
		ring_indices.append_array(PackedInt32Array([corner*2,following,corner*2+1,following,following+1,corner*2+1]))
	ring_arrays[Mesh.ARRAY_VERTEX] = ring_vertices
	ring_arrays[Mesh.ARRAY_NORMAL] = ring_normals
	ring_arrays[Mesh.ARRAY_TEX_UV] = ring_uvs
	ring_arrays[Mesh.ARRAY_INDEX] = ring_indices
	var ring_mesh := ArrayMesh.new()
	ring_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,ring_arrays)
	_ocean_horizon_water.mesh = ring_mesh
	_ocean_horizon_water.material_override = _water_material
	_ocean_horizon_water.layers = 2
	_ocean_horizon_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ocean_horizon_water.visible = (region_id.ends_with("_ocean") or region_id == "red_sea")
	add_child(_ocean_horizon_water)

func _load_character() -> void:
	if ResourceLoader.exists("res://assets/3d/angler.glb"):
		var packed := load("res://assets/3d/angler.glb") as PackedScene
		_angler = packed.instantiate() as Node3D
		_angler.name = "RiggedAngler"
		_angler.position = ANGLER_POS
		add_child(_angler)
		_mark_character_light_layer(_angler)
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

func _mark_character_light_layer(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		mesh_node.layers |= 4
		for surface: int in range(mesh_node.mesh.get_surface_count()):
			var original := mesh_node.get_active_material(surface) as StandardMaterial3D
			if original == null: continue
			var material := original.duplicate() as StandardMaterial3D
			var title: String = material.resource_name.to_lower()
			# Keep the authored albedo, normal maps, depth modes and skin weights.
			material.metallic = 0.0
			if "body" in title:
				material.roughness = 0.58
				material.metallic_specular = 0.30
			elif "low-poly" in title:
				material.roughness = 0.24
				material.metallic_specular = 0.48
			elif "casualsuit" in title:
				material.roughness = 0.86
				material.metallic_specular = 0.22
				material.normal_scale = 0.72
			elif "short02" in title or "eyebrow" in title:
				material.roughness = 0.79
				material.metallic_specular = 0.24
			elif "shoes" in title:
				material.roughness = 0.69
				material.metallic_specular = 0.30
			mesh_node.set_surface_override_material(surface, material)
	for child: Node in node.get_children(): _mark_character_light_layer(child)

func _update_character_motion(delta: float) -> void:
	if _animator:
		var speed: float = 1.0
		if presentation_state == "fight" and session:
			# Releasing the control eases the retrieve rather than turning an idle reel.
			speed = 0.98 + session.tension * 0.16 if session.reeling else 0.22
		elif presentation_state in ["lobby", "ready"]:
			speed = 0.82
		# Authored cast timing is exact; never retime its release frame.
		_animator.speed_scale = 1.0 if cast_in_progress else lerpf(_animator.speed_scale, speed, 1.0 - exp(-delta * 8.0))
	if _reel_handle:
		var target: float = 7.8 if presentation_state == "fight" and session and session.reeling else 0.0
		_reel_handle_speed = lerpf(_reel_handle_speed, target, 1.0 - exp(-delta * 9.0))
		_reel_handle.rotation.y += _reel_handle_speed * delta

func _build_rod() -> void:
	_rod = Node3D.new()
	_rod.name = "GraphiteFishingRod"
	_rod_socket.add_child(_rod)
	_rod_mesh = MeshInstance3D.new()
	_rod_mesh.name = "TaperedFlexibleBlank"
	_rod_mesh.material_override = _material(Color("273b36"), 0.3, 0.2)
	_rod.add_child(_rod_mesh)
	var grip := MeshInstance3D.new()
	_rod_grip = grip
	grip.name = "FixedRearHandGrip"
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
	_rod_reel = reel
	reel.name = "FixedReelSeat"
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
	_build_reel_details(reel)
	for i in range(4):
		var band := MeshInstance3D.new()
		band.name = "BlankBinding_%d" % i
		var wrap := CylinderMesh.new()
		wrap.top_radius = 1.0
		wrap.bottom_radius = 1.0
		wrap.height = 1.0
		wrap.radial_segments = 8
		band.mesh = wrap
		band.material_override = _material(Color("aeb5a0"), 0.34, 0.55)
		_rod.add_child(band)
		_rod_accents.append(band)
	set_gear_profile(gear_profile)

func _build_reel_details(reel: MeshInstance3D) -> void:
	var dark_metal: StandardMaterial3D = _material(Color("3d4f54"), 0.30, 0.78)
	var pale_metal: StandardMaterial3D = _material(Color("d6d4ba"), 0.27, 0.72)
	for side: float in [-1.0, 1.0]:
		var rim := MeshInstance3D.new()
		rim.name = "SpoolFlange"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.053
		ring.outer_radius = 0.068
		ring.rings = 20
		ring.ring_segments = 6
		rim.mesh = ring
		rim.position.y = side * 0.029
		rim.material_override = pale_metal
		reel.add_child(rim)
	for index: int in range(5):
		var winding := MeshInstance3D.new()
		winding.name = "LineWinding_%d" % index
		var ring := TorusMesh.new()
		ring.inner_radius = 0.063
		ring.outer_radius = 0.065
		ring.rings = 20
		ring.ring_segments = 4
		winding.mesh = ring
		winding.position.y = -0.019 + float(index) * 0.0095
		winding.material_override = _material(Color("d7d6bd"), 0.74)
		reel.add_child(winding)
	_reel_handle = Node3D.new()
	_reel_handle.name = "WorkingReelHandle"
	_reel_handle.position.y = -0.042
	reel.add_child(_reel_handle)
	var arm := MeshInstance3D.new()
	arm.name = "HandleCrank"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.078, 0.009, 0.011)
	arm.mesh = arm_mesh
	arm.position.x = 0.036
	arm.material_override = dark_metal
	_reel_handle.add_child(arm)
	var knob := MeshInstance3D.new()
	knob.name = "HandleCorkKnob"
	var knob_mesh := CapsuleMesh.new()
	knob_mesh.radius = 0.011
	knob_mesh.height = 0.038
	knob_mesh.radial_segments = 8
	knob_mesh.rings = 3
	knob.mesh = knob_mesh
	knob.position = Vector3(0.071, -0.017, 0)
	knob.material_override = _material(Color("74634a"), 0.84)
	_reel_handle.add_child(knob)

func _update_rod() -> void:
	var flex: float = 0.025
	var warning: float = session.surge_warning if presentation_state == "fight" and session else 0.0
	var danger: float = _line_danger()
	var lateral_flex: float = sin(_time * 31.0) * danger * 0.038
	if presentation_state == "fight" and session: flex = 0.14 + session.tension * 0.50 + warning * 0.22
	elif cast_in_progress: flex = sin(clampf(_cast_time / CAST_DURATION, 0, 1) * PI) * 0.23
	elif presentation_state == "landing": flex = 0.30
	flex *= _rod_flex_scale
	# Bone transforms can move twice in one frame; the blank's local shape need not
	# be rebuilt twice. Always refresh its exact world endpoint before this cache.
	_rod_tip = _rod.to_global(Vector3(lateral_flex, -flex, -_rod_length))
	var shape_key := Vector4(flex, lateral_flex, _rod_length, _rod_radius)
	if shape_key == _rod_shape_key and _rod_mesh.mesh != null: return
	_rod_shape_key = shape_key
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(19):
		var u: float = float(i) / 18.0
		points.append(Vector3(lateral_flex * pow(u, 3.0), -flex * pow(u, 2.4), -u * _rod_length))
		radii.append(lerpf(_rod_radius, _rod_tip_radius, u))
	_rod_mesh.mesh = _tube_mesh(points, radii, 6)
	_rod_tip = _rod.to_global(points[18])
	for index: int in _rod_accents.size():
		var u: float = [0.055, 0.19, 0.47, 0.74][index]
		var band: MeshInstance3D = _rod_accents[index]
		var radius: float = lerpf(_rod_radius, _rod_tip_radius, u) * 1.12
		band.position = Vector3(lateral_flex * pow(u, 3.0), -flex * pow(u, 2.4), -u * _rod_length)
		var tangent: Vector3 = Vector3(lateral_flex * 3.0 * pow(u, 2.0), -flex * 2.4 * pow(u, 1.4), -_rod_length).normalized()
		var frame := Basis(Quaternion(Vector3.UP, tangent))
		frame.x *= radius
		frame.y *= 0.048 if index < 2 else 0.028
		frame.z *= radius
		band.basis = frame

func _build_line() -> void:
	_line = MeshInstance3D.new()
	_line.name = "PhysicalCurvedFishingLine"
	_line_material = _material(Color(0.57, 0.66, 0.62, 0.80), 0.7)
	_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = _line_material
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line.visible = false
	add_child(_line)

func _fish_mouth_world() -> Vector3:
	# The 1 m normalized model has its mouth near +X. Scale the attachment
	# offset with the actual specimen, rather than leaving a 3 cm gap on fry.
	var normalized: Vector3 = FISH_MOUTH_OFFSETS.get(_fish_id, Vector3(0.49, 0.008, 0.0))
	var supplied: Variant = _fish_info.get("mouth_offset_normalized",null)
	if supplied is Array and supplied.size() == 3:
		normalized = Vector3(float(supplied[0]),float(supplied[1]),float(supplied[2]))
	return _fish_root.position + _fish_root.basis * (normalized * _fish_length)

func _sturgeon_leader_guide_world() -> Vector3:
	return _fish_root.position + _fish_root.basis * (Vector3(0.53, -0.050, 0.0) * _fish_length)

func _line_danger() -> float:
	if presentation_state != "fight" or session == null: return 0.0
	return maxf(smoothstep(0.70, 0.98, session.tension), smoothstep(0.48, 0.90, session.line_wear))

func _update_line() -> void:
	var end: Vector3 = _bobber.to_global(FLOAT_LINE_EYE)
	var sag: float = 0.11 if presentation_state in ["fight", "landing", "landed"] else 0.35
	var danger: float = _line_danger()
	if presentation_state in ["waiting", "nibble", "bite"] and session:
		# Directional travel tightens the same physical line continuously.
		sag = lerpf(0.35, 0.07, clampf(session.float_drag.length() / 0.40, 0.0, 1.0))
	if presentation_state == "fight" and session:
		sag = lerpf(0.20, 0.018, clampf(session.tension + session.surge_warning * 0.18, 0, 1))
	_line_material.albedo_color = Color(0.57, 0.66, 0.62, 0.80).lerp(Color(0.86, 0.82, 0.66, 0.92), danger * 0.65)
	if cast_in_progress: sag = 0.30 + sin(_cast_time * 3.5) * 0.12
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in range(33):
		var p: float = float(i) / 32.0
		var tremor := Vector3(sin(_time * 39.0 + p * 24.0), 0.0, cos(_time * 33.0 + p * 19.0)) * sin(p * PI) * danger * 0.014
		points.append(_rod_tip.lerp(end, p) + Vector3.DOWN * sin(p * PI) * sag + tremor)
		radii.append(0.0025 if camera.position.distance_to(end) > 8 else (0.00045 if camera.position.distance_to(end) < 2.0 else 0.0017))
	if presentation_state in ["landing", "landed"] and _fish != null:
		# One continuous line through the float eye, then a short leader to the
		# real mouth attachment. The float no longer masquerades as the hook.
		if _fish_id == "chinese_sturgeon":
			var leader_start: Vector3 = points[-1]
			var guide: Vector3 = _sturgeon_leader_guide_world()
			var mouth: Vector3 = _fish_mouth_world()
			for step: int in range(1, 13):
				var u: float = float(step) / 12.0
				points.append(leader_start.lerp(guide, u).lerp(guide.lerp(mouth, u), u))
				radii.append(radii[-1])
		else:
			points.append(_fish_mouth_world())
			radii.append(radii[-1])
	_line.mesh = _tube_mesh(points, radii, 4)

func _build_bobber() -> void:
	_bobber = Node3D.new()
	_bobber.name = "BuoyantFloat"
	add_child(_bobber)
	var lacquer := _material(Color("66402b"), 0.24)
	lacquer.clearcoat_enabled = true
	lacquer.clearcoat = 0.65
	lacquer.clearcoat_roughness = 0.22
	var carbon := _material(Color("202826"), 0.34)
	var ivory := _material(Color("fff1c6"), 0.42)
	var vermilion := _material(Color("ff572c"), 0.38)
	var yellow := _material(Color("dfec56"), 0.40)
	var black := _material(Color("161c19"), 0.38)
	var brass := _material(Color("b69a57"), 0.26, 0.55)
	# Slender lacquered balsa body, shaped as a genuine solid of revolution.
	_float_part("LacqueredBalsaBody", _float_profile_mesh(PackedVector2Array([
		Vector2(-0.089, 0.0016), Vector2(-0.085, 0.004), Vector2(-0.077, 0.010),
		Vector2(-0.064, 0.015), Vector2(-0.052, 0.0165), Vector2(-0.041, 0.0155),
		Vector2(-0.031, 0.012), Vector2(-0.023, 0.007), Vector2(-0.018, 0.0055)
	])), lacquer)
	_float_cylinder("CarbonKeel", -0.156, -0.086, 0.00125, carbon)
	_float_cylinder("LowerFerrule", -0.091, -0.084, 0.0023, brass)
	_float_cylinder("ShoulderFerrule", -0.020, -0.015, 0.0060, brass)
	_float_cylinder("SightAntennaCore", -0.026, -0.016, 0.0053, ivory)
	# Alternating paint bands are actual opaque cylindrical geometry. The lower
	# cream/red bands are hidden at rest and appear as the fish unloads the shot.
	var bands: Array[Dictionary] = [
		{"name":"LiftIvory", "bottom":-0.016, "top":-0.002, "mat":ivory},
		{"name":"LiftRed", "bottom":-0.002, "top":0.014, "mat":vermilion},
		{"name":"WaterlineBlack", "bottom":0.014, "top":0.020, "mat":black},
		{"name":"LowerIvory", "bottom":0.020, "top":0.034, "mat":ivory},
		{"name":"LowerBlack", "bottom":0.034, "top":0.040, "mat":black},
		{"name":"YellowSight", "bottom":0.040, "top":0.057, "mat":yellow},
		{"name":"UpperBlack", "bottom":0.057, "top":0.063, "mat":black},
		{"name":"UpperIvory", "bottom":0.063, "top":0.077, "mat":ivory},
		{"name":"TipBlack", "bottom":0.077, "top":0.083, "mat":black},
		{"name":"OrangeTip", "bottom":0.083, "top":0.111, "mat":vermilion}
	]
	for band: Dictionary in bands:
		_float_cylinder(str(band.name), float(band.bottom), float(band.top), FLOAT_SIGHT_RADIUS, band.mat)
	var cap := SphereMesh.new()
	cap.radius = FLOAT_SIGHT_RADIUS
	cap.height = 0.006
	cap.radial_segments = 16
	cap.rings = 8
	_float_part("RoundedTipCap", cap, vermilion, Vector3(0, 0.111, 0))
	var eye := TorusMesh.new()
	eye.inner_radius = 0.0022
	eye.outer_radius = 0.0036
	eye.rings = 16
	eye.ring_segments = 8
	var eye_part: MeshInstance3D = _float_part("StainlessLineEye", eye, _material(Color("bcc8c2"), 0.23, 0.8), FLOAT_LINE_EYE)
	eye_part.rotation.x = PI * 0.5
	_float_cylinder("EyeWhipping", -0.158, -0.150, 0.0017, ivory)
	_bobber.visible = false
	# Small, lit water geometry. It follows shaft intersection and actual travel;
	# it neither glows nor reacts to hidden nibble/bite state changes.
	_float_meniscus = MeshInstance3D.new()
	_float_meniscus.name = "FloatSurfaceMeniscus"
	_float_meniscus.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var contact_mesh := TorusMesh.new()
	contact_mesh.inner_radius = 0.88
	contact_mesh.outer_radius = 1.0
	contact_mesh.rings = 32
	contact_mesh.ring_segments = 6
	_float_meniscus.mesh = contact_mesh
	var water_film := _material(Color(0.56, 0.64, 0.55, 0.24), 0.28)
	water_film.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_float_meniscus.material_override = water_film
	_float_meniscus.visible = false
	add_child(_float_meniscus)
	_float_wake = MeshInstance3D.new()
	_float_wake.name = "FloatDirectionalWake"
	_float_wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_float_wake.material_override = water_film.duplicate()
	_float_wake.visible = false
	add_child(_float_wake)

func _float_part(label: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	var material_key: int = material.get_instance_id()
	if not _float_materials.has(material_key):
		var paint: StandardMaterial3D = material as StandardMaterial3D
		var shader_material := ShaderMaterial.new()
		shader_material.shader = FLOAT_SHADER
		shader_material.set_shader_parameter("paint_color", paint.albedo_color)
		shader_material.set_shader_parameter("paint_roughness", paint.roughness)
		shader_material.set_shader_parameter("paint_metallic", paint.metallic)
		shader_material.set_shader_parameter("lacquer_amount", paint.clearcoat if paint.clearcoat_enabled else 0.0)
		_float_materials[material_key] = shader_material
	part.material_override = _float_materials[material_key]
	part.position = at
	# Subpixel shadow flicker would become a false visual bite signal.
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bobber.add_child(part)
	return part

func _set_float_water_material(at_surface: bool, water_height: float) -> void:
	for material: ShaderMaterial in _float_materials.values():
		material.set_shader_parameter("at_water_surface", at_surface)
		material.set_shader_parameter("water_height", water_height)

func _float_cylinder(label: String, bottom: float, top: float, radius: float, material: Material) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = top - bottom
	shape.radial_segments = 16
	_float_part(label, shape, material, Vector3(0, (top + bottom) * 0.5, 0))

func _float_profile_mesh(profile: PackedVector2Array) -> ArrayMesh:
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for point: Vector2 in profile:
		points.append(Vector3(0, point.x, 0))
		radii.append(point.y)
	return _tube_mesh(points, radii, 24)

func _water_surface_height(at: Vector2, clock: float) -> float:
	# Exact analytic displacement used by river_water.gdshader. Session force
	# signals are relative to this surface; float_water_height is not added twice.
	var warp: float = sin(at.x * 0.47 - at.y * 0.29 + clock * 0.22) * 0.85 + sin(at.y * 0.71 + at.x * 0.12) * 0.31
	var height: float = sin(at.dot(Vector2(0.87, 0.38)) * 2.1 + clock * 1.05 + warp) * 0.006
	height += sin(at.dot(Vector2(-0.67, 0.74)) * 3.7 - clock * 1.43 + warp * 0.72) * 0.004
	height += sin(at.dot(Vector2(0.55, -0.81)) * 7.4 + clock * 1.73 + sin(at.x * 1.7) * 0.4) * 0.002
	return height * (1.45 if weather in ["rain", "wind", "storm"] else 0.7)

func _update_float_surface(delta: float, water_height: float) -> void:
	var axis: Vector3 = _bobber.basis.y
	var shaft_height: float = (water_height - _bobber.position.y) / maxf(0.35, axis.y)
	var surface_position: Vector3 = _bobber.position + axis * shaft_height
	surface_position.y = water_height + 0.002
	var velocity := Vector3.ZERO
	if _float_surface_tracking and delta > 0.0:
		velocity = (surface_position - _float_last_surface_position) / delta
		velocity.y = 0.0
	_float_last_surface_position = surface_position
	_float_surface_tracking = true
	var contact: bool = shaft_height < FLOAT_TIP_TOP and shaft_height > -0.089
	_float_meniscus.visible = contact
	_float_meniscus.position = surface_position
	var radius: float = 0.0068 if shaft_height >= -0.018 else lerpf(0.007, 0.017, clampf((-shaft_height - 0.018) / 0.035, 0.0, 1.0))
	_float_meniscus.scale = Vector3(radius, 0.0018, radius)
	var speed: float = velocity.length()
	_float_wake.visible = contact and speed > 0.008
	if not _float_wake.visible: return
	var trailing: Vector3 = -velocity.normalized()
	var side: Vector3 = trailing.cross(Vector3.UP)
	var length: float = clampf(speed * 0.65, 0.008, 0.11)
	var points := PackedVector3Array([
		surface_position + trailing * length + side * (length * 0.28 + radius),
		surface_position + side * radius,
		surface_position - side * radius,
		surface_position + trailing * length - side * (length * 0.28 + radius)
	])
	_float_wake.mesh = _tube_mesh(points, PackedFloat32Array([0.0003, 0.0008, 0.0008, 0.0003]), 4)
	(_float_wake.material_override as StandardMaterial3D).albedo_color.a = clampf(speed * 1.1, 0.025, 0.20)

func _ensure_fish(record: Dictionary) -> bool:
	var id: String = str(record.get("species_id", record.get("id", "")))
	var millimeters: float = float(record.get("length_mm", float(record.get("length_cm", record.get("length", 72.0))) * 10.0))
	_fish_length = clampf(millimeters / 1000.0, 0.001, 30.0)
	if id != _fish_id or _fish == null:
		if _fish:
			_fish.visible = false
			_fish.queue_free()
		_fish = null
		_fish_animator = null
		_fish_id = id
		_fish_info = FishModels.model_info(id)
		if _fish_info.is_empty() or not FishModels.is_available(id):
			_show_model_error(id, "Species-specific 3D model is not ready: " + id)
			return false
		_fish = FishModels.instantiate_fish(id)
		if _fish == null:
			_show_model_error(id, "Unable to load species-specific 3D model: " + id)
			return false
		_fish.name = "Fish_" + id
		_fish_root.add_child(_fish)
		_fish_animator = _find_animator(_fish)
	asset_error = ""
	if _asset_error_label: _asset_error_label.visible = false
	# Registry models use +X nose, +Y dorsal and their declared physical rest length.
	var rest_length: float = maxf(0.01, float(_fish_info.get("rest_length_m", 1.0)))
	_fish.scale = Vector3.ONE * (_fish_length / rest_length)
	return true

func _show_model_error(id: String, message: String) -> void:
	_fish_root.visible = false
	if _asset_error_label:
		_asset_error_label.text = "3D MODEL NOT READY\n" + id
		_asset_error_label.visible = true
	if asset_error != message:
		asset_error = message
		push_warning(message)
		model_error.emit(id, message)

func _play_character(clip: String, loop: bool = true) -> void:
	if not _animator: return
	var found: String = _resolve_animation(_animator, clip)
	if found.is_empty(): return
	if _last_anim == found and loop == _last_loop and _animator.is_playing(): return
	_last_anim = found
	_last_loop = loop
	_animator.get_animation(found).loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	_animator.speed_scale = 1.0 if clip in ["cast", "lift"] else _animator.speed_scale
	_animator.play(found, 0.12 if clip == "cast" else 0.28)
	if _suspended:
		_character_was_playing = true
		_animator.pause()

func _play_fish(clip: String) -> void:
	if not _fish_animator: return
	var found: String = _resolve_animation(_fish_animator, clip)
	if found.is_empty(): found = _resolve_animation(_fish_animator, "swim")
	if not found.is_empty():
		_fish_animator.get_animation(found).loop_mode = Animation.LOOP_LINEAR
		_fish_animator.play(found, 0.15)
		if _suspended:
			_fish_was_playing = true
			_fish_animator.pause()

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
		ring.mesh = _ripple_mesh()
		var material := ShaderMaterial.new()
		material.shader = RIPPLE_SHADER
		material.render_priority = 1
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

func _build_weather() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "NativeRainStreaks"
	_rain.amount = 256
	_rain.lifetime = 1.35
	_rain.preprocess = 0.5
	_rain.local_coords = false
	_rain.visibility_aabb = AABB(Vector3(-12, -18, -15), Vector3(24, 32, 30))
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(7.0, 3.5, 9.0)
	motion.direction = Vector3(-0.04, -1.0, 0.02)
	motion.spread = 3.0
	motion.initial_velocity_min = 14.0
	motion.initial_velocity_max = 18.0
	motion.gravity = Vector3(-0.8, -3.5, 0.0)
	motion.scale_min = 0.7
	motion.scale_max = 1.2
	motion.particle_flag_align_y = true
	_rain.process_material = motion
	var streak := CylinderMesh.new()
	streak.top_radius = 0.003
	streak.bottom_radius = 0.006
	streak.height = 0.30
	streak.radial_segments = 4
	var rain_material := _material(Color(0.60, 0.75, 0.82, 0.37), 0.3)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.material = rain_material
	_rain.draw_pass_1 = streak
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rain.emitting = false
	_rain.visible = false
	add_child(_rain)

func _ripple_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(81):
		var a: float = TAU * float(i) / 80.0
		for j in range(2):
			var radius: float = 0.36 if j == 0 else 0.50
			vertices.append(Vector3(cos(a) * radius, 0, sin(a) * radius))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(i) / 80.0, float(j)))
		if i > 0:
			var b: int = i * 2
			indices.append_array(PackedInt32Array([b-2, b, b-1, b-1, b, b+1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _spawn_ripple(at: Vector3, power: float, duration: float, radius_scale: float = 1.0) -> void:
	_last_ripple = _time
	for effect: Dictionary in _ripple_pool:
		if float(effect.age) < float(effect.duration): continue
		var ring: MeshInstance3D = effect.node
		ring.position = Vector3(at.x, 0.012, at.z)
		ring.visible = true
		effect.age = 0.0
		effect.duration = duration
		effect.power = power
		effect.radius_scale = radius_scale
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
		var radius: float = (0.2 + ratio * (1.6 + float(effect.power))) * float(effect.get("radius_scale", 1.0))
		ring.scale = Vector3(radius, 0.10, radius)
		(effect.material as ShaderMaterial).set_shader_parameter("ripple_color", Color(0.57, 0.71, 0.61, pow(1.0 - ratio, 1.2) * 0.35))
		(effect.material as ShaderMaterial).set_shader_parameter("progress", ratio)
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
	return {"state": presentation_state, "mode": mode, "suspended": _suspended, "cast_in_progress": cast_in_progress, "landing_time": _landing_time, "camera_position": camera.position if camera else Vector3.ZERO, "angler_loaded": _animator != null, "fish_loaded": _fish != null, "fish_id": _fish_id, "asset_error": asset_error, "region_id": region_id, "spot_id": spot_id, "location_rebuild_count": location_rebuild_count, "gear_id": gear_id, "rod_length": _rod_length, "rod_radius": _rod_radius, "renderer": RenderingServer.get_current_rendering_method(), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "rendered_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
