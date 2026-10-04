extends SceneTree
## Real SaveStore I/O regression; no Main, artwork, player data, or Android device.
## Run in isolated HOME/XDG directories; every fixture is under a fresh /tmp root.
## Historical IDs/locations/anchor dimensions were transcribed with git show from
## installed 1.2.0 commit 7df14ff (fish_a..d.json and world.json), NOT live catalogs.
## Synthetic progress models that release's documented schema; it is not a user save.

const Store = preload("res://scripts/save_store.gd")
const Catalog = preload("res://scripts/catalog.gd")
const HISTORICAL_SPECIES: Array = [
	["common_carp", "lake", "lake_shore", 450, 1500],
	["crucian_carp", "lake", "lake_shore", 230, 280],
	["roach", "lake", "lake_shore", 220, 160],
	["rudd", "lake", "lake_shore", 240, 240],
	["european_perch", "lake", "lake_shore", 280, 330],
	["northern_pike", "lake", "lake_bay", 600, 1600],
	["common_bream", "lake", "lake_bay", 420, 1000],
	["tench", "lake", "lake_shore", 360, 750],
	["japanese_horse_mackerel", "japan", "japan_harbor", 240, 150],
	["chub_mackerel", "japan", "japan_reef", 320, 350],
	["red_seabream", "japan", "japan_reef", 380, 900],
	["black_seabream", "japan", "japan_harbor", 330, 600],
	["japanese_seabass", "japan", "japan_harbor", 520, 1500],
	["japanese_whiting", "japan", "japan_harbor", 200, 70],
	["marbled_rockfish", "japan", "japan_reef", 230, 250],
	["olive_flounder", "japan", "japan_reef", 480, 1100],
	["atlantic_cod", "norway", "norway_harbor", 650, 2600],
	["pollack", "norway", "norway_harbor", 550, 1700],
	["saithe", "norway", "norway_harbor", 600, 2200],
	["haddock", "norway", "norway_boat", 420, 900],
	["atlantic_mackerel", "norway", "norway_harbor", 350, 500],
	["atlantic_herring", "norway", "norway_boat", 270, 230],
	["european_plaice", "norway", "norway_harbor", 350, 650],
	["atlantic_wolffish", "norway", "norway_boat", 750, 4000],
	["european_seabass", "med", "med_pier", 450, 1100],
	["gilthead_seabream", "med", "med_pier", 380, 1100],
	["saddled_seabream", "med", "med_pier", 220, 210],
	["white_seabream", "med", "med_pier", 270, 450],
	["annular_seabream", "med", "med_pier", 160, 110],
	["red_mullet", "med", "med_boat", 210, 160],
	["painted_comber", "med", "med_pier", 180, 130],
	["common_pandora", "med", "med_boat", 280, 450],
	["alligator_gar", "bayou", "bayou_backwater", 1400, 22000],
	["longnose_gar", "bayou", "bayou_backwater", 900, 3500],
	["bowfin", "bayou", "bayou_backwater", 500, 1500],
	["largemouth_bass", "bayou", "bayou_backwater", 400, 1200],
	["channel_catfish", "bayou", "bayou_backwater", 550, 2000],
	["flathead_catfish", "bayou", "bayou_backwater", 750, 8000],
	["chinese_sturgeon", "yangtze", "yangtze_estuary", 1400, 18000],
	["mandarin_fish", "yangtze", "yangtze_river", 360, 900],
	["northern_snakehead", "yangtze", "yangtze_river", 450, 1000],
	["yellowcheek", "yangtze", "yangtze_river", 700, 3500],
	["southern_catfish", "yangtze", "yangtze_river", 650, 2500],
	["longsnout_catfish", "yangtze", "yangtze_river", 450, 1100],
]
const HISTORICAL_REGIONS: Array = ["lake", "japan", "norway", "med", "bayou", "yangtze"]
const OCEAN_REGIONS: Array = ["pacific_ocean", "atlantic_ocean", "indian_ocean"]
const OCEAN_SPECIES: Array = [
	"atlantic_bluefin_tuna", "pacific_bluefin_tuna", "yellowfin_tuna", "bigeye_tuna", "albacore",
	"skipjack_tuna", "mahi_mahi", "wahoo", "swordfish", "blue_marlin", "striped_marlin",
	"indo_pacific_sailfish", "great_barracuda", "giant_trevally", "greater_amberjack", "cobia",
	"roosterfish", "red_snapper", "giant_grouper", "dogtooth_tuna", "yellowtail_kingfish", "opah",
	"great_white_shark", "scalloped_hammerhead", "great_hammerhead", "blue_shark", "shortfin_mako",
	"tiger_shark", "oceanic_whitetip_shark", "whitetip_reef_shark"
]

class FailingStore extends "res://scripts/save_store.gd":
	var fail_once: String = ""
	var fail_rollback_once: bool = false
	func _copy_verified(source: String, destination: String) -> bool:
		if fail_once == "snapshot_copy" and destination.get_file().begins_with("save.before-import.rollback-"):
			fail_once = ""
			return super._copy_verified(source + ".does-not-exist", destination)
		return super._copy_verified(source, destination)
	func _write_verified_json(path: String, value: Dictionary) -> bool:
		if (fail_once == "snapshot_write" and path.ends_with("/save.before-import.tmp.json")) or (fail_once == "write" and path.ends_with("/save.tmp.json")):
			fail_once = ""
			return super._write_verified_json(path.path_join("missing/blocked.json"), value)
		return super._write_verified_json(path, value)
	func _read_save(path: String) -> Dictionary:
		if (fail_once == "snapshot_validation" and path.ends_with("/save.before-import.tmp.json")) or (fail_once == "validation" and path.ends_with("/save.tmp.json")):
			fail_once = ""
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string("{truncated temporary write")
				file.close()
		return super._read_save(path)
	func _replace_file(source: String, destination: String) -> bool:
		if fail_rollback_once and source.get_file().begins_with("save.before-import.rollback-"):
			fail_rollback_once = false
			return super._replace_file(source + ".does-not-exist", destination)
		if (fail_once == "snapshot_replace" and destination.ends_with("/save.before-import.json")) or (fail_once == "primary_replace" and destination.ends_with("/save.json")) or (fail_once == "backup_replace" and destination.ends_with("/save.backup.json")):
			fail_once = ""
			return super._replace_file(source + ".does-not-exist", destination)
		return super._replace_file(source, destination)

var checks: int = 0
var failures: int = 0
var test_root: String = ""
var catalog: ContentCatalog

func _initialize() -> void:
	test_root = "/tmp/farshore-ocean-save-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(test_root) != OK:
		printerr("Cannot create isolated fixture root")
		quit(1)
		return
	print("OCEAN_SAVE_TEST_ROOT=", test_root)
	catalog = Catalog.new()
	_check(catalog.load_all(false), "data-only expanded catalog validates: " + str(catalog.errors))
	_test_historical_catalog_bindings()
	_test_historical_expansion(2, false)
	_test_historical_expansion(1, false)
	_test_historical_expansion(1, true)
	_test_historical_dispositions()
	_test_transfer_roundtrip()
	_test_transfer_validation()
	_test_import_guards()
	_test_failed_imports_and_undo()
	_test_failed_snapshot_copy_and_rollback()
	_test_corruption_and_future_saves()
	print("OCEAN_SAVE_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func _json(value: Variant) -> String:
	return JSON.stringify(value, "", true, true)

func _same(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(_json(left)) == JSON.parse_string(_json(right))

func _expected_runtime(value: Dictionary) -> Dictionary:
	# Legacy fixture files intentionally have no whale namespace. The current
	# reader adds this empty independent progress field in memory; all historical
	# fields and original disk bytes must still compare exactly.
	var result: Dictionary = value.duplicate(true)
	if not result.has("whale_challenge"):
		result["whale_challenge"] = {"completion_count": 0, "notebook_unlocked": false,
			"first": {}, "last": {}, "best": {}, "recent_ids": []}
	return result

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

func _files(root_path: String) -> Dictionary:
	var result: Dictionary = {}
	for name: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME, Store.PRE_IMPORT_NAME]:
		result[name] = _read(root_path.path_join(name))
	return result

func _seed(root_path: String, state: Dictionary) -> String:
	# Deliberate whitespace tests source-byte preservation, not just canonical JSON.
	var text: String = JSON.stringify(state, "  ", false, true) + "\n"
	_write(root_path.path_join(Store.PRIMARY_NAME), text)
	_write(root_path.path_join(Store.BACKUP_NAME), text)
	return text

func _historical_record(row: Array, index: int, kind: String, length_mm: int, weight_g: int) -> Dictionary:
	var record: Dictionary = {
		"catch_id": "old_%02d_%s" % [index, kind], "session_id": "old_session_%02d_%s" % [index, kind],
		"species_id": row[0], "length_mm": length_mm, "weight_g": weight_g,
		"region_id": row[1], "spot_id": row[2], "caught_at": "2026-10-02T07:%02d:00Z" % index,
		"game_time": 1000.25 + index, "weather": "rain" if index % 2 else "clear",
		"equipment": {"gear": 4, "name": "重潮 · 巨物枪柄竿", "historical_rig": {"line": "braid", "knots": 3}},
		"bait_id": "cut_fish", "disposition": "pending", "reward": 25, "sale_value": 20 + index,
		"legacy_record_extension": {"note": "历史照片与独立尺寸记录", "tags": [kind, index]}
	}
	if row[0] == "chinese_sturgeon":
		record["release_only"] = true
		record["conservation_note"] = "虚拟保护观察：中华鲟必须放归，不可出售。"
		record["sale_value"] = 0
	return record

func _historical_fixture(schema: int = 2, implicit_schema: bool = false) -> Dictionary:
	# Spell out historical fields; do not derive them from Store.default_state().
	var result: Dictionary = {
		"schema_version": schema, "save_revision": 417, "currency": 1234567,
		"gear": 4, "owned_gear": [0, 1, 2, 3, 4],
		"unlocked_regions": ["lake", "japan", "norway", "med", "bayou", "yangtze"],
		"favorites": ["common_carp", "atlantic_cod", "chinese_sturgeon", "alligator_gar", "olive_flounder", "longsnout_catfish"],
		"species_stats": {}, "pending_catches": {}, "recent_ids": [],
		"settings": {"sound": false, "vibration": false, "volume": 0.35},
		"selection": {"region_id": "yangtze", "spot_id": "yangtze_estuary", "bait_id": "cut_fish"},
		"game_clock": 98765.125,
		# Added compatibility sentinels are synthetic; no claim the old producer emitted them.
		"legacy_extension": {"note": "保留旧旅行记录", "nested": [null, true, 2.5, {"stamp": "old_v1_2_0"}]}
	}
	for index: int in range(HISTORICAL_SPECIES.size()):
		var row: Array = HISTORICAL_SPECIES[index]
		var length_mm: int = int(row[3])
		var weight_g: int = int(row[4])
		var stats: Dictionary = {
			"catch_count": 7 + index,
			"first": _historical_record(row, index, "first", length_mm - 20, weight_g - 20),
			"last": _historical_record(row, index, "last", length_mm, weight_g),
			"max_length": _historical_record(row, index, "longest", length_mm + 40, weight_g - 10),
			"max_weight": _historical_record(row, index, "heaviest", length_mm - 10, weight_g + 100),
			"regions": {str(row[1]): 7 + index}, "legacy_stats_extension": "separate real fish snapshots"
		}
		if index == 0:
			stats["last"]["region_id"] = "yangtze"
			stats["last"]["spot_id"] = "yangtze_river"
			stats["regions"] = {"lake": 4, "yangtze": 3}
		if index % 4 == 0 or row[0] == "chinese_sturgeon":
			result["pending_catches"][stats["last"]["catch_id"]] = stats["last"].duplicate(true)
		for key: String in ["first", "last", "max_length", "max_weight"]:
			result["recent_ids"].append(stats[key]["catch_id"])
		if schema == 1:
			stats["count"] = stats["catch_count"]
			stats["region_counts"] = stats["regions"]
			stats.erase("catch_count")
			stats.erase("regions")
		result["species_stats"][row[0]] = stats
	if implicit_schema:
		result.erase("schema_version")
		result.erase("save_revision")
		result["settings"].erase("vibration")
		result["settings"].erase("volume")
	return result

func _ocean_record(index: int) -> Dictionary:
	var species_id: String = OCEAN_SPECIES[index]
	var fish: FishDefinition = catalog.fish[species_id]
	var spot_id: String = str(fish.spots()[0])
	var record: Dictionary = {
		"catch_id": "ocean_%02d" % index, "session_id": "ocean_session_%02d" % index,
		"species_id": species_id, "length_mm": fish.anchor_mm, "weight_g": fish.anchor_g,
		"region_id": str(catalog.spots[spot_id]["region_id"]), "spot_id": spot_id,
		"caught_at": "2026-10-04T08:%02d:00Z" % index, "game_time": 100001.25 + index,
		"weather": "clear", "equipment": {"gear": 4, "name": "重潮 · 巨物枪柄竿"},
		"bait_id": "cut_fish", "disposition": "pending", "reward": 25 + index, "sale_value": 50 + index
	}
	if bool(fish.raw.get("release_only", false)):
		record["release_only"] = true
		record["conservation_note"] = str(fish.raw.get("conservation_note", "保护观察"))
		record["sale_value"] = 0
	return record

func _settle(store: Store, record: Dictionary) -> Dictionary:
	store.begin_session(str(record["session_id"]))
	return store.settle_catch(record)

func _test_historical_catalog_bindings() -> void:
	_check(Store.SCHEMA_VERSION == 2, "expansion keeps installed release schema 2")
	_check(HISTORICAL_SPECIES.size() == 44 and OCEAN_SPECIES.size() == 30, "independent 44 + 30 literal identities")
	_check(catalog.fish.size() == 111 and catalog.fish_species_count() == 110 and catalog.regions.size() == 10 and catalog.spots.size() == 21 and catalog.gear.size() == 6, "current catalog keeps 110 fish, one mammal, ten regions, 21 spots and six rods")
	for row: Array in HISTORICAL_SPECIES:
		_check(catalog.fish.has(row[0]), "historical fish identity remains: " + str(row[0]))
		_check(catalog.spots.has(row[2]) and str(catalog.spots[row[2]]["region_id"]) == row[1], "historical location remains: " + str(row[2]))
	for species_id: String in OCEAN_SPECIES:
		_check(catalog.fish.has(species_id), "new ocean identity exists: " + species_id)
	for region_id: String in HISTORICAL_REGIONS + OCEAN_REGIONS:
		_check(not catalog.region(region_id).is_empty(), "old/new region identity exists: " + region_id)
	for index: int in range(5):
		_check(int(catalog.gear[index]["id"]) == index, "historical numeric equipment ID remains: %d" % index)
	_check(not catalog.bait_definition("cut_fish").is_empty(), "historical selected bait remains valid")
	print("PASS GROUP historical identifiers and data-only catalog bindings")

func _test_historical_expansion(schema: int, implicit_schema: bool) -> void:
	var label: String = "schema_%d%s" % [schema, "_implicit" if implicit_schema else ""]
	var root_path: String = test_root.path_join(label)
	var raw: Dictionary = _historical_fixture(schema, implicit_schema)
	_check(not raw.has("whale_challenge"), label + " raw historical fixture has no invented whale progress")
	var original_bytes: String = _seed(root_path, raw)
	var store: Store = Store.new()
	_check(store.initialize(root_path), label + " loads literal 44-species fixture: " + store.error_message)
	var expected: Dictionary = _expected_runtime(_historical_fixture())
	if implicit_schema:
		expected["save_revision"] = 0
		expected["settings"]["vibration"] = true
		expected["settings"]["volume"] = 0.6
	_check(_same(store.state, expected), label + " entire state normalizes exactly, including extension fields")
	_check(store.total_count() == 1254 and store.discovered_count() == 44, label + " historical count is exact, without replay")
	_check(_files(root_path) == {Store.PRIMARY_NAME: original_bytes, Store.BACKUP_NAME: original_bytes, Store.PRE_IMPORT_NAME: "<absent>"}, label + " initialization/migration preserves all original disk bytes")
	for row: Array in HISTORICAL_SPECIES:
		var stats: Dictionary = store.state["species_stats"][row[0]]
		_check(stats["first"]["catch_id"] != stats["last"]["catch_id"] and stats["max_length"]["catch_id"] != stats["max_weight"]["catch_id"], label + " independent first/last/length/weight: " + str(row[0]))
		_check(_same(stats, expected["species_stats"][row[0]]), label + " exact historical snapshots and count: " + str(row[0]))
	var before: Dictionary = store.state
	var candidate: Dictionary = store.state
	(candidate["unlocked_regions"] as Array).append_array(OCEAN_REGIONS)
	_check(store.commit_state(candidate), label + " appends three ocean regions")
	_check(_read(root_path.path_join(Store.BACKUP_NAME)) == original_bytes, label + " first commit preserves original historical bytes as rolling backup")
	var reward_total: int = 0
	for index: int in range(OCEAN_SPECIES.size()):
		var record: Dictionary = _ocean_record(index)
		var result: Dictionary = _settle(store, record)
		_check(bool(result.get("ok", false)) and bool(result.get("new_species", false)), label + " settles new species once: " + str(record["species_id"]))
		reward_total += int(record["reward"])
		var settled: Dictionary = store.state
		var bytes_after: Dictionary = _files(root_path)
		var duplicate: Dictionary = store.settle_catch(record)
		_check(not bool(duplicate["ok"]) and bool(duplicate["duplicate"]) and _same(store.state, settled) and _files(root_path) == bytes_after, label + " duplicate callback cannot add counts or currency")
	_check(store.total_count() == 1284 and store.discovered_count() == 74, label + " 30 discoveries append without resetting old counters")
	_check(int(store.state["currency"]) == 1234567 + reward_total, label + " exact independent catch reward total")
	for row: Array in HISTORICAL_SPECIES:
		_check(_same(store.state["species_stats"][row[0]], before["species_stats"][row[0]]), label + " new catches retain entire old species entry: " + str(row[0]))
	for key: String in ["favorites", "gear", "owned_gear", "settings", "selection", "game_clock", "legacy_extension"]:
		_check(_same(store.state[key], before[key]), label + " extension retains " + key)
	for catch_id: String in before["pending_catches"]:
		_check(_same(store.state["pending_catches"][catch_id], before["pending_catches"][catch_id]), label + " historical pending catch remains intact")
	_check((store.state["pending_catches"] as Dictionary).size() == 42, label + " twelve old pending plus thirty new pending coexist")
	_check(_same(store.state["unlocked_regions"], HISTORICAL_REGIONS + OCEAN_REGIONS), label + " six old plus three new unlocks coexist")
	var combined: Dictionary = store.state
	var combined_bytes: Dictionary = _files(root_path)
	var restart: Store = Store.new()
	_check(restart.initialize(root_path) and _same(restart.state, combined), label + " exact entire expanded-state restart")
	_check(restart.total_count() == 1284 and restart.discovered_count() == 74 and _files(root_path) == combined_bytes, label + " restart replays no rewards, counters, writes")
	var duplicate_old: Dictionary = before["species_stats"]["common_carp"]["last"]
	_check(not bool(restart.settle_catch(duplicate_old)["ok"]) and _same(restart.state, combined), label + " original historical catch remains deduplicated")
	print("PASS GROUP ", label, " retains old history and appends thirty fish/three regions")

func _test_historical_dispositions() -> void:
	var root_path: String = test_root.path_join("old_dispositions")
	_seed(root_path, _historical_fixture())
	var store: Store = Store.new()
	_check(store.initialize(root_path), "old dispositions initialize")
	var before: Dictionary = store.state
	var primary: String = _read(root_path.path_join(Store.PRIMARY_NAME))
	_check(not bool(store.dispose_catch("old_38_last", "sold")["ok"]), "historical protected sturgeon remains unsellable")
	_check(_same(store.state, before) and _read(root_path.path_join(Store.PRIMARY_NAME)) == primary, "protected historical sale is side-effect free")
	_check(bool(store.dispose_catch("old_00_last", "sold")["ok"]), "historical pending carp may be sold after update")
	_check(bool(store.dispose_catch("old_38_last", "released")["ok"]), "historical protected sturgeon may be released")
	_check(int(store.state["currency"]) == 1234595 and store.total_count() == 1254, "historical disposition grants exactly original sale value plus release bonus")
	_check(_same(store.state["species_stats"], before["species_stats"]), "disposition retains all historical snapshots, including recorded disposition")
	var after: Dictionary = store.state
	_check(not bool(store.dispose_catch("old_00_last", "sold")["ok"]) and not bool(store.dispose_catch("old_38_last", "released")["ok"]) and _same(store.state, after), "historical dispositions cannot be repeated")
	var restart: Store = Store.new()
	_check(restart.initialize(root_path) and _same(restart.state, after), "historical disposition persists once across restart")
	print("PASS GROUP historical pending/disposition/protection compatibility")

func _expanded_fixture() -> Dictionary:
	var result: Dictionary = _historical_fixture()
	result["save_revision"] = 923
	result["currency"] = 9876543
	(result["unlocked_regions"] as Array).append_array(OCEAN_REGIONS)
	result["settings"].merge({"ambience_volume": 0.2, "effects_volume": 0.8, "reduce_motion": true, "visual_quality": "low", "unknown_sound_extension": "retain"})
	var first: Dictionary = _ocean_record(0)
	result["selection"] = {"region_id": first["region_id"], "spot_id": first["spot_id"], "bait_id": "cut_fish", "legacy_selection_extension": 17}
	for index: int in range(OCEAN_SPECIES.size()):
		var record: Dictionary = _ocean_record(index)
		result["species_stats"][record["species_id"]] = {"catch_count": 1, "first": record.duplicate(true), "last": record.duplicate(true), "max_length": record.duplicate(true), "max_weight": record.duplicate(true), "regions": {str(record["region_id"]): 1}}
		result["pending_catches"][record["catch_id"]] = record.duplicate(true)
		result["recent_ids"].append(record["catch_id"])
	return result

func _envelope(value: Dictionary) -> String:
	var payload: String = _json(value)
	return _json({"format": "farshore-fishing-backup", "format_version": 1, "created_at": "2026-10-04T00:00:00", "sha256": payload.sha256_text(), "payload": payload})

func _test_transfer_roundtrip() -> void:
	var source_root: String = test_root.path_join("transfer_source")
	var raw_source: Dictionary = _expanded_fixture()
	var expected: Dictionary = _expected_runtime(raw_source)
	_seed(source_root, raw_source)
	var source: Store = Store.new()
	_check(source.initialize(source_root), "expanded transfer source initializes")
	var source_files: Dictionary = _files(source_root)
	var export_result: Dictionary = source.export_save_text()
	_check(bool(export_result.get("ok", false)), "expanded save exports to portable text")
	var text: String = str(export_result.get("text", ""))
	var envelope: Dictionary = JSON.parse_string(text)
	_check(envelope["format"] == "farshore-fishing-backup" and int(envelope["format_version"]) == 1, "portable envelope identity/version unchanged")
	_check(str(envelope["payload"]).sha256_text() == str(envelope["sha256"]) and _same(JSON.parse_string(envelope["payload"]), expected), "export checksum covers exact complete payload")
	_check(_same(source.state, expected) and _files(source_root) == source_files, "export never changes progress or disk bytes")
	var root_path: String = test_root.path_join("transfer_destination")
	_seed(root_path, _historical_fixture())
	var store: Store = Store.new()
	_check(store.initialize(root_path), "transfer destination initializes with historical progress")
	var before: Dictionary = store.state
	var before_files: Dictionary = _files(root_path)
	var preview: Dictionary = store.inspect_save_text("\uFEFF \n" + text + "\n ")
	_check(bool(preview.get("ok", false)) and bool(preview.get("checksum_verified", false)), "BOM/whitespace portable preview verifies checksum")
	_check(int(preview["catch_count"]) == 1284 and int(preview["discovered_count"]) == 74 and int(preview["pending_count"]) == 42 and int(preview["currency"]) == 9876543, "preview reports exact full expanded progress")
	_check(_same(preview["state"], expected), "preview retains all historical and new fields")
	preview["state"]["currency"] = 1
	_check(_same(store.state, before) and _files(root_path) == before_files and not store.has_previous_save(), "preview/cancel/detached preview state never write or replace local progress")
	var imported: Dictionary = store.import_save_text(text, int(before["save_revision"]))
	_check(bool(imported.get("ok", false)), "confirmed expanded portable import succeeds")
	expected["save_revision"] = 418
	_check(_same(store.state, expected) and int(imported["save_revision"]) == 418, "import uses local next revision, all source progress otherwise exact")
	_check(store.has_previous_save(), "import preserves an undo snapshot")
	var previous_export: Dictionary = store.export_previous_save_text()
	var previous_preview: Dictionary = store.inspect_save_text(str(previous_export.get("text", "")))
	_check(bool(previous_export.get("ok", false)) and bool(previous_preview.get("checksum_verified", false)) and _same(previous_preview["state"], before), "previous-save export retains exact pre-import progress")
	var restart: Store = Store.new()
	_check(restart.initialize(root_path) and _same(restart.state, expected) and restart.has_previous_save(), "import plus undo snapshot survive restart exactly")
	var imported_files: Dictionary = _files(root_path)
	_check(not bool(restart.restore_previous_save(417).get("ok", false)) and _same(restart.state, expected) and _files(root_path) == imported_files, "stale undo confirmation cannot discard current progress")
	_check(bool(restart.restore_previous_save(418).get("ok", false)), "undo successfully restores historical save")
	before["save_revision"] = 419
	_check(_same(restart.state, before), "undo restores complete historical progress with monotonic local revision")
	var redo_preview: Dictionary = restart.inspect_save_text(str(restart.export_previous_save_text().get("text", "")))
	_check(_same(redo_preview["state"], expected), "undo is itself reversible; prior ocean state remains available")
	_check(bool(restart.restore_previous_save(419).get("ok", false)), "redo restores expanded progress")
	expected["save_revision"] = 420
	_check(_same(restart.state, expected), "redo retains exact expanded progress without replay")
	var final_reload: Store = Store.new()
	_check(final_reload.initialize(root_path) and _same(final_reload.state, expected), "redo restarts exactly")
	# Raw version 1 is supported but deliberately not labelled checksum-verified.
	var raw_v1: String = _json(_historical_fixture(1))
	var raw_preview: Dictionary = final_reload.inspect_save_text(raw_v1)
	_check(bool(raw_preview.get("ok", false)) and not bool(raw_preview.get("checksum_verified", true)) and int(raw_preview["schema_version"]) == 1, "legacy schema 1 raw preview accurately reports absent checksum")
	_check(bool(final_reload.import_save_text(raw_v1, 420).get("ok", false)), "legacy schema 1 raw backup imports")
	before["save_revision"] = 421
	_check(_same(final_reload.state, before), "legacy import migrates without changing any historical progress")
	print("PASS GROUP backup export/checksum/preview/import/undo/redo/raw migration")

func _test_transfer_validation() -> void:
	var root_path: String = test_root.path_join("transfer_invalid")
	_seed(root_path, _historical_fixture())
	var store: Store = Store.new()
	_check(store.initialize(root_path), "invalid transfer fixture initializes")
	var before: Dictionary = store.state
	var before_files: Dictionary = _files(root_path)
	var valid: Dictionary = JSON.parse_string(_envelope(_expanded_fixture()))
	var cases: Dictionary = {"empty": "", "truncated_json": "{", "array": "[]", "random_object": "{}", "missing_species": '{"currency": 5}', "missing_currency": '{"species_stats": {}}'}
	var changed: Dictionary = valid.duplicate(true)
	changed["payload"] = str(changed["payload"]) + " "
	cases["tampered_payload"] = _json(changed)
	changed = valid.duplicate(true)
	changed["sha256"] = "0".repeat(64)
	cases["wrong_checksum"] = _json(changed)
	changed = valid.duplicate(true)
	changed.erase("sha256")
	cases["missing_checksum"] = _json(changed)
	changed = valid.duplicate(true)
	changed["format"] = "another-game"
	cases["wrong_game"] = _json(changed)
	for version: Variant in [2, 0, 1.5, "1"]:
		changed = valid.duplicate(true)
		changed["format_version"] = version
		cases["envelope_version_" + str(version)] = _json(changed)
	changed = valid.duplicate(true)
	changed["payload"] = "[]"
	changed["sha256"] = "[]".sha256_text()
	cases["checksummed_non_save"] = _json(changed)
	for version: Variant in [3, 0, 1.5, "2"]:
		changed = _historical_fixture()
		changed["schema_version"] = version
		cases["schema_version_" + str(version)] = _envelope(changed)
	for setting: String in ["ambience_volume", "effects_volume", "reduce_motion", "visual_quality"]:
		changed = _historical_fixture()
		changed["settings"][setting] = 2.0
		cases["invalid_setting_" + setting] = _envelope(changed)
	changed = _historical_fixture()
	changed["currency"] = -1
	cases["negative_currency"] = _envelope(changed)
	changed = _historical_fixture()
	changed["species_stats"]["common_carp"]["regions"]["lake"] = 10000
	cases["regional_count_exceeds_total"] = _envelope(changed)
	changed = _historical_fixture()
	changed["pending_catches"]["old_00_last"]["disposition"] = "sold"
	cases["invalid_pending_disposition"] = _envelope(changed)
	changed = _historical_fixture()
	changed["favorites"].append("atlantic_cod")
	cases["duplicate_favorite"] = _envelope(changed)
	for label: String in cases:
		var preview: Dictionary = store.inspect_save_text(cases[label])
		_check(not bool(preview.get("ok", false)) and not str(preview.get("error", "")).is_empty(), label + " preview rejects with reason")
		var result: Dictionary = store.import_save_text(cases[label], int(before["save_revision"]))
		_check(not bool(result.get("ok", false)) and not str(result.get("error", "")).is_empty(), label + " import rejects with reason")
		_check(_same(store.state, before) and _files(root_path) == before_files, label + " rejection preserves every live byte and all progress")
	var too_big: String = " ".repeat(Store.MAX_TRANSFER_BYTES + 1)
	_check(not bool(store.inspect_save_text(too_big).get("ok", false)) and not bool(store.import_save_text(too_big, 417).get("ok", false)), "oversized envelope rejected before decoding")
	_check(_same(store.state, before) and _files(root_path) == before_files, "oversized backup rejection never writes")
	print("PASS GROUP malformed/checksum/future/version/semantic/size rejection")

func _test_import_guards() -> void:
	var root_path: String = test_root.path_join("import_guards")
	_seed(root_path, _historical_fixture())
	var store: FailingStore = FailingStore.new()
	_check(store.initialize(root_path), "import guards initialize")
	var text: String = _envelope(_expanded_fixture())
	var before: Dictionary = store.state
	var before_files: Dictionary = _files(root_path)
	store.begin_session("in_progress")
	_check(not bool(store.import_save_text(text, 417).get("ok", false)) and _same(store.state, before) and _files(root_path) == before_files, "active fishing session blocks import without writing")
	store.abandon_session("in_progress")
	store.fail_once = "write"
	var record: Dictionary = _ocean_record(0)
	_check(not bool(_settle(store, record).get("ok", false)), "failed catch creates genuine retry-pending session")
	_check(not bool(store.import_save_text(text, 417).get("ok", false)) and _same(store.state, before) and _files(root_path) == before_files, "unsaved catch retry blocks import and preserves original progress")
	_check(bool(store.settle_catch(record).get("ok", false)), "original failed catch still retries after blocked import")
	before = store.state
	before_files = _files(root_path)
	_check(not bool(store.import_save_text(text, 417).get("ok", false)) and _same(store.state, before) and _files(root_path) == before_files, "stale preview revision cannot discard newly saved catch")
	_check(not bool(store.import_save_text(text, -1).get("ok", false)), "negative expected revision rejected")
	for name: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME, Store.PRE_IMPORT_NAME]:
		var future_root: String = test_root.path_join("import_future_" + name)
		_seed(future_root, _historical_fixture())
		var current: Store = Store.new()
		_check(current.initialize(future_root), name + " future guard fixture initializes")
		var future: Dictionary = _historical_fixture()
		future["schema_version"] = 3
		_write(future_root.path_join(name), _json(future))
		var files_before: Dictionary = _files(future_root)
		_check(not bool(current.import_save_text(text, 417).get("ok", false)) and _same(current.state, _expected_runtime(_historical_fixture())) and _files(future_root) == files_before, name + " introduced future file prevents import without touching any file")
	var max_root: String = test_root.path_join("revision_limit")
	var at_limit: Dictionary = _historical_fixture()
	at_limit["save_revision"] = Store.MAX_COUNTER
	_seed(max_root, at_limit)
	var limit: Store = Store.new()
	_check(limit.initialize(max_root), "maximum revision readable")
	before_files = _files(max_root)
	_check(not bool(limit.import_save_text(text, Store.MAX_COUNTER).get("ok", false)) and _same(limit.state, _expected_runtime(at_limit)) and _files(max_root) == before_files, "revision limit cannot replace state or undo snapshot")
	print("PASS GROUP active/retry/stale/future-file/revision-limit import guards")

func _test_failed_imports_and_undo() -> void:
	var modes: Array = ["snapshot_write", "snapshot_validation", "snapshot_replace", "write", "validation", "backup_replace", "primary_replace"]
	for mode: String in modes:
		var root_path: String = test_root.path_join("failed_import_" + mode)
		_seed(root_path, _historical_fixture())
		var store: FailingStore = FailingStore.new()
		_check(store.initialize(root_path), mode + " failed import fixture initializes")
		var before: Dictionary = store.state
		var primary_before: String = _read(root_path.path_join(Store.PRIMARY_NAME))
		store.fail_once = mode
		var result: Dictionary = store.import_save_text(_envelope(_expanded_fixture()), 417)
		_check(not bool(result.get("ok", false)) and not str(result.get("error", "")).is_empty() and store.fail_once.is_empty(), mode + " genuine filesystem/validation import failure reported")
		_check(_same(store.state, before) and _read(root_path.path_join(Store.PRIMARY_NAME)) == primary_before, mode + " failed import never publishes candidate or changes primary bytes")
		var reload: Store = Store.new()
		_check(reload.initialize(root_path) and _same(reload.state, before), mode + " failed import restarts original progress")
		_check(bool(store.import_save_text(_envelope(_expanded_fixture()), 417).get("ok", false)), mode + " same import can be retried successfully")
		var expanded: Dictionary = _expected_runtime(_expanded_fixture())
		expanded["save_revision"] = 418
		_check(_same(store.state, expanded), mode + " retried import exact, revision increments once")
		# Failed undo must retain BOTH the current save and the target snapshot so
		# retry can still recover the prior progress, rather than silently losing it.
		var target_before: String = _read(root_path.path_join(Store.PRE_IMPORT_NAME))
		primary_before = _read(root_path.path_join(Store.PRIMARY_NAME))
		store.fail_once = mode
		var undo: Dictionary = store.restore_previous_save(418)
		_check(not bool(undo.get("ok", false)) and store.fail_once.is_empty(), mode + " genuine failed undo reported")
		_check(_same(store.state, expanded) and _read(root_path.path_join(Store.PRIMARY_NAME)) == primary_before, mode + " failed undo retains current expanded progress")
		_check(_read(root_path.path_join(Store.PRE_IMPORT_NAME)) == target_before, mode + " failed undo retains exact target snapshot for retry")
		_check(bool(store.restore_previous_save(418).get("ok", false)), mode + " failed undo can be retried")
		before["save_revision"] = 419
		_check(_same(store.state, before), mode + " retried undo actually restores original historical progress")
	print("GROUP real import/undo write, validation and replacement failures")

func _test_failed_snapshot_copy_and_rollback() -> void:
	var root_path: String = test_root.path_join("failed_snapshot_copy")
	_seed(root_path, _historical_fixture())
	var store: FailingStore = FailingStore.new()
	_check(store.initialize(root_path), "snapshot copy fixture initializes")
	_check(bool(store.import_save_text(_envelope(_expanded_fixture()), 417).get("ok", false)), "snapshot copy fixture imports expanded progress")
	var before: Dictionary = store.state
	var before_files: Dictionary = _files(root_path)
	store.fail_once = "snapshot_copy"
	_check(not bool(store.restore_previous_save(418).get("ok", false)) and store.fail_once.is_empty(), "verified rollback-copy failure aborts before replacing undo target")
	_check(_same(store.state, before) and _files(root_path) == before_files, "failed rollback copy retains current progress and all original bytes")
	var restart: Store = Store.new()
	_check(restart.initialize(root_path) and _same(restart.state, before), "failed rollback copy restarts unchanged")
	_check(bool(store.restore_previous_save(418).get("ok", false)) and _same(_without_revision(store.state), _without_revision(_expected_runtime(_historical_fixture()))), "failed rollback copy retries to the correct historical target")
	_check(bool(store.restore_previous_save(419).get("ok", false)), "redo remains available after copy-failure retry")
	before = store.state
	before_files = _files(root_path)
	store.fail_once = "write"
	store.fail_rollback_once = true
	_check(not bool(store.restore_previous_save(420).get("ok", false)) and not store.fail_rollback_once and store.read_only, "secondary rollback rename failure enters protection mode")
	_check(_same(store.state, before) and _read(root_path.path_join(Store.PRIMARY_NAME)) == before_files[Store.PRIMARY_NAME], "secondary rollback failure never changes current primary/progress")
	var saved_target: bool = false
	for file: String in DirAccess.get_files_at(root_path):
		if file.begins_with(Store.IMPORT_ROLLBACK_PREFIX) and _read(root_path.path_join(file)) == before_files[Store.PRE_IMPORT_NAME]:
			saved_target = true
	_check(saved_target, "secondary rollback failure retains byte-exact original undo target in a recovery file")
	_check(not bool(store.restore_previous_save(420).get("ok", false)), "secondary rollback failure cannot silently retry against wrong target")
	var protected_restart: Store = Store.new()
	var protected_files: Dictionary = _files(root_path)
	_check(not protected_restart.initialize(root_path) and protected_restart.read_only and _same(protected_restart.state, before), "unresolved rollback stays protected after restart while exposing last committed state")
	_check(not bool(protected_restart.import_save_text(_envelope(_historical_fixture()), 420).get("ok", false)) and _files(root_path) == protected_files, "unresolved rollback recovery files cannot be overwritten after restart")
	print("PASS GROUP rollback copy failure and protected secondary rollback failure")

func _test_corruption_and_future_saves() -> void:
	var valid: Dictionary = _historical_fixture()
	for name: String in [Store.PRIMARY_NAME, Store.BACKUP_NAME]:
		var root_path: String = test_root.path_join("future_" + name)
		_seed(root_path, valid)
		var future: Dictionary = _historical_fixture()
		future["schema_version"] = 3
		_write(root_path.path_join(name), _json(future))
		var before_files: Dictionary = _files(root_path)
		var store: Store = Store.new()
		_check(not store.initialize(root_path) and store.read_only, name + " future schema fails closed despite another valid file")
		_check(not store.commit_state(store.state) and not bool(store.export_save_text().get("ok", false)) and not bool(store.import_save_text(_envelope(valid), 0).get("ok", false)), name + " future protection blocks write/export/import")
		_check(_files(root_path) == before_files, name + " future schema retains original bytes")
	var broken_root: String = test_root.path_join("both_corrupt")
	_write(broken_root.path_join(Store.PRIMARY_NAME), "original corrupt primary")
	_write(broken_root.path_join(Store.BACKUP_NAME), "original corrupt backup")
	var broken_files: Dictionary = _files(broken_root)
	var broken: Store = Store.new()
	_check(not broken.initialize(broken_root) and broken.read_only, "both corrupt files fail closed without creating blank progress")
	_check(not bool(broken.import_save_text(_envelope(valid), 0).get("ok", false)) and not broken.commit_state(broken.state) and _files(broken_root) == broken_files, "both-corrupt protection preserves bytes through write/import attempts")
	var recovery_root: String = test_root.path_join("corrupt_primary")
	var legacy_bytes: String = _seed(recovery_root, valid)
	_write(recovery_root.path_join(Store.PRIMARY_NAME), "{corrupt primary from interruption")
	var recovery: Store = Store.new()
	_check(recovery.initialize(recovery_root) and _same(recovery.state, _expected_runtime(valid)), "corrupt primary recovers all 44 species from valid backup")
	_check(_read(recovery_root.path_join(Store.PRIMARY_NAME)) == "{corrupt primary from interruption" and _read(recovery_root.path_join(Store.BACKUP_NAME)) == legacy_bytes, "recovery itself preserves both original file bytes")
	_check(bool(_settle(recovery, _ocean_record(0)).get("ok", false)), "recovered historical save may append ocean discovery")
	var found_archive: bool = false
	for file: String in DirAccess.get_files_at(recovery_root):
		if file.begins_with(Store.PRIMARY_NAME + ".corrupt-") and _read(recovery_root.path_join(file)) == "{corrupt primary from interruption":
			found_archive = true
	_check(found_archive and _read(recovery_root.path_join(Store.BACKUP_NAME)) == legacy_bytes, "recovery commit archives original corrupt bytes and preserves valid historical backup")
	_check(recovery.total_count() == 1255 and recovery.discovered_count() == 45 and int(recovery.state["currency"]) == 1234592, "recovery appends exactly one catch and reward")
	var restart: Store = Store.new()
	_check(restart.initialize(recovery_root) and _same(restart.state, recovery.state), "recovered plus expanded state restarts exactly")
	print("PASS GROUP corrupt/future saves fail closed or recover without destructive resets")
