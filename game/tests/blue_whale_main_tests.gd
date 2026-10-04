extends SceneTree
## Exercise production Main, its strict asset gate and real transactions using
## an injected Store whose initialization can only target this /tmp fixture.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const Challenge = preload("res://scripts/blue_whale_challenge.gd")
const Session = preload("res://scripts/fishing_session.gd")

class FixtureStore extends "res://scripts/save_store.gd":
	var fixture_root: String = ""
	var initialize_calls: int = 0
	var fail_once: bool = false
	func initialize(_unused_root: String = "user://") -> bool:
		initialize_calls += 1
		if not fixture_root.begins_with("/tmp/farshore-whale-main-"):
			return _fail("Main regression requires an explicit /tmp fixture")
		return super.initialize(fixture_root)
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if fail_once and path.ends_with("/save.tmp.json"):
			fail_once = false
			return _fail("Synthetic whale Main save failure")
		return super._write_verified_json(path,value)

var app: Control
var fixture: FixtureStore
var checks: int = 0
var failures: int = 0
var original: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL WHALE MAIN: ",label)

func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left,"",true,true)) == JSON.parse_string(JSON.stringify(right,"",true,true))

func _button(name: String, node: Node) -> Button:
	if node is Button and node.name == name: return node as Button
	for child: Node in node.get_children():
		var found: Button = _button(name,child)
		if found != null: return found
	return null

func _contains(node: Node, text: String) -> bool:
	if node == null: return false
	if node is Label and text in node.text: return true
	for child: Node in node.get_children():
		if _contains(child,text): return true
	return false

func _has_sale_action(node: Node) -> bool:
	if node is Button and ("出售" in node.text or "放生" in node.text): return true
	for child: Node in node.get_children():
		if _has_sale_action(child): return true
	return false

func _seed_legacy() -> void:
	fixture = FixtureStore.new()
	fixture.fixture_root = "/tmp/farshore-whale-main-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(fixture.fixture_root) == OK,"explicit isolated Main save fixture created")
	var state: Dictionary = Store.default_state()
	state.erase("whale_challenge")
	state.currency = 2731
	state.gear = 4
	state.owned_gear = [0,2,4]
	state.unlocked_regions = ["lake","japan","norway","med","bayou","yangtze","pacific_ocean","atlantic_ocean","indian_ocean"]
	state.selection = {"region_id":"pacific_ocean","spot_id":"pacific_bluewater","bait_id":"shrimp"}
	state.game_clock = 812.0
	state.settings = {"sound":false,"vibration":false,"volume":0.0,"reduce_motion":true,"custom_future_setting":"preserved"}
	state.favorites = ["common_carp","atlantic_bluefin_tuna"]
	var frozen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/ocean_diversity_legacy_1_3_0.json"))
	for row: Dictionary in frozen.legacy_species:
		var id: String = str(row.species_id)
		var snapshot: Dictionary = {"species_id":id,"length_mm":350,"weight_g":500}
		state.species_stats[id] = {"catch_count":2,"first":snapshot.duplicate(true),"last":snapshot.duplicate(true),"max_length":snapshot.duplicate(true),"max_weight":snapshot.duplicate(true),"regions":{"lake":2}}
	var file: FileAccess = FileAccess.open(fixture.fixture_root.path_join(Store.PRIMARY_NAME),FileAccess.WRITE)
	_check(file != null,"legacy synthetic Main save fixture opens")
	if file != null: file.store_string(JSON.stringify(state,"\t",true,true)+"\n"); file.close()
	original = state.duplicate(true)
	print("BLUE_WHALE_MAIN_FIXTURE_ROOT=",fixture.fixture_root)

func _run() -> void:
	root.size = Vector2i(720,1280)
	root.content_scale_size = Vector2i(720,1280)
	_seed_legacy()
	app = Main.instantiate()
	app.store = fixture
	root.add_child(app)
	var deadline: int = Time.get_ticks_msec() + 120000
	while not app._startup_complete and Time.get_ticks_msec() < deadline: await process_frame
	_check(app._startup_complete,"real staged Main startup completes")
	_check(app._content_ok and app._models_complete and app.fish_art.complete,"all 111 real animal assets pass the unchanged strict startup gate")
	if not app._startup_complete or not app._content_ok:
		printerr("WHALE_MAIN_ASSET_ERRORS=",app.catalog.errors)
		await _finish()
		return
	app.set_process(false)
	_check(fixture.initialize_calls == 1,"Main initializes the injected isolated Store exactly once")
	_check(fixture.total_count() == 148 and fixture.discovered_count() == 74 and int(fixture.state.currency) == 2731,"Main preserves all legacy fish progress without a new-install grant")
	_check(app.catalog.fish_species_count() == 110 and not app.catalog.is_fishing_species(app.catalog.fish.blue_whale),"strict catalog distinguishes 110 fish from the separate whale")
	_check(_button("LobbyWhaleEntry",app._overlay) != null,"Pacific bluewater lobby exposes the dedicated challenge entry")
	app._show_whale_briefing()
	var start: Button = _button("StartWhaleChallenge",app._overlay)
	_check(start != null and not start.disabled and _contains(app._page,"三个操作阶段"),"real briefing explains playable controls and enables start after assets pass")
	if start == null:
		await _finish()
		return
	start.pressed.emit()
	await process_frame
	_check(app._mode == "whale" and app._whale_view != null and not app.scenery.visible and not app._safe.visible,"briefing starts dedicated meter-scale ocean and suspends the ordinary fishery")
	for phase: int in [Challenge.State.LINK,Challenge.State.CURRENT,Challenge.State.RESONANCE]:
		_drive_until(phase)
		_check(app.whale_challenge.state == phase,"Main reaches phase %d through required inputs" % phase)
		_check_duplicate_start("phase %d" % phase)
		if phase == Challenge.State.LINK:
			app.whale_challenge.set_hold(true)
			app._notification(app.NOTIFICATION_APPLICATION_FOCUS_OUT)
			var before: float = app.whale_challenge.elapsed
			_check_duplicate_start("paused")
			app._process(12.0)
			app._notification(app.NOTIFICATION_APPLICATION_FOCUS_IN)
			_check(app.whale_challenge.state == Challenge.State.PAUSED and is_equal_approx(before,app.whale_challenge.elapsed) and not app.whale_challenge.holding,"background pause preserves challenge clocks and requires explicit resume")
			app._resume_whale()
			var selected: Dictionary = fixture.state.selection
			app._choose_spot("lake","lake_shore")
			app._set_bait("worm")
			app._equip(1)
			app._show_travel()
			app._show_settings()
			app._close_page()
			_check(app._mode == "whale" and app._overlay == null and app.spot_id == "pacific_bluewater" and _same(fixture.state.selection,selected),"late ordinary navigation and equipment callbacks cannot disturb a running whale challenge")
	_drive_until(Challenge.State.SUCCESS)
	_check(app._whale_save_ok and fixture.state.whale_challenge.completion_count == 1,"same challenge still completes and saves after all duplicate start callbacks")
	_check(fixture._active_whale_session.is_empty() and fixture.state.whale_challenge.notebook_unlocked,"successful Main settlement closes independent transaction and unlocks whale notebook")
	_check_legacy_fields()
	app._open_completed_whale_notebook()
	await process_frame
	_check(app._mode == "lobby" and app._screen == "whale_notebook" and _contains(app._page,"哺乳纲") and _contains(app._page,"最快完成"),"completed result opens a separate scientific whale notebook with real saved metrics")
	_check(_button("WhaleNotebookEntry",app._page) == null and not _has_sale_action(app._page),"whale notebook has no ordinary inventory or sale action")
	app._show_whale_briefing()
	app._start_whale_challenge()
	var first_id: String = app.whale_challenge.challenge_id
	app._process(31.0)
	_check(app.whale_challenge.state == Challenge.State.FAILED and fixture._active_whale_session.is_empty(),"no input visibly fails in Main and releases the transaction")
	app._start_whale_challenge()
	_check(app.whale_challenge.is_active() and app.whale_challenge.challenge_id != first_id,"failed Main result starts a fresh retry")
	app._handle_back()
	_check(app.whale_challenge.state == Challenge.State.PAUSED,"system back pauses a live challenge")
	app._handle_back()
	_check(app._mode == "lobby" and app._screen == "prepare" and fixture.state.whale_challenge.completion_count == 1,"back from paused challenge cancels and returns to prior preparation without a record")
	app._enter_fishery()
	_check(app._mode == "fishing" and app._whale_navigation.visible,"ordinary bluewater fishery exposes the independent whale button")
	app._action_down()
	app._start_whale_challenge()
	_check(app.session.state == Session.State.CHARGING and app._mode == "fishing" and not app.whale_challenge.is_active(),"a charged fishing cast blocks the whale challenge entry")
	app._abandon_round()
	app._show_whale_briefing()
	app._start_whale_challenge()
	fixture.fail_once = true
	_drive_until(Challenge.State.SUCCESS)
	var pending_id: String = app.whale_challenge.challenge_id
	var pending_record: Dictionary = app._whale_record.duplicate(true)
	_check(not app._whale_save_ok and fixture.state.whale_challenge.completion_count == 1,"Main exposes a failed save without pretending the result persisted")
	app._leave_whale_challenge()
	app._start_whale_challenge()
	_check(app._mode == "whale" and app.whale_challenge.challenge_id == pending_id and fixture._active_whale_session == pending_id and app._whale_record == pending_record,"unsaved success blocks exit and retry while preserving the exact pending transaction")
	app._settle_whale_challenge()
	_check(app._whale_save_ok and fixture.state.whale_challenge.completion_count == 2,"retry saves the exact completed record once")
	app._settle_whale_challenge()
	_check(fixture.state.whale_challenge.completion_count == 2,"repeated UI save callback is idempotent")
	app._leave_whale_challenge()
	_check(app._mode == "fishing" and app.session.state == Session.State.IDLE and app.scenery.visible and app._safe.visible,"return restores the original fishing mode, camera and neutral input")
	app._show_whale_briefing()
	app._start_whale_challenge()
	fixture.fail_once = true
	_drive_until(Challenge.State.SUCCESS)
	app._discard_whale_result()
	_check(app._mode == "fishing" and fixture._active_whale_session.is_empty() and fixture.state.whale_challenge.completion_count == 2,"explicit discard abandons only the unsaved whale result")
	_check_legacy_fields()
	await _finish()

func _check_duplicate_start(label: String) -> void:
	var id: String = app.whale_challenge.challenge_id
	var state: int = app.whale_challenge.state
	var view: Control = app._whale_view
	for i: int in range(3): app._start_whale_challenge()
	_check(app.whale_challenge.challenge_id == id and app.whale_challenge.state == state and app._whale_view == view and fixture._active_whale_session == id,"duplicate start preserves exact active model, HUD and save session in " + label)

func _drive_until(target: int) -> void:
	var steps: int = 0
	while app.whale_challenge.state != target and app.whale_challenge.is_active() and steps < 12000:
		var challenge: BlueWhaleChallenge = app.whale_challenge
		match challenge.state:
			Challenge.State.LINK:
				if challenge.pulse < 0.48: challenge.set_hold(true)
				elif challenge.pulse > 0.58: challenge.set_hold(false)
			Challenge.State.CURRENT:
				var error: float = challenge.route_target - challenge.route_position
				challenge.set_direction(1 if error > 0.025 else (-1 if error < -0.025 else 0))
			Challenge.State.RESONANCE:
				if challenge.tension < 0.46: challenge.set_hold(true)
				elif challenge.tension > 0.58: challenge.set_hold(false)
		app._process(1.0/120.0)
		steps += 1

func _check_legacy_fields() -> void:
	var state: Dictionary = fixture.state
	for key: String in ["species_stats","currency","owned_gear","gear","unlocked_regions","favorites","settings","pending_catches"]:
		_check(_same(state.get(key),original.get(key)),"all whale Main flows preserve legacy " + key)
	_check(fixture.total_count() == 148 and fixture.discovered_count() == 74,"Main completions remain outside fish collection counters")

func _finish() -> void:
	if is_instance_valid(app): app.queue_free()
	await process_frame
	print("BLUE_WHALE_MAIN_TESTS: ",checks-failures,"/",checks," passed; failures=",failures)
	quit(0 if failures == 0 else 1)
