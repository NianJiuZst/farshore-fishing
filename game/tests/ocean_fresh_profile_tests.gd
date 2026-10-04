extends SceneTree
## Production SaveStore and real I/O only. Every fixture uses a unique /tmp root.
## Fresh-profile compensation must never become a migration or restore bonus.

const Store = preload("res://scripts/save_store.gd")
const Catalog = preload("res://scripts/catalog.gd")
const ORIGINAL_REGIONS: Array = ["lake", "japan", "norway", "med", "bayou", "yangtze"]
const ORIGINAL_SPOTS: Array = ["lake_shore", "lake_bay", "japan_harbor", "japan_reef", "norway_harbor", "norway_boat", "med_pier", "med_boat", "bayou_backwater", "bayou_channel", "yangtze_river", "yangtze_estuary"]
const OCEAN_REQUIREMENTS: Dictionary = {
	"pacific_ocean": {"unlock_count": 20, "unlock_cost": 450},
	"atlantic_ocean": {"unlock_count": 28, "unlock_cost": 600},
	"indian_ocean": {"unlock_count": 36, "unlock_cost": 750}
}

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: String = ""
	var corrupt_after_replace: bool = false
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if (fail_once == "write_primary" and path.ends_with("/save.tmp.json")) or (fail_once == "write_backup" and path.ends_with("/save.backup.tmp.json")):
			fail_once = ""
			return super._write_verified_json(path.path_join("missing/blocked.json"), value)
		return super._write_verified_json(path, value)
	func _read_save(path: String) -> Dictionary:
		if (fail_once == "validation" and path.ends_with("/save.tmp.json")) or (corrupt_after_replace and path.ends_with("/save.json")):
			fail_once = ""
			corrupt_after_replace = false
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string("{interrupted initial write")
				file.close()
		return super._read_save(path)
	func _replace_file(source: String, destination: String) -> bool:
		if (fail_once == "backup_replace" and destination.ends_with("/save.backup.json")) or (fail_once == "primary_replace" and destination.ends_with("/save.json")):
			fail_once = ""
			return super._replace_file(source + ".does-not-exist", destination)
		var success: bool = super._replace_file(source, destination)
		if success and fail_once == "final_validation" and destination.ends_with("/save.json"):
			fail_once = ""
			corrupt_after_replace = true
		return success

var checks: int = 0
var failures: int = 0
var test_root: String = ""
var catalog: ContentCatalog

func _initialize() -> void:
	test_root = "/tmp/farshore-ocean-fresh-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(test_root) == OK, "isolated fixture directory created")
	print("OCEAN_FRESH_PROFILE_TEST_ROOT=", test_root)
	catalog = Catalog.new()
	_check(catalog.load_all(false), "data-only catalog validates: " + str(catalog.errors))
	_test_fresh_defaults()
	_test_restart_and_spending()
	_test_legacy_missing_fields()
	_test_existing_selected_regions()
	_test_import_and_undo()
	_test_creation_failures()
	_test_existing_recovery_and_protection()
	print("OCEAN_FRESH_PROFILE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left, "", true, true)) == JSON.parse_string(JSON.stringify(right, "", true, true))

func _without_revision(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.erase("save_revision")
	return result

func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"

func _write(path: String, text: String) -> void:
	_check(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK, "fixture directory opens")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "fixture file opens: " + path.get_file())
	if file != null:
		file.store_string(text)
		file.close()

func _seed(root_path: String, value: Dictionary) -> String:
	var text: String = JSON.stringify(value, "  ", false, true) + "\n"
	_write(root_path.path_join(Store.PRIMARY_NAME), text)
	_write(root_path.path_join(Store.BACKUP_NAME), text)
	return text

func _files(root_path: String) -> Dictionary:
	var result: Dictionary = {}
	for name: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME, Store.PRE_IMPORT_NAME]:
		result[name] = _read(root_path.path_join(name))
	return result

func _check_fresh(value: Dictionary, label: String) -> void:
	_check(int(value["currency"]) == 1500, label + " has exactly 1,500 coins")
	_check(_same(value["unlocked_regions"], ORIGINAL_REGIONS), label + " unlocks exactly the original six regions")
	_check(int(value["gear"]) == 0 and _same(value["owned_gear"], [0]), label + " retains only the original starter rod")
	_check((value["species_stats"] as Dictionary).is_empty() and (value["pending_catches"] as Dictionary).is_empty(), label + " fabricates no discoveries, records or pending fish")
	_check((value["favorites"] as Array).is_empty() and (value["recent_ids"] as Array).is_empty(), label + " fabricates no favorites or settled IDs")
	_check(float(value["game_clock"]) == 0.0 and int(value["save_revision"]) == 0, label + " has no fabricated playtime or transactions")
	_check(_same(value["selection"], {"region_id": "lake", "spot_id": "lake_shore", "bait_id": "worm"}), label + " keeps the initial selection")
	for region_id: String in OCEAN_REQUIREMENTS:
		_check(region_id not in value["unlocked_regions"], label + " leaves " + region_id + " locked")

func _test_fresh_defaults() -> void:
	var baseline: Dictionary = Store.default_state()
	_check(int(baseline["currency"]) == 120 and _same(baseline["unlocked_regions"], ["lake"]), "historical normalization defaults remain unchanged")
	var fresh: Dictionary = Store.fresh_state()
	_check_fresh(fresh, "fresh builder")
	var difference: Dictionary = fresh.duplicate(true)
	difference["currency"] = baseline["currency"]
	difference["unlocked_regions"] = baseline["unlocked_regions"]
	_check(_same(difference, baseline), "fresh builder changes only coins and original region unlocks")
	fresh["unlocked_regions"].append("pacific_ocean")
	fresh["settings"]["sound"] = false
	_check_fresh(Store.fresh_state(), "independent fresh builder")
	_check(bool(Store.fresh_state()["settings"]["sound"]), "fresh builder returns independent nested defaults")
	var root_path: String = test_root.path_join("fresh")
	var store: Store = Store.new()
	_check(store.initialize(root_path), "new on-disk save initializes: " + store.error_message)
	_check_fresh(store.state, "created profile")
	_check(store.total_count() == 0 and store.discovered_count() == 0, "public counters remain zero")
	for name: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME]:
		_check(_same(JSON.parse_string(_read(root_path.path_join(name))), store.state), "initial " + name + " contains the complete compensated profile")
	var regional_spots: Array = []
	for region_id: String in store.state["unlocked_regions"]:
		var region: Dictionary = catalog.region(region_id)
		_check(not region.is_empty(), "compensated region exists: " + region_id)
		for spot_id: String in region["spots"]:
			_check(catalog.spots.has(spot_id) and str(catalog.spots[spot_id]["region_id"]) == region_id, "original spot remains bound: " + spot_id)
			regional_spots.append(spot_id)
	_check(_same(regional_spots, ORIGINAL_SPOTS), "all twelve original spot listings are covered, in historical order")
	for region_id: String in OCEAN_REQUIREMENTS:
		var region: Dictionary = catalog.region(region_id)
		for key: String in ["unlock_count", "unlock_cost"]:
			_check(int(region.get(key, -1)) == int(OCEAN_REQUIREMENTS[region_id][key]), region_id + " keeps its original ocean " + key)
	_check(_same(catalog.spots[store.state["selection"]["spot_id"]]["region_id"], store.state["selection"]["region_id"]), "initial selected spot belongs to its unlocked region")

func _test_restart_and_spending() -> void:
	var root_path: String = test_root.path_join("restart")
	var store: Store = Store.new()
	_check(store.initialize(root_path), "restart fixture initializes")
	var initial_bytes: Dictionary = _files(root_path)
	_check(store.initialize(root_path), "reinitializing the same object succeeds")
	_check_fresh(store.state, "reinitialized profile")
	_check(_files(root_path) == initial_bytes, "reinitialization never rewrites the compensation")
	var candidate: Dictionary = store.state
	candidate["currency"] = 0
	candidate["selection"] = {"region_id": "yangtze", "spot_id": "yangtze_estuary", "bait_id": "cut_fish"}
	candidate["game_clock"] = 125.5
	_check(store.commit_state(candidate), "spending all initial coins and changing selected region persists")
	var expected: Dictionary = store.state
	var bytes_after: Dictionary = _files(root_path)
	for attempt: int in 3:
		var restart: Store = Store.new()
		_check(restart.initialize(root_path), "restart after spending %d succeeds" % attempt)
		_check(_same(restart.state, expected), "restart after spending %d preserves exact progress without another bonus" % attempt)
		_check(_files(root_path) == bytes_after, "restart after spending %d is read-only" % attempt)
		_check(restart.total_count() == 0 and restart.discovered_count() == 0, "travel and spending produce no discoveries")

func _legacy(schema: int, region_id: String = "lake", spot_id: String = "lake_shore") -> Dictionary:
	# Literal old-format fixture: never derive migration expectations from the new builder.
	var record: Dictionary = {"catch_id": "historical_carp", "session_id": "historical_session", "species_id": "common_carp", "length_mm": 450, "weight_g": 1500,
		"region_id": "lake", "spot_id": "lake_shore", "caught_at": "2026-10-02T08:00:00Z", "game_time": 10.0, "weather": "clear",
		"equipment": {"gear": 0, "name": "旅行手竿"}, "bait_id": "worm", "disposition": "pending", "reward": 25, "sale_value": 20}
	var stats: Dictionary = {"catch_count": 7, "first": record.duplicate(true), "last": record.duplicate(true), "max_length": record.duplicate(true), "max_weight": record.duplicate(true), "regions": {"lake": 7}}
	if schema == 1:
		stats["count"] = stats["catch_count"]
		stats["region_counts"] = stats["regions"]
		stats.erase("catch_count")
		stats.erase("regions")
	return {"schema_version": schema, "save_revision": 11, "currency": 0, "gear": 0, "owned_gear": [0],
		"unlocked_regions": ["lake"] if region_id == "lake" else ["lake", region_id],
		"species_stats": {"common_carp": stats}, "favorites": ["common_carp"], "pending_catches": {"historical_carp": record}, "recent_ids": ["historical_carp"],
		"selection": {"region_id": region_id, "spot_id": spot_id, "bait_id": "worm"}, "settings": {"sound": false}, "game_clock": 20.0,
		"historical_extension": {"note": "preserve nested old profile data", "values": [true, null, 7]}}

func _test_legacy_missing_fields() -> void:
	for schema: int in [1, 2, 0]:
		var old: Dictionary = _legacy(1 if schema == 0 else schema)
		old.erase("unlocked_regions")
		old.erase("owned_gear")
		old.erase("selection")
		if schema == 0:
			old.erase("schema_version")
			old.erase("save_revision")
		var root_path: String = test_root.path_join("missing_fields_%d" % schema)
		var original_text: String = _seed(root_path, old)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "legacy missing fields schema %d loads" % schema)
		_check(int(store.state["currency"]) == 0 and _same(store.state["unlocked_regions"], ["lake"]), "missing legacy unlocks keep lake-only semantics and zero coins")
		_check(store.total_count() == 7 and store.discovered_count() == 1, "missing optional fields preserve exact historical counters")
		_check(_same(store.state["pending_catches"], old["pending_catches"]) and _same(store.state["historical_extension"], old["historical_extension"]), "missing optional fields preserve snapshots and extension data")
		_check(_read(root_path.path_join(Store.PRIMARY_NAME)) == original_text and _read(root_path.path_join(Store.BACKUP_NAME)) == original_text, "legacy normalization does not rewrite either original file")
		var candidate: Dictionary = store.state
		candidate["settings"]["vibration"] = false
		_check(store.commit_state(candidate), "legacy normalized optional fields can be committed")
		_check(_read(root_path.path_join(Store.BACKUP_NAME)) == original_text, "first normalized write keeps exact original bytes in rolling backup")
		var restart: Store = Store.new()
		_check(restart.initialize(root_path) and _same(restart.state, store.state), "normalized legacy restart adds no compensation")

func _test_existing_selected_regions() -> void:
	for region_id: String in ORIGINAL_REGIONS:
		var spot_id: String = str((catalog.region(region_id)["spots"] as Array).back())
		var old: Dictionary = _legacy(2, region_id, spot_id)
		var root_path: String = test_root.path_join("selected_" + region_id)
		_seed(root_path, old)
		var files_before: Dictionary = _files(root_path)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "existing selected " + region_id + " loads")
		_check(int(store.state["currency"]) == 0 and _same(store.state["unlocked_regions"], old["unlocked_regions"]), "existing selected " + region_id + " retains exact coins and unlocks")
		_check(_same(store.state["selection"], old["selection"]) and _same(store.state["species_stats"], old["species_stats"]), "existing selection and full catches remain exact in " + region_id)
		_check(region_id in store.state["unlocked_regions"] and str(catalog.spots[spot_id]["region_id"]) == region_id, "existing selected spot remains valid in " + region_id)
		_check(_files(root_path) == files_before, "existing selected profile bytes remain untouched")

func _test_import_and_undo() -> void:
	for schema: int in [1, 2, 0]:
		var old: Dictionary = _legacy(1 if schema == 0 else schema)
		old.erase("unlocked_regions")
		if schema == 0:
			old.erase("schema_version")
		var text: String = JSON.stringify(old, "  ", false, true)
		var root_path: String = test_root.path_join("import_%d" % schema)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "import destination starts as a fresh compensated profile")
		var initial: Dictionary = store.state
		var before_files: Dictionary = _files(root_path)
		var preview: Dictionary = store.inspect_save_text(text)
		_check(bool(preview.get("ok", false)) and int(preview.get("currency", -1)) == 0, "legacy import preview retains zero coins")
		_check(_same(preview.get("state", {}).get("unlocked_regions", []), ["lake"]), "legacy import preview does not grant absent unlocks")
		_check(_same(store.state, initial) and _files(root_path) == before_files, "preview does not mutate compensated destination")
		_check(bool(store.import_save_text(text, int(store.state["save_revision"])).get("ok", false)), "legacy import succeeds")
		var imported: Dictionary = store.state
		_check(int(imported["currency"]) == 0 and _same(imported["unlocked_regions"], ["lake"]), "import replaces compensation with exact historical funds and unlocks")
		_check(store.total_count() == 7 and store.discovered_count() == 1, "import retains exact historical catches")
		_check(_same(imported["pending_catches"], old["pending_catches"]) and _same(imported["selection"], old["selection"]), "import preserves historical pending fish and valid selection")
		var restart: Store = Store.new()
		_check(restart.initialize(root_path) and _same(restart.state, imported), "imported zero-balance profile restarts without a bonus")
		_check(bool(restart.restore_previous_save(int(restart.state["save_revision"])).get("ok", false)), "undo restores the actual pre-import snapshot")
		_check(_same(_without_revision(restart.state), _without_revision(initial)), "undo restores original fresh snapshot exactly, not a new bonus")
		_check(bool(restart.restore_previous_save(int(restart.state["save_revision"])).get("ok", false)), "redo restores the imported snapshot")
		_check(_same(_without_revision(restart.state), _without_revision(imported)), "redo preserves zero currency and lake-only unlocks again")
		var exported: Dictionary = restart.export_save_text()
		_check(bool(exported.get("ok", false)), "restored legacy state can export a portable envelope")
		var envelope_preview: Dictionary = restart.inspect_save_text(str(exported.get("text", "")))
		_check(bool(envelope_preview.get("checksum_verified", false)) and int(envelope_preview.get("currency", -1)) == 0, "portable envelope remains checksummed and uncompensated")
	# Explicit unlocks and non-lake selection are authoritative as well. Include
	# a later ocean save to prove already earned new-region progress also survives.
	for region_id: String in ["yangtze", "pacific_ocean"]:
		var spot_id: String = str((catalog.region(region_id)["spots"] as Array).back())
		var old: Dictionary = _legacy(2, region_id, spot_id)
		old["currency"] = 731
		var root_path: String = test_root.path_join("explicit_import_" + region_id)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "explicit-selection import fixture initializes")
		var preview: Dictionary = store.inspect_save_text(JSON.stringify(old))
		_check(bool(preview.get("ok", false)) and _same(preview["state"]["unlocked_regions"], old["unlocked_regions"]), "explicit import preview retains exact selected-region unlock subset")
		_check(bool(store.import_save_text(JSON.stringify(old), int(store.state["save_revision"])).get("ok", false)), "explicit-selection import succeeds")
		_check(int(store.state["currency"]) == 731 and _same(store.state["unlocked_regions"], old["unlocked_regions"]), "explicit import preserves nonzero balance and exact unlock subset")
		_check(_same(store.state["selection"], old["selection"]) and region_id in store.state["unlocked_regions"], "explicit imported selected region stays valid and unlocked")
		_check(_same(store.state["species_stats"], old["species_stats"]) and _same(store.state["pending_catches"], old["pending_catches"]), "explicit import preserves all real historical catches")
		var restart: Store = Store.new()
		_check(restart.initialize(root_path) and _same(restart.state, store.state), "explicit selected-region import restarts without compensation")

func _test_creation_failures() -> void:
	for failure: String in ["write_primary", "validation", "write_backup", "backup_replace", "primary_replace", "final_validation"]:
		var root_path: String = test_root.path_join("creation_failure_" + failure)
		var store: FailingStore = FailingStore.new()
		store.fail_once = failure
		_check(not store.initialize(root_path) and not store.error_message.is_empty(), failure + " prevents a claimed successful fresh creation")
		_check(_same(store.state, Store.default_state()), failure + " publishes no uncommitted compensated state")
		var files_after_failure: Dictionary = _files(root_path)
		_check(not store.commit_state(store.state), failure + " leaves failed initializer unable to write")
		_check(not bool(store.export_save_text().get("ok", false)), failure + " cannot export a failed new profile")
		_check(_files(root_path) == files_after_failure, failure + " blocked follow-up calls do not alter disk bytes")
		_check(store.initialize(root_path), failure + " initialization retry recovers safely: " + store.error_message)
		_check_fresh(store.state, failure + " recovered fresh profile")
		_check(store.total_count() == 0 and store.discovered_count() == 0, failure + " recovery adds no fictitious catches")
		var recovered: Dictionary = store.state
		_check(store.commit_state(store.state), failure + " recovered profile can commit normally")
		var restart: Store = Store.new()
		_check(restart.initialize(root_path), failure + " committed recovery restarts")
		_check(_same(_without_revision(restart.state), _without_revision(recovered)), failure + " recovery/restart grants compensation exactly once")

func _test_existing_recovery_and_protection() -> void:
	for missing_primary: bool in [false, true]:
		var root_path: String = test_root.path_join("old_recovery_%s" % str(missing_primary))
		var old: Dictionary = _legacy(1)
		old.erase("unlocked_regions")
		var text: String = _seed(root_path, old)
		if missing_primary:
			_check(DirAccess.remove_absolute(root_path.path_join(Store.PRIMARY_NAME)) == OK, "fixture removes primary only")
		else:
			_write(root_path.path_join(Store.PRIMARY_NAME), "{broken old primary")
		var files_before: Dictionary = _files(root_path)
		var store: Store = Store.new()
		_check(store.initialize(root_path), "old backup recovers despite missing/corrupt primary")
		_check(int(store.state["currency"]) == 0 and _same(store.state["unlocked_regions"], ["lake"]), "old backup recovery never uses fresh compensation")
		_check(store.total_count() == 7 and store.discovered_count() == 1, "old backup recovery retains real historical catches")
		_check(_files(root_path) == files_before, "reading recovered old backup leaves original bytes untouched")
		_check(store.commit_state(store.state), "old recovered state writes normally")
		_check(_read(root_path.path_join(Store.BACKUP_NAME)) == text, "old valid backup remains exact after recovery write")
		var restart: Store = Store.new()
		_check(restart.initialize(root_path) and _same(restart.state, store.state), "old recovered state restarts without fresh grants")
	for mode: String in ["both_corrupt", "future_primary", "future_backup", "unresolved_rollback"]:
		var root_path: String = test_root.path_join(mode)
		_seed(root_path, _legacy(2))
		if mode == "both_corrupt":
			_write(root_path.path_join(Store.PRIMARY_NAME), "{old corrupted primary")
			_write(root_path.path_join(Store.BACKUP_NAME), "{old corrupted backup")
		elif mode.begins_with("future_"):
			_write(root_path.path_join(Store.PRIMARY_NAME if mode == "future_primary" else Store.BACKUP_NAME), '{"schema_version":999,"currency":0,"species_stats":{}}')
		else:
			_write(root_path.path_join(Store.IMPORT_ROLLBACK_PREFIX + "fixture.json"), JSON.stringify(_legacy(2)))
		var files_before: Dictionary = _files(root_path)
		var store: Store = Store.new()
		_check(not store.initialize(root_path) and store.read_only, mode + " remains protected rather than treated as fresh")
		_check(not store.commit_state(Store.fresh_state()), mode + " cannot commit fresh compensation over existing data")
		_check(_files(root_path) == files_before, mode + " preserves primary, backup and previous-save bytes")
