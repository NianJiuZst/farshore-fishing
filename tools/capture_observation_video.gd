extends SceneTree
## Bounded actual Main/Session/Stage runtime capture, with ordinary generated fish.
## Manually advanced simulation at20fps is evidence of visuals, not phone FPS.
## Run with tools/render_godot.py. See docs/OBSERVATION_PRESENTATION_QA.md.
## FARSHORE_CAPTURE_OUTPUT can select a fresh directory; no player data is used.
const MainScene = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/fishing_session.gd")
var app: Control
var output: String = "/tmp/farshore-observation-final20-frames"
var frame_index: int = 0
var states: Dictionary = {}
var phase_rows: Array[Dictionary] = []
var first_fight_time: float = -1.0
var saw_surge: bool = false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"):
		printerr("Actual isolated render environment required")
		quit(2)
		return
	if not OS.get_environment("FARSHORE_CAPTURE_OUTPUT").is_empty(): output = OS.get_environment("FARSHORE_CAPTURE_OUTPUT")
	root.size = Vector2i(450,800)
	DisplayServer.window_set_size(root.size)
	DirAccess.make_dir_recursive_absolute(output)
	app = MainScene.instantiate()
	root.add_child(app)
	# Native Main startup yields between loading stages; wait for its real completion.
	var startup_deadline: int = Time.get_ticks_msec() + 120000
	while not app._startup_complete and Time.get_ticks_msec() < startup_deadline:
		await process_frame
	if not app._startup_complete:
		printerr("FAIL CAPTURE: Main startup timed out before _startup_complete")
		quit(1)
		return
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	app.encounter.rng.seed = 20261002
	app.session._rng.seed = 2468
	app._show_prepare()
	app._enter_fishery()
	tick(1.5)
	for frame: int in 18: await process_frame
	app._action_down()
	tick(1.15)
	app._action_up()
	print("OBSERVATION_CAPTURE_RENDERER ",RenderingServer.get_current_rendering_method()," / ",RenderingServer.get_video_adapter_name())
	print("ORDINARY_ENCOUNTER ",JSON.stringify(app.session.individual))
	var source_hashes: Dictionary = {}
	for path: String in ["res://scripts/fishing_stage_3d.gd","res://scripts/fishing_session.gd","res://scripts/main.gd"]: source_hashes[path] = FileAccess.get_sha256(path)
	for frame: int in 500:
		if app.session.state == Session.State.BITE and app.session.elapsed > 0.58:
			app._action_down()
			app._action_up()
		if app.session.state == Session.State.FIGHT:
			if app.session.fight_phase == "surge": saw_surge = true
			if first_fight_time < 0: first_fight_time = app.session.fight_time
			if app.session.surge_warning > 0.12 or app.session.tension > 0.63: app._action_up()
			elif app.session.tension < 0.46: app._action_down()
			if saw_surge and app.session.fight_time > 8.0: break
		if app.session.state in [Session.State.ESCAPED,Session.State.CAUGHT]: break
		tick(0.05)
		await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		assert(picture.save_jpg(output.path_join("frame_%04d.jpg" % frame_index),0.94) == OK)
		var key: String = str(app.session.state)
		if not states.has(key):
			states[key] = frame_index
			assert(picture.save_png(output.path_join("state_%s.png" % key)) == OK)
			print("CAPTURE_STATE ",key," frame=",frame_index," action=",app._action.text," disabled=",app._action.disabled," fish_visible=",app.scenery._fish_root.visible)
		phase_rows.append({"frame":frame_index,"state":app.session.state,"phase":app.session.fight_phase,"warning":app.session.surge_warning,"dip":app.session.float_dip,"lift":app.session.float_lift,"drag":str(app.session.float_drag),"camera":str(app.scenery.camera.transform),"fov":app.scenery.camera.fov})
		frame_index += 1
	var evidence: Dictionary = {"scope":"Actual desktop Godot4.6.3 Mobile software Vulkan; ordinary generated encounter; simulation advanced at20fps for capture, not measured phone performance", "renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"frames":frame_index,"states":states,"saw_surge":saw_surge,"capture_rows":phase_rows,"source_hashes":source_hashes}
	for path: String in source_hashes:
		assert(source_hashes[path] == FileAccess.get_sha256(path), "Runtime source changed during capture: " + path)
	var file := FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")+"\n")
	file.close()
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	for frame: int in 6: await process_frame
	print("OBSERVATION_CAPTURE_COMPLETE frames=",frame_index," states=",states," surge=",saw_surge)
	quit(0)
func tick(seconds: float) -> void:
	var left: float = seconds
	while left > 0.00001:
		var delta: float = minf(left,0.025)
		if not app.scenery._suspended:
			app.scenery._animator.advance(delta)
			if app.scenery._fish_animator:
				app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				app.scenery._fish_animator.advance(delta)
		app.scenery._process(delta)
		app._process(delta)
		left -= delta
