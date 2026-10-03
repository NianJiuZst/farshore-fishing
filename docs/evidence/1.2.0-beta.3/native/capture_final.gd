extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
var app: Control
var out: String
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	root.size=Vector2i(720,1280 if "--short" in OS.get_cmdline_user_args() else 1584)
	out=ProjectSettings.globalize_path("res://../build/beta3-final-native/screens" if "--short" in OS.get_cmdline_user_args() else "res://../build/beta3-final-native/screens-tall")
	DirAccess.make_dir_recursive_absolute(out)
	app=Main.instantiate()
	root.add_child(app)
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	await capture("home_zero")
	app._show_prepare()
	await capture("prepare_zero")
	app._show_travel()
	await capture("travel_zero")
	app._show_gear()
	await capture("gear_zero")
	app._scroll_to_section("BaitSection")
	await capture("gear_baits")
	app._show_catalog()
	await capture("catalog_zero")
	var tile: Control=app._list.get_child(0)
	var art: Control=tile.get_child(0).get_child(0).get_child(0)
	await touch(art.get_global_rect().get_center())
	print("INPUT_AFTER touch_image screen=",app._screen)
	assert(app._screen=="species")
	app._handle_back()
	await process_frame
	await process_frame
	assert(app._screen=="catalog")
	tile=app._list.get_child(0)
	art=tile.get_child(0).get_child(0).get_child(0)
	await create_timer(0.25).timeout
	await mouse(art.get_global_rect().get_center())
	print("INPUT_AFTER mouse_image screen=",app._screen)
	assert(app._screen=="species")
	await capture("species_zero")
	app._show_favorites()
	await capture("favorites_zero")
	app._show_settings()
	await capture("settings")
	app._show_about()
	await capture("about")
	app._show_home()
	app._enter_fishery()
	await capture("hud_idle")
	var fixture: SaveStore=Store.new()
	assert(fixture.initialize(OS.get_environment("XDG_DATA_HOME").path_join("ui-audit-fixture")))
	app.store=fixture
	for i: int in range(3):
		var fish: Dictionary=app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","grain",2,"day","clear")
		fish["session_id"]="audit_%d"%i
		fish["catch_id"]="audit_%d_catch"%i
		fish["length_mm"]=[650,550,600][i]
		fish["weight_g"]=[3800,4400,4100][i]
		fixture.begin_session(fish.session_id)
		assert(fixture.settle_catch(fish).ok)
		assert(fixture.dispose_catch(fish.catch_id,"released").ok)
	var stats: Dictionary=fixture.state.species_stats.common_carp
	print("STATS_BASELINE count=",stats.catch_count," max_length_id=",stats.max_length.catch_id," max_weight_id=",stats.max_weight.catch_id," first_id=",stats.first.catch_id," last_id=",stats.last.catch_id)
	app._show_species("common_carp")
	await capture("species_known")
	var scroll: ScrollContainer=app._overlay.find_child("PageScroll",true,false)
	scroll.scroll_vertical=2000
	await capture("species_known_records")
	var state: Dictionary=fixture.state.duplicate(true)
	state.favorites=["common_carp"]
	assert(fixture.commit_state(state))
	app._show_favorites()
	await capture("favorites_known")
	app._open_fish_details("common_carp")
	app._show_zoom("common_carp")
	app._handle_back()
	assert(app._screen=="species")
	app._handle_back()
	assert(app._screen=="favorites")
	print("BACK_AFTER favorites_species_zoom_chain=PASS")
	app._show_catalog()
	await capture("catalog_known")
	app._show_home()
	app._enter_fishery()
	app.session.start_charge()
	var record: Dictionary=app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","grain",2,"day","clear")
	app.session.cast(record,app.catalog.gear[2])
	fixture.begin_session(app.session.session_id)
	app.session.set_state(FishingSession.State.BITE)
	app.session._finish(false,"空竿收回，鱼还没有咬牢。下次再多观察一会儿浮漂")
	await create_timer(0.3).timeout
	await capture("empty_cast")
	app._finish_result()
	app.session.start_charge()
	record=app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","grain",2,"day","clear")
	app.session.cast(record,app.catalog.gear[2])
	fixture.begin_session(app.session.session_id)
	app.session.set_state(FishingSession.State.FIGHT)
	app.session.tension=0.67
	app.session.progress=0.47
	await capture("hud_fight")
	app.session._finish(true,"")
	app._landing_pending=false
	app.scenery.cancel_landing()
	app._show_result()
	await capture("result")
	app._dispose_result("released")
	await capture_extra_results()
	app._show_pause()
	await capture("pause")
	app._show_settings()
	app._toggle_setting("sound")
	app._show_about()
	app._handle_back()
	assert(app._screen=="settings")
	app._handle_back()
	print("SETTINGS_BACK_AFTER toggle_about_back=",app._screen)
	assert(app._screen=="pause")
	app._show_home()
	app._show_lobby_exit()
	await create_timer(0.3).timeout
	await capture("lobby_exit")
	app._show_home()
	root.size=Vector2i(720,1584)
	await capture("home_tall_final")
	app._show_lobby_exit()
	await create_timer(0.3).timeout
	await capture("lobby_exit_tall_final")
	app.sound.suspend(true)
	app.fish_art._textures.clear()
	app.queue_free()
	app=null
	for f: int in range(4): await process_frame
	print("BETA3_AFTER_COMPLETE ",out)
	call_deferred("quit")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(out.path_join(label+".png"))==OK)
	print("CAPTURE ",label)
func touch(point: Vector2) -> void:
	for down: bool in [true,false]:
		var e: InputEventScreenTouch=InputEventScreenTouch.new()
		e.position=point
		e.pressed=down
		root.push_input(e,true)
		await process_frame
	await process_frame
func mouse(point: Vector2) -> void:
	for down: bool in [true,false]:
		var e: InputEventMouseButton=InputEventMouseButton.new()
		e.position=point
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=down
		root.push_input(e,true)
		await process_frame
	await process_frame

func capture_extra_results() -> void:
	var fish: FishDefinition=app.catalog.fish["chinese_sturgeon"]
	var sid: String=str(fish.spots()[0])
	var rid: String=str(app.catalog.spots[sid].region_id)
	var record: Dictionary=app.encounter.make_individual(fish,sid,rid,"worm",4,"day","clear")
	record["session_id"]="ui_audit_protected"
	record["catch_id"]="ui_audit_protected_catch"
	app.store.begin_session(record.session_id)
	app._last_settlement=app.store.settle_catch(record)
	assert(app._last_settlement.ok)
	app._last_record=record
	app._save_ok=true
	app._landing_pending=false
	app._show_result()
	await capture("result_protected")
	var sc: ScrollContainer=app._overlay.find_child("PageScroll",true,false)
	sc.scroll_vertical=9999
	await capture("result_protected_actions")
	app._dispose_result("released")
	record=app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","grain",2,"day","clear")
	app._last_record=record
	app._last_settlement={"error":"截图专用：保存失败状态"}
	app._save_ok=false
	app._show_result()
	await capture("result_save_error")
	app._last_record={}
	app._save_ok=true
	app._finish_result()
