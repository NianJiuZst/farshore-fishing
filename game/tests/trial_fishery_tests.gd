extends SceneTree
const Trial = preload("res://scripts/trial_fishery.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Store = preload("res://scripts/save_store.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL TRIAL: ", detail)

func _run() -> void:
	var catalog: ContentCatalog = Catalog.new()
	_check(catalog.load_all(false), "full legacy catalog loads")
	var encounter: EncounterGenerator = Encounter.new(12345)
	var original_world: String = JSON.stringify({"regions": catalog.regions, "spots": catalog.spots, "gear": catalog.gear})
	var original_species: Dictionary = {}
	for id: String in catalog.fish: original_species[id] = JSON.stringify(catalog.fish[id].raw)
	var seen: Dictionary = {}
	for target: String in ["mixed", "common_carp", "alligator_gar"]:
		for bait_definition: Dictionary in catalog.baits:
			var bait: String = str(bait_definition.bait_id)
			for gear: int in range(catalog.gear.size()):
				for sample: int in range(50):
					var record: Dictionary = Trial.generate(catalog, encounter, bait, gear, 0.5, "day", "clear", target)
					_check(not record.is_empty(), "both fish available with starter and later gear")
					_check(str(record.species_id) in Trial.PLAYABLE_SPECIES, "only two fish are playable")
					_check(target == "mixed" or record.species_id == target, "explicit trial target respected")
					_check(record.spot_id == Trial.SPOT_ID and record.region_id == Trial.REGION_ID, "managed location correctly recorded")
					var fish: FishDefinition = catalog.fish[record.species_id]
					_check(record.length_mm >= fish.min_mm and record.length_mm <= fish.max_mm and record.weight_g > 0, "real specimen range retained")
					seen[record.species_id] = true
	_check(catalog.gear.size() == 5 and catalog.baits.size() == 12, "five rods and twelve baits present")
	for species_id: String in Trial.PLAYABLE_SPECIES:
		for original_bait: String in ["worm", "grain", "shrimp", "lure"]:
			_check(is_equal_approx(Trial.bait_weight(catalog.fish[species_id], original_bait), catalog.fish[species_id].weight_for("bait_weights", original_bait)), "original bait balance unchanged")
	var rates: Dictionary = {}
	for extra_bait: String in ["sweetcorn", "dough", "cut_fish", "spinner"]:
		var carp_count: int = 0
		for sample: int in range(2000):
			var sampled: Dictionary = Trial.generate(catalog, encounter, extra_bait, 0, 0.5, "day", "clear")
			_check(not sampled.is_empty(), "new bait creates valid encounter")
			if str(sampled.get("species_id", "")) == "common_carp": carp_count += 1
		rates[extra_bait] = float(carp_count) / 2000.0
	_check(float(rates.sweetcorn) > 0.93 and float(rates.dough) > 0.90, "corn and dough meaningfully favor carp")
	_check(float(rates.cut_fish) < 0.08 and float(rates.spinner) < 0.12, "cut bait and spinner meaningfully favor gar")
	print("TRIAL BAIT carp rates (fixed seed, 2000 each): ", rates)
	_check(seen.size() == 2, "both trial species sampled")
	_check(Trial.generate(catalog, encounter, "worm", 0, 0.5, "day", "clear", "chinese_sturgeon").is_empty(), "non-trial target rejected")
	_check(Trial.generate(catalog, encounter, "unknown", 0, 0.5, "day", "clear").is_empty(), "invalid bait rejected")
	_check(Trial.generate(catalog, encounter, "worm", catalog.gear.size(), 0.5, "day", "clear").is_empty(), "out-of-range new gear rejected")
	_check(Trial.generate(catalog, encounter, "worm", -1, 0.5, "day", "clear").is_empty(), "invalid gear rejected")
	_check(JSON.stringify({"regions": catalog.regions, "spots": catalog.spots, "gear": catalog.gear}) == original_world, "legacy world unchanged")
	for id: String in catalog.fish: _check(JSON.stringify(catalog.fish[id].raw) == original_species[id], "legacy species unchanged " + id)
	_check(catalog.fish.size() == 74 and catalog.regions.size() == 9 and catalog.spots.size() == 18, "original collection inventory intact")
	var directory: String = "/tmp/farshore-trial-save-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())
	var store: SaveStore = Store.new()
	_check(store.initialize(directory), "isolated store initializes")
	var selection: Dictionary = store.state.selection.duplicate(true)
	var records: Array[Dictionary] = []
	var old: Dictionary = encounter.make_individual(catalog.fish["chinese_sturgeon"], "yangtze_estuary", "yangtze", "shrimp", 2, "day", "clear")
	records.append(old)
	for id: String in Trial.PLAYABLE_SPECIES: records.append(Trial.generate(catalog, encounter, "lure", 0, 0.5, "day", "clear", id))
	for index: int in range(records.size()):
		var record: Dictionary = records[index]
		record["session_id"] = "trial_compat_" + str(index)
		record["catch_id"] = "trial_compat_catch_" + str(index)
		store.begin_session(record.session_id)
		_check(store.settle_catch(record).ok, "transactional settlement accepts legacy and managed records")
		_check(store.dispose_catch(record.catch_id, "released").ok, "release preserves historical record")
	_check(store.total_count() == 3 and store.discovered_count() == 3, "old protected record and new two species coexist")
	_check(store.state.selection == selection, "trial never overwrites saved destination/bait selection")
	var restored: SaveStore = Store.new()
	_check(restored.initialize(directory), "reload actual disk")
	_check(restored.total_count() == 3 and restored.discovered_count() == 3, "all records retained after restart")
	_check(restored.state.selection == selection, "legacy selection survives restart")
	var expanded_profile: Dictionary = restored.state.duplicate(true)
	expanded_profile.owned_gear = [0, 3, 4]
	expanded_profile.gear = 4
	expanded_profile.selection.bait_id = "cut_fish"
	_check(restored.commit_state(expanded_profile), "new gear and bait persist through the existing transaction writer")
	var expanded_reload: SaveStore = Store.new()
	_check(expanded_reload.initialize(directory), "expanded profile reloads from real disk")
	_check(expanded_reload.state.gear == 4 and expanded_reload.state.owned_gear == [0, 3, 4], "new owned gear IDs survive reload")
	_check(expanded_reload.state.selection.bait_id == "cut_fish", "new bait ID survives reload")
	_check(expanded_reload.total_count() == 3 and expanded_reload.discovered_count() == 3, "expanded loadout never wipes old protected or trial records")
	_check(Trial.record_location(records[1], catalog) == "河湾试钓场 / 木栈桥", "trial record gets explicit managed label")
	_check("江海观察站" in Trial.record_location(old, catalog), "old record label remains resolvable")
	print("TRIAL_FISHERY_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)
