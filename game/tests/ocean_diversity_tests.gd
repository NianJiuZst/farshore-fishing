extends SceneTree
## Data/encounter integration checks for 1.4.0. No Main, player saves, network,
## RNG sampling promises, visual quality certification or Android device claims.
## The baseline fixture comes from git show at the last published 1.3.0 commit.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const History = preload("res://scripts/fish_natural_history.gd")
const Registry = preload("res://scripts/fish_3d_registry.gd")
const FIXTURE: String = "res://tests/fixtures/ocean_diversity_legacy_1_3_0.json"
const EXPECTED_REGION_POOLS: Dictionary = {
	"pacific_ocean": 20, "atlantic_ocean": 22, "indian_ocean": 20, "red_sea": 16
}
const RED_SEA_SPOTS: Array[String] = ["red_sea_lagoon", "red_sea_wall", "red_sea_bluehole"]
const DEEP_IDS: Array[String] = ["barreleye", "black_scabbardfish"]
var catalog: ContentCatalog = Catalog.new()
var generator: EncounterGenerator = Encounter.new(20261004)
var checks: int = 0
var failures: Array[String] = []
var report: Dictionary = {
	"scope": "Headless source/data/encounter logic only; no real player saves, visual or Android certification",
	"species_witnesses": {}, "species_spot_witnesses": {}, "species_bait_witnesses": {},
	"region_pools": {}, "jaccard": {}, "combo_count": 0, "candidate_count": 0
}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL OCEAN DIVERSITY: ", label)

func _run() -> void:
	# Native macOS Godot uses HOME/Library/Application Support. The runner must
	# set HOME in subprocess.env, not just prefix an XDG variable in the shell.
	var home: String = OS.get_environment("HOME")
	var xdg: String = OS.get_environment("XDG_DATA_HOME")
	var user_data: String = OS.get_user_data_dir()
	if not home.begins_with("/tmp/farshore-") or not xdg.begins_with(home + "/") or not user_data.begins_with(home + "/"):
		printerr("OCEAN_DIVERSITY: refusing a non-isolated HOME/XDG/native user-data directory")
		quit(2)
		return
	report["native_user_data_dir"] = user_data
	check(catalog.load_all(false), "expanded catalog loads: " + str(catalog.errors))
	if not catalog.errors.is_empty():
		_finish()
		return
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	check(fixture is Dictionary and int(fixture.get("schema_version", -1)) == 1, "frozen 1.3.0 fixture loads")
	if not fixture is Dictionary:
		_finish()
		return
	_test_catalog_counts()
	_test_legacy(fixture)
	var history: FishNaturalHistory = History.new()
	check(history.load_all(catalog), "all offline natural histories validate: " + str(history.errors))
	_test_sources(history)
	_test_new_diversity(fixture, history)
	_test_region_pools()
	_enumerate_encounters()
	_test_reachability_and_depth()
	_test_generated_layers()
	_test_model_contract(fixture)
	if "--require-assets" in OS.get_cmdline_user_args():
		_test_asset_readiness()
	_finish()

func _test_catalog_counts() -> void:
	check(catalog.fish.size() == 111, "111 catalog identities including the blue whale")
	check(catalog.fish_species_count() == 110, "110 ordinary fish plus one independent mammal")
	check(catalog.regions.size() == 10 and catalog.spots.size() == 21 and catalog.gear.size() == 6,
		"10 regions, 21 spots, six stable numeric gear positions")
	check(catalog.fish.has("blue_whale"), "blue whale identity exists")
	if catalog.fish.has("blue_whale"):
		var whale: FishDefinition = catalog.fish.blue_whale
		check(str(whale.raw.get("animal_kind", "")) == "mammal", "blue whale explicitly identified as a mammal")
		check(not catalog.is_fishing_species(whale) and not bool(whale.raw.get("fishing_enabled", true)),
			"blue whale cannot use ordinary fishing admission")
		check(generator.make_individual(whale, "pacific_bluewater", "pacific_ocean", "lure", 5, "day", "clear").is_empty(),
			"direct ordinary make_individual call cannot manufacture a whale catch")
		for spot: String in catalog.spots:
			check(whale not in catalog.fish_at(spot), "blue whale excluded from ordinary spot list: " + spot)
			for rod: Dictionary in catalog.gear:
				for bait: Dictionary in catalog.baits:
					check(not bool(generator.preparation_status(catalog, whale, spot, str(bait.bait_id), int(rod.id)).available),
						"whale has no ordinary preparation route: %s/%s/%d" % [spot, str(bait.bait_id), int(rod.id)])

func _test_legacy(fixture: Dictionary) -> void:
	check(str(fixture.baseline_commit) == "7b406cccaf57c9ca213693f75860443a118ed656", "fixture pins published 1.3.0 main")
	check(fixture.legacy_species.size() == 74, "exact original74 species identities retained in fixture")
	for path: String in fixture.legacy_source_sha256:
		check(FileAccess.get_sha256(path) == str(fixture.legacy_source_sha256[path]), "old fish_a..d source bytes remain exact: " + path)
	for before: Dictionary in fixture.legacy_species:
		var id: String = str(before.species_id)
		check(catalog.fish.has(id), "old saved identity still resolves: " + id)
		if not catalog.fish.has(id): continue
		var after: Dictionary = catalog.fish[id].raw
		for field: String in before:
			check(after.has(field) and _same(before[field], after[field]), "legacy non-route field unchanged: " + id + "/" + field)
	for group: String in ["legacy_baits", "legacy_gear", "legacy_regions"]:
		var current: Array = catalog.baits if group == "legacy_baits" else (catalog.gear if group == "legacy_gear" else catalog.regions)
		var before: Array = fixture[group]
		check(current.size() >= before.size(), "legacy world prefix not shortened: " + group)
		for index: int in before.size():
			check(index < current.size() and _same(before[index], current[index]), "legacy world prefix exact: " + group + "/" + str(index))
	var current_spots: Array = catalog.spots.keys()
	for index: int in fixture.legacy_spot_ids.size():
		check(index < current_spots.size() and str(current_spots[index]) == str(fixture.legacy_spot_ids[index]), "old spot ID/order retained: " + str(index))
	for before: Dictionary in fixture.legacy_spots_original_six_regions:
		var id: String = str(before.spot_id)
		check(catalog.spots.has(id) and _same(catalog.spots[id], before), "first six regions' old spot data exact: " + id)

func _test_sources(history: FishNaturalHistory) -> void:
	check(history.complete and history.entries.size() == 111, "111 identities have complete offline sourced entries")
	var seen: Dictionary = {}
	for file: String in History.FILES:
		var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(envelope is Dictionary and int(envelope.get("schema_version", 0)) == 1 and envelope.get("entries") is Array,
			"uniform schema_version=1 envelope: " + file)
		if not envelope is Dictionary or not envelope.get("entries") is Array: continue
		for entry: Dictionary in envelope.entries:
			var id: String = str(entry.species_id)
			check(not seen.has(id) and catalog.fish.has(id), "natural-history identity unique and known: " + id)
			seen[id] = true
			check(History.validate_entry(entry).is_empty(), "every field, citation and metric validated: " + id)
			check(entry.sources.size() >= 2, "at least two documented sources: " + id)
			for field: String in ["taxonomy", "typical_size", "max_length", "max_weight", "habitat", "distribution", "behavior", "diet", "story"]:
				check(entry[field].source_ids.size() > 0, "referenced natural-history field: " + id + "/" + field)
			for source: Dictionary in entry.sources:
				check(History.safe_source_url(str(source.url)), "ordinary HTTPS source URL: " + id + "/" + str(source.id))
	check(seen.size() == catalog.fish.size(), "source coverage has no extras or gaps")
	if history.entries.has("blue_whale"):
		check(str(history.entries.blue_whale.taxonomy.family_scientific) == "Balaenopteridae", "whale science taxonomy is rorqual mammal family")

func _test_new_diversity(fixture: Dictionary, history: FishNaturalHistory) -> void:
	var old_ids: Dictionary = {}
	for before: Dictionary in fixture.legacy_species: old_ids[str(before.species_id)] = true
	var added: Dictionary = {}
	for id: String in catalog.fish:
		if catalog.is_fishing_species(catalog.fish[id]) and not old_ids.has(id): added[id] = true
	check(added.size() == 36 and fixture.new_fish_ids.size() == 36, "exactly36 planned fish added; whale separate")
	var families: Dictionary = {}
	for id: String in fixture.new_fish_ids:
		check(added.has(id), "planned new fish present with stable ID: " + id)
		if not catalog.fish.has(id) or not history.entries.has(id): continue
		var fish: FishDefinition = catalog.fish[id]
		var entry: Dictionary = history.entries[id]
		var family: String = str(entry.taxonomy.family_scientific)
		families[family] = true
		check("tuna" not in id and "shark" not in id and "金枪" not in fish.name and "鲨" not in fish.name,
			"new additions widen beyond tuna and sharks: " + id)
		check(family not in ["Scombridae", "Lamnidae", "Alopiidae", "Carcharhinidae", "Sphyrnidae", "Rhincodontidae", "Scyliorhinidae"],
			"new fish not another tuna/shark family representative: " + id)
		check(fish.scientific_name == str(entry.accepted_scientific_name), "new gameplay and accepted scientific name agree: " + id)
		check(fish.morphology.length() >= 25, "species-specific morphological description: " + id)
		var chosen_region: String = str(fixture.new_region_assignments[id])
		for spot: String in fish.spots():
			check(catalog.spots.has(spot) and str(catalog.spots[spot].region_id) == chosen_region,
				"new species follows its planned exclusive game route: " + id + "/" + spot)
	check(families.size() >= 18, "new roster spans at least18 families rather than renamed near-duplicates")
	report["new_family_count"] = families.size()
	report["new_families"] = families.keys()
	for id: String in fixture.morphology_representatives:
		check(added.has(id) and catalog.fish[id].morphology.length() >= 35, "distinct body-form representative included: " + id)
	check(history.scientific_name("klunzingers_wrasse", "") == "Thalassoma rueppellii", "wrasse accepted name updated while stable ID remains")

func _test_region_pools() -> void:
	var pools: Dictionary = {}
	for region: String in EXPECTED_REGION_POOLS:
		var ids: Dictionary = {}
		for spot: String in catalog.region(region).get("spots", []):
			for fish: FishDefinition in catalog.fish_at(spot): ids[fish.species_id] = true
		pools[region] = ids
		check(ids.size() == int(EXPECTED_REGION_POOLS[region]), "actual spot-route ordinary fish count: " + region + "/" + str(ids.size()))
		report.region_pools[region] = ids.keys()
	var regions: Array = EXPECTED_REGION_POOLS.keys()
	for a: int in regions.size():
		for b: int in range(a + 1, regions.size()):
			var first: Dictionary = pools[regions[a]]
			var second: Dictionary = pools[regions[b]]
			var common: int = 0
			for id: String in first:
				if second.has(id): common += 1
			var union_count: int = first.size() + second.size() - common
			var overlap: float = float(common) / maxi(1, union_count)
			var key: String = str(regions[a]) + "/" + str(regions[b])
			report.jaccard[key] = {"intersection":common, "union":union_count, "ratio":overlap}
			check(overlap <= 0.2 + 0.000001, "actual game-route Jaccard at most20%: " + key + "/" + str(overlap))
	for spot: String in RED_SEA_SPOTS:
		check(catalog.spots.has(spot) and not catalog.fish_at(spot).is_empty(), "red sea spot exists with ordinary fish: " + spot)

func _cast_values(spot: String, reach: float) -> Array[float]:
	# Candidates change only at configured min/max cast boundaries. Visit each
	# boundary and the midpoint of every interval, plus the rod's physical reach.
	var values: Array[float] = [0.0, reach]
	for fish: FishDefinition in catalog.fish_at(spot):
		for key: String in ["min_cast", "max_cast"]:
			var point: float = clampf(float(fish.raw.get(key, 0.0 if key == "min_cast" else 1.0)), 0.0, reach)
			if point not in values: values.append(point)
	values.sort()
	var boundaries: Array[float] = values.duplicate()
	for index: int in range(1, boundaries.size()):
		var midpoint: float = (boundaries[index - 1] + boundaries[index]) * 0.5
		if midpoint not in values: values.append(midpoint)
	values.sort()
	return values

func _enumerate_encounters() -> void:
	var invalid: Dictionary = {}
	var time_values: Array[String] = ["day", "dusk"]
	var weather_values: Array[String] = ["clear", "rain"]
	for fish: FishDefinition in catalog.fish.values():
		for key: String in fish.raw.get("time_weights", {}):
			if key not in time_values: time_values.append(key)
		for key: String in fish.raw.get("weather_weights", {}):
			if key not in weather_values: weather_values.append(key)
	var pools: Dictionary = report.species_witnesses
	var spot_pools: Dictionary = report.species_spot_witnesses
	var bait_pools: Dictionary = report.species_bait_witnesses
	for spot_id: String in catalog.spots:
		var spot: Dictionary = catalog.spots[spot_id]
		for rod: Dictionary in catalog.gear:
			var gear_id: int = int(rod.id)
			if gear_id < int(spot.min_gear): continue
			var casts: Array[float] = _cast_values(spot_id, float(rod.reach))
			for bait: Dictionary in catalog.baits:
				var bait_id: String = str(bait.bait_id)
				for power: float in casts:
					for time: String in time_values:
						for weather: String in weather_values:
							report.combo_count += 1
							var seen: Dictionary = {}
							var candidates: Array[Dictionary] = generator.candidates(catalog, spot_id, bait_id, gear_id, power, time, weather)
							for candidate: Dictionary in candidates:
								var fish: FishDefinition = candidate.fish
								var id: String = fish.species_id
								report.candidate_count += 1
								var key: String = id + "/" + spot_id + "/" + str(gear_id)
								var shallow: float = maxf(float(spot.depth_min_m), float(fish.raw.get("depth_min_m", 0)))
								var deep: float = minf(float(rod.max_depth_m), minf(float(spot.depth_max_m), float(fish.raw.get("depth_max_m", 999))))
								if id == "blue_whale" or not catalog.is_fishing_species(fish): invalid[key + "/mammal"] = "mammal in ordinary candidate pool: " + key
								if shallow > deep: invalid[key + "/depth"] = "candidate has no physical water-depth intersection: " + key
								if not is_finite(float(candidate.weight)) or float(candidate.weight) <= 0.0: invalid[key + "/weight"] = "candidate weight nonpositive/nonfinite: " + key
								if seen.has(id): invalid[key + "/duplicate"] = "duplicate identity in one candidate pool: " + key
								seen[id] = true
								var witness: Dictionary = {"spot":spot_id, "gear":gear_id, "bait":bait_id, "cast":power, "time":time, "weather":weather}
								if not pools.has(id): pools[id] = witness
								if not spot_pools.has(id + "/" + spot_id): spot_pools[id + "/" + spot_id] = witness
								if not bait_pools.has(id + "/" + bait_id): bait_pools[id + "/" + bait_id] = witness
	for key: String in invalid: check(false, str(invalid[key]))
	check(invalid.is_empty(), "every candidate in all legal gear/bait/cast/time/weather partitions is an ordinary, physically reachable fish")
	check(int(report.combo_count) > 10000, "reachability examines the full configured combination grid")
	report["time_values"] = time_values
	report["weather_values"] = weather_values
	report["invalid_candidate_invariants"] = invalid

func _test_reachability_and_depth() -> void:
	check(report.species_witnesses.size() == 110 and not report.species_witnesses.has("blue_whale"), "all110 ordinary fish reachable and whale excluded across complete combinations")
	for fish: FishDefinition in catalog.fish.values():
		if not catalog.is_fishing_species(fish): continue
		check(report.species_witnesses.has(fish.species_id), "at least one actual encounter witness: " + fish.species_id)
		for spot: String in fish.spots():
			check(report.species_spot_witnesses.has(fish.species_id + "/" + spot), "listed species/spot has an actual witness: " + fish.species_id + "/" + spot)
		for bait: Dictionary in catalog.baits:
			if catalog.bait_weight(fish, str(bait.bait_id)) > 0:
				check(report.species_bait_witnesses.has(fish.species_id + "/" + str(bait.bait_id)), "each admitted species/bait has a legal route: " + fish.species_id + "/" + str(bait.bait_id))
	for id: String in DEEP_IDS:
		check(catalog.fish.has(id), "deep specialist exists: " + id)
		if not catalog.fish.has(id): continue
		var fish: FishDefinition = catalog.fish[id]
		check(int(fish.raw.min_gear) == 5 and float(fish.raw.depth_min_m) > 180.0, "deep specialist explicitly requires gear5 and deep water: " + id)
		for rod_id: int in [2, 4]:
			for spot: String in fish.spots():
				for bait: Dictionary in catalog.baits:
					check(not bool(generator.preparation_status(catalog, fish, spot, str(bait.bait_id), rod_id).available), "180m/90m rods cannot prepare deep specialist: %s/%s/%d" % [id, spot, rod_id])
		check(report.species_witnesses.has(id) and int(report.species_witnesses[id].gear) == 5, "deep specialist genuinely reachable on700m rod: " + id)
	var light_ids: Dictionary = {}
	for bait: Dictionary in catalog.baits:
		for power: float in _cast_values("red_sea_lagoon", float(catalog.gear[0].reach)):
			for candidate: Dictionary in generator.candidates(catalog, "red_sea_lagoon", str(bait.bait_id), 0, power, "day", "clear"):
				light_ids[candidate.fish.species_id] = true
	check(light_ids.size() >= 8, "red sea lagoon has at least8 genuinely reachable starter-rod fish")
	report["red_sea_starter_ids"] = light_ids.keys()
	for bait: Dictionary in catalog.baits:
		for power: float in _cast_values("red_sea_bluehole", float(catalog.gear[3].reach)):
			check(generator.candidates(catalog, "red_sea_bluehole", str(bait.bait_id), 3, power, "day", "clear").is_empty(), "25m spinning rod cannot reach30m bluehole minimum")
	if catalog.fish.has("orbicular_batfish"):
		var blocked: Dictionary = generator.preparation_status(catalog, catalog.fish.orbicular_batfish, "red_sea_bluehole", "shrimp", 3)
		check(not bool(blocked.available) and "30 m" in str(blocked.reason), "bluehole preparation explains30m floor even when species also lives shallower elsewhere")

func _test_generated_layers() -> void:
	# Restrict only the candidate roster to one known species. Keep the actual
	# world, rod, bait, cast and generation/presentation code so every species'
	# lower/upper water layer is exercised without relying on lucky RNG draws.
	var one: ContentCatalog = Catalog.new()
	one.regions = catalog.regions
	one.spots = catalog.spots
	one.gear = catalog.gear
	one.baits = catalog.baits
	var tested: Dictionary = {}
	var records: int = 0
	var generated_rows: Array[Dictionary] = []
	for fish: FishDefinition in catalog.fish.values():
		if not catalog.is_fishing_species(fish): continue
		one.fish = {fish.species_id: fish}
		for spot_id: String in fish.spots():
			var spot: Dictionary = catalog.spots[spot_id]
			for rod: Dictionary in catalog.gear:
				if int(rod.id) < int(spot.min_gear): continue
				var shallow: float = maxf(float(spot.depth_min_m), float(fish.raw.get("depth_min_m", 0)))
				var deep: float = minf(float(rod.max_depth_m), minf(float(spot.depth_max_m), float(fish.raw.get("depth_max_m", 999))))
				if shallow > deep or int(rod.id) < int(fish.raw.get("min_gear", 0)): continue
				var min_cast: float = float(fish.raw.get("min_cast", 0.0))
				var max_cast: float = minf(float(rod.reach), float(fish.raw.get("max_cast", 1.0)))
				if min_cast > max_cast: continue
				var casts: Array[float] = [min_cast, (min_cast + max_cast) * 0.5, max_cast]
				for bait: Dictionary in catalog.baits:
					var bait_id: String = str(bait.bait_id)
					if catalog.bait_weight(fish, bait_id) <= 0.0: continue
					for power: float in casts:
						var record: Dictionary = generator.generate(one, spot_id, bait_id, int(rod.id), power, "day", "clear")
						var label: String = "%s/%s/gear%d/%s/%s" % [fish.species_id, spot_id, int(rod.id), bait_id, str(power)]
						check(not record.is_empty() and str(record.get("species_id", "")) == fish.species_id, "production generate returns chosen species: " + label)
						if record.is_empty(): continue
						var bait_depth: float = float(record.get("bait_depth_m", -1))
						var ground: float = float(record.get("water_depth_m", -1))
						check(bait_depth >= shallow - 0.000001 and bait_depth <= deep + 0.000001, "generated bait depth inside species/spot/rod triple intersection: " + label)
						check(ground >= bait_depth - 0.000001 and ground >= shallow - 0.000001 and ground <= minf(float(rod.max_depth_m), float(spot.depth_max_m)) + 0.000001,
							"generated ground contains species lower bound and never exceeds rod/spot depth: " + label)
						if fish.species_id == "atlantic_flyingfish":
							check(bait_depth <= float(fish.raw.depth_max_m) + 0.000001 and str(record.float_rig) == "suspended", "flyingfish stays in its surface layer without a bottom rig")
						if fish.species_id == "barreleye":
							check(bait_depth >= 500.0 and ground >= 500.0, "barreleye remains at least500m deep even for minimum cast")
						records += 1
						if not tested.has(fish.species_id):
							tested[fish.species_id] = true
							generated_rows.append({"species_id":fish.species_id, "spot":spot_id, "gear":int(rod.id), "bait":bait_id, "cast":power, "bait_depth_m":bait_depth, "ground_depth_m":ground})
	check(tested.size() == 110 and records > 1000, "actual generate + float presentation exercised for all110 fish on legal rods and admitted baits")
	report["generated_depth_records"] = records
	report["generated_depth_first_witnesses"] = generated_rows

func _test_model_contract(fixture: Dictionary) -> void:
	check(Registry.species_ids().size() == 111 and Registry.validate_catalog(catalog, false).is_empty(), "111 distinct required model definitions match catalog")
	var motions: Dictionary = {}
	for id: String in fixture.new_fish_ids:
		check(Registry.model_path(id) == "res://assets/3d/" + id + ".glb", "new species-specific model path: " + id)
		var info: Dictionary = Registry.model_info(id)
		var motion: String = str(info.get("motion_style", ""))
		check(not motion.is_empty(), "new species has explicit animation family: " + id)
		motions[motion] = true
	check(motions.size() >= 6, "new roster has several genuinely distinct required motion/body families")
	check(bool(Registry.model_info("pacific_halibut").get("asymmetric_flatfish", false)) and str(Registry.model_info("pacific_halibut").get("eyed_side", "")) == "right", "halibut model records right-eyed asymmetric anatomy")
	check(str(Registry.model_info("giant_moray").get("motion_style", "")) == "anguilliform", "moray gets independent serpentine animation family")
	check(str(Registry.model_info("longhorn_cowfish").get("motion_style", "")) == "boxfish", "cowfish gets box-shaped motion family")
	check(str(Registry.model_info("blue_whale").get("presentation_type", "")) == "aquatic_giant_mammal" and str(Registry.model_info("blue_whale").get("motion_style", "")) == "rorqual_dorsoventral", "whale has mammal presentation and vertical-fluke animation contract")
	report["new_motion_families"] = motions.keys()

func _test_asset_readiness() -> void:
	check(catalog.load_all(true), "required full-size images and thumbnails are actually imported: " + str(catalog.errors))
	check(Registry.validate_catalog(catalog, true).is_empty(), "every required model is actually imported")
	check(not Registry.is_available("unknown_species"), "missing model never substitutes another species")
	report["required_assets_checked"] = true

func _same(before: Variant, after: Variant) -> bool:
	return JSON.stringify(before, "", true) == JSON.stringify(after, "", true)

func _finish() -> void:
	report["completed_utc"] = Time.get_datetime_string_from_system(true, true)
	var frozen_paths: Array[String] = [
		"res://scripts/catalog.gd", "res://scripts/encounter.gd", "res://scripts/fish_natural_history.gd",
		"res://scripts/fish_3d_registry.gd", "res://tests/ocean_diversity_tests.gd", FIXTURE,
		"res://data/world.json", "res://data/fish_3d.json", "res://data/fish_art.json"
	]
	for suffix: String in ["a", "b", "c", "d", "e", "f", "g", "h", "whale"]:
		frozen_paths.append("res://data/fish_" + suffix + ".json")
	for path: String in History.FILES: frozen_paths.append(path)
	var source_hashes: Dictionary = {}
	for path: String in frozen_paths:
		if FileAccess.file_exists(path): source_hashes[path] = FileAccess.get_sha256(path)
	report["source_sha256"] = source_hashes
	report["checks"] = checks
	report["failures"] = failures
	var path: String = OS.get_environment("FARSHORE_DIVERSITY_REPORT")
	if not path.is_empty():
		var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		check(output != null, "integration report path writable")
		report["checks"] = checks
		report["failures"] = failures
		if output: output.store_string(JSON.stringify(report, "  ", true) + "\n")
	print("OCEAN_DIVERSITY_TESTS: %d/%d; failures=%d; combos=%d; candidates=%d; ordinary witnesses=%d" % [checks - failures.size(), checks, failures.size(), int(report.combo_count), int(report.candidate_count), report.species_witnesses.size()])
	quit(0 if failures.is_empty() else 1)
