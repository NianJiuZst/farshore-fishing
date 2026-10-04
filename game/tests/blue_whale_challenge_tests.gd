extends SceneTree
## Pure gameplay + real transaction fixtures. Every save root is explicit /tmp;
## this test never initializes SaveStore with its player-data default.
const Challenge = preload("res://scripts/blue_whale_challenge.gd")
const Store = preload("res://scripts/save_store.gd")
const Stage = preload("res://scripts/whale_challenge_stage_3d.gd")
const Biology = preload("res://scripts/fish_natural_history.gd")
const Historical = preload("res://tests/ocean_save_tests.gd")

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: bool = false
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if fail_once and path.ends_with("/save.tmp.json"):
			fail_once = false
			return _fail("Synthetic whale transaction write failure")
		return super._write_verified_json(path, value)

var checks: int = 0
var failures: int = 0
var fixture_root: String = ""

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL WHALE: ", label)

func _policy(challenge: BlueWhaleChallenge) -> void:
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

func _complete(delta: float = 1.0 / 60.0) -> BlueWhaleChallenge:
	var challenge: BlueWhaleChallenge = Challenge.new()
	_check(challenge.start(123.0), "fresh challenge starts")
	var steps: int = 0
	while challenge.is_active() and steps < ceili(90.0 / delta):
		_policy(challenge)
		challenge.step(delta)
		steps += 1
	_check(challenge.state == Challenge.State.SUCCESS, "observable-input controller completes all stages at %.4f s/frame: %s" % [delta, challenge.failure_reason])
	_check(challenge.links == 3 and challenge.current_sync >= 9.999 and challenge.resonance_sync >= 7.999, "completion requires all three phase goals")
	_check(challenge.elapsed >= 18.0 and challenge.elapsed < 82.0, "complete challenge has bounded playable duration")
	_check(not challenge.record.has("weight_g") and not challenge.record.has("bait_id") and not challenge.record.has("reward"), "whale result has no ordinary fish mass, bait or reward")
	return challenge

func _run() -> void:
	fixture_root = "/tmp/farshore-whale-tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(fixture_root) == OK, "isolated fixture root created")
	print("BLUE_WHALE_TEST_ROOT=", fixture_root)
	var winner: BlueWhaleChallenge = _complete()
	print("BLUE_WHALE_OBSERVABLE_INPUT_TIME_MS=",winner.record.duration_ms)
	_complete(1.0 / 16.0)
	_complete(1.0 / 30.0)
	_complete(1.0 / 120.0)
	_complete(0.2)
	_test_required_input_and_lifecycle()
	_test_transaction_and_legacy(winner.record)
	_test_facts()
	await _test_camera_and_model()
	print("BLUE_WHALE_CHALLENGE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)

func _test_required_input_and_lifecycle() -> void:
	for phase: int in [Challenge.State.LINK, Challenge.State.CURRENT, Challenge.State.RESONANCE]:
		var challenge: BlueWhaleChallenge = Challenge.new()
		challenge.start()
		for i: int in range(12000):
			if challenge.state == phase or not challenge.is_active(): break
			_policy(challenge)
			challenge.step(1.0 / 120.0)
		_check(challenge.state == phase, "test enters target phase %d with prior goals earned" % phase)
		challenge.cancel_input()
		challenge.step(40.0)
		_check(challenge.state == Challenge.State.FAILED and challenge.record.is_empty(), "phase %d cannot complete with no input" % phase)
		var old_id: String = challenge.challenge_id
		_check(challenge.start() and challenge.challenge_id != old_id and challenge.state == Challenge.State.LINK, "failed phase can retry with a fresh challenge id")
	var paused: BlueWhaleChallenge = Challenge.new()
	paused.start()
	paused.set_hold(true)
	paused.step(1.1)
	var before: Vector3 = Vector3(paused.elapsed, paused.phase_elapsed, paused.pulse)
	paused.pause()
	paused.step(40.0)
	_check(paused.state == Challenge.State.PAUSED and Vector3(paused.elapsed, paused.phase_elapsed, paused.pulse) == before and not paused.holding, "pause preserves all simulation clocks and releases touch")
	paused.resume()
	_check(paused.state == Challenge.State.LINK and not paused.holding, "resume does not restore a held control")
	var terminal_events: Array = []
	paused.ended.connect(func(success: bool, record: Dictionary) -> void: terminal_events.append([success, record]))
	paused.cancel()
	paused.cancel()
	paused.step(80.0)
	_check(paused.state == Challenge.State.CANCELLED and terminal_events.size() == 1 and bool(terminal_events[0][1].get("cancelled",false)), "cancel is terminal and emits only once")
	_check(paused.start(), "cancelled challenge restarts")
	before = Vector3(paused.elapsed, paused.phase_elapsed, paused.pulse)
	for delta: float in [-1.0, 0.0, INF, NAN]: paused.step(delta)
	_check(Vector3(paused.elapsed, paused.phase_elapsed, paused.pulse) == before, "invalid delta cannot corrupt simulation")
	var complete: BlueWhaleChallenge = _complete()
	var original: Dictionary = complete.record.duplicate(true)
	complete.step(120.0)
	complete.cancel()
	_check(complete.state == Challenge.State.SUCCESS and complete.record == original, "late steps and cancel cannot mutate completed result")

func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left, "", true, true)) == JSON.parse_string(JSON.stringify(right, "", true, true))

func _write(path: String, text: String) -> void:
	_check(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK, "fixture parent created")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "fixture opens")
	if file != null: file.store_string(text); file.close()

func _legacy_state() -> Dictionary:
	var state: Dictionary = Store.default_state()
	state.erase("whale_challenge")
	state.currency = 2731
	state.gear = 6
	state.owned_gear = [0, 2, 4, 6]
	state.unlocked_regions = ["lake", "japan", "norway", "med", "bayou", "yangtze", "pacific_ocean", "atlantic_ocean", "indian_ocean"]
	state.selection = {"region_id":"pacific_ocean", "spot_id":"pacific_bluewater", "bait_id":"shrimp"}
	state.game_clock = 812.0
	state.settings["custom_future_setting"] = "preserved"
	var ids: Array = []
	for row: Array in Historical.HISTORICAL_SPECIES: ids.append(row[0])
	ids.append_array(Historical.OCEAN_SPECIES)
	for id: String in ids:
		var snapshot: Dictionary = {"species_id": id, "length_mm": 350, "weight_g": 500}
		state.species_stats[id] = {"catch_count":2, "first":snapshot.duplicate(true), "last":snapshot.duplicate(true), "max_length":snapshot.duplicate(true), "max_weight":snapshot.duplicate(true), "regions":{"lake":2}}
	state.favorites = ["common_carp", "atlantic_bluefin_tuna"]
	return state

func _test_transaction_and_legacy(record: Dictionary) -> void:
	var legacy: Dictionary = _legacy_state()
	var save_root: String = fixture_root.path_join("legacy")
	var old_text: String = JSON.stringify(legacy,"\t",true,true) + "\n"
	_write(save_root.path_join(Store.PRIMARY_NAME),old_text)
	var store: FailingStore = FailingStore.new()
	_check(store.initialize(save_root), "1.3.0 schema 2 / 74-species legacy save initializes")
	_check(FileAccess.get_file_as_string(save_root.path_join(Store.PRIMARY_NAME)) == old_text, "initialization only normalizes in memory, preserves original bytes")
	_check(store.state.species_stats.size() == 74 and store.total_count() == 148 and store.discovered_count() == 74, "all 74 historical species and fish counts preserved")
	_check(int(store.state.currency) == 2731 and _same(store.state.owned_gear,legacy.owned_gear) and _same(store.state.unlocked_regions,legacy.unlocked_regions), "legacy currency, gear and region unlocks do not receive fresh-install grant")
	_check(store.state.whale_challenge.completion_count == 0 and not store.state.whale_challenge.notebook_unlocked, "legacy gets an empty independent whale extension")
	var before: Dictionary = store.state
	_check(store.begin_whale_challenge(str(record.challenge_id)), "whale transaction session starts")
	var backup_text: Dictionary = store.export_save_text()
	_check(not bool(store.import_save_text(str(backup_text.text),int(before.save_revision)).ok), "backup import is blocked during whale challenge")
	store.fail_once = true
	_check(not bool(store.settle_whale_challenge(record).ok), "injected failed write reports unsaved whale result")
	_check(_same(store.state,before) and FileAccess.get_file_as_string(save_root.path_join(Store.PRIMARY_NAME)) == old_text, "failed whale transaction preserves memory and original primary bytes")
	var altered: Dictionary = record.duplicate(true)
	altered.duration_ms = int(altered.duration_ms) + 1
	_check(not bool(store.settle_whale_challenge(altered).ok), "save retry must retain exact completed record")
	var success: Dictionary = store.settle_whale_challenge(record)
	_check(bool(success.ok) and bool(success.new_best), "original result retries successfully and sets first best")
	var after: Dictionary = store.state
	_check(after.whale_challenge.completion_count == 1 and after.whale_challenge.notebook_unlocked, "completion saves independent count and notebook unlock")
	_check(_same(after.species_stats,before.species_stats) and _same(after.pending_catches,before.pending_catches) and int(after.currency) == int(before.currency), "whale completion does not change any fish records, pending inventory or currency")
	_check(_same(after.owned_gear,before.owned_gear) and _same(after.unlocked_regions,before.unlocked_regions) and _same(after.favorites,before.favorites) and _same(after.settings,before.settings), "legacy gear, unlocks, favorites and settings untouched")
	_check(store.total_count() == 148 and store.discovered_count() == 74, "whale completion never counts as a fish")
	_check(not bool(store.settle_whale_challenge(record).ok) and int(store.state.whale_challenge.completion_count) == 1, "duplicate success cannot settle twice")
	_check(not bool(store.dispose_catch(str(record.challenge_id),"sold").ok), "whale completion cannot be sold")
	store.begin_session("forged-fish-whale")
	var forged: Dictionary = {"catch_id":"forged-fish-whale", "session_id":"forged-fish-whale", "species_id":"blue_whale", "region_id":"pacific_ocean", "spot_id":"pacific_bluewater", "bait_id":"worm", "length_mm":26000, "weight_g":120000000, "caught_at":"2026-10-04T00:00:00Z", "weather":"clear", "game_time":1.0, "equipment":"fictional", "reward":1000, "sale_value":1000}
	_check(not bool(store.settle_catch(forged).ok), "even forged ordinary catch contract rejects blue whale")
	store.abandon_session("forged-fish-whale")
	_check(_same(store.state,after), "forged whale does not alter the saved state")
	var exported: Dictionary = store.export_save_text()
	var destination: SaveStore = Store.new()
	_check(destination.initialize(fixture_root.path_join("roundtrip")), "roundtrip fixture starts separately")
	var restored: Dictionary = destination.import_save_text(str(exported.text),int(destination.state.save_revision))
	_check(bool(restored.ok) and _same(destination.state.whale_challenge,after.whale_challenge), "backup transfer roundtrips independent whale record")
	_check(destination.total_count() == 148 and destination.discovered_count() == 74 and int(destination.state.currency) == 2731, "backup restore keeps original fish progress and currency")
	var restart: SaveStore = Store.new()
	_check(restart.initialize(save_root) and _same(restart.state.whale_challenge,after.whale_challenge), "disk restart reads committed whale extension")
	var stable: Dictionary = restart.state
	stable.game_clock = float(stable.game_clock) + 1.0
	_check(restart.commit_state(stable), "ordinary clock transaction includes whale state in rolling backup")
	_write(save_root.path_join(Store.PRIMARY_NAME),"{corrupt fixture")
	var recovery: SaveStore = Store.new()
	_check(recovery.initialize(save_root) and _same(recovery.state.whale_challenge,after.whale_challenge) and recovery.discovered_count() == 74, "backup recovery restores whale extension and all historical fish")

func _test_facts() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/encyclopedia_whale.json"))
	var entry: Dictionary = parsed.entries[0]
	_check(Biology.validate_entry(entry).is_empty(), "blue whale fact entry has valid taxonomy, metrics and field-level sources")
	_check(entry.animal_kind == "mammal" and entry.encounter_type == "fantasy_challenge", "natural history explicitly identifies mammal and fantasy mode")
	_check(str(entry.conservation.text).contains("不喂食") and str(entry.habitat.text).contains("游戏"), "facts distinguish real conservation and fictional display water layer")
	var definition: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/fish_whale.json")) as Array)[0]
	_check(not bool(definition.fishing_enabled) and str(definition.animal_kind) == "mammal", "catalog definition explicitly disables fishing")

func _test_camera_and_model() -> void:
	var stage: WhaleChallengeStage3D = Stage.new()
	stage.size = Vector2(720.0,1280.0)
	root.add_child(stage)
	await process_frame
	for extent: Vector2 in [Vector2(720,1280),Vector2(1280,720),Vector2(720,720),Vector2(1080,2400)]:
		stage.size = extent
		await process_frame
		stage._fit_camera()
		var viewport_extent: Vector2 = Vector2(stage.viewport.size)
		var points: Array[Vector2] = stage.framing_endpoints()
		var inside: bool = points.size() == 4
		for point: Vector2 in points:
			inside = inside and point.x > viewport_extent.x * 0.08 and point.x < viewport_extent.x * 0.92 and point.y > viewport_extent.y * 0.08 and point.y < viewport_extent.y * 0.92
		_check(inside,"26-meter animated whale fits dedicated camera at %s" % str(extent))
	_check(stage.body_length_m == 26.0 and stage.BOAT_LENGTH_M == 5.6, "dedicated scene uses whale and boat real meter scale")
	_check(stage._echo_ring.position.x > 13.0 and stage._echo_ring.get_parent() != stage.model, "fantasy line endpoint is external ring beyond whale head, not mouth")
	stage.show_success()
	_check(stage.success_view and stage._whale_root.position.y < 0.0,"success retains the giant in water")
	var require_model: bool = OS.get_cmdline_user_args().has("--require-whale-model")
	if require_model:
		_check(stage.model != null and stage.animator != null,"final asset proof requires real whale model and animation")
		if stage.model != null: _check(stage.model.scale.is_equal_approx(Vector3.ONE * 26.0),"dedicated stage maps normalized whale mesh to 26 meters")
		if stage.animator != null:
			_check(stage.animator.has_animation("swim") and stage.animator.get_animation("swim").loop_mode == Animation.LOOP_LINEAR,"whale swim loops in its waterborne completion")
	else:
		print("WHALE_MODEL_ASSET_PROOF=deferred; rerun with --require-whale-model when dedicated asset exists")
	stage.queue_free()
	await process_frame
