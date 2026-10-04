extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL BAIT BALANCE: ", detail)
func _initialize() -> void:
	var catalog: ContentCatalog = Catalog.new()
	check(catalog.load_all(false), "catalog loads")
	check(catalog.gear.size() == 6 and catalog.baits.size() == 12, "six rods/twelve bait definitions")
	for fish: FishDefinition in catalog.fish.values():
		if not catalog.is_fishing_species(fish): continue
		for original: String in ["worm", "grain", "shrimp", "lure"]:
			check(is_equal_approx(catalog.bait_weight(fish, original), fish.weight_for("bait_weights", original)), "legacy attraction preserved " + fish.species_id + "/" + original)
		for bait: Dictionary in catalog.baits:
			var weight: float = catalog.bait_weight(fish, str(bait.bait_id))
			check(is_finite(weight) and weight >= 0.0, "finite non-negative balance " + fish.species_id + "/" + str(bait.bait_id))
	var carp: FishDefinition = catalog.fish.common_carp
	var gar: FishDefinition = catalog.fish.alligator_gar
	check(catalog.bait_weight(carp, "sweetcorn") > catalog.bait_weight(carp, "dough"), "corn and dough differ for carp")
	check(catalog.bait_weight(catalog.fish.common_bream, "dough") > catalog.bait_weight(catalog.fish.common_bream, "sweetcorn"), "bream reverses that preference")
	check(catalog.bait_weight(gar, "cut_fish") > catalog.bait_weight(gar, "spinner"), "cut fish and spinner differ for gar")
	check(catalog.bait_weight(carp, "sweetcorn") > 10.0 * catalog.bait_weight(gar, "sweetcorn"), "corn selects carp meaningfully")
	check(catalog.bait_weight(gar, "cut_fish") > 10.0 * catalog.bait_weight(carp, "cut_fish"), "cut fish selects gar meaningfully")
	var generator: EncounterGenerator = Encounter.new(1405)
	var reachable: Dictionary = {}
	for spot: String in catalog.spots:
		for gear: Dictionary in catalog.gear:
			for bait: Dictionary in catalog.baits:
				for power: float in [0.25, 0.5, 0.85, 1.0]:
					if power > float(gear.reach): continue
					for time: String in ["day", "dusk"]:
						for weather: String in ["clear", "rain"]:
							for candidate: Dictionary in generator.candidates(catalog, spot, str(bait.bait_id), int(gear.id), power, time, weather):
								var fish: FishDefinition = candidate.fish
								check(float(candidate.weight) > 0 and is_finite(float(candidate.weight)), "valid encounter weight")
								reachable[fish.species_id] = true
	for id: String in catalog.fish:
		if catalog.is_fishing_species(catalog.fish[id]): check(reachable.has(id), "species remains reachable " + id)
	check(reachable.size() == 110 and not reachable.has("blue_whale"), "all fishing species reachable without mammal bait encounters")
	print("BAIT_BALANCE_TESTS: ", checks-failures, "/", checks, "; reachable_species=", reachable.size(), "/", catalog.fish_species_count())
	quit(0 if failures == 0 else 1)
