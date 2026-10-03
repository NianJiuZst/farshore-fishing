extends SceneTree
## Actual Main/Session/Stage, selected reproducible encounters, fixed120Hz steps.
## Movie samples20fps at450x990; crisp720px stills are separate. Not phone FPS.
const MainScene = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/fishing_session.gd")
const FightController = preload("res://tests/fishing_test_controller.gd")
const MOVIE_SIZE := Vector2i(450, 990)
const MOVIE_FPS: int = 20
var app: Control
var output: String
var frame_index: int = 0
var rows: Array[Dictionary] = []
var sources: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	output = OS.get_environment("FARSHORE_FLOAT_CAPTURE_OUTPUT")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../build/float-presentation-final")
	DirAccess.make_dir_recursive_absolute(output)
	for source: String in ["res://scripts/fishing_stage_3d.gd", "res://scripts/fishing_session.gd", "res://scripts/float_encounter.gd", "res://assets/shaders3d/float_lacquer.gdshader", "res://assets/shaders3d/river_water.gdshader", "res://scripts/main.gd", "res://scripts/fishing_menu_pages.gd", "res://assets/3d/angler.glb"]:
		sources[source] = FileAccess.get_sha256(source)
	set_size(MOVIE_SIZE)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false, "vibration":false, "volume":0.0})
	app.sound.suspend(true)
	# NoiseTexture2D is generated asynchronously. Simulation ticks do not wait
	# for that image or for panorama/reflection-probe render work.
	var water_normal: Texture2D = app.scenery._water_material.get_shader_parameter("normal_texture")
	if water_normal.get_image() == null: await water_normal.changed
	assert(water_normal.get_image() != null and not water_normal.get_image().is_empty())
	print("FLOAT_WATER_NORMAL_READY ", water_normal.get_image().get_size())
	for warmup_frame: int in 24:
		await process_frame
		await RenderingServer.frame_post_draw
	tick(1.2)
	await capture("human_lobby_720x1280")
	await capture("human_lobby_720x1584")
	app._show_prepare()
	app._enter_fishery()
	tick(2.0)
	for warmup_frame: int in 18:
		await process_frame
		await RenderingServer.frame_post_draw
	print("FLOAT_CAPTURE_RENDERER ", RenderingServer.get_current_rendering_method(), " / ", RenderingServer.get_video_adapter_name())
	app.encounter.rng.seed = 63193
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"], "lake_shore", "lake", "worm", 2, "day", "clear")
	var fixtures: Dictionary = find_fixtures(record)
	print("FLOAT_CAPTURE_FIXTURES ", JSON.stringify(fixtures))
	for signature: String in ["lift", "sink", "travel", "soft"]:
		var fixture: Dictionary = fixtures[signature]
		begin_fixture(record, int(fixture.seed))
		tick(3.3)
		await capture(signature + "_neutral_720x1280")
		await capture(signature + "_neutral_720x1584")
		tick(0.8)
		await capture(signature + "_wave_720x1280")
		tick(maxf(0.0, float(fixture.video_start) - app.session.float_clock))
		var camera_transform: Transform3D = app.scenery.camera.transform
		var peak_saved: bool = false
		var contact_saved: bool = false
		var duration: float = float(fixture.return_time) + 0.25 - app.session.float_clock
		for index: int in int(ceil(duration * MOVIE_FPS)):
			tick(1.0 / MOVIE_FPS)
			assert(app.scenery.camera.transform.is_equal_approx(camera_transform), "Observation cannot reframe by bite state")
			assert(not app.scenery._fish_root.visible, "Fish cannot reveal before hook")
			await movie_frame(signature)
			if not contact_saved and app.session.float_clock >= float(fixture.contact_time):
				contact_saved = true
				await capture(signature + "_contact_720x1280")
			if not peak_saved and app.session.float_clock >= float(fixture.peak_time):
				peak_saved = true
				await capture(signature + "_signal_720x1280")
				await capture(signature + "_signal_720x1584")
				app.scenery.set_weather("rain")
				app.scenery._process(0.0)
				await capture(signature + "_rain_lighting_720x1584")
				app.scenery.set_weather("clear")
				app.scenery._process(0.0)
		await capture(signature + "_recovery_720x1280")
	await capture_human_fishing(record, int(fixtures.sink.seed))
	# Explicit inspection fixture, separate from production-camera evidence.
	app.session.reset()
	app.scenery.cancel_landing()
	app._landing_pending = false
	app.scenery._bobber.visible = true
	app.scenery._bobber.position = Vector3(-0.3, 0.45, -7.0)
	app.scenery._bobber.rotation = Vector3.ZERO
	app.scenery._line.visible = false
	app.scenery._set_float_water_material(false, 0.0)
	app.scenery.camera.position = app.scenery._bobber.position + Vector3(0.22, 0.06, 0.70)
	app.scenery._camera_target = app.scenery._bobber.position + Vector3(0, -0.025, 0)
	app.scenery.camera.look_at(app.scenery._camera_target)
	await capture("float_construction_inspection_720x1280")
	app._show_prepare()
	app._show_float_guide()
	await capture("float_guide_top_720x1280")
	var guide_scroll: ScrollContainer = app._overlay.find_child("PageScroll", true, false)
	guide_scroll.scroll_vertical = 100000
	await capture("float_guide_bottom_720x1280")
	var stable: bool = true
	for source: String in sources: stable = stable and sources[source] == FileAccess.get_sha256(source)
	var evidence: Dictionary = {"scope":"Actual desktop Godot4.6.3 Mobile software Vulkan; actual selected seeded common-carp encounters;120Hz simulation with20fps450x990 movie sampling and720px stills, not Android hardware performance", "renderer":RenderingServer.get_current_rendering_method(), "adapter":RenderingServer.get_video_adapter_name(), "sources":sources, "sources_unchanged":stable, "record":record, "weather_note":"rain_lighting screens preserve a genuine encounter snapshot and change only stage rain lighting/water; they isolate readability, not rain encounter balance", "fixtures":fixtures, "frames":frame_index, "movie_fps":MOVIE_FPS, "rows":rows}
	var file := FileAccess.open(output.path_join("evidence.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t") + "\n")
	file.close()
	app.fish_art._textures.clear()
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	for frame: int in 6: await process_frame
	print("FLOAT_CAPTURE_COMPLETE frames=", frame_index, " sources_unchanged=", stable, " output=", output)
	quit(0)
func begin_fixture(record: Dictionary, seed_value: int) -> void:
	app.session.reset()
	app.session.set_seed(seed_value)
	app.session.start_charge()
	app.session.charge = 0.65
	assert(app.session.cast(record, app.catalog.gear[2]))
	app.store.begin_session(app.session.session_id)
func capture_human_fishing(record: Dictionary, seed_value: int) -> void:
	begin_fixture(record, seed_value)
	for frame: int in 44:
		tick(0.05)
		await movie_frame("human_cast")
		if frame == 17: await capture("human_cast_loading_720x1280")
		if frame == 26: await capture("human_cast_release_720x1280")
	tick(1.1)
	# A visible sustained load chooses the strike. No hidden BITE/possession
	# state, elapsed wait, species, future timing or RNG drives this reader.
	var held_signal: float = 0.0
	for step: int in 60 * 40:
		if app.session.float_dip > 0.60 or app.session.float_lift > 0.60: held_signal += 0.025
		else: held_signal = 0.0
		if held_signal >= 0.25:
			app._action_down()
			app._action_up()
			break
		tick(0.025)
	assert(app.session.state == Session.State.FIGHT, "Visible sustained take should hook actual fish")
	var controller = FightController.new()
	var reel_saved: bool = false
	var windup_saved: bool = false
	for step: int in 120 * 40:
		if app.session.state != Session.State.FIGHT: break
		if controller.update(app.session, 0.025): app._action_down()
		else: app._action_up()
		tick(0.025)
		if app.session.fight_time <= 3.0 and step % 2 == 1: await movie_frame("human_reel")
		if not reel_saved and app.session.fight_time >= 1.5:
			reel_saved = true
			await capture("human_reel_720x1280")
			await capture("human_reel_720x1584")
		if not windup_saved and app.session.surge_warning > 0.60:
			windup_saved = true
			await capture("human_fight_load_720x1280")
	app._action_up()
	print("HUMAN_CAPTURE_FIGHT_OUTCOME state=", app.session.state, " time=", app.session.fight_time)
	if app.session.state == Session.State.CAUGHT:
		tick(0.8)
		await capture("human_lift_720x1280")
		tick(1.8)
		await capture("human_landing_720x1280")
	else: await capture("human_fight_terminal_720x1280")
func find_fixtures(record: Dictionary) -> Dictionary:
	var found: Dictionary = {}
	for seed_value: int in range(1, 200):
		var trial: FishingSession = Session.new(seed_value)
		trial.start_charge()
		trial.cast(record, app.catalog.gear[2])
		trial.set_state(Session.State.WAITING)
		var contact_peak: float = 0.0
		var contact_time: float = -1.0
		var contact_start: float = -1.0
		var first_motion: float = INF
		var previous_phase: String = "approach"
		var candidate: Dictionary = {}
		for frame: int in 36 * 120:
			trial.step(1.0 / 120.0)
			var phase: String = trial.float_encounter.phase
			if trial.float_activity > 0.005: first_motion = minf(first_motion, trial.float_clock)
			if phase == "contact" and previous_phase != "contact":
				contact_peak = 0.0
				contact_start = trial.float_clock
			if phase == "contact" and trial.float_dip > contact_peak:
				contact_peak = trial.float_dip
				contact_time = trial.float_clock
			previous_phase = phase
			var signature: String = trial.float_encounter.signature
			var strong: bool = trial.float_lift > 0.74 if signature == "lift" else trial.float_dip > 0.83 if signature == "sink" else trial.float_drag.length() > 0.17 if signature == "travel" else trial.float_dip > 0.225
			if candidate.is_empty() and strong and phase == "carry" and not found.has(signature) and first_motion > 2.5 and contact_time > 2.5:
				candidate = {"signature":signature, "seed":seed_value, "peak_time":trial.float_clock, "contact_time":contact_time, "contact_peak":contact_peak, "video_start":maxf(1.9, contact_start - 0.55)}
			if not candidate.is_empty() and phase in ["spit", "return", "approach"] and maxf(trial.float_dip, trial.float_lift) < 0.03:
				candidate["return_time"] = trial.float_clock
				if trial.float_clock - float(candidate.video_start) < 9.0: found[str(candidate.signature)] = candidate
				break
		if found.size() == 4: return found
	assert(false, "Cannot find actual lift/sink/travel/soft fixtures")
	return found
func set_size(value: Vector2i) -> void:
	root.size = value
	DisplayServer.window_set_size(value)
	if is_instance_valid(app): app.scenery._update_camera(0.0)
func capture(label: String) -> void:
	var previous_size: Vector2i = root.size
	set_size(Vector2i(720, 1584 if label.ends_with("720x1584") else 1280))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK)
	print("FLOAT_CAPTURE ", label, " dip=", app.session.float_dip, " lift=", app.session.float_lift, " drag=", app.session.float_drag)
	set_size(previous_size)
	await process_frame
func movie_frame(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.size == MOVIE_SIZE)
	if "--video" in OS.get_cmdline_user_args(): assert(root.get_texture().get_image().save_jpg(output.path_join("frame_%04d.jpg" % frame_index), 0.94) == OK)
	rows.append({"frame":frame_index, "signature":label, "clock":app.session.float_clock, "fight_time":app.session.fight_time, "dip":app.session.float_dip, "lift":app.session.float_lift, "drag":str(app.session.float_drag), "position":str(app.scenery._bobber.position), "camera":str(app.scenery.camera.transform), "fov":app.scenery.camera.fov, "fish_visible":app.scenery._fish_root.visible})
	frame_index += 1
func tick(seconds: float) -> void:
	var left: float = seconds
	while left > 0.000001:
		var delta: float = minf(left, 1.0 / 120.0)
		if not app.scenery._suspended:
			app.scenery._animator.advance(delta)
			if app.scenery._fish_animator:
				app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				app.scenery._fish_animator.advance(delta)
		app._process(delta)
		app.scenery._process(delta)
		left -= delta
