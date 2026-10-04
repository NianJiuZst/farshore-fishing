extends SceneTree
## Actual failure dismissal and successful catch disposition followed by short
## charging gestures. Uses isolated saves; does not force BITE/CAUGHT states.
const MainScene = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/fishing_session.gd")
const Controller = preload("res://tests/fishing_test_controller.gd")
var app: Control
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	root.size = Vector2i(720,1280)
	app = MainScene.instantiate()
	root.add_child(app)
	# Native Main startup yields between loading stages; wait for its real completion.
	var startup_deadline: int = Time.get_ticks_msec() + 120000
	while not app._startup_complete and Time.get_ticks_msec() < startup_deadline:
		await process_frame
	if not app._startup_complete:
		check(false, "Main startup timed out before _startup_complete")
		quit(1)
		return
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app._show_prepare()
	app._enter_fishery()
	tick(3.0)
	app._action_down()
	tick(1.0)
	app._action_up()
	tick(2.4)
	for charge_seconds: float in [0.05,0.15]:
		assert(app.session.state == Session.State.WAITING)
		app._action_down()
		app._action_up()
		assert(app._screen == "escape")
		app._overlay.dismiss_requested.emit()
		assert(app.session.state == Session.State.IDLE and app._overlay == null)
		app._action_down()
		tick(charge_seconds)
		app._action_up()
		assert(app.scenery.cast_in_progress)
		probe("failure-dismiss charge="+str(charge_seconds))
		tick(0.8)
		probe("failure-dismiss windup0.8 charge="+str(charge_seconds))
		tick(1.6)
	# Generate a genuine successful catch, then use its normal result action.
	app._action_down()
	app._action_up()
	app._overlay.dismiss_requested.emit()
	app.session.set_seed(2)
	app.encounter.rng.seed = 63193
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","worm",2,"day","clear")
	app.session.start_charge()
	app.session.charge = 0.65
	app.session.cast(record,app.catalog.gear[2])
	app.store.begin_session(app.session.session_id)
	tick(2.3)
	var held: float = 0.0
	for step: int in 60*40:
		if app.session.float_dip > 0.60 or app.session.float_lift > 0.60: held += 0.025
		else: held = 0.0
		if held >= 0.25:
			app._action_down()
			app._action_up()
			break
		tick(0.025)
	assert(app.session.state == Session.State.FIGHT)
	var controller = Controller.new()
	for step: int in 120*40:
		if app.session.state != Session.State.FIGHT: break
		if controller.update(app.session,0.025): app._action_down()
		else: app._action_up()
		tick(0.025)
	assert(app.session.state == Session.State.CAUGHT)
	tick(3.5)
	assert(app._screen == "result")
	app._dispose_result("released")
	assert(app.session.state == Session.State.IDLE and app._overlay == null)
	app._action_down()
	tick(0.05)
	app._action_up()
	assert(app.scenery.cast_in_progress)
	probe("catch-result dispose/recast charge=0.05")
	tick(0.8)
	probe("catch-result windup0.8 charge=0.05")
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	await process_frame
	print("FAST_RECAST_CAMERA_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; actual Main flow, desktop geometry projection")
	quit(0 if failures == 0 else 1)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FAST_RECAST_CAMERA: ",label)
func probe(label: String) -> void:
	var torso: Vector3 = app.scenery._angler.to_global(Vector3(0,1.15,0))
	var camera: Camera3D = app.scenery.camera
	var point: Vector2 = camera.unproject_position(torso)
	var visible: bool = not camera.is_position_behind(torso) and Rect2(Vector2.ZERO,root.get_visible_rect().size).has_point(point)
	check(visible,label+": angler torso is visible throughout windup")
	check(camera.position.is_equal_approx(app.scenery.FISHING_CAMERA_POSITION),label+": cast starts from the standard fishing camera")
	print("RECAST_PROBE ",label," torso_visible=",visible," behind=",camera.is_position_behind(torso)," screen=",point," camera=",camera.position," origin=",app.scenery._cast_camera_origin)
func tick(seconds: float) -> void:
	var left: float = seconds
	while left > 0.000001:
		var delta: float = minf(left,1.0/120.0)
		if not app.scenery._suspended:
			app.scenery._animator.advance(delta)
			if app.scenery._fish_animator:
				app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				app.scenery._fish_animator.advance(delta)
		app._process(delta)
		app.scenery._process(delta)
		left -= delta
