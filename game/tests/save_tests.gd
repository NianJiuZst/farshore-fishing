extends SceneTree
## Run with: godot --headless --path game --script res://tests/save_tests.gd
## All fixtures live in a fresh /tmp directory, never the player's user://.

const Store = preload("res://scripts/save_store.gd")

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: String = ""
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if fail_once == "write" and path.ends_with("save.tmp.json"):
			fail_once = ""
			# Exercise the production FileAccess open-error branch, not a fake success.
			return super._write_verified_json(path.path_join("missing/blocked.json"), value)
		return super._write_verified_json(path, value)
	func _read_save(path: String) -> Dictionary:
		if fail_once == "validation" and path.ends_with("/save.tmp.json"):
			fail_once = ""
			var corrupt: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if corrupt != null:
				corrupt.store_string("{truncated temporary write")
				corrupt.close()
		return super._read_save(path)
	func _replace_file(source: String, destination: String) -> bool:
		if (fail_once == "primary_replace" and destination.ends_with("/save.json")) or (fail_once == "backup_replace" and destination.ends_with("/save.backup.json")):
			fail_once = ""
			# The real rename operation reports ERR_FILE_NOT_FOUND, leaving destination intact.
			return super._replace_file(source + ".nonexistent", destination)
		return super._replace_file(source, destination)

class MemoryStore extends "res://scripts/save_store.gd":
	var writes: int = 0
	func _persist_candidate(_candidate: Dictionary) -> bool:
		writes += 1
		return true

var failures: int = 0
var checks: int = 0
var test_root: String = ""

func _initialize() -> void:
	test_root = "/tmp/farshore-save-tests-%s-%s-%s" % [str(Time.get_unix_time_from_system()).replace(".", "_"), str(OS.get_process_id()), str(Time.get_ticks_usec())]
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(test_root)
	if mkdir_error != OK:
		printerr("TEST ROOT FAILED: ", error_string(mkdir_error))
		quit(1)
		return
	print("SAVE_TEST_ROOT=", test_root)
	_test_stats_transactions_restart()
	_test_duplicate_and_stale()
	_test_write_failure_and_retry()
	_test_release_only_protection()
	_test_corruption_recovery()
	_test_future_schema_protection()
	_test_migration_and_validation()
	_test_bounded_pending()
	_test_ten_thousand()
	print("SAVE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func _record(index: int, length_mm: int = 400, weight_g: int = 1100, region: String = "lake", species: String = "common_carp") -> Dictionary:
	return {"catch_id": "catch_%d" % index, "session_id": "session_%d" % index,
		"species_id": species, "length_mm": length_mm, "weight_g": weight_g,
		"region_id": region, "spot_id": region + "_shore", "caught_at": "2026-10-02T08:00:%02dZ" % (index % 60),
		"game_time": float(index), "weather": "clear", "equipment": {"gear": 0, "name": "旅行手竿"},
		"bait_id": "worm", "disposition": "pending", "reward": 25, "sale_value": 20}

func _catch(store: Store, record: Dictionary) -> Dictionary:
	store.begin_session(str(record["session_id"]))
	return store.settle_catch(record)

func _test_stats_transactions_restart() -> void:
	var root_path: String = test_root.path_join("stats")
	var store: Store = Store.new()
	_check(store.initialize(root_path), "new save initializes: " + store.error_message)
	var fish_one: Dictionary = _record(1, 600, 1000)
	var fish_two: Dictionary = _record(2, 500, 2000, "med")
	var fish_three: Dictionary = _record(3, 550, 1400)
	var result: Dictionary = _catch(store, fish_one)
	_check(bool(result["ok"]) and bool(result["new_species"]) and bool(result["new_length"]) and bool(result["new_weight"]), "first discovery flags")
	result = _catch(store, fish_two)
	_check(bool(result["ok"]) and not bool(result["new_species"]) and not bool(result["new_length"]) and bool(result["new_weight"]), "independent heavier record flag")
	_check(bool(_catch(store, fish_three)["ok"]), "third same-species catch saved")
	_check(store.total_count() == 3 and store.discovered_count() == 1, "three catches, one unique species")
	var stats: Dictionary = store.state["species_stats"]["common_carp"]
	_check(_same(stats["first"], fish_one) and _same(stats["last"], fish_three), "first and last full snapshots")
	_check(_same(stats["max_length"], fish_one) and _same(stats["max_weight"], fish_two), "length and weight refer to independent real fish")
	_check(stats["regions"] == {"lake": 2, "med": 1}, "cross-region catches merge globally with subcounts")
	_check(int(store.state["currency"]) == 195, "catch reward exactly three times")
	_check(bool(store.dispose_catch("catch_1", "sold")["ok"]), "sale saves")
	_check(bool(store.dispose_catch("catch_2", "released")["ok"]), "release saves")
	var balance: int = int(store.state["currency"])
	_check(balance == 223 and store.total_count() == 3, "sale/release retain count and exact rewards")
	_check(not bool(store.dispose_catch("catch_1", "sold")["ok"]), "repeat sale rejected")
	_check(not bool(store.dispose_catch("catch_2", "sold")["ok"]), "sale after release rejected")
	_check(int(store.state["currency"]) == balance and store.total_count() == 3, "repeated disposition has no side effects")
	var detached: Dictionary = store.state
	detached["currency"] = 1
	_check(int(store.state["currency"]) == balance, "state getter returns detached snapshot")
	var candidate: Dictionary = store.state
	candidate["favorites"] = ["common_carp"]
	candidate["gear"] = 1
	candidate["owned_gear"] = [0, 1]
	candidate["unlocked_regions"] = ["lake", "japan"]
	candidate["settings"]["sound"] = false
	candidate["selection"] = {"region_id": "japan", "spot_id": "japan_harbor", "bait_id": "shrimp"}
	candidate["game_clock"] = 654.25
	_check(store.commit_state(candidate), "favorites, equipment, regions and settings commit")
	_check(store.total_count() == 3 and int(store.state["currency"]) == balance, "favorites and preview snapshots cannot count or reward")
	var restart: Store = Store.new()
	_check(restart.initialize(root_path), "restart loads")
	_check(_same(restart.state, store.state), "restart preserves entire state and records without replay")
	_check(restart.total_count() == 3 and int(restart.state["currency"]) == balance, "restart does not replay settlement")
	_check((restart.state["pending_catches"] as Dictionary).has("catch_3"), "unprocessed catch survives restart")
	_check(bool(restart.dispose_catch("catch_3", "released")["ok"]), "restored pending fish can be processed")
	_check(restart.total_count() == 3, "restored disposition retains historical count")
	var uncommitted: Dictionary = restart.state
	uncommitted["currency"] = 99999
	_write_text(root_path.path_join("save.tmp.json"), JSON.stringify(uncommitted))
	var interrupted_restart: Store = Store.new()
	_check(interrupted_restart.initialize(root_path) and int(interrupted_restart.state["currency"]) == balance + 8, "orphan temp file cannot override committed primary")
	_check(not restart.commit_state(candidate), "stale state revision cannot overwrite a later transaction")
	print("PASS GROUP stats, independent records, dispositions, favorites, restart")

func _test_duplicate_and_stale() -> void:
	var store: Store = Store.new()
	_check(store.initialize(test_root.path_join("duplicates")), "duplicate test initialize")
	var record: Dictionary = _record(10)
	_check(bool(_catch(store, record)["ok"]), "initial settlement for duplicate test")
	var before: Dictionary = store.state
	var result: Dictionary = store.settle_catch(record)
	_check(not bool(result["ok"]) and bool(result["duplicate"]), "duplicate callback rejected explicitly")
	_check(store.state == before, "duplicate unchanged state and reward")
	store.begin_session("session_new")
	_check(not bool(store.settle_catch(_record(11))["ok"]), "old callback cannot affect newer session")
	var forged: Dictionary = _record(12)
	forged["session_id"] = "session_new"
	forged["length_mm"] = -1
	_check(not bool(store.settle_catch(forged)["ok"]), "invalid catch rejected")
	store.abandon_session("session_new")
	forged["length_mm"] = 400
	_check(not bool(store.settle_catch(forged)["ok"]), "escaped/abandoned session cannot settle")
	_check(store.total_count() == 1, "escape and malformed result do not count")
	var restart: Store = Store.new()
	_check(restart.initialize(test_root.path_join("duplicates")), "duplicate restart initialize")
	_check(not bool(restart.settle_catch(_record(11))["ok"]), "restart has no active pre-crash session")
	print("PASS GROUP duplicate and stale-session rejection")

func _test_write_failure_and_retry() -> void:
	var store: FailingStore = FailingStore.new()
	var root_path: String = test_root.path_join("failure")
	_check(store.initialize(root_path), "failure fixture initializes")
	for failure: String in ["write", "validation", "backup_replace", "primary_replace"]:
		var index: int = 20 + ["write", "validation", "backup_replace", "primary_replace"].find(failure)
		var record: Dictionary = _record(index)
		var before: Dictionary = store.state
		var bytes_before: String = FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME))
		store.fail_once = failure
		var result: Dictionary = _catch(store, record)
		_check(not bool(result["ok"]) and not store.error_message.is_empty(), failure + " clearly reports save failure")
		_check(store.state == before, failure + " does not publish candidate state")
		_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == bytes_before, failure + " preserves primary")
		var changed: Dictionary = record.duplicate(true)
		changed["weight_g"] = 9999
		_check(not bool(store.settle_catch(changed)["ok"]), failure + " retry cannot change fish")
		store.begin_session("unrelated_new_session")
		_check(not store.error_message.is_empty(), failure + " prevents replacing an unsaved result")
		_check(bool(store.settle_catch(record)["ok"]), failure + " exact result retry succeeds")
		_check(store.total_count() == int((index - 20) + 1), failure + " retry counts once")
		_check(int(store.state["currency"]) == 120 + 25 * (index - 19), failure + " retry rewards once")
		_check(not bool(store.settle_catch(record)["ok"]), failure + " successful retry is subsequently deduplicated")
	var before_sale: Dictionary = store.state
	store.fail_once = "write"
	_check(not bool(store.dispose_catch("catch_20", "sold")["ok"]), "sale write failure is visible")
	_check(store.state == before_sale, "failed sale keeps pending fish and balance")
	_check(bool(store.dispose_catch("catch_20", "sold")["ok"]), "sale can be retried")
	_check(int(store.state["currency"]) == 240 and store.total_count() == 4, "sale retry grants only once")
	print("PASS GROUP real I/O error injection and transactional retries")

func _test_release_only_protection() -> void:
	_check(Store.SCHEMA_VERSION == 2, "optional protection metadata stays backward-compatible with schema 2")
	for failure: String in ["write", "validation", "backup_replace", "primary_replace"]:
		var root_path: String = test_root.path_join("protected_" + failure)
		var store: FailingStore = FailingStore.new()
		_check(store.initialize(root_path), failure + " protected fixture initializes")
		var record: Dictionary = _record(2000, 1250, 12000, "yangtze", "chinese_sturgeon")
		record["spot_id"] = "yangtze_estuary"
		record["release_only"] = true
		record["conservation_note"] = "虚拟保护观察：中华鲟必须放归，不可出售。"
		# A nonzero value must never bypass the protected-disposition rule.
		record["sale_value"] = 999999
		var before: Dictionary = store.state
		var primary_before: String = FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME))
		store.fail_once = failure
		_check(not bool(_catch(store, record)["ok"]), failure + " protected settlement failure is visible")
		_check(store.state == before and FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == primary_before, failure + " protected settlement failure publishes no state or reward")
		var changed: Dictionary = record.duplicate(true)
		changed["release_only"] = false
		_check(not bool(store.settle_catch(changed)["ok"]), failure + " retry cannot remove protection metadata")
		_check(bool(store.settle_catch(record)["ok"]), failure + " original protected settlement retries successfully")
		_check(store.total_count() == 1 and store.discovered_count() == 1 and int(store.state["currency"]) == 145, failure + " protected observation counts and rewards exactly once")
		_check(_same(store.state["pending_catches"][record["catch_id"]], record), failure + " full pending protection snapshot preserved")
		for key: String in ["first", "last", "max_length", "max_weight"]:
			_check(_same(store.state["species_stats"]["chinese_sturgeon"][key], record), failure + " full protected historical snapshot: " + key)
		before = store.state
		primary_before = FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME))
		var backup_before: String = FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME))
		store.fail_once = failure
		var sale: Dictionary = store.dispose_catch(str(record["catch_id"]), "sold")
		_check(not bool(sale["ok"]) and not bool(sale["duplicate"]) and not str(sale["error"]).is_empty(), failure + " direct protected sale returns an explicit rejection")
		_check(store.fail_once == failure, failure + " rejected protected sale never enters the disk writer")
		_check(store.state == before and FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == primary_before and FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME)) == backup_before, failure + " rejected protected sale leaves all memory and disk bytes unchanged")
		var reload: FailingStore = FailingStore.new()
		_check(reload.initialize(root_path) and _same(reload.state, before), failure + " protected pending record survives reload")
		_check(not bool(reload.dispose_catch(str(record["catch_id"]), "sold")["ok"]) and _same(reload.state, before), failure + " protected sale still rejected after reload")
		reload.fail_once = failure
		_check(not bool(reload.dispose_catch(str(record["catch_id"]), "released")["ok"]), failure + " protected release write failure is visible")
		_check(_same(reload.state, before) and FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == primary_before, failure + " failed protected release keeps pending fish and balance")
		var failed_reload: Store = Store.new()
		_check(failed_reload.initialize(root_path) and _same(failed_reload.state, before), failure + " failed protected release reloads unchanged primary")
		_check(not bool(reload.dispose_catch(str(record["catch_id"]), "sold")["ok"]), failure + " failed release cannot be retried as a sale")
		_check(bool(reload.dispose_catch(str(record["catch_id"]), "released")["ok"]), failure + " protected release retries successfully")
		_check(int(reload.state["currency"]) == 153 and reload.total_count() == 1 and reload.discovered_count() == 1, failure + " protected release grants only ordinary release bonus and retains history")
		_check(_same(reload.state["species_stats"], before["species_stats"]) and (reload.state["pending_catches"] as Dictionary).is_empty(), failure + " protected release removes only pending entry and preserves all historical snapshots")
		before = reload.state
		for action: String in ["released", "sold"]:
			var duplicate: Dictionary = reload.dispose_catch(str(record["catch_id"]), action)
			_check(not bool(duplicate["ok"]) and bool(duplicate["duplicate"]) and reload.state == before, failure + " protected post-release " + action + " is idempotent")
		var final_reload: Store = Store.new()
		_check(final_reload.initialize(root_path) and _same(final_reload.state, before), failure + " completed protected release persists without replay")
	var legacy: Store = Store.new()
	var legacy_root: String = test_root.path_join("protection_optional")
	_check(legacy.initialize(legacy_root), "legacy optional-metadata fixture initializes")
	var legacy_record: Dictionary = _record(2100)
	_check(not legacy_record.has("release_only") and bool(_catch(legacy, legacy_record)["ok"]), "legacy schema 2 record without protection metadata still settles")
	var ordinary_record: Dictionary = _record(2101)
	ordinary_record["release_only"] = false
	ordinary_record["conservation_note"] = ""
	_check(bool(_catch(legacy, ordinary_record)["ok"]), "explicit false protection flag still settles")
	var legacy_reload: Store = Store.new()
	_check(legacy_reload.initialize(legacy_root), "mixed old/new metadata reloads")
	_check(not (legacy_reload.state["pending_catches"]["catch_2100"] as Dictionary).has("release_only"), "missing optional field remains absent without destructive migration")
	_check(legacy_reload.state["pending_catches"]["catch_2101"]["release_only"] is bool and not bool(legacy_reload.state["pending_catches"]["catch_2101"]["release_only"]), "false protection flag preserves its JSON boolean type")
	_check(bool(legacy_reload.dispose_catch("catch_2100", "sold")["ok"]) and bool(legacy_reload.dispose_catch("catch_2101", "sold")["ok"]), "legacy and explicitly ordinary catches both remain sellable")
	_check(int(legacy_reload.state["currency"]) == 210 and legacy_reload.total_count() == 2, "ordinary sales preserve exact legacy economics and historical count")
	print("PASS GROUP protected observation sale guard, four settlement/release I/O failures, exact retries, restart and schema 2 compatibility")

func _test_corruption_recovery() -> void:
	var root_path: String = test_root.path_join("recover")
	var store: Store = Store.new()
	_check(store.initialize(root_path), "corruption fixture initializes")
	_check(bool(_catch(store, _record(30))["ok"]), "corruption fixture first catch")
	_check(bool(_catch(store, _record(31))["ok"]), "corruption fixture second catch")
	var backup_before: String = FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME))
	_write_text(root_path.path_join(Store.PRIMARY_NAME), "{broken primary")
	var recovered: Store = Store.new()
	_check(recovered.initialize(root_path), "corrupt primary falls back to valid backup")
	_check(recovered.total_count() == 1 and not recovered.status_message.is_empty(), "backup recovery reports previous committed state")
	_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == "{broken primary", "recovery does not silently erase corrupt primary")
	_check(bool(_catch(recovered, _record(32))["ok"]), "recovered save accepts valid next transaction")
	_check(FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME)) == backup_before, "recovery keeps last valid backup")
	var archived: bool = false
	for file_name: String in DirAccess.get_files_at(root_path):
		if file_name.begins_with("save.json.corrupt-"):
			archived = FileAccess.get_file_as_string(root_path.path_join(file_name)) == "{broken primary"
	_check(archived, "corrupt primary preserved byte-for-byte before replacement")
	var broken_path: String = test_root.path_join("both_corrupt")
	DirAccess.make_dir_recursive_absolute(broken_path)
	_write_text(broken_path.path_join(Store.PRIMARY_NAME), "bad primary")
	_write_text(broken_path.path_join(Store.BACKUP_NAME), "bad backup")
	var blocked: Store = Store.new()
	_check(not blocked.initialize(broken_path) and blocked.read_only, "both corrupt enters protective read-only state")
	_check(not blocked.commit_state(blocked.state), "both-corrupt store cannot overwrite with defaults")
	_check(FileAccess.get_file_as_string(broken_path.path_join(Store.PRIMARY_NAME)) == "bad primary" and FileAccess.get_file_as_string(broken_path.path_join(Store.BACKUP_NAME)) == "bad backup", "both corrupt original files retained")
	print("PASS GROUP corruption fallback and preservation")

func _test_future_schema_protection() -> void:
	for future_file: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME]:
		var root_path: String = test_root.path_join("future_" + future_file)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "future fixture initializes")
		var future_json: String = '{"schema_version":999999999999,"currency":99999,"unknown_future_data":"do not touch"}'
		_write_text(root_path.path_join(future_file), future_json)
		var before_primary: String = FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME))
		var before_backup: String = FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME))
		var restart: Store = Store.new()
		_check(not restart.initialize(root_path) and restart.read_only, future_file + " protects higher schema")
		_check(not restart.commit_state(restart.state), future_file + " cannot overwrite future schema")
		_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == before_primary and FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME)) == before_backup, future_file + " both files unchanged")
		_check(not store.commit_state(store.state) and store.read_only, future_file + " detects future file introduced during play")
	print("PASS GROUP unknown higher schema protection")

func _test_migration_and_validation() -> void:
	var root_path: String = test_root.path_join("migration")
	DirAccess.make_dir_recursive_absolute(root_path)
	var old_record: Dictionary = _record(40, 610, 1900)
	var old: Dictionary = {"schema_version": 1, "currency": 321, "species_stats": {"common_carp": {
		"count": 7, "first": old_record.duplicate(true), "last": old_record.duplicate(true),
		"max_length": old_record.duplicate(true), "max_weight": old_record.duplicate(true), "region_counts": {"lake": 7}}},
		"favorites": ["common_carp"], "settings": {"sound": false}}
	var old_json: String = JSON.stringify(old)
	_write_text(root_path.path_join(Store.PRIMARY_NAME), old_json)
	var store: Store = Store.new()
	_check(store.initialize(root_path), "schema 1 loads and migrates")
	_check(int(store.state["schema_version"]) == 2 and store.total_count() == 7 and int(store.state["currency"]) == 321, "migration preserves counts and currency without replay")
	_check(_same(store.state["species_stats"]["common_carp"]["max_weight"], old_record), "migration preserves full records")
	_check(bool(store.state["settings"]["vibration"]) and not bool(store.state["settings"]["sound"]), "missing settings default, existing setting preserved")
	_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == old_json, "migration does not write before a commit")
	_check(bool(_catch(store, _record(41, 350, 800, "japan", "new_content_species"))["ok"]), "new content species can be added without resetting legacy species")
	_check(store.total_count() == 8 and store.discovered_count() == 2, "migration plus added species retains global history")
	_check(FileAccess.get_file_as_string(root_path.path_join(Store.BACKUP_NAME)) == old_json, "first migrated commit preserves original schema 1 backup")
	var restart: Store = Store.new()
	_check(restart.initialize(root_path) and _same(restart.state, store.state), "migrated save survives restart")
	var invalid: Dictionary = store.state
	invalid["currency"] = -1
	_check(not store.commit_state(invalid), "negative currency state rejected")
	invalid = store.state
	invalid["species_stats"]["common_carp"]["catch_count"] = "seven"
	_check(not store.commit_state(invalid), "non-numeric historical count rejected")
	invalid = store.state
	invalid["favorites"] = ["missing_species"]
	_check(not store.commit_state(invalid), "invalid favorite reference rejected")
	_check(store.total_count() == 8, "invalid updates preserve count")
	print("PASS GROUP schema migration, defaults, validation and new content")

func _test_bounded_pending() -> void:
	var store: MemoryStore = MemoryStore.new()
	_check(store.initialize(test_root.path_join("bounded_pending")), "pending-limit memory persistence fixture initializes")
	for index: int in Store.MAX_PENDING:
		_check(bool(_catch(store, _record(100 + index))["ok"]), "pending slot %d saves" % index)
	var before: Dictionary = store.state
	var overflow: Dictionary = _record(1000)
	_check(not bool(_catch(store, overflow)["ok"]), "full pending queue blocks without discarding a fish")
	_check(store.state == before and store.total_count() == Store.MAX_PENDING, "full queue preserves every pending record and reward")
	_check(bool(store.dispose_catch("catch_100", "released")["ok"]), "pending slot can be freed")
	_check(bool(store.settle_catch(overflow)["ok"]), "blocked same-session settlement succeeds after freeing slot")
	_check((store.state["pending_catches"] as Dictionary).size() == Store.MAX_PENDING, "pending queue remains bounded")
	print("PASS GROUP pending cap preserves unprocessed catches")

func _test_ten_thousand() -> void:
	var start_time: int = Time.get_ticks_msec()
	var store: MemoryStore = MemoryStore.new()
	_check(store.initialize(test_root.path_join("ten_thousand")), "10k fixture initializes")
	var all_success: bool = true
	for index: int in 10000:
		var record: Dictionary = _record(10000 + index, 400 + index % 200, 1000 + index % 1000, "lake" if index % 2 == 0 else "med")
		if not bool(_catch(store, record)["ok"]) or not bool(store.dispose_catch(str(record["catch_id"]), "released")["ok"]):
			all_success = false
			printerr("10k failed at ", index, ": ", store.error_message)
			break
	_check(all_success, "10,000 real settlements and dispositions succeed")
	_check(store.total_count() == 10000 and store.discovered_count() == 1, "10k exact count without separate global counter")
	_check(int(store.state["currency"]) == 330120, "10k exact catch and release rewards")
	_check((store.state["recent_ids"] as Array).size() == Store.MAX_RECENT_IDS and (store.state["pending_catches"] as Dictionary).is_empty(), "10k dedupe and pending data bounded")
	var serialized_bytes: int = JSON.stringify(store.state).to_utf8_buffer().size()
	_check(serialized_bytes < 15000, "10k save stays below 15KB, no full event log")
	_check(not (store.state["recent_ids"] as Array).has("catch_10000"), "old ID really expired from dedupe window")
	store.begin_session("new_after_ten_thousand")
	var before: Dictionary = store.state
	_check(not bool(store.settle_catch(_record(10000))["ok"]), "expired old catch still rejected by session gate")
	_check(store.state == before, "expired callback gives no count or reward")
	# Persist the resulting high-count snapshot using the unmodified real disk writer.
	var disk: Store = Store.new()
	var disk_root: String = test_root.path_join("ten_thousand_disk")
	_check(disk.initialize(disk_root), "10k real disk writer initializes")
	var candidate: Dictionary = store.state
	candidate["save_revision"] = disk.state["save_revision"]
	_check(disk.commit_state(candidate), "10k accumulated state passes real write/validate/backup/replace")
	var restart: Store = Store.new()
	_check(restart.initialize(disk_root) and restart.total_count() == 10000, "10k actual JSON restarts with exact history")
	print("PASS GROUP 10,000 catches: ", serialized_bytes, " bytes, ", Time.get_ticks_msec() - start_time, " ms; memory adapter replaces I/O only, final disk roundtrip verified")

func _write_text(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "fixture file opens: " + path.get_file())
	if file == null:
		return
	file.store_string(content)
	file.close()

func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left, "", true, true)) == JSON.parse_string(JSON.stringify(right, "", true, true))
