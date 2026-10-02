extends Node
# Development-only visual harness. Excluded from the Android release.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
var app: Control
var output: String
func _ready() -> void:
	get_window().size=Vector2i(720,1280)
	output = ProjectSettings.globalize_path("res://../docs/screenshots")
	DirAccess.make_dir_recursive_absolute(output)
	app = Main.instantiate()
	add_child(app)
	await get_tree().process_frame
	app._close_page()
	app.session.reset()
	await capture("lake_playable")
	var isolated: SaveStore = Store.new()
	assert(isolated.initialize(ProjectSettings.globalize_path("res://../build/visual-save-"+str(Time.get_ticks_usec()))), isolated.error_message)
	app.store = isolated
	for index: int in range(app.catalog.fish.size()):
		var species: FishDefinition = app.catalog.fish.values()[index]
		var sid: String = str(species.spots()[0])
		var rid: String = str(app.catalog.spots[sid].region_id)
		var record: Dictionary = app.encounter.make_individual(species,sid,rid,"shrimp",2,"day","clear")
		record["session_id"]="visual_%d"%index
		record["catch_id"]="visual_%d_catch"%index
		isolated.begin_session(record.session_id)
		var settled: Dictionary = isolated.settle_catch(record)
		if not settled.ok:
			push_error("VISUAL_FIXTURE_FAILED "+str(settled))
			return
		assert(isolated.dispose_catch(record.catch_id,"released").ok)
	var state: Dictionary=isolated.state.duplicate(true)
	state["gear"]=2
	state["owned_gear"]=[0,1,2]
	state["unlocked_regions"]=["lake","japan","norway","med","bayou","yangtze"]
	state["favorites"]=["common_carp","olive_flounder","atlantic_cod","atlantic_wolffish","painted_comber","gilthead_seabream"]
	assert(isolated.commit_state(state),isolated.error_message)
	for sid: String in app.catalog.spots:
		app.region_id=str(app.catalog.spots[sid].region_id)
		app.spot_id=sid
		app._refresh_location()
		await capture(sid)
	app._show_catalog()
	await capture("catalog_discovered")
	app._show_species("atlantic_wolffish")
	await capture("species_detail")
	app._show_zoom("olive_flounder")
	await capture("fish_zoom")
	app._show_favorites()
	await capture("favorites")
	app._show_travel()
	await capture("travel")
	app._show_gear()
	await capture("gear")
	app._show_settings()
	await capture("settings")
	app._close_page()
	app.session.reset()
	app.region_id="lake"
	app.spot_id="lake_shore"
	app._refresh_location()
	app.session.start_charge()
	var fish: Dictionary=app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","grain",2,"day","clear")
	app.session.cast(fish,app.catalog.gear[2])
	isolated.begin_session(app.session.session_id)
	app.session.set_state(FishingSession.State.BITE)
	await capture("bite")
	app.session.press()
	app.session.tension=0.67
	app.session.progress=0.47
	await capture("fight")
	app.session._finish(true,"")
	await capture("catch_result")
	app._dispose_result("released")
	app._show_species("alligator_gar")
	await capture("alligator_gar_detail")
	app._show_species("chinese_sturgeon")
	await capture("chinese_sturgeon_detail")
	await capture_specimen("alligator_gar","alligator_gar_catch")
	await capture_specimen("chinese_sturgeon","chinese_sturgeon_release")
	print("VISUAL_AUDIT_COMPLETE ",output)
	app.sound.suspend(true)
func capture(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var picture: Image=get_viewport().get_texture().get_image()
	assert(picture.save_png(output.path_join(label+".png"))==OK)
	print("VISUAL_CAPTURE ",label," ",picture.get_width(),"x",picture.get_height())

func capture_specimen(id: String,label: String) -> void:
	if not app._last_record.is_empty(): app._dispose_result("released")
	app._close_page()
	app.session.reset()
	var species: FishDefinition=app.catalog.fish[id]
	app.spot_id=str(species.spots()[0])
	app.region_id=str(app.catalog.spots[app.spot_id].region_id)
	app._refresh_location()
	app.session.start_charge()
	var fish: Dictionary=app.encounter.make_individual(species,app.spot_id,app.region_id,"lure",2,"day","clear")
	app.session.cast(fish,app.catalog.gear[2])
	app.store.begin_session(app.session.session_id)
	app.session.set_state(FishingSession.State.FIGHT)
	app.session._finish(true,"")
	await capture(label)
