extends SceneTree
## Real Main/Session/Stage screenshots with a disposable QA save, never player data.
const MainScene = preload("res://scenes/main.tscn")
var app: Control
var output: String
var rows: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	assert(OS.get_user_data_dir().begins_with(OS.get_environment("XDG_DATA_HOME") + "/"))
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	output = OS.get_environment("FARSHORE_REVISION_CAPTURE")
	assert(not output.is_empty())
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(720,1280)
	app = MainScene.instantiate()
	root.add_child(app)
	var deadline: int = Time.get_ticks_msec() + 120000
	while not app._startup_complete and Time.get_ticks_msec() < deadline: await process_frame
	assert(app._startup_complete and app._content_ok)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	var fixture: Dictionary = app.store.state
	fixture.gear = 5
	fixture.owned_gear = [0,1,2,3,4,5]
	fixture.unlocked_regions = []
	for region: Dictionary in app.catalog.regions: fixture.unlocked_regions.append(region.region_id)
	assert(app.store.commit_state(fixture))
	app._refresh_location()
	await capture("lobby")
	for route: String in ["travel","gear","catalog","settings"]:
		app.call("_show_"+route)
		await capture(route)
	app._show_species("common_carp")
	await capture("species")
	var spots: Array=["yangtze_river","yangtze_estuary"]
	if "--all-spots" in OS.get_cmdline_user_args(): spots=app.catalog.spots.keys()
	for sid: String in spots:
		var rid: String=str(app.catalog.spots[sid].region_id)
		app.session.reset()
		app._show_travel()
		app._choose_spot(rid,sid)
		app._show_prepare()
		app._enter_fishery()
		assert(app.scenery.spot_id == sid and app._mode == "fishing")
		tick(3.0)
		await capture(sid+"_ready")
		for charge: float in [0.0,0.5,1.0]:
			app.session.reset()
			app.session.set_seed(63193)
			var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"],sid,rid,"worm",5,"day","clear")
			app.encounter.apply_float_presentation(record,app.catalog,charge)
			app.session.start_charge()
			app.session.charge=charge
			assert(app.session.cast(record,app.catalog.gear[5]))
			tick(2.5)
			await capture(sid+"_cast_"+str(int(charge*100)))
			if charge==0.5:
				root.size=Vector2i(720,1584)
				await capture(sid+"_tall")
				root.size=Vector2i(720,1280)
	app.session.reset()
	app._show_lobby_exit()
	await capture("confirmation")
	var file := FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"scope":"macOS real game rendering; isolated synthetic QA save; not Android device acceptance", "main_sha256":FileAccess.get_sha256("res://scripts/main.gd"),"stage_sha256":FileAccess.get_sha256("res://scripts/fishing_stage_3d.gd"),"rows":rows},"\t")+"\n")
	file.close()
	app.queue_free()
	for i: int in 6: await process_frame
	print("UI_WATER_CAPTURE_COMPLETE ",output)
	quit()
func tick(seconds: float) -> void:
	for i: int in int(ceil(seconds*120.0)):
		app._process(1.0/120.0)
		app.scenery._animator.advance(1.0/120.0)
		app.scenery._process(1.0/120.0)
func capture(label: String) -> void:
	for i: int in 12: await process_frame
	await RenderingServer.frame_post_draw
	var path: String=output.path_join(label+".png")
	assert(root.get_texture().get_image().save_png(path)==OK)
	rows.append({"image":label+".png","size":str(root.size),"spot":app.scenery.spot_id,"presentation":app.scenery.presentation_state,"target":str(app.scenery._bobber_target),"camera":str(app.scenery.camera.position),"region_target":str(app.scenery._station_frame()*app.scenery._bobber_target)})
	print("CAPTURE ",label)
