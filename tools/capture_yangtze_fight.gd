extends SceneTree
const MainScene=preload("res://scenes/main.tscn")
const Controller=preload("res://tests/fishing_test_controller.gd")
var app: Control
var output: String
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	output=OS.get_environment("FARSHORE_REVISION_CAPTURE")
	root.size=Vector2i(720,1280)
	app=MainScene.instantiate()
	root.add_child(app)
	while not app._startup_complete: await process_frame
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	var fixture: Dictionary=app.store.state
	fixture.gear=2
	fixture.owned_gear=[0,1,2]
	assert(app.store.commit_state(fixture))
	app._show_travel()
	app._choose_spot("yangtze","yangtze_river")
	app._show_prepare()
	app._enter_fishery()
	tick(3.0)
	app.encounter.rng.seed=63193
	var record: Dictionary=app.encounter.make_individual(app.catalog.fish["common_carp"],"yangtze_river","yangtze","worm",2,"day","clear")
	app.session.set_seed(2)
	app.session.start_charge()
	app.session.charge=0.65
	assert(app.session.cast(record,app.catalog.gear[2]))
	app.store.begin_session(app.session.session_id)
	tick(2.4)
	var held: float=0.0
	for step: int in 2400:
		if app.session.float_dip>0.6 or app.session.float_lift>0.6: held+=0.025
		else: held=0.0
		if held>=0.25:
			app._action_down()
			app._action_up()
			break
		tick(0.025)
	assert(app.session.state==FishingSession.State.FIGHT)
	var controller=Controller.new()
	var captured: Dictionary={}
	for step: int in 4800:
		if app.session.state!=FishingSession.State.FIGHT: break
		if controller.update(app.session,0.025): app._action_down()
		else: app._action_up()
		tick(0.025)
		for progress: float in [0.1,0.5,0.85,0.95]:
			if app.session.progress>=progress and not captured.has(progress):
				captured[progress]=true
				await capture("yangtze_river_fight_"+str(int(progress*100)))
	print("ACTUAL_FIGHT outcome=",app.session.state," progress=",app.session.progress," captures=",captured)
	app.queue_free()
	for i: int in 5: await process_frame
	quit(0 if captured.size()==4 else 1)
func tick(seconds: float) -> void:
	for i: int in int(ceil(seconds*120.0)):
		app.scenery._animator.advance(1.0/120.0)
		app._process(1.0/120.0)
		app.scenery._process(1.0/120.0)
func capture(label: String) -> void:
	for i: int in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label+".png"))==OK)
	print("ACTUAL_FIGHT_CAPTURE ",label," progress=",app.session.progress," bobber=",app.scenery._bobber.position)
