extends SceneTree
## Main travel transaction boundaries. This does not override the 44-model gate
## or claim full gameplay: it may run during partial asset production.
const Main = preload("res://scripts/main.gd")
const Store = preload("res://scripts/save_store.gd")
const Registry = preload("res://scripts/fish_3d_registry.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Encounter = preload("res://scripts/encounter.gd")

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: bool = false
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if fail_once and path.ends_with("save.tmp.json"):
			fail_once = false
			return false
		return super._write_verified_json(path, value)

class RejectingScene extends Node3D:
	var calls: int = 0
	func set_location(_region: String, _spot: String) -> bool:
		calls += 1
		return false

var checks: int = 0
var failures: int = 0
var app: Control
var fixture: FailingStore

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL MAIN TRAVEL: ",label)

func _run() -> void:
	var data: String = OS.get_environment("XDG_DATA_HOME")
	if not data.begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(data+"/"):
		printerr("MAIN_TRAVEL_TESTS: refusing non-isolated XDG_DATA_HOME")
		quit(2)
		return
	root.size = Vector2i(720,1280)
	app = Main.new()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	await process_frame
	fixture = FailingStore.new()
	_check(fixture.initialize(data.path_join("travel-fixture")),"isolated save fixture initializes")
	var setup: Dictionary = fixture.state
	setup.gear = 4
	setup.owned_gear = [0,1,2,3,4]
	setup.unlocked_regions = ["lake","japan","norway","med","bayou","yangtze"]
	_check(fixture.commit_state(setup),"fixture explicitly unlocks travel without fabricating catches")
	app.store = fixture
	_check(app._models_complete == Registry.validate_catalog(app.catalog,true).is_empty(),"readiness remains the real strict44 asset result")
	app._show_travel()
	var before: Dictionary = fixture.state
	var old_region: String = app.region_id
	var old_spot: String = app.spot_id
	var old_place: String = app._place.text
	var old_label: String = app._spot_label.text
	var live_stage: Node3D = app.scenery
	var old_root: Node3D = live_stage._environment_root
	var rejecting: RejectingScene = RejectingScene.new()
	app.scenery = rejecting
	_check(not app._refresh_location(),"refresh reports rejected scene load")
	_check(app._place.text == old_place and app._spot_label.text == old_label,"rejected refresh preserves displayed region and spot")
	app._choose_spot("japan","japan_harbor")
	_check(rejecting.calls == 2,"travel checks the scene before saving")
	_check(fixture.state == before and app.region_id == old_region and app.spot_id == old_spot,"rejected scene leaves entire save and live selection unchanged")
	_check(app._screen == "travel" and app._place.text == old_place and app._spot_label.text == old_label,"rejected scene does not claim destination or close travel")
	_check(live_stage._environment_root == old_root,"rejected scene does not disturb current real biome")
	app.scenery = live_stage
	rejecting.free()
	fixture.fail_once = true
	app._choose_spot("japan","japan_harbor")
	_check(fixture.state == before,"scene accepted but failed save preserves complete saved state")
	_check(app.region_id == old_region and app.spot_id == old_spot and live_stage.region_id == old_region and live_stage.spot_id == old_spot,"failed travel save restores Main and actual stage location")
	_check(app._place.text == old_place and app._spot_label.text == old_label and app._screen == "travel","failed save retains old location labels and travel retry page")
	app._choose_spot("japan","japan_harbor")
	_check(app.region_id == "japan" and app.spot_id == "japan_harbor" and live_stage.region_id == "japan" and live_stage.spot_id == "japan_harbor","travel retry changes Main and scene together")
	_check(str(fixture.state.selection.spot_id) == "japan_harbor" and int(fixture.state.save_revision) == int(before.save_revision)+1,"travel retry persists exactly once")
	_check(app._place.text == str(app.catalog.region("japan").name) and app._spot_label.text == str(app.catalog.spots.japan_harbor.name),"successful travel labels match actual loaded biome")
	var restart: SaveStore = Store.new()
	_check(restart.initialize(data.path_join("travel-fixture")) and restart.state.selection == fixture.state.selection,"only successful travel selection survives disk restart")
	app._show_travel()
	before = fixture.state
	old_root = live_stage._environment_root
	app.session.reset()
	app.session.press()
	app._choose_spot("lake","lake_shore")
	_check(fixture.state == before and live_stage._environment_root == old_root and app._screen == "pause","active charging travel is rejected before a scene or save change")
	app.session.reset()
	var record: Dictionary = Encounter.new(445).make_individual(app.catalog.fish.common_carp,"japan_harbor","japan","worm",4,"day","clear")
	# Synthetic boundary fixture, never settled or counted as an actual catch.
	record.catch_id = "guard-fixture"
	record.session_id = "guard-fixture"
	app._last_record = record
	app._landing_pending = true
	app._save_ok = false
	app.session.set_state(Session.State.CAUGHT)
	app._choose_spot("lake","lake_shore")
	_check(fixture.state == before and live_stage._environment_root == old_root and app.spot_id == "japan_harbor","queued CAUGHT travel cannot change scene or save during landing")
	_check(app._landing_pending and app._last_record == record and app._screen == "pause","landing travel keeps exact unresolved record and presentation gate")
	app._landing_pending = false
	app._choose_spot("lake","lake_shore")
	_check(fixture.state == before and live_stage._environment_root == old_root and app.spot_id == "japan_harbor","queued travel cannot change scene or save while result is unresolved")
	_check(app._screen == "result" and app._last_record == record and not app._save_ok,"rejected unresolved-result travel exposes the same retry result")
	app.session.reset()
	app._choose_spot("lake","lake_shore")
	_check(fixture.state == before and live_stage._environment_root == old_root and app._last_record == record,"unresolved record blocks stale travel even when Session has reset to IDLE")
	app._last_record = {}
	app._save_ok = true
	app._result_waiting = false
	app._show_travel()
	app._choose_spot("lake","lake_shore")
	_check(app.spot_id == "lake_shore" and live_stage.spot_id == "lake_shore" and str(fixture.state.selection.spot_id) == "lake_shore","resolved boundary permits ordinary travel again")
	_check(fixture.total_count() == 0,"guard fixtures never fabricate earned catch statistics")
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	await process_frame
	await process_frame
	print("MAIN_TRAVEL_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; boundary tests only, no readiness override")
	quit(0 if failures == 0 else 1)
