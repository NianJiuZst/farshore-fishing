extends "res://tests/slice3d_tests.gd"
## Four actual production Main frames. Only region/rod ownership is seeded;
## the catch is generated and fought through ordinary full-world gameplay.
var capture_output: String
var capture_rows: Array[Dictionary] = []

func _run() -> void:
	var data: String = OS.get_environment("XDG_DATA_HOME")
	if not data.begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(data+"/"):
		printerr("Refusing non-isolated capture")
		quit(2)
		return
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
	capture_output = ProjectSettings.globalize_path("res://../build/qa3d/main-capture-%s-%s" % [OS.get_process_id(),Time.get_ticks_usec()])
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): capture_output=argument.trim_prefix("--output=")
	if DirAccess.dir_exists_absolute(capture_output):
		printerr("Capture refuses to overwrite an existing evidence directory: ",capture_output)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(capture_output)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	print("EVIDENCE_SCOPE: actual Main; isolated save with Norway/rod ownership seeded; ordinary generated encounter and balanced fight; no trial target, readiness override or fake scene")
	print("ACTUAL_RENDERER ",RenderingServer.get_current_rendering_method()," | ",RenderingServer.get_video_adapter_name()," | ",RenderingServer.get_video_adapter_api_version())
	print("VERSION ",ProjectSettings.get_setting("application/config/version")," MODEL_READINESS complete=",app._models_complete," errors=",app._model_errors.size()," ROOT_MSAA=",root.msaa_3d," physical=",root.size," logical=",app.size)
	_check(root.msaa_3d==Viewport.MSAA_4X and app.size==Vector2(root.size),"actual capture fills requested aspect with native4x MSAA")
	_check(app._models_complete and app._content_ok and Registry.validate_catalog(app.catalog,true).is_empty(),"actual strict44 readiness is complete")
	if failures > 0:
		quit(1)
		return
	if "--first-run" in OS.get_cmdline_user_args():
		_check(app.store.total_count()==0 and app.store.discovered_count()==0 and app.region_id=="lake" and app.spot_id=="lake_shore" and int(app.store.state.gear)==0,"genuine new-player defaults, no seeded ownership or catches")
		var default_start: Button = _find_button(app._overlay,"开始钓鱼")
		_check(default_start!=null and not default_start.disabled and not app._action.is_visible_in_tree(),"default lobby enables Start without a cast action")
		_tick(2.0)
		await _capture_frame("01_first_run_lake_lobby","Genuine first-run lake lobby, empty isolated save, no unlock or gear fixture")
		default_start=null
		_write_capture_evidence({}, {}, true)
		await _end_capture()
		return
	var fixture: SaveStore = Store.new()
	test_root = data.path_join("main-norway-capture")
	_check(fixture.initialize(test_root),"isolated fixture initializes")
	var setup: Dictionary = fixture.state
	setup.gear = 4
	setup.owned_gear = [0,4]
	setup.unlocked_regions = ["lake","norway"]
	_check(fixture.commit_state(setup) and fixture.total_count()==0,"only ownership/travel seeded; zero catch records")
	app.store = fixture
	var recipe: Dictionary = _find_recipe("atlantic_cod","norway_boat")
	_check(not recipe.is_empty() and int(recipe.gear)==4,"ordinary cod route exists with selected heavy rod")
	app._show_travel()
	app._choose_spot(str(recipe.region),str(recipe.spot))
	app._show_home()
	_tick(2.0)
	var start: Button = _find_button(app._overlay,"开始钓鱼")
	_check(app._mode=="lobby" and not app._action.is_visible_in_tree() and start!=null and not start.disabled,"real no-Cast lobby has enabled Start")
	await _capture_frame("01_lobby_norway_start_enabled","Actual Norway lobby, Start enabled, no visible cast action")
	start.pressed.emit()
	var enter: Button = _find_button(app._overlay,"进入钓点")
	_check(enter!=null and not enter.disabled,"actual preparation entry is enabled")
	enter.pressed.emit()
	app.game_clock = 0.0
	app._update_conditions()
	app.encounter = Encounter.new(int(recipe.seed))
	app.session._rng.seed = 2468
	app._action_down()
	_tick(float(recipe.charge)/0.48)
	app._action_up()
	_check(app.session.state==Session.State.CASTING and str(app.session.individual.get("species_id",""))=="atlantic_cod","ordinary Main cast generated Atlantic cod")
	print("ORDINARY_ENCOUNTER_RECIPE ",JSON.stringify(recipe))
	_tick(1.25)
	_check(app.scenery.cast_in_progress and app.session.state==Session.State.CASTING,"capture remains inside full animated cast")
	await _capture_frame("02_actual_cast_over_shoulder","Actual charged cast and over-shoulder Norway fishing HUD")
	for tick: int in 1200:
		if app.session.state==Session.State.BITE: break
		_tick(0.025)
	_check(app.session.state==Session.State.BITE,"ordinary wait/nibble reaches bite")
	app._action_down()
	app._action_up()
	for tick: int in 3000:
		if app.session.state!=Session.State.FIGHT: break
		if app.session.tension<0.46: app._action_down()
		elif app.session.tension>0.58: app._action_up()
		_tick(0.025)
	_check(app.session.state==Session.State.CAUGHT and app._landing_pending and app._save_ok and fixture.total_count()==1,"real balanced fight settles one catch before landing")
	_tick(0.80)
	_check(app._landing_pending and app.scenery._fish_root.position.y>0,"actual fish is breaching above water")
	await _capture_frame("03_actual_cod_breach","Real cod breach/lift after normal fight, durable save before result")
	_tick(3.30)
	_check(app._screen=="result" and not app._landing_pending,"actual landing completion reveals production3D result/ruler")
	await _capture_frame("04_actual_cod_result_ruler","Production cod result with animated3D specimen and projected physical ruler")
	var record: Dictionary = app._last_record.duplicate(true)
	app._dispose_result("released")
	_check(fixture.total_count()==1 and fixture.state.pending_catches.is_empty(),"isolated capture catch resolves without duplicate reward")
	fixture = null
	start = null
	enter = null
	_write_capture_evidence(recipe,record,false)
	await _end_capture()

func _write_capture_evidence(recipe: Dictionary, record: Dictionary, first_run: bool) -> void:
	var evidence: Dictionary = {"scope":"Genuine empty first-run save" if first_run else "Actual Main, isolated travel/rod fixture; catch generated by ordinary Encounter and completed FishingSession; not a user catch", "hardware_scope":"Desktop Mobile/Vulkan only, no Android/device identity or FPS certification", "version":ProjectSettings.get_setting("application/config/version"),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"api":RenderingServer.get_video_adapter_api_version(),"main_msaa":root.msaa_3d,"physical_window":str(root.size),"logical_viewport":str(app.size),"aspect":ProjectSettings.get_setting("display/window/stretch/aspect"),"models_complete":app._models_complete,"recipe":recipe,"catch":record,"frames":capture_rows,"checks":checks,"failures":failures,"runtime_hashes":{}}
	for path: String in ["res://project.godot","res://scripts/main.gd","res://scripts/fishing_stage_3d.gd","res://assets/3d/atlantic_cod.glb"]: evidence.runtime_hashes[path]=FileAccess.get_sha256(path)
	var file: FileAccess = FileAccess.open(capture_output.path_join("evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")+"\n")
	file.close()
	file = null

func _end_capture() -> void:
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	app = null
	await process_frame
	await process_frame
	print("FULL44_MAIN_CAPTURE: ",checks-failures,"/",checks," passed; failures=",failures,"; frames=",capture_rows.size(),"; output=",capture_output)
	call_deferred("quit",0 if failures==0 else 1)

func _capture_frame(label: String, description: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = capture_output.path_join(label+".png")
	_check(picture.save_png(path)==OK,"actual framebuffer saved: "+label)
	capture_rows.append({"file":label+".png","description":description,"width":picture.get_width(),"height":picture.get_height(),"mode":app._mode,"screen":app._screen,"region":app.region_id,"spot":app.spot_id,"session_state":app.session.state})
	print("CAPTURE ",label," ",picture.get_width(),"x",picture.get_height()," scene=",app.scenery.region_id,"/",app.scenery.spot_id)
