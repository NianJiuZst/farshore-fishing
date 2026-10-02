extends SceneTree
## Production-class integration tests. Run with an isolated HOME and XDG_DATA_HOME.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const TestController = preload("res://tests/fishing_test_controller.gd")
const Store = preload("res://scripts/save_store.gd")
const Main = preload("res://scripts/main.gd")
const Registry = preload("res://scripts/fish_3d_registry.gd")
const EXPECTED_SPECIES: int = 44
const EXPECTED_REGIONS: int = 6
const EXPECTED_SPOTS: int = 12

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: bool = false
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if fail_once and path.ends_with("save.tmp.json"):
			fail_once = false
			return super._write_verified_json(path.path_join("missing/blocked.json"), value)
		return super._write_verified_json(path, value)

var checks: int = 0
var failures: int = 0
var catalog: ContentCatalog = Catalog.new()
var test_root: String = ""
var timings: Array[String] = []
var main_completed: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	test_root = "/tmp/farshore-core-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(test_root) == OK, "temporary fixtures directory")
	print("CORE_TEST_ROOT=", test_root)
	_test_catalog_and_reachability()
	_test_seed_and_size()
	_test_state_machine()
	_test_pause_and_input()
	_test_failures_and_terminal()
	_test_behavior_balance()
	_test_real_settlement()
	_test_protected_observation()
	_test_growth()
	if "--skip-ui" in OS.get_cmdline_user_args():
		print("MAIN INTEGRATION SKIPPED: content-production logic-only run; not a complete suite")
	else:
		await _test_main_integration()
		_check(main_completed,"Main integration reaches its explicit completion marker")
	print("CORE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _test_catalog_and_reachability() -> void:
	var art_check: bool = "--check-art" in OS.get_cmdline_user_args()
	_check(catalog.load_all(art_check), "catalog load: " + str(catalog.errors))
	_check(catalog.fish.size() == EXPECTED_SPECIES and catalog.spots.size() == EXPECTED_SPOTS, "44 unique fish and twelve spots")
	_check(catalog.regions.size() == EXPECTED_REGIONS and catalog.gear.size() == 5 and catalog.baits.size() == 8, "six regions, five rods, eight baits")
	var scientific_names: Dictionary = {}
	var region_counts: Dictionary = {}
	var protected_ids: Array[String] = []
	for fish: FishDefinition in catalog.fish.values():
		_check(not scientific_names.has(fish.scientific_name), "unique scientific species: " + fish.species_id)
		scientific_names[fish.scientific_name] = true
		_check(not fish.name.is_empty() and not fish.description.is_empty() and not fish.morphology.is_empty(), "complete identity and field-guide text: " + fish.species_id)
		_check(not fish.raw.get("sources", []).is_empty(), "source provenance present: " + fish.species_id)
		_check(fish.behavior in ["steady", "burst", "rest"], "supported behavior: " + fish.species_id)
		if fish.release_only:
			protected_ids.append(fish.species_id)
			_check(fish.raw.get("release_only") is bool and not fish.conservation_note.is_empty(), "protected species carries boolean flag and conservation explanation")
		for rid: String in fish.regions():
			region_counts[rid] = int(region_counts.get(rid, 0)) + 1
	for region: Dictionary in catalog.regions:
		_check(int(region_counts.get(str(region.region_id), 0)) >= 8, "at least eight species per region: " + str(region.region_id))
	_check(protected_ids == ["chinese_sturgeon"], "exactly Chinese sturgeon is the protected virtual observation")
	_check(int(catalog.region("bayou").get("unlock_count", -1)) == 20 and int(catalog.region("bayou").get("unlock_cost", -1)) == 450, "Mississippi discovery and currency gate remains 20 / 450")
	_check(int(catalog.region("yangtze").get("unlock_count", -1)) == 28 and int(catalog.region("yangtze").get("unlock_cost", -1)) == 600, "Yangtze discovery and currency gate remains 28 / 600")
	var generator: EncounterGenerator = Encounter.new(42)
	var reachable: Dictionary = {}
	var reachable_by_region: Dictionary = {}
	var empty_count: int = 0
	var combinations: int = 0
	for spot_id: String in catalog.spots:
		var spot: Dictionary = catalog.spots[spot_id]
		var region_id: String = str(spot.region_id)
		if not reachable_by_region.has(region_id): reachable_by_region[region_id] = {}
		_check(int(spot.min_gear) >= 0 and int(spot.min_gear) <= 2, "all spots reachable with shipped gear: " + spot_id)
		var spot_seen: Dictionary = {}
		for gear_id: int in catalog.gear.size():
			if gear_id < int(spot.min_gear): continue
			for power_index: int in range(1, 21):
				var power: float = power_index * 0.05
				if power > float(catalog.gear[gear_id].reach): continue
				for bait: Dictionary in catalog.baits:
					for time: String in ["day", "dusk"]:
						for weather: String in ["clear", "rain"]:
							combinations += 1
							var candidates: Array[Dictionary] = generator.candidates(catalog, spot_id, str(bait.bait_id), gear_id, power, time, weather)
							if candidates.is_empty(): empty_count += 1
							for item: Dictionary in candidates:
								var fish: FishDefinition = item.fish
								reachable[fish.species_id] = true
								reachable_by_region[region_id][fish.species_id] = true
								spot_seen[fish.species_id] = true
								_check(float(item.weight) > 0.0 and spot_id in fish.spots() and region_id in fish.regions() and int(fish.raw.get("min_gear", 0)) <= gear_id and str(fish.raw.get("salinity", spot.salinity)) == str(spot.salinity), "candidate valid membership, salinity, gear and positive weight")
		_check(not spot_seen.is_empty(), "each legal spot has real candidates: " + spot_id)
	_check(reachable.size() == EXPECTED_SPECIES and reachable.size() == catalog.fish.size(), "all 44 fish reachable across legal gear/cast/bait/time/weather combinations")
	for region: Dictionary in catalog.regions:
		_check((reachable_by_region.get(str(region.region_id), {}) as Dictionary).size() >= 8, "at least eight actually reachable species per region: " + str(region.region_id))
	_check(generator.generate(catalog, "not_a_spot", "worm", 0, 0.5, "day", "clear").is_empty(), "unknown spot explicitly returns no encounter")
	_check(not generator.candidates(catalog, "lake_shore", "worm", 0, 0.05, "day", "clear").is_empty(), "minimum starter cast remains playable")
	var worm: Array[Dictionary] = generator.candidates(catalog, "lake_shore", "worm", 0, 0.5, "day", "clear")
	var grain: Array[Dictionary] = generator.candidates(catalog, "lake_shore", "grain", 0, 0.5, "day", "clear")
	_check(worm != grain, "bait changes actual encounter weights")
	_check(worm != generator.candidates(catalog, "lake_shore", "worm", 0, 0.5, "dusk", "clear"), "game time changes actual encounter weights")
	_check(worm != generator.candidates(catalog, "lake_shore", "worm", 0, 0.5, "day", "rain"), "weather changes actual encounter weights")
	print("PASS GROUP catalog/reachability: ", combinations, " legal combinations; ", empty_count, " intentionally possible empty combinations; fish=", reachable.size(), "; art=", art_check)

func _test_seed_and_size() -> void:
	var a: EncounterGenerator = Encounter.new(98765)
	var b: EncounterGenerator = Encounter.new(98765)
	var distinct: Dictionary = {}
	for index: int in 150:
		var left: Dictionary = a.generate(catalog, "lake_bay", "worm", 1, 0.6, "dusk", "rain")
		var right: Dictionary = b.generate(catalog, "lake_bay", "worm", 1, 0.6, "dusk", "rain")
		left.erase("caught_at")
		right.erase("caught_at")
		_check(left == right, "seed reproduces selection, size, weight and behavior %d" % index)
		distinct[str(left.species_id) + ":" + str(left.length_mm)] = true
	_check(distinct.size() > 100, "individual outcomes vary across sequential draws")
	var anchors: Dictionary = {}
	for fish: FishDefinition in catalog.fish.values():
		anchors[str(fish.anchor_mm) + ":" + str(fish.anchor_g)] = true
		var samples: Array[Dictionary] = []
		var giant_count: int = 0
		for index: int in 160:
			var sample: Dictionary = a.make_individual(fish, str(fish.spots()[0]), str(fish.regions()[0]), "worm", 2, "day", "clear")
			_check(int(sample.length_mm) >= fish.min_mm and int(sample.length_mm) <= fish.max_mm and int(sample.weight_g) > 0, "valid integer size/weight: " + fish.species_id)
			_check(sample.get("release_only") is bool and bool(sample.get("release_only")) == fish.release_only and str(sample.get("conservation_note", "")) == fish.conservation_note, "generator preserves exact conservation metadata: " + fish.species_id)
			_check(int(sample.sale_value) == 0 if fish.release_only else int(sample.sale_value) >= 10, "protected observation has zero sale value; ordinary fish retains economics: " + fish.species_id)
			var anchor_weight: float = float(fish.anchor_g) * pow(float(sample.length_mm) / fish.anchor_mm, 3.0)
			_check(absf(float(sample.weight_g) - anchor_weight) <= anchor_weight * 0.091 + 0.51, "weight follows species cubic anchor with bounded condition: " + fish.species_id)
			if str(sample.size_class) == "巨物": giant_count += 1
			samples.append(sample)
		samples.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x.length_mm) < int(y.length_mm))
		_check(int(samples.back().weight_g) > int(samples.front().weight_g) and float(samples.back().difficulty) >= float(samples.front().difficulty), "larger individuals heavier and at least as difficult: " + fish.species_id)
		_check(giant_count < 35, "giants uncommon: " + fish.species_id)
	_check(anchors.size() >= 24, "species-specific size anchors, not one shared range")
	print("PASS GROUP reproducible RNG and ", catalog.fish.size() * 160, " real individual samples, including conservation metadata")

func _individual(id: String = "roach", seed_value: int = 42) -> Dictionary:
	var fish: FishDefinition = catalog.fish[id]
	return Encounter.new(seed_value).make_individual(fish, str(fish.spots()[0]), str(fish.regions()[0]), "worm", 0, "day", "clear")

func _launch(record: Dictionary, gear_id: int = 0) -> FishingSession:
	var session: FishingSession = Session.new()
	session._rng.seed = 2468
	session.press()
	for tick: int in 10: session.step(0.05)
	_check(session.cast(record, catalog.gear[gear_id]), "production session accepts a generated individual")
	return session

func _advance_to(session: FishingSession, target: int, limit: int = 1200) -> bool:
	for tick: int in limit:
		if session.state == target: return true
		if session.state in [Session.State.CAUGHT, Session.State.ESCAPED]: return false
		session.step(0.05)
	return session.state == target

func _fight(session: FishingSession, mode: String = "balanced") -> void:
	if session.state == Session.State.BITE: session.press()
	session.release() # Hook and reeling are independent input edges.
	var controller = TestController.new("always_pull" if mode == "hold" else "never_pull" if mode == "release" else "behavior_aware")
	for tick: int in 16000:
		if session.state != Session.State.FIGHT: return
		_drive_fight(session, controller, 0.025)
		session.step(0.025)

func _drive_fight(session: FishingSession, controller: RefCounted, delta: float) -> void:
	var desired: bool = controller.update(session, delta)
	if desired and not session.reeling: session.press()
	elif not desired and session.reeling: session.release()

func _test_state_machine() -> void:
	var session: FishingSession = Session.new()
	var states: Array[int] = []
	var cues: Array[String] = []
	var endings: Array[Dictionary] = []
	session.changed.connect(func(value: int) -> void: states.append(value))
	session.cue.connect(func(value: String) -> void: cues.append(value))
	session.ended.connect(func(success: bool, record: Dictionary) -> void: endings.append({"success":success,"record":record}))
	session.press()
	session.step(0.05)
	_check(session.state == Session.State.CHARGING and session.charge > 0, "press charges")
	for tick: int in 100: session.step(0.05)
	_check(is_equal_approx(session.charge, 1.0), "charge bounded at one")
	var input_record: Dictionary = _individual()
	_check(session.cast(input_record, catalog.gear[0]), "cast from charge succeeds")
	input_record.length_mm = -999
	_check(int(session.individual.length_mm) > 0, "cast copies individual, protects against caller mutation")
	_check(not session.cast(_individual(), catalog.gear[0]), "duplicate cast rejected outside charging")
	_check(_advance_to(session, Session.State.BITE), "casting, waiting and nibble reach bite")
	session.press()
	_check(session.state == Session.State.FIGHT and not session.reeling, "hook starts fight without stuck held input")
	_fight(session)
	_check(session.state == Session.State.CAUGHT, "balanced hold/release catches a real fish")
	_check(states == [Session.State.CHARGING, Session.State.CASTING, Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.FIGHT, Session.State.CAUGHT], "complete state order")
	_check(cues == ["cast", "hook"], "only deliberate cast/hook emit cues; pre-hook states are silent")
	_check(endings.size() == 1 and bool(endings[0].success), "one successful terminal event")
	_check(not str(endings[0].record.catch_id).is_empty() and str(endings[0].record.session_id) == session.session_id, "catch linked to unique session")
	for tick: int in 500: session.step(0.05)
	session._finish(false, "late failure")
	session._finish(true, "late success")
	_check(endings.size() == 1 and session.state == Session.State.CAUGHT, "successful terminal result cannot later fail or duplicate")
	print("PASS GROUP real charge → cast → wait → nibble → bite → fight → success")

func _snapshot(session: FishingSession) -> Array:
	return [session.elapsed, session.charge, session.tension, session.progress, session.fight_time, session.slack_time, session.overload_time, session.wait_duration, session._rng.state, session.individual.duplicate(true), session.session_id]

func _test_pause_and_input() -> void:
	for target: int in [Session.State.CASTING, Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.FIGHT]:
		var session: FishingSession = _launch(_individual())
		if target == Session.State.FIGHT:
			_advance_to(session, Session.State.BITE)
			session.press()
			session.release()
			session.press()
			session.step(0.05)
		else: _advance_to(session, target)
		var snapshot: Array = _snapshot(session)
		session.pause()
		for tick: int in 1000:
			session.step(0.05)
			session.press()
		_check(session.state == Session.State.PAUSED and not session.reeling, "pause rejects input and clears reel for state %d" % target)
		_check(_snapshot(session) == snapshot, "pause freezes timers, physics, RNG and individual for state %d" % target)
		session.pause()
		session.resume()
		_check(session.state == target and not session.reeling and _snapshot(session) == snapshot, "repeat pause then resume restores exact round %d" % target)
	var cancelled: FishingSession = Session.new()
	cancelled.press()
	cancelled.step(0.05)
	cancelled.cancel_input()
	_check(cancelled.state == Session.State.IDLE and not cancelled.reeling, "pointer cancel abandons charge cleanly")
	_check(not cancelled.cast(_individual(), catalog.gear[0]), "late release after cancel cannot cast")
	cancelled = _launch(_individual())
	_advance_to(cancelled, Session.State.BITE)
	cancelled.press()
	cancelled.press()
	cancelled.cancel_input()
	_check(cancelled.state == Session.State.FIGHT and not cancelled.reeling, "pointer cancellation clears held reel without reroll")
	var original: Dictionary = _individual("rudd", 36)
	var baseline: FishingSession = _launch(original)
	var interrupted: FishingSession = _launch(original)
	interrupted.pause()
	for tick: int in 800: interrupted.step(0.05)
	interrupted.resume()
	_advance_to(baseline, Session.State.BITE)
	_advance_to(interrupted, Session.State.BITE)
	_fight(baseline)
	_fight(interrupted)
	var baseline_record: Dictionary = baseline.individual.duplicate(true)
	var interrupted_record: Dictionary = interrupted.individual.duplicate(true)
	for key: String in ["session_id", "catch_id"]:
		baseline_record.erase(key)
		interrupted_record.erase(key)
	_check(baseline.state == interrupted.state and baseline.state == Session.State.CAUGHT and is_equal_approx(baseline.fight_time, interrupted.fight_time) and baseline_record == interrupted_record, "pause leaves eventual outcome, duration and exact fish unchanged")
	print("PASS GROUP pause invariance across five live states and canceled input")

func _test_failures_and_terminal() -> void:
	for mode: String in ["miss", "hold", "release"]:
		var session: FishingSession = _launch(_individual("common_carp"))
		var events: Array[bool] = []
		session.ended.connect(func(success: bool, _record: Dictionary) -> void: events.append(success))
		_advance_to(session, Session.State.BITE)
		if mode == "miss": _advance_to(session, Session.State.ESCAPED)
		else: _fight(session, mode)
		_check(session.state == Session.State.ESCAPED and not session.escape_reason.is_empty(), mode + " ends with explicit escape reason")
		_check(events == [false], mode + " emits exactly one failure")
		for tick: int in 500:
			session.step(0.05)
			session.press()
			session.release()
		session._finish(true, "late duplicate")
		session._finish(false, "late duplicate")
		_check(events == [false], mode + " terminal callbacks cannot emit success or another event")
	var empty: FishingSession = Session.new()
	empty.press()
	_check(not empty.cast({}, catalog.gear[0]) and empty.state == Session.State.IDLE, "empty encounter resets to playable idle")
	print("PASS GROUP missed bite, overload, slack and terminal idempotence")

func _test_behavior_balance() -> void:
	var phases: Dictionary = {}
	for id: String in ["common_bream", "rudd", "roach"]:
		for gear_id: int in catalog.gear.size():
			var record: Dictionary = {}
			for fixed_seed: int in 100:
				record = _individual(id, fixed_seed)
				if float(record.size_fraction) >= 0.25 and float(record.size_fraction) <= 0.4: break
			_check(str(record.size_class) == "标准", "ordinary timing benchmark uses standard-size fish")
			var session: FishingSession = _launch(record, gear_id)
			_advance_to(session, Session.State.BITE)
			session.press()
			session.release()
			var controller = TestController.new()
			var seen: Dictionary = {}
			for tick: int in 16000:
				if session.state != Session.State.FIGHT: break
				_drive_fight(session, controller, 0.025)
				session.step(0.025)
				seen[session.behavior_phase] = true
			_check(session.state == Session.State.CAUGHT, "all behavior/gear combos winnable: %s/%d" % [id, gear_id])
			_check(session.fight_time >= 15.0 and session.fight_time <= 95.0, "ordinary reactive fight remains bounded: %s/%d actual %.2f" % [id, gear_id, session.fight_time])
			if gear_id == 0: phases[id] = seen.keys()
			timings.append("%s gear=%d fraction=%.3f difficulty=%.3f fight=%.2fs" % [id, gear_id, float(record.size_fraction), float(record.difficulty), session.fight_time])
	_check((phases.common_bream as Array).size() == 4 and (phases.rudd as Array).size() == 4 and (phases.roach as Array).size() == 4 and phases.common_bream != phases.rudd and phases.rudd != phases.roach, "all three behavior families expose distinct cruise/windup/surge/recovery patterns")
	print("BALANCE ", "; ".join(timings))

func _test_real_settlement() -> void:
	var store: FailingStore = FailingStore.new()
	_check(store.initialize(test_root.path_join("session-settlement")), "real-session store initializes")
	for index: int in 3:
		var session: FishingSession = _launch(_individual("roach", 100 + index))
		store.begin_session(session.session_id)
		var ended: Array[Dictionary] = []
		session.ended.connect(func(success: bool, record: Dictionary) -> void: ended.append({"success":success,"record":record}))
		_advance_to(session, Session.State.BITE)
		_check(store.total_count() == index, "bite does not count")
		_fight(session)
		_check(ended.size() == 1 and bool(ended[0].success), "real terminal outcome reaches settlement")
		if ended.is_empty(): continue
		var record: Dictionary = ended[0].record
		if index == 1:
			store.fail_once = true
			var before: Dictionary = store.state
			_check(not bool(store.settle_catch(record).get("ok",false)) and store.state == before, "actual-session catch save failure grants nothing")
		_check(bool(store.settle_catch(record).get("ok",false)), "actual-session success settles/retries")
		var saved: Dictionary = store.state
		_check(not bool(store.settle_catch(record).get("ok",false)) and store.state == saved, "actual-session duplicate cannot count twice")
		_check(bool(store.dispose_catch(str(record.catch_id), "sold" if index % 2 == 0 else "released").get("ok",false)), "actual-session disposition succeeds")
		_check(store.total_count() == index + 1 and store.discovered_count() == 1, "sales/releases preserve three actual catches of one species")
	var failed: FishingSession = _launch(_individual())
	store.begin_session(failed.session_id)
	_advance_to(failed, Session.State.ESCAPED)
	store.abandon_session(failed.session_id)
	_check(not bool(store.settle_catch(failed.individual).get("ok",false)) and store.total_count() == 3, "escaped session cannot count")
	var restarted: SaveStore = Store.new()
	_check(restarted.initialize(test_root.path_join("session-settlement")) and restarted.total_count() == 3 and restarted.discovered_count() == 1, "real-session records survive disk reload")
	print("PASS GROUP actual sessions → save → retry → sale/release → restart")

func _test_protected_observation() -> void:
	_check(catalog.fish.has("chinese_sturgeon"), "production catalog contains protected observation")
	if not catalog.fish.has("chinese_sturgeon"): return
	var fish: FishDefinition = catalog.fish["chinese_sturgeon"]
	var record: Dictionary = Encounter.new(413).make_individual(fish, str(fish.spots()[0]), "yangtze", "shrimp", 2, "day", "clear")
	_check(bool(record.release_only) and int(record.sale_value) == 0 and not str(record.conservation_note).is_empty(), "production protected observation starts flagged with zero sale value")
	var session: FishingSession = _launch(record, 2)
	var root_path: String = test_root.path_join("protected-session")
	var store: SaveStore = Store.new()
	_check(store.initialize(root_path), "protected session store initializes")
	store.begin_session(session.session_id)
	_check(_advance_to(session, Session.State.BITE), "protected observation follows actual encounter lifecycle")
	_fight(session)
	_check(session.state == Session.State.CAUGHT and bool(session.individual.get("release_only", false)), "actual session preserves protected flag through completion")
	_check(bool(store.settle_catch(session.individual).get("ok", false)), "actual protected observation persists")
	var before: Dictionary = store.state
	var catch_id: String = str(session.individual.get("catch_id", ""))
	_check(not bool(store.dispose_catch(catch_id, "sold").get("ok", false)) and store.state == before, "actual generated protected record cannot be sold")
	var reload: SaveStore = Store.new()
	_check(reload.initialize(root_path) and _same_json(reload.state, before), "actual protected metadata survives JSON roundtrip")
	_check(not bool(reload.dispose_catch(catch_id, "sold").get("ok", false)) and _same_json(reload.state, before), "reloaded actual protected record cannot be sold")
	_check(bool(reload.dispose_catch(catch_id, "released").get("ok", false)), "actual protected observation can be released")
	_check(reload.total_count() == 1 and reload.discovered_count() == 1 and int(reload.state.currency) == 153, "protected release preserves one discovery with ordinary rewards only")
	_check(_same_json(reload.state.species_stats, before.species_stats) and (reload.state.pending_catches as Dictionary).is_empty(), "protected release retains immutable historical record and clears pending")
	before = reload.state
	_check(not bool(reload.dispose_catch(catch_id, "released").get("ok", false)) and reload.state == before, "actual protected release is idempotent")
	print("PASS GROUP actual protected observation → production session → save → sale refusal → reload → release")

func _accessible(gear_id: int, unlocked: Array) -> Dictionary:
	var generator: EncounterGenerator = Encounter.new(75)
	var available: Dictionary = {}
	for sid: String in catalog.spots:
		var spot: Dictionary = catalog.spots[sid]
		if str(spot.region_id) not in unlocked or int(spot.min_gear) > gear_id: continue
		for bait: Dictionary in catalog.baits:
			for power: float in [0.25, 0.5, 0.75, 0.85]:
				if power > float(catalog.gear[gear_id].reach): continue
				for entry: Dictionary in generator.candidates(catalog, sid, str(bait.bait_id), gear_id, power, "day", "clear"):
					available[entry.fish.species_id] = {"fish":entry.fish,"spot":sid,"region":str(spot.region_id),"bait":str(bait.bait_id)}
	return available

func _test_growth() -> void:
	var store: SaveStore = Store.new()
	_check(store.initialize(test_root.path_join("growth")), "growth fixture initializes")
	var state: Dictionary = store.state
	state.currency = 0
	_check(store.commit_state(state), "zero-currency starting scenario")
	for bait: Dictionary in catalog.baits: _check(int(bait.price) == 0, "basic bait always free: " + str(bait.bait_id))
	var generator: EncounterGenerator = Encounter.new(9357)
	var catches: int = 0
	var spent: int = 0
	var unlock_history: Array[String] = []
	# 160 exceeds all mandatory costs / the 33-coin round reward plus 44 discoveries.
	for iteration: int in 160:
		state = store.state
		var available: Dictionary = _accessible(int(state.gear), state.unlocked_regions)
		_check(not available.is_empty(), "growth always retains a free playable encounter")
		if available.is_empty(): break
		var selected: String = str(available.keys()[0])
		for id: String in available:
			if not state.species_stats.has(id):
				selected = id
				break
		var route: Dictionary = available[selected]
		_check(str(route.region) in state.unlocked_regions and int(catalog.spots[str(route.spot)].min_gear) <= int(state.gear), "growth route obeys actual region and spot equipment gates")
		var record: Dictionary = generator.make_individual(route.fish, route.spot, route.region, route.bait, int(state.gear), "day", "clear")
		var session: FishingSession = _launch(record, int(state.gear))
		store.begin_session(session.session_id)
		_advance_to(session, Session.State.BITE)
		_fight(session)
		_check(session.state == Session.State.CAUGHT and bool(store.settle_catch(session.individual).get("ok",false)), "progression catches only a fish actually available on current gear")
		_check(bool(store.dispose_catch(str(session.individual.catch_id),"released").get("ok",false)), "release-only progression yields nonconsumable income")
		catches += 1
		state = store.state
		_check(int(state.currency) == catches * 33 - spent, "growth earns only exact catch plus release income")
		var next_gear: int = int(state.gear) + 1
		if next_gear < catalog.gear.size() and int(state.currency) >= int(catalog.gear[next_gear].price):
			spent += int(catalog.gear[next_gear].price)
			state.currency = int(state.currency) - int(catalog.gear[next_gear].price)
			state.gear = next_gear
			state.owned_gear.append(next_gear)
			_check(store.commit_state(state), "earned gear purchase commits")
		for region: Dictionary in catalog.regions:
			state = store.state
			if str(region.region_id) in state.unlocked_regions: continue
			if store.discovered_count() >= int(region.unlock_count) and int(state.currency) >= int(region.unlock_cost):
				spent += int(region.unlock_cost)
				state.currency = int(state.currency) - int(region.unlock_cost)
				state.unlocked_regions.append(str(region.region_id))
				_check(store.commit_state(state), "earned regional unlock commits: " + str(region.region_id))
				unlock_history.append("%s discoveries=%d cost=%d" % [region.region_id, store.discovered_count(), region.unlock_cost])
		_check(int(store.state.currency) == catches * 33 - spent and int(store.state.currency) >= 0, "growth never spends unearned currency or creates a negative balance")
		if store.discovered_count() == EXPECTED_SPECIES: break
	_check(store.discovered_count() == EXPECTED_SPECIES and (store.state.unlocked_regions as Array).size() == EXPECTED_REGIONS and int(store.state.gear) == 4, "zero-currency release-only route reaches all 44 species/six regions/gear without resource cycle")
	_check(spent == 3070 and (store.state.owned_gear as Array).size() == 5, "full collection pays exact nine configured purchases totaling 3070")
	var restart: Store = Store.new()
	_check(restart.initialize(test_root.path_join("growth")) and _same_json(restart.state, store.state) and restart.discovered_count() == EXPECTED_SPECIES, "expanded collection, all unlocks and exact economy survive restart")
	print("PASS GROUP zero-start release-only growth: ", catches, " real encounters, discovered=", store.discovered_count(), ", balance=", store.state.currency, "; purchases=", spent, "; unlocks=", unlock_history)

func _test_main_integration() -> void:
	var ui = Main.new()
	root.add_child(ui)
	ui.set_process(false)
	ui.scenery.set_process(false)
	await process_frame
	# Virtual-time stepping emits many cues in one frame; audio output is not under test.
	ui.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	ui.sound.suspend(false)
	ui.sound.ambience.stop()
	ui.sound.ambience.stream = null
	var fixture: FailingStore = FailingStore.new()
	_check(fixture.initialize(test_root.path_join("ui")), "UI store fixture initializes")
	ui.store = fixture
	ui.encounter.rng.seed = 20261002
	ui.session._rng.seed = 2468
	var asset_errors: Array[String] = Registry.validate_catalog(catalog,true)
	_check(asset_errors.is_empty(),"aggregate Main gameplay requires all44 species-specific imported resources: " + str(asset_errors))
	_check(ui._models_complete == asset_errors.is_empty(),"Main readiness agrees with the actual full44 registry")
	if not asset_errors.is_empty():
		_check(not ui._content_ok,"partial assets keep content gate closed")
		var start: Button = _find_button(ui._overlay,"开始钓鱼")
		_check(start != null and start.disabled,"partial assets disable visible lobby Start")
		ui._show_prepare()
		var enter: Button = _find_button(ui._overlay,"进入钓点")
		_check(enter != null and enter.disabled,"partial assets disable visible prepare entry")
		ui._enter_fishery()
		_check(ui._mode == "lobby" and ui._overlay != null,"direct callback cannot bypass missing-model gate")
		print("MAIN_SCOPE: incomplete44 assets; full gameplay checks NOT RUN; no readiness override")
		await _free_main(ui)
		# Reaching this explicit dependency result is not a full-suite pass: the
		# strict asset assertion above fails. Avoid misleading cascade failures.
		main_completed = true
		return
	_check(ui._content_ok,"complete-model Main validates actual production content")
	ui._show_prepare()
	ui._enter_fishery()
	_check(ui._mode == "fishing" and ui._overlay == null,"full-world Main enters saved lake spot")
	ui._action_down()
	for tick: int in 15: ui.session.step(0.05)
	ui._action_up()
	_check(ui.session.state == Session.State.CASTING, "real Main action buttons create session")
	_check(str(ui.session.individual.get("region_id","")) == ui.region_id and str(ui.session.individual.get("spot_id","")) == ui.spot_id,"ordinary Main encounter uses actual selected full-world location")
	_check(ui.spot_id in catalog.fish[str(ui.session.individual.species_id)].spots(),"ordinary Main encounter respects species spot eligibility")
	_advance_to(ui.session, Session.State.BITE)
	var record_before: Dictionary = ui.session.individual.duplicate(true)
	ui._show_catalog()
	_check(ui.session.state == Session.State.PAUSED, "catalog pauses actual round")
	ui._handle_back()
	_check(ui.session.state == Session.State.BITE and ui.session.individual == record_before, "catalog back restores same individual")
	ui._notification(Main.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	_check(ui.session.state == Session.State.PAUSED and ui._screen == "pause", "background shows paused overlay")
	ui._close_page()
	_advance_to(ui.session, Session.State.ESCAPED)
	_check(ui._screen == "escape" and fixture.total_count() == 0, "missed bite opens actual escape page without count")
	# Exercise the actual visible Back button, not the Android back shortcut.
	var back: Button = _find_button(ui._overlay, "返回")
	_check(back != null, "escape page has visible Back button")
	if back: back.pressed.emit()
	_check(ui.session.state == Session.State.IDLE and ui._screen == "", "escape visible Back restores playable idle")
	ui._action_down()
	for tick: int in 15: ui.session.step(0.05)
	ui._action_up()
	_advance_to(ui.session, Session.State.ESCAPED)
	_check(ui._screen == "escape", "second missed bite provides independent terminal pause fixture")
	ui._notification(Main.NOTIFICATION_WM_CLOSE_REQUEST)
	if ui._screen == "pause": ui._close_page()
	_check(ui.session.state == Session.State.IDLE and ui._screen == "", "escape close/pause/continue returns to playable idle")
	ui._abandon_round()
	ui._action_down()
	for tick: int in 15: ui.session.step(0.05)
	ui._action_up()
	_advance_to(ui.session, Session.State.BITE)
	fixture.fail_once = true
	_fight(ui.session)
	_check(ui._screen == "result" and not ui._save_ok and fixture.total_count() == 0, "real Main failed catch save remains result with zero count")
	var catch_identity: String = str(ui._last_record.get("catch_id", ""))
	ui._handle_back()
	_check(ui._screen == "result" and str(ui._last_record.get("catch_id", "")) == catch_identity, "Back on failed save preserves exact result")
	ui._notification(Main.NOTIFICATION_WM_CLOSE_REQUEST)
	ui._exit_game()
	_check(ui._screen == "result" and not ui._save_ok and str(ui._last_record.get("catch_id", "")) == catch_identity, "closing then exit protects unsaved result")
	ui._settle()
	_check(ui._save_ok and fixture.total_count() == 1 and str(ui._last_record.catch_id) == catch_identity, "Main retry saves same catch exactly once")
	ui._settle()
	_check(ui._save_ok and fixture.total_count() == 1, "queued duplicate retry keeps successful save status and exact count")
	ui._show_result()
	_check(fixture.total_count() == 1, "reopening result does not replay settlement")
	ui._notification(Main.NOTIFICATION_WM_CLOSE_REQUEST)
	if ui._screen == "pause": ui._close_page()
	_check(ui._screen == "result" and ui.session.state == Session.State.PAUSED, "window close/continue cannot expose disabled terminal catch without its result")
	ui._show_pause()
	_check(ui._screen == "result" and ui.session.state == Session.State.PAUSED and fixture.total_count() == 1, "direct pause after catch preserves result and count")
	var old_record: Dictionary = ui._last_record.duplicate(true)
	ui._dispose_result("released")
	_check(ui.session.state == Session.State.IDLE and ui._screen == "" and fixture.total_count() == 1, "result disposition restores playable idle without subtracting history")
	ui._action_down()
	for tick: int in 15: ui.session.step(0.05)
	ui._action_up()
	var newer_session_id: String = ui.session.session_id
	ui._fishing_ended(true, old_record)
	_check(ui.session.state == Session.State.CASTING and ui._screen == "" and ui.session.session_id == newer_session_id and fixture.total_count() == 1, "stale completion cannot replace new round or result UI")
	# Restore the fixture even if a stale-callback regression failed, avoiding cascading failures.
	ui._last_record = {}
	ui._save_ok = true
	ui._screen = ""
	ui.session.reset()
	ui._close_page()
	ui._show_catalog()
	var known_id: String = str(old_record.species_id)
	ui._show_species(known_id)
	ui._favorite(known_id)
	ui._show_favorites()
	_check(fixture.total_count() == 1 and known_id in fixture.state.favorites, "actual catalog/favorites views reference saved species without extra count")
	ui._show_catalog()
	ui._search = "不存在的鱼种查找"
	ui._fill_catalog()
	_check(_has_label_fragment(ui._list, "没有符合条件"), "catalog search presents an empty-result hint independent of visual layout")
	ui._search = ""
	ui._show_travel()
	var old_spot: String = ui.spot_id
	var old_region: String = ui.region_id
	fixture.fail_once = true
	ui._choose_spot("lake", "lake_bay")
	_check(ui.spot_id == old_spot and ui.region_id == old_region, "failed travel save rolls live selection back")
	_check(ui.scenery.spot_id == old_spot and ui.scenery.region_id == old_region and str(fixture.state.selection.spot_id) == old_spot,"failed travel save also restores actual3D scene and preserves saved location")
	ui._show_gear()
	var old_bait: String = ui.bait_id
	fixture.fail_once = true
	ui._set_bait("grain")
	_check(ui.bait_id == old_bait, "failed bait save rolls live selection back")
	var setup: Dictionary = fixture.state
	setup.gear = 2
	setup.owned_gear = [0, 1, 2]
	setup.unlocked_regions = ["lake", "japan", "norway", "med"]
	setup.selection = {"region_id":"norway", "spot_id":"norway_boat", "bait_id":ui.bait_id}
	_check(fixture.commit_state(setup), "deep-spot fixture is valid")
	ui.region_id = "norway"
	ui.spot_id = "norway_boat"
	ui._equip(0)
	_check(int(fixture.state.gear) == 0 and str(fixture.state.selection.spot_id) == "norway_boat", "equipping owned starter gear preserves saved deep-water selection")
	ui._show_prepare()
	var deep_enter: Button = _find_button(ui._overlay,"进入钓点")
	_check(not ui._can_use_spot("norway_boat") and deep_enter != null and deep_enter.disabled,"deep-water spot correctly requires suitable gear instead of a trial-only exception")
	ui._enter_fishery()
	_check(ui._screen == "prepare","direct entry respects deep-water gear restriction")
	_test_main_expansion(ui, fixture)
	await _free_main(ui)
	main_completed = true
	print("PASS GROUP Main controls, full-world navigation, background, escaped/result flows and failed selection writes")

func _free_main(ui: Variant) -> void:
	ui.sound.suspend(false)
	ui.sound.ambience.stop()
	ui.sound.effect.stop()
	ui.sound.ambience.stream = null
	ui.sound.effect.stream = null
	await create_timer(0.10).timeout
	ui.queue_free()
	await process_frame
	await create_timer(0.10).timeout

func _test_main_expansion(ui: Variant, original: FailingStore) -> void:
	var candidate: Dictionary = original.state
	candidate.currency = 1000
	_check(original.commit_state(candidate), "UI discovery-gate fixture has sufficient travel money")
	for region_id: String in ["bayou", "yangtze"]:
		var before: Dictionary = original.state
		ui._unlock_region(region_id)
		_check(original.state == before, "Main rejects new region before discovery gate: " + region_id)
	# Reuse actual earned collection data from the full production-session growth test.
	var source: Store = Store.new()
	_check(source.initialize(test_root.path_join("growth")) and source.discovered_count() == EXPECTED_SPECIES, "Main expansion fixture uses actual completed growth history")
	var fixture: FailingStore = FailingStore.new()
	var root_path: String = test_root.path_join("ui-expansion")
	_check(fixture.initialize(root_path), "Main expansion store initializes")
	candidate = source.state
	candidate.save_revision = fixture.state.save_revision
	candidate.unlocked_regions = ["lake", "japan", "norway", "med"]
	candidate.selection = {"region_id":"norway", "spot_id":"norway_boat", "bait_id":"worm"}
	_check(fixture.commit_state(candidate), "Main expansion fixture preserves actual earned statistics")
	ui.store = fixture
	ui.region_id = "norway"
	ui.spot_id = "norway_boat"
	ui.bait_id = "worm"
	_check(ui._refresh_location() and ui.scenery.region_id == "norway" and ui.scenery.spot_id == "norway_boat","expanded fixture loads its actual saved biome and station")
	for region_id: String in ["bayou", "yangtze"]:
		var cost: int = int(catalog.region(region_id).unlock_cost)
		candidate = fixture.state
		candidate.currency = cost - 1
		_check(fixture.commit_state(candidate), "Main insufficient-currency fixture: " + region_id)
		var before: Dictionary = fixture.state
		ui._unlock_region(region_id)
		_check(fixture.state == before, "Main rejects new region below exact currency gate: " + region_id)
		candidate = fixture.state
		candidate.currency = cost
		_check(fixture.commit_state(candidate), "Main exact-price fixture: " + region_id)
		before = fixture.state
		fixture.fail_once = true
		ui._unlock_region(region_id)
		_check(fixture.state == before, "failed new-region unlock keeps currency and unlock list unchanged: " + region_id)
		ui._unlock_region(region_id)
		_check(region_id in fixture.state.unlocked_regions and int(fixture.state.currency) == 0, "new-region retry spends exact price once: " + region_id)
		before = fixture.state
		ui._unlock_region(region_id)
		_check(fixture.state == before, "duplicate new-region unlock spends nothing: " + region_id)
	ui._choose_spot("bayou", "bayou_backwater")
	ui._equip(1)
	ui._show_travel()
	for spot_id: String in ["bayou_backwater", "bayou_channel", "yangtze_river", "yangtze_estuary"]:
		var button: Button = _find_button_fragment(ui._overlay, str(catalog.spots[spot_id].name))
		_check(button != null,"full-world travel advertises the actual original spot: " + spot_id)
		if button != null: _check(button.disabled == not ui._can_use_spot(spot_id),"actual travel button enforces configured gear/depth gate: " + spot_id)
	ui._equip(2)
	ui._choose_spot("yangtze", "yangtze_estuary")
	_check(ui.region_id == "yangtze" and ui.spot_id == "yangtze_estuary" and str(fixture.state.selection.spot_id) == "yangtze_estuary", "actual Main travels to unlocked expanded region and persists selection")
	_check(ui.scenery.region_id == "yangtze" and ui.scenery.spot_id == "yangtze_estuary","expanded travel loads the matching actual3D biome")
	ui._enter_fishery()
	if not catalog.fish.has("chinese_sturgeon"): return
	var fish: FishDefinition = catalog.fish["chinese_sturgeon"]
	var record: Dictionary = Encounter.new(413).make_individual(fish, "yangtze_estuary", "yangtze", "shrimp", 2, "day", "clear")
	ui.session.reset()
	ui.session.press()
	_check(ui.session.cast(record, catalog.gear[2]), "Main accepts production protected encounter")
	fixture.begin_session(ui.session.session_id)
	_check(_advance_to(ui.session, Session.State.BITE), "Main protected session reaches virtual observation")
	_fight(ui.session)
	# Settlement is immediate; the 3D presentation must finish before showing results.
	for tick: int in 90: ui.scenery._process(0.05)
	_check(ui._screen == "result" and ui._save_ok and bool(ui._last_record.get("release_only", false)), "Main automatically settles and displays actual protected observation")
	_check(_find_button_fragment(ui._overlay, "出售") == null and _has_label_fragment(ui._overlay, "保护观察"), "protected result offers conservation guidance and no sale button")
	var before: Dictionary = fixture.state
	ui._dispose_result("sold")
	_check(fixture.state == before and ui._screen == "result", "direct Main protected sale bypass leaves saved result and balance intact")
	fixture.fail_once = true
	ui._dispose_result("released")
	_check(fixture.state == before and ui._screen == "result", "Main protected release write failure preserves exact result and history")
	var release: Button = _find_button_fragment(ui._overlay, "放归")
	_check(release != null and not release.disabled, "protected result retains enabled release control for retry")
	if release: release.pressed.emit()
	_check(ui._screen == "" and ui.session.state == Session.State.IDLE and int(fixture.state.currency) == int(before.currency) + 8 and fixture.total_count() == source.total_count() + 1, "actual protected release control retries once and restores playable idle")
	_check(_same_json(fixture.state.species_stats, before.species_stats), "Main protected release keeps all observation history unchanged")
	# Restore a new actual protected observation from disk to exercise the pending page.
	var session: FishingSession = _launch(record, 2)
	fixture.begin_session(session.session_id)
	_advance_to(session, Session.State.BITE)
	_fight(session)
	_check(bool(fixture.settle_catch(session.individual).get("ok", false)), "protected pending-page fixture comes from another completed production session")
	var reload: FailingStore = FailingStore.new()
	_check(reload.initialize(root_path), "pending protected observation reloads for actual Main")
	ui.store = reload
	ui._show_pending()
	_check(_find_button_fragment(ui._overlay, "出售") == null and _has_label_fragment(ui._overlay, "保护观察"), "reloaded protected pending page has no sale control")
	before = reload.state
	var catch_id: String = str(session.individual.catch_id)
	ui._dispose_pending(catch_id, "sold")
	_check(reload.state == before and ui._screen == "pending", "direct protected pending sale bypass is rejected")
	reload.fail_once = true
	ui._dispose_pending(catch_id, "released")
	_check(reload.state == before, "pending protected release failure keeps exact balance and observation")
	release = _find_button_fragment(ui._overlay, "放归")
	_check(release != null and not release.disabled, "reloaded protected pending page exposes release retry")
	if release: release.pressed.emit()
	_check((reload.state.pending_catches as Dictionary).is_empty() and int(reload.state.currency) == int(before.currency) + 8 and _same_json(reload.state.species_stats, before.species_stats), "pending release control rewards once without altering historical counts or records")
	before = reload.state
	ui._dispose_pending(catch_id, "released")
	_check(reload.state == before, "duplicate pending release cannot replay its bonus")
	print("PASS GROUP Main expanded discovery/currency/gear gates, failed unlock retry, protected result and reloaded pending controls")

func _find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label: return node
	for child: Node in node.get_children():
		var result: Button = _find_button(child,label)
		if result != null: return result
	return null

func _find_button_fragment(node: Node, fragment: String) -> Button:
	if node is Button and fragment in node.text: return node
	for child: Node in node.get_children():
		var result: Button = _find_button_fragment(child, fragment)
		if result != null: return result
	return null

func _has_label_fragment(node: Node, fragment: String) -> bool:
	if node is Label and fragment in node.text: return true
	for child: Node in node.get_children():
		if _has_label_fragment(child, fragment): return true
	return false

func _same_json(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left, "", true, true)) == JSON.parse_string(JSON.stringify(right, "", true, true))
