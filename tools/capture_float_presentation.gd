extends SceneTree
## Genuine Mobile Vulkan render of the real Main/Session/Stage. Encounter seeds
## are selected for sight-tip coverage, never by changing the live output values.
## Screens and slow sampled movie frames are desktop evidence, not phone FPS.
const MainScene = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/fishing_session.gd")
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
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../build/float-presentation")
	DirAccess.make_dir_recursive_absolute(output)
	for source: String in ["res://scripts/fishing_stage_3d.gd", "res://scripts/fishing_session.gd", "res://scripts/float_encounter.gd", "res://assets/shaders3d/float_lacquer.gdshader", "res://assets/shaders3d/river_water.gdshader", "res://scripts/main.gd", "res://scripts/fishing_menu_pages.gd", "res://assets/3d/angler.glb"]:
		sources[source] = FileAccess.get_sha256(source)
	root.size = Vector2i(720, 1280)
	DisplayServer.window_set_size(root.size)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false, "vibration":false, "volume":0.0})
	app.sound.suspend(true)
	app._show_prepare()
	app._enter_fishery()
	print("FLOAT_CAPTURE_RENDERER ", RenderingServer.get_current_rendering_method(), " / ", RenderingServer.get_video_adapter_name())
	app.encounter.rng.seed = 63193
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"], "lake_shore", "lake", "worm", 2, "day", "clear")
	var fixtures: Dictionary = find_fixtures(record)
	print("FLOAT_CAPTURE_FIXTURES ", JSON.stringify(fixtures))
	for signature: String in ["lift", "sink", "travel", "soft"]:
		var fixture: Dictionary = fixtures[signature]
		app.session.reset()
		app.session.set_seed(int(fixture.seed))
		app.session.start_charge()
		app.session.charge = 0.65
		assert(app.session.cast(record, app.catalog.gear[2]))
		app.store.begin_session(app.session.session_id)
		tick(3.3)
		await capture(signature + "_neutral_720x1280")
		root.size = Vector2i(720, 1584)
		DisplayServer.window_set_size(root.size)
		app.scenery._update_camera(0.0)
		await capture(signature + "_neutral_720x1584")
		root.size = Vector2i(720, 1280)
		DisplayServer.window_set_size(root.size)
		app.scenery._update_camera(0.0)
		var camera_transform: Transform3D = app.scenery.camera.transform
		var peak_saved: bool = false
		var wave_saved: bool = false
		var contact_saved: bool = false
		var duration: float = float(fixture.peak_time) + 2.8 - app.session.float_clock
		for index: int in int(ceil(duration * 8.0)):
			tick(0.125)
			assert(app.scenery.camera.transform.is_equal_approx(camera_transform), "Observation cannot reframe by bite state")
			assert(not app.scenery._fish_root.visible, "Fish cannot reveal before hook")
			await process_frame
			await RenderingServer.frame_post_draw
			if "--video" in OS.get_cmdline_user_args():
				assert(root.get_texture().get_image().save_jpg(output.path_join("frame_%04d.jpg" % frame_index), 0.94) == OK)
			rows.append({"frame":frame_index, "signature":signature, "clock":app.session.float_clock, "dip":app.session.float_dip, "lift":app.session.float_lift, "drag":str(app.session.float_drag), "position":str(app.scenery._bobber.position), "camera":str(app.scenery.camera.transform), "fov":app.scenery.camera.fov, "fish_visible":app.scenery._fish_root.visible})
			frame_index += 1
			if not wave_saved and app.session.float_clock >= 2.0:
				wave_saved = true
				await capture(signature + "_wave_720x1280")
			if not contact_saved and float(fixture.contact_time) > 0.0 and app.session.float_clock >= float(fixture.contact_time):
				contact_saved = true
				await capture(signature + "_contact_720x1280")
			if not peak_saved and app.session.float_clock >= float(fixture.peak_time):
				peak_saved = true
				await capture(signature + "_signal_720x1280")
				root.size = Vector2i(720, 1584)
				DisplayServer.window_set_size(root.size)
				app.scenery._update_camera(0.0)
				await capture(signature + "_signal_720x1584")
				app.scenery.set_weather("rain")
				app.scenery._process(0.0)
				await capture(signature + "_rain_lighting_720x1584")
				app.scenery.set_weather("clear")
				app.scenery._process(0.0)
				root.size = Vector2i(720, 1280)
				DisplayServer.window_set_size(root.size)
				app.scenery._update_camera(0.0)
				await process_frame
				await process_frame
		await capture(signature + "_recovery_720x1280")
	# Deliberately labeled inspection view, separate from gameplay evidence.
	# It exposes submerged construction without changing any production camera.
	app.session.reset()
	app.scenery._bobber.visible = true
	app.scenery._bobber.position = Vector3(-0.3, 0.45, -7.0)
	app.scenery._bobber.rotation = Vector3.ZERO
	app.scenery._line.visible = false
	app.scenery._set_float_water_material(false, 0.0)
	app.scenery.camera.position = app.scenery._bobber.position + Vector3(0.22, 0.06, 0.70)
	app.scenery.camera.look_at(app.scenery._bobber.position + Vector3(0, -0.025, 0))
	await capture("float_construction_inspection_720x1280")
	app._show_prepare()
	app._show_float_guide()
	await capture("float_guide_top_720x1280")
	var guide_scroll: ScrollContainer = app._overlay.find_child("PageScroll", true, false)
	guide_scroll.scroll_vertical = 100000
	await capture("float_guide_bottom_720x1280")
	var stable: bool = true
	for source: String in sources:
		stable = stable and sources[source] == FileAccess.get_sha256(source)
	var evidence: Dictionary = {"scope":"Actual desktop Godot4.6.3 Mobile software Vulkan; real selected seeded common-carp encounters;8fps sampled simulation frames, not Android hardware performance", "renderer":RenderingServer.get_current_rendering_method(), "adapter":RenderingServer.get_video_adapter_name(), "sources":sources, "sources_unchanged":stable, "record":record, "weather_note":"rain_lighting screens preserve an actual encounter snapshot and change only stage rain lighting/water; they isolate visual readability, not rain encounter balance", "fixtures":fixtures, "frames":frame_index, "rows":rows}
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
func find_fixtures(record: Dictionary) -> Dictionary:
	var found: Dictionary = {}
	for seed_value: int in range(1, 160):
		var trial: FishingSession = Session.new(seed_value)
		trial.start_charge()
		trial.cast(record, app.catalog.gear[2])
		trial.set_state(Session.State.WAITING)
		var contact_peak: float = 0.0
		var contact_time: float = -1.0
		var first_motion: float = INF
		for frame: int in 30 * 120:
			trial.step(1.0 / 120.0)
			if trial.float_activity > 0.005: first_motion = minf(first_motion, trial.float_clock)
			if trial.float_encounter.phase == "contact" and trial.float_dip > contact_peak:
				contact_peak = trial.float_dip
				contact_time = trial.float_clock
			var signature: String = trial.float_encounter.signature
			var strong: bool = trial.float_lift > 0.74 if signature == "lift" else trial.float_dip > 0.75 if signature == "sink" else trial.float_drag.length() > 0.17 if signature == "travel" else trial.float_dip > 0.225 and trial.float_encounter.phase == "carry"
			if strong and trial.float_encounter.phase == "carry":
				if not found.has(signature) and first_motion > 2.5 and contact_time > 2.5:
					found[signature] = {"seed":seed_value, "peak_time":trial.float_clock, "contact_time":contact_time, "contact_peak":contact_peak}
				break
		if found.size() == 4: return found
	assert(false, "Cannot find actual lift/sink/travel/soft fixtures")
	return found
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK)
	print("FLOAT_CAPTURE ", label, " dip=", app.session.float_dip, " lift=", app.session.float_lift, " drag=", app.session.float_drag)
func tick(seconds: float) -> void:
	var left: float = seconds
	while left > 0.000001:
		var delta: float = minf(left, 1.0 / 120.0)
		if not app.scenery._suspended:
			app.scenery._animator.advance(delta)
		app._process(delta)
		app.scenery._process(delta)
		left -= delta
