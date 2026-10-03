class_name TrialFishery
extends RefCounted
## Deliberately bounded 3D acceptance content. Never mutates the legacy catalog,
## player selection, unlocked regions or species records.
const REGION_ID: String = "river_trial"
const SPOT_ID: String = "river_trial_dock"
const NAME: String = "河湾试钓场"
const SPOT_NAME: String = "木栈桥"
const PLAYABLE_SPECIES: Array[String] = ["common_carp", "alligator_gar"]
# Deliberate game-balance weights, not measured feeding probabilities. Existing
# bait IDs retain their legacy values; the four additions are tuned for this
# explicitly managed two-species acceptance site only.
const EXTRA_BAIT_WEIGHTS: Dictionary = {
	"common_carp": {"sweetcorn": 2.4, "dough": 2.1, "cut_fish": 0.06, "spinner": 0.09},
	"alligator_gar": {"sweetcorn": 0.05, "dough": 0.06, "cut_fish": 2.6, "spinner": 2.05}
}
const DESCRIPTION: String = "虚构的管理型试钓水域 · 本版体验鲤鱼与鳄雀鳝的3D钓鱼流程"

static func region() -> Dictionary:
	return {"region_id": REGION_ID, "name": NAME, "subtitle": "两种鱼的3D体验", "scene": "res://assets/scenery/bayou_channel.png", "color": "#488c80", "spots": [SPOT_ID]}

static func spot() -> Dictionary:
	return {"spot_id": SPOT_ID, "region_id": REGION_ID, "name": SPOT_NAME, "habitat": "虚构的管理型河湾试钓场，不表示两种鱼在所有自然水域共同分布", "salinity": "fresh", "depth_min_m": 1.0, "depth_max_m": 8.0, "min_gear": 0, "foreground": "pier", "cast_hint": "长按蓄力、松手抛竿；观察送漂、顿沉或定向横移后及时提竿"}

static func generate(catalog: ContentCatalog, encounter: EncounterGenerator, bait_id: String, gear_id: int, cast_power: float, time_of_day: String, weather: String, target_species: String = "mixed") -> Dictionary:
	if gear_id < 0 or gear_id >= catalog.gear.size() or not is_finite(cast_power):
		return {}
	var valid_bait: bool = false
	for bait: Dictionary in catalog.baits:
		if str(bait.bait_id) == bait_id: valid_bait = true
	if not valid_bait or time_of_day not in ["day", "dusk"] or weather not in ["clear", "rain"]:
		return {}
	if target_species != "mixed" and target_species not in PLAYABLE_SPECIES:
		return {}
	var choices: Array[Dictionary] = []
	var total: float = 0.0
	for id: String in PLAYABLE_SPECIES:
		if not catalog.fish.has(id): return {}
		if target_species != "mixed" and id != target_species: continue
		var species: FishDefinition = catalog.fish[id]
		# Trial targets intentionally bypass the old travel/gear unlock gates. Mixed
		# mode still uses the existing bait and weather preferences. No raw species
		# distribution data is edited to manufacture a natural shared habitat.
		var weight: float = maxf(0.05, bait_weight(species, bait_id)) * species.weight_for("time_weights", time_of_day) * species.weight_for("weather_weights", weather)
		choices.append({"species": species, "weight": weight})
		total += weight
	if choices.is_empty() or total <= 0.0: return {}
	var draw: float = encounter.rng.randf() * total
	var selected: FishDefinition = choices.back().species
	for choice: Dictionary in choices:
		draw -= float(choice.weight)
		if draw <= 0.0:
			selected = choice.species
			break
	# Real length/weight sampling, record IDs, rewards and transactional settlement
	# remain the same production pipeline used by the 44-species game.
	var record: Dictionary = encounter.make_individual(selected, SPOT_ID, REGION_ID, bait_id, gear_id, time_of_day, weather)
	# This is an explicit game-balance choice for the two-fish animation trial,
	# not a biological claim that a real fish always behaves this way.
	if selected.species_id == "alligator_gar": record["behavior"] = "burst"
	return record

static func bait_weight(species: FishDefinition, bait_id: String) -> float:
	var additions: Dictionary = EXTRA_BAIT_WEIGHTS.get(species.species_id, {})
	if additions.has(bait_id): return float(additions[bait_id])
	return species.weight_for("bait_weights", bait_id)

static func record_location(record: Dictionary, catalog: ContentCatalog) -> String:
	var rid: String = str(record.get("region_id", ""))
	var sid: String = str(record.get("spot_id", ""))
	if rid == REGION_ID and sid == SPOT_ID: return NAME + " / " + SPOT_NAME
	return str(catalog.region(rid).get("name", rid)) + " / " + str(catalog.spots.get(sid, {}).get("name", sid))

static func is_playable(species_id: String) -> bool:
	return species_id in PLAYABLE_SPECIES
