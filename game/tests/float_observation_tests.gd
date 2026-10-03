extends SceneTree
## Actual stage geometry + camera contract. Synthetic signals isolate presentation;
## separate Session tests cover how real encounters produce those signals.
const Stage = preload("res://scripts/fishing_stage_3d.gd")
const Session = preload("res://scripts/fishing_session.gd")
var checks: int = 0
var failures: int = 0
var stage: FishingStage3D
var session: FishingSession

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL FLOAT OBSERVATION: ", label)

func run() -> void:
	root.size = Vector2i(720, 1280)
	stage = Stage.new()
	root.add_child(stage)
	stage.set_process(false)
	stage._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	session = Session.new()
	stage.bind_session(session)
	stage.set_mode("fishing")
	session.start_charge()
	session.charge = 0.65
	session.cast({"species_id":"common_carp", "length_mm":700, "difficulty":0.4, "behavior":"steady"}, {})
	for frame: int in 88: advance(0.025)
	check(stage._cast_impact_emitted, "cast impact emits exactly once when float reaches water")
	var active_spray: int = 0
	var small_rings: int = 0
	for effect: Dictionary in stage._spray_pool:
		if (effect.node as Node3D).visible: active_spray += 1
	for effect: Dictionary in stage._ripple_pool:
		if (effect.node as Node3D).visible and is_equal_approx(float(effect.get("radius_scale", 1.0)), 0.28): small_rings += 1
	check(active_spray == 0 and small_rings == 1, "slender float landing creates one small ring without oversized droplets")
	var landed_camera: Transform3D = stage.camera.transform
	var landed_fov: float = stage.camera.fov
	var impacts_before: int = stage._impact_index
	var ripple_before: float = stage._last_ripple
	for state: int in [Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.NIBBLE, Session.State.WAITING, Session.State.BITE]:
		session.set_state(state)
		advance(0.025)
		check(stage.camera.transform.is_equal_approx(landed_camera), "unchanged exact camera transform in pre-hook state %d" % state)
		check(is_equal_approx(stage.camera.fov, landed_fov), "unchanged FOV in pre-hook state %d" % state)
		check(not stage._fish_root.visible and stage._fish == null, "no species geometry instantiated or shown before hook %d" % state)
		check(stage._impact_index == impacts_before and stage._last_ripple == ripple_before, "no transition splash or ripple giveaway %d" % state)
		check(stage._last_anim.ends_with("wait"), "angler does not react to unseen fish %d" % state)
	# Hold presentation time fixed so only the signal under test can change geometry.
	session.float_dip = 0.0
	session.float_lift = 0.0
	session.float_drag = Vector2.ZERO
	session.float_tilt = 0.0
	session.float_current = Vector2.ZERO
	session.float_clock = 4.0
	stage._update_fishing(0.0)
	var neutral: Transform3D = stage._bobber.transform
	session.float_dip = 0.85
	session.float_drag = Vector2(0.16, -0.11)
	session.float_tilt = 0.40
	stage._update_fishing(0.0)
	check(stage._bobber.position.y < neutral.origin.y - 0.08, "committed dip moves real float under surface")
	check(is_equal_approx(stage._bobber.position.x - neutral.origin.x, 0.16) and is_equal_approx(stage._bobber.position.z - neutral.origin.z, -0.11), "lateral signal moves actual water-plane position")
	check(not stage._bobber.basis.is_equal_approx(neutral.basis), "tilt changes actual float orientation")
	check(stage.camera.transform.is_equal_approx(landed_camera), "float motion never drives or follows camera")
	session.float_dip = 0.0
	session.float_drag = Vector2.ZERO
	session.float_tilt = 0.0
	session.float_lift = 0.75
	stage._update_fishing(0.0)
	check(stage._bobber.position.y > neutral.origin.y + 0.02, "lift-bite signal physically raises float")
	var projected_height: float = stage.camera.unproject_position(stage._bobber_target + Vector3.UP * Stage.FLOAT_TIP_TOP).distance_to(stage.camera.unproject_position(stage._bobber_target))
	check(projected_height >= 36.0 and projected_height <= 55.0, "neutral antenna projects to36–55px at720px portrait width")
	print("FLOAT_PROJECTED_HEIGHT_720: ", projected_height)
	root.size = Vector2i(720, 1584)
	stage._update_camera(0.0)
	var tall_height: float = stage.camera.unproject_position(stage._bobber_target + Vector3.UP * Stage.FLOAT_TIP_TOP).distance_to(stage.camera.unproject_position(stage._bobber_target))
	check(absf(tall_height - projected_height) < 0.1, "19.8:9 keeps exactly the same readable float scale")
	root.size = Vector2i(720, 1280)
	session.float_lift = 0.0
	stage._update_fishing(0.0)
	var still_float: Transform3D = stage._bobber.transform
	stage._time += 17.0
	stage._update_fishing(0.0)
	check(stage._bobber.transform.is_equal_approx(still_float), "presentation clock cannot add random wobble to a held observation")
	check(stage._bobber.basis.is_equal_approx(Basis.IDENTITY), "zero force and zero tilt have a stable vertical rest position")
	check(absf(stage._bobber.position.y - stage._water_surface_height(Vector2(stage._bobber.position.x, stage._bobber.position.z), session.float_clock)) < 0.000001, "neutral waterline is exact shader wave at authoritative clock")
	var body: MeshInstance3D = stage._bobber.get_node("LacqueredBalsaBody")
	check(body.mesh.get_aabb().end.y < -0.017, "buoyant balsa body is fully shotted beneath the neutral waterline")
	check(stage._bobber.has_node("CarbonKeel") and stage._bobber.has_node("StainlessLineEye") and stage._bobber.has_node("RoundedTipCap"), "real3D float includes keel, line eye and rounded tip")
	var painted_bands: int = 0
	for child: Node in stage._bobber.get_children():
		if child is MeshInstance3D:
			var material: ShaderMaterial = child.material_override
			check(material.shader == Stage.FLOAT_SHADER and not "EMISSION" in material.shader.code and not "unshaded" in material.shader.code, "float part has physically lit nonglowing material: " + child.name)
			if child.name in ["LiftIvory", "LiftRed", "WaterlineBlack", "LowerIvory", "LowerBlack", "YellowSight", "UpperBlack", "UpperIvory", "TipBlack", "OrangeTip"]: painted_bands += 1
	check(painted_bands == 10, "ten separate opaque paint bands remain inspectable geometry")
	session.float_dip = 1.0
	stage._update_fishing(0.0)
	var sunk_tip: Vector3 = stage._bobber.to_global(Vector3.UP * Stage.FLOAT_TIP_TOP)
	check(sunk_tip.y < stage._water_surface_height(Vector2(sunk_tip.x, sunk_tip.z), session.float_clock) - 0.04, "committed sink submerges the whole antenna at least4cm")
	check(not stage._float_meniscus.visible, "fully submerged tip has no floating marker")
	var tip_paint: ShaderMaterial = stage._bobber.get_node("OrangeTip").material_override
	check(bool(tip_paint.get_shader_parameter("at_water_surface")) and float(tip_paint.get_shader_parameter("water_height")) > sunk_tip.y + 0.03, "whole sunk tip is beyond fine-marking underwater visibility depth")
	session.float_dip = 0.0
	session.float_drag = Vector2.ZERO
	stage._update_fishing(0.025)
	stage._update_fishing(0.025)
	check(not stage._float_wake.visible, "still float produces no directional wake")
	session.float_drag = Vector2(0.01, -0.005)
	stage._update_fishing(0.1)
	check(stage._float_wake.visible, "actual lateral travel makes a small continuous physical wake")
	stage._update_fishing(0.1)
	check(not stage._float_wake.visible, "directional wake ceases when travel ceases")
	# Same installed fish remains hidden on a subsequent cast.
	session.set_state(Session.State.FIGHT)
	advance(0.025)
	check(stage._fish_root.visible and stage._fish != null, "species appears only after hook")
	stage._time = 9.25
	session.tension = 0.55
	session.line_wear = 0.0
	session.surge_warning = 0.0
	stage._update_rod()
	var normal_tip: Vector3 = stage._rod_tip
	var grip: Transform3D = stage._rod_grip.transform
	session.surge_warning = 1.0
	stage._update_rod()
	check(stage._rod_tip.distance_to(normal_tip) > 0.15, "windup visibly loads real rod tip before surge")
	check(stage._rod_grip.transform.is_equal_approx(grip), "windup never displaces hand grip")
	stage._update_camera(6.0)
	await process_frame
	stage._update_rod()
	var tip_screen: Vector2 = stage.camera.unproject_position(stage._rod_tip)
	var tip_visible: bool = not stage.camera.is_position_behind(stage._rod_tip) and Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(tip_screen)
	check(tip_visible, "loaded rod tip windup is inside the fight viewport")
	print("WINDUP_ROD_TIP_SCREEN: ", tip_screen)
	session.line_wear = 0.88
	check(stage._line_danger() > 0.9, "accumulated wear produces physical warning intensity")
	session.reset()
	session.start_charge()
	session.cast({"species_id":"common_carp", "length_mm":700, "difficulty":0.4, "behavior":"steady"}, {})
	for frame: int in 90: advance(0.025)
	session.set_state(Session.State.BITE)
	advance(0.025)
	check(not stage._fish_root.visible, "previous catch cannot leak species during next bite")
	session.pause()
	var paused: Transform3D = stage._bobber.transform
	var paused_camera: Transform3D = stage.camera.transform
	advance(0.6)
	check(stage._bobber.transform.is_equal_approx(paused) and stage.camera.transform.is_equal_approx(paused_camera), "pause freezes float and observation camera")
	session.resume()
	advance(0.025)
	check(stage.camera.transform.is_equal_approx(paused_camera), "resume does not reframe bite")
	# The physically longer float keeps its eye above the actual mouth and stays
	# inside existing landing views, even beside the smallest10cm species.
	for fixture: Array in [["japanese_whiting",100], ["common_carp",700], ["chinese_sturgeon",2400]]:
		stage.play_landing({"species_id":fixture[0], "length_mm":fixture[1], "catch_id":"float_landing_" + str(fixture[0])})
		stage._update_landing(3.4)
		stage._update_camera(6.0)
		stage._update_line()
		var tip: Vector3 = stage._bobber.to_global(Vector3.UP * Stage.FLOAT_TIP_TOP)
		var eye: Vector3 = stage._bobber.to_global(Stage.FLOAT_LINE_EYE)
		check(Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(stage.camera.unproject_position(tip)), "entire float sight tip stays in landing viewport: " + str(fixture[0]))
		check(eye.y > stage._fish_mouth_world().y + 0.02, "lower line eye remains above fish mouth: " + str(fixture[0]))
		var vertices: PackedVector3Array = stage._line.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var terminal := Vector3.ZERO
		for vertex: int in range(vertices.size() - 4, vertices.size()): terminal += vertices[vertex] * 0.25
		check(terminal.distance_to(stage._fish_mouth_world()) < 0.000001, "continuous leader still terminates at anatomical mouth: " + str(fixture[0]))
	stage.queue_free()
	await process_frame
	print("FLOAT_OBSERVATION_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures, "; presentation fixtures, not phone performance")
	quit(0 if failures == 0 else 1)

func advance(delta: float) -> void:
	if not stage._suspended: stage._animator.advance(delta)
	stage._process(delta)
