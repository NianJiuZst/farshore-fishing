extends SceneTree
## Real persistence regression for Godot's non-idempotent decimal float parser.
## No epsilon comparisons: readback must match exactly one expected JSON parse.
const Store = preload("res://scripts/save_store.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")

class CorruptingStore extends "res://scripts/save_store.gd":
	var corrupt_once: String = ""
	func _read_text(path: String) -> Dictionary:
		if corrupt_once == "bytes" and path.ends_with("/save.tmp.json"):
			corrupt_once = ""
			var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
			if file != null:
				file.seek_end()
				file.store_string(" ") # Valid JSON, same values, different committed bytes.
				file.close()
		return super._read_text(path)
	func _read_save(path: String) -> Dictionary:
		if corrupt_once in ["float", "integer"] and path.ends_with("/save.tmp.json"):
			var kind: String = corrupt_once
			corrupt_once = ""
			var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			if kind == "integer": raw["currency"] = int(raw["currency"]) + 1
			else: raw["game_clock"] = float(raw["game_clock"]) + 0.000001
			var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(raw,"",true,true))
				file.close()
		return super._read_save(path)

var checks: int = 0
var failures: int = 0
var test_root: String = ""
var catalog: ContentCatalog = Catalog.new()
var records_saved: int = 0
var former_false_rejections: int = 0

func _initialize() -> void:
	test_root = "/tmp/farshore-ocean-float-save-%d-%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(test_root) == OK, "isolated test root created")
	print("OCEAN_FLOAT_SAVE_TEST_ROOT=",test_root)
	_check(catalog.load_all(false), "data-only catalog loads: " + str(catalog.errors))
	_check(catalog.baits.size() == 12 and catalog.fish.size() == 111 and catalog.fish_species_count() == 110, "matrix contains twelve baits,110 fish and one excluded mammal")
	_test_exact_float_regression()
	_test_strict_readback_and_bytes()
	if failures == 0: _test_generated_matrix()
	print("OCEAN_FLOAT_SAVE_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; generated records=",records_saved,"; former false rejections=",former_false_rejections)
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ",label)

func _float_from_bits(last_byte: int = 232) -> float:
	# Exact runtime fraction from the first failing real growth catch. A decimal
	# source literal is itself parsed by Godot and would hide the original value.
	return PackedByteArray([last_byte,136,234,101,215,21,150,63]).to_float64_array()[0]

func _json(value: Variant) -> String:
	return JSON.stringify(value,"",true,true)

func _decoded_expected(store: SaveStore, value: Dictionary) -> Dictionary:
	return store._normalize_state(JSON.parse_string(_json(value)))["state"]

func _failed_record() -> Dictionary:
	# Exact non-secret generated record from iteration103 of the 9357 growth seed.
	return {"bait_id":"large_surface_lure","behavior":"steady","catch_id":"float_regression:catch","caught_at":"2026-10-04 18:33:02",
		"conservation_note":"保护观察：仅限游戏虚拟互动，结束后必须放归且不可出售；不代表现实法律、钓捕许可或安全操作建议。",
		"difficulty":0.6477838466622678,"disposition":"pending","equipment":4,"game_time":0.0,"length_mm":1440,
		"region_id":"pacific_ocean","release_only":true,"reward":25,"sale_value":0,"session_id":"float_regression",
		"size_class":"小巧","size_fraction":_float_from_bits(),"species_id":"oceanic_whitetip_shark","spot_id":"pacific_bluewater",
		"time_of_day":"day","weather":"clear","weight_g":13332}

func _test_exact_float_regression() -> void:
	var original: float = _float_from_bits()
	var parsed_once: float = JSON.parse_string(_json(original))
	var parsed_twice: float = JSON.parse_string(_json(parsed_once))
	_check(PackedFloat64Array([original]).to_byte_array().hex_encode() == "e888ea65d715963f", "regression reproduces the exact original IEEE-754 bits")
	_check(PackedFloat64Array([parsed_once]).to_byte_array().hex_encode() == "e788ea65d715963f", "first engine parse moves one ULP lower")
	_check(PackedFloat64Array([parsed_twice]).to_byte_array().hex_encode() == "e588ea65d715963f", "second engine parse moves two more ULPs lower")
	_check(parsed_once != parsed_twice, "double parsing is demonstrably not an exact-value equivalence")
	var root_path: String = test_root.path_join("exact_regression")
	var store: SaveStore = Store.new()
	_check(store.initialize(root_path), "exact regression initializes")
	var record: Dictionary = _failed_record()
	store.begin_session(str(record["session_id"]))
	var settled: Dictionary = store.settle_catch(record)
	_check(bool(settled.get("ok",false)), "formerly rejected generated protected fish settles: " + store.error_message)
	if not bool(settled.get("ok",false)): return
	_check(store.total_count() == 1 and store.discovered_count() == 1 and int(store.state["currency"]) == 1525, "exact regression counts and rewards once")
	_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == _json(store.state), "successful original write is still byte-exact")
	_check(not bool(store.settle_catch(record).get("ok",false)) and int(store.state["currency"]) == 1525, "repeat callback cannot replay the formerly rejected record")
	var before_import: Dictionary = store.state
	var replacement: Dictionary = Store.default_state()
	replacement["currency"] = 0
	_check(bool(store.import_save_text(_json(replacement),int(store.state["save_revision"])).get("ok",false)), "pre-import snapshot can contain the exact drifting source float")
	_check(int(store.state["currency"]) == 0 and store.total_count() == 0, "replacement retains its own exact currency and counters")
	_check(bool(store.restore_previous_save(int(store.state["save_revision"])).get("ok",false)), "undo restores the drifting-float catch from its verified snapshot")
	_check(int(store.state["currency"]) == 1525 and store.total_count() == 1, "undo preserves original integer progress without reward replay")
	_check(int(store.state["pending_catches"]["float_regression:catch"]["length_mm"]) == 1440 and int(store.state["pending_catches"]["float_regression:catch"]["weight_g"]) == 13332, "undo retains exact integer fish dimensions")
	var restart: SaveStore = Store.new()
	_check(restart.initialize(root_path) and restart.state == _decoded_expected(store,store.state), "readback equals exactly one expected normalization/parse")
	_check(not bool(restart.dispose_catch("float_regression:catch","sold").get("ok",false)), "drifting metadata cannot bypass protected sale rejection")
	_check(bool(restart.dispose_catch("float_regression:catch","released").get("ok",false)), "restored regression catch releases successfully")
	_check(int(restart.state["currency"]) == 1533 and restart.total_count() == 1, "release grants exactly eight coins and keeps history")
	_check((before_import["species_stats"] as Dictionary).size() == 1, "detached original snapshot remains intact")

func _test_strict_readback_and_bytes() -> void:
	var store: SaveStore = Store.new()
	var expected: Dictionary = Store.fresh_state()
	expected["float_probe"] = _float_from_bits()
	var readback: Dictionary = _decoded_expected(store,expected)
	_check(store._matches_persisted_state(readback,expected), "one expected parse matches exact valid readback")
	var caught: Dictionary = _failed_record()
	var with_catch: Dictionary = expected.duplicate(true)
	with_catch["species_stats"] = {"oceanic_whitetip_shark":{"catch_count":1,"first":caught.duplicate(true),"last":caught.duplicate(true),"max_length":caught.duplicate(true),"max_weight":caught.duplicate(true),"regions":{"pacific_ocean":1}}}
	with_catch["pending_catches"] = {"float_regression:catch":caught.duplicate(true)}
	var caught_readback: Dictionary = _decoded_expected(store,with_catch)
	_check(store._matches_persisted_state(caught_readback,with_catch), "strict comparison accepts complete exact caught history")
	for field: String in ["length_mm","weight_g","catch_id","species_id"]:
		var changed: Dictionary = caught_readback.duplicate(true)
		var pending: Dictionary = changed["pending_catches"]["float_regression:catch"]
		pending[field] = int(pending[field])+1 if field in ["length_mm","weight_g"] else str(pending[field])+"_changed"
		_check(not store._matches_persisted_state(changed,with_catch), "strict comparison rejects record identity/integer corruption: "+field)
	var changed_count: Dictionary = caught_readback.duplicate(true)
	changed_count["species_stats"]["oceanic_whitetip_shark"]["catch_count"] = 2
	_check(not store._matches_persisted_state(changed_count,with_catch), "strict comparison rejects one-unit historical count corruption")
	for field: String in ["currency","gear","save_revision"]:
		var changed: Dictionary = readback.duplicate(true)
		changed[field] = int(changed[field])+1
		_check(not store._matches_persisted_state(changed,expected), "one-unit integer corruption is rejected: " + field)
	for mutation: String in ["one_ulp","meaningful_float","region_id","boolean","unknown_field"]:
		var changed: Dictionary = readback.duplicate(true)
		match mutation:
			"one_ulp": changed["float_probe"] = _float_from_bits(232)
			"meaningful_float": changed["float_probe"] = float(changed["float_probe"])+0.000001
			"region_id": changed["selection"]["region_id"] = "yangtze"
			"boolean": changed["settings"]["sound"] = false
			"unknown_field": changed["unexpected"] = "do not ignore"
		_check(not store._matches_persisted_state(changed,expected), "strict readback rejects " + mutation)
	for fault: String in ["bytes","float","integer"]:
		var root_path: String = test_root.path_join("corrupt_"+fault)
		var corrupting: CorruptingStore = CorruptingStore.new()
		_check(corrupting.initialize(root_path), fault + " fixture initializes")
		var before: Dictionary = corrupting.state
		var bytes_before: String = FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME))
		corrupting.corrupt_once = fault
		var record: Dictionary = _failed_record()
		corrupting.begin_session(str(record["session_id"]))
		_check(not bool(corrupting.settle_catch(record).get("ok",false)), fault + " corruption is rejected by actual writer")
		_check(corrupting.state == before and FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == bytes_before, fault + " failed write retains exact committed state and bytes")
		_check(bool(corrupting.settle_catch(record).get("ok",false)), fault + " original unchanged catch retries successfully")
		_check(corrupting.total_count() == 1 and int(corrupting.state["currency"]) == 1525, fault + " retry counts and rewards exactly once")

func _draw_extremes(fish: FishDefinition,bait_id: String,seed_value: int) -> Array[Dictionary]:
	var generator: EncounterGenerator = Encounter.new(seed_value)
	var found: Dictionary = {}
	var spot_id: String = str(fish.spots()[0])
	var region_id: String = str(catalog.spots[spot_id]["region_id"])
	var normal_max: int = int(fish.raw["normal_max_mm"])
	var gear_id: int = 5 if float(fish.raw.get("depth_min_m",0.0)) > float(catalog.gear[4].get("max_depth_m",180.0)) else 4
	for attempt: int in 10000:
		var record: Dictionary = generator.make_individual(fish,spot_id,region_id,bait_id,gear_id,"day","clear")
		var fraction: float = float(record["size_fraction"])
		if fraction < 0.05 and not found.has("small"): found["small"] = record
		if fraction > 0.95 and fraction < 1.0 and not found.has("large"): found["large"] = record
		if int(record["length_mm"]) > normal_max and not found.has("extended"): found["extended"] = record
		if found.size() == 3: break
	_check(found.size() == 3,"production RNG generates small/large/extended cases for "+fish.species_id+"/"+bait_id)
	if found.size() != 3: return []
	return [found["small"],found["large"],found["extended"]]

func _test_generated_matrix() -> void:
	var start: int = Time.get_ticks_msec()
	var matrix_index: int = 0
	for bait: Dictionary in catalog.baits:
		var bait_id: String = str(bait["bait_id"])
		for fish: FishDefinition in catalog.fish.values():
			if not catalog.is_fishing_species(fish): continue
			matrix_index += 1
			var root_path: String = test_root.path_join("matrix_%04d"%matrix_index)
			var store: SaveStore = Store.new()
			_check(store.initialize(root_path), "matrix profile initializes")
			var records: Array[Dictionary] = _draw_extremes(fish,bait_id,9357+matrix_index*97)
			for cycle: int in records.size():
				var record: Dictionary = records[cycle]
				# Include the same production automatic depth/affinity metadata that
				# generate() adds. Session IDs are synthetic fixture identities only.
				Encounter.new(1).apply_float_presentation(record,catalog,0.63)
				record["session_id"] = "matrix_%d_%d"%[matrix_index,cycle]
				record["catch_id"] = str(record["session_id"])+":catch"
				var single: Variant = JSON.parse_string(_json(record))
				if JSON.parse_string(_json(single)) != single: former_false_rejections += 1
				store.begin_session(str(record["session_id"]))
				var result: Dictionary = store.settle_catch(record)
				_check(bool(result.get("ok",false)), "matrix settlement "+fish.species_id+"/"+bait_id+"/"+str(cycle)+": "+store.error_message)
				if not bool(result.get("ok",false)): return
				records_saved += 1
				_check(store.total_count() == cycle+1 and store.discovered_count() == 1 and int(store.state["currency"]) == 1500+cycle*33+25, "matrix exact catch count and reward")
				_check(FileAccess.get_file_as_string(root_path.path_join(Store.PRIMARY_NAME)) == _json(store.state), "matrix primary written bytes remain exact")
				var expected: Dictionary = _decoded_expected(store,store.state)
				var restarted: SaveStore = Store.new()
				_check(restarted.initialize(root_path) and restarted.state == expected, "matrix complete snapshot survives one exact disk roundtrip")
				var pending: Dictionary = restarted.state["pending_catches"][record["catch_id"]]
				for field: String in ["catch_id","session_id","species_id","length_mm","weight_g","bait_id","release_only","conservation_note"]:
					_check(pending[field] == record[field], "matrix exact identity/dimension/protection field: "+field)
				_check(bool(restarted.dispose_catch(str(record["catch_id"]),"released").get("ok",false)), "matrix disposal after reload succeeds")
				_check(int(restarted.state["currency"]) == 1500+(cycle+1)*33 and restarted.total_count() == cycle+1, "matrix reload/disposal never replays compensation or catch reward")
				store = Store.new()
				_check(store.initialize(root_path) and store.state == _decoded_expected(restarted,restarted.state), "matrix second reload preserves complete historical snapshots")
		print("PASS MATRIX bait=",bait_id," profiles=",matrix_index," records=",records_saved," elapsed_ms=",Time.get_ticks_msec()-start)
	_check(matrix_index == 1320 and records_saved == 3960, "all twelve baits by110 fish by three size classes persisted and reloaded twice; whale excluded")
	_check(former_false_rejections > 0, "matrix includes actual generated metadata affected by former extra parsing")
