class_name EncounterGenerator
extends RefCounted
const FloatModel = preload("res://scripts/float_encounter.gd")
const Catalog = preload("res://scripts/catalog.gd")
# Game-only length tuning. The 2% extended tail can exceed published natural
# records; those records remain untouched in the independent encyclopedia.
const SIZE_EXPONENT: float = 1.55
const EXTENDED_SIZE_CHANCE: float = 0.02
const EXTENDED_SIZE_EXPONENT: float = 2.6
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(fixed_seed: int = -1) -> void:
	if fixed_seed < 0:
		rng.randomize()
	else:
		rng.seed = fixed_seed

func candidates(catalog: ContentCatalog, spot_id: String, bait: String, gear_id: int, cast_power: float, time: String, weather: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not catalog.spots.has(spot_id) or gear_id < 0 or gear_id >= catalog.gear.size():
		return result
	var spot: Dictionary = catalog.spots[spot_id]
	var max_depth: float = minf(float(spot.depth_max_m), float(catalog.gear[gear_id].max_depth_m))
	if max_depth < float(spot.depth_min_m):
		return result
	for fish: FishDefinition in catalog.fish_at(spot_id):
		var data: Dictionary = fish.raw
		if int(data.get("min_gear", 0)) > gear_id:
			continue
		if str(data.get("salinity", spot.salinity)) != str(spot.salinity):
			continue
		if float(data.get("depth_min_m", 0)) > max_depth or float(data.get("depth_max_m", 999)) < float(spot.depth_min_m):
			continue
		if cast_power < float(data.get("min_cast", 0.0)) or cast_power > float(data.get("max_cast", 1.0)):
			continue
		var weight: float = float(data.get("weight", 1.0)) * catalog.bait_weight(fish, bait) * fish.weight_for("time_weights", time) * fish.weight_for("weather_weights", weather)
		if weight > 0.0:
			result.append({"fish":fish,"weight":weight})
	return result

func preparation_status(catalog: ContentCatalog, fish: FishDefinition, spot_id: String, bait: String, gear_id: int) -> Dictionary:
	# Read-only preview of the same hard gates used by candidates(). A rod with
	# more fighting power may have less depth, so numeric gear tier is not enough.
	if not catalog.is_fishing_species(fish):
		return {"available":false,"reason":"通过专用幻想巨物挑战相遇"}
	if not catalog.spots.has(spot_id) or gear_id < 0 or gear_id >= catalog.gear.size():
		return {"available":false,"reason":"装备或钓点不可用"}
	var spot: Dictionary = catalog.spots[spot_id]
	var gear: Dictionary = catalog.gear[gear_id]
	var data: Dictionary = fish.raw
	var reason: String = ""
	if int(data.get("min_gear", 0)) > gear_id:
		reason = "需要旅行或探深装备"
	elif float(gear.max_depth_m) < float(spot.depth_min_m):
		reason = "钓竿需探深至少 %d m" % ceili(float(spot.depth_min_m))
	elif float(data.get("depth_min_m", 0)) > minf(float(spot.depth_max_m), float(gear.max_depth_m)):
		reason = "钓竿需探深至少 %d m" % ceili(float(data.get("depth_min_m", 0)))
	elif float(data.get("depth_max_m", 999)) < float(spot.depth_min_m) or str(data.get("salinity", spot.salinity)) != str(spot.salinity):
		reason = "此处水层不适合"
	elif float(data.get("min_cast", 0)) > float(gear.reach):
		reason = "钓竿需达到 %d%% 落点" % ceili(float(data.get("min_cast", 0)) * 100.0)
	elif catalog.bait_weight(fish, bait) <= 0.0:
		reason = "需要更换鱼饵"
	return {"available":reason.is_empty(),"reason":reason,
		"min_cast":float(data.get("min_cast",0.0)),
		"max_cast":minf(float(data.get("max_cast",1.0)),float(gear.reach))}

func generate(catalog: ContentCatalog, spot_id: String, bait: String, gear_id: int, cast_power: float, time: String, weather: String) -> Dictionary:
	var available: Array[Dictionary] = candidates(catalog, spot_id, bait, gear_id, cast_power, time, weather)
	if available.is_empty():
		return {}
	var total: float = 0.0
	for item: Dictionary in available:
		total += float(item.weight)
	var pick: float = rng.randf() * total
	var selected: FishDefinition = available.back().fish
	for item: Dictionary in available:
		pick -= float(item.weight)
		if pick <= 0.0:
			selected = item.fish
			break
	var record: Dictionary = make_individual(selected, spot_id, str(catalog.spots[spot_id].region_id), bait, gear_id, time, weather)
	apply_float_presentation(record, catalog, cast_power)
	return record

func apply_float_presentation(record: Dictionary, catalog: ContentCatalog, cast_power: float = 0.6) -> void:
	## Automatic game presentation, not a claim that one real float rig suits
	## every depth/lure/species. It preserves the catalog's existing reach rules.
	var spot: Dictionary = catalog.spots.get(str(record.get("spot_id", "")), {})
	var fish: FishDefinition = catalog.fish.get(str(record.get("species_id", "")))
	if spot.is_empty() or fish == null: return
	var gear: Dictionary = catalog.gear[clampi(int(record.get("equipment", 0)), 0, catalog.gear.size() - 1)]
	var shallow: float = maxf(0.5, float(spot.get("depth_min_m", 1.0)))
	var deep: float = maxf(shallow, minf(float(spot.get("depth_max_m", 8.0)), float(gear.get("max_depth_m", 8.0))))
	var water_depth: float = lerpf(shallow, deep, clampf(cast_power, 0.0, 1.0))
	var fish_shallow: float = maxf(shallow, float(fish.raw.get("depth_min_m", 0.5)))
	var fish_deep: float = minf(deep, float(fish.raw.get("depth_max_m", 999.0)))
	# The ground can be deeper than a pelagic fish, but its presented bait layer
	# must stay inside the species/spot/rod intersection used by candidates().
	water_depth = maxf(water_depth, fish_shallow)
	var bait: String = str(record.get("bait_id", "worm"))
	var bottom_rig: bool = fish.species_id in FloatModel.BOTTOM_FEEDERS and water_depth <= 12.0 and bait not in ["spinner", "lure", "large_surface_lure"]
	record["water_depth_m"] = water_depth
	var presented_depth: float = maxf(0.3, water_depth - 0.12) if bottom_rig else water_depth * 0.6
	record["bait_depth_m"] = clampf(presented_depth, fish_shallow, minf(fish_deep, water_depth))
	record["float_rig"] = "near_bottom" if bottom_rig else "suspended"
	record["bait_affinity"] = catalog.bait_weight(fish, bait)

func make_individual(fish: FishDefinition, spot: String, region: String, bait: String, gear_id: int, time: String, weather: String) -> Dictionary:
	if str(fish.raw.get("animal_kind", "fish")) != "fish" or not bool(fish.raw.get("fishing_enabled", true)):
		return {}
	# Keep the ordinary population close to its old range. Only a small explicit
	# tail uses the new fictional extreme, so a record does not become the mean.
	var normal_max: float = clampf(float(fish.raw.get("normal_max_mm", fish.max_mm)), float(fish.min_mm), float(fish.max_mm))
	var extended: bool = rng.randf() < EXTENDED_SIZE_CHANCE and normal_max < float(fish.max_mm)
	# Larger baits only reshape this same species' ordinary size draw. They do
	# not add RNG draws, extend its game cap, or enlarge the 2% fictional tail.
	var fraction: float = pow(rng.randf(), Catalog.bait_size_exponent(bait, SIZE_EXPONENT))
	var length_mm: int
	if extended:
		length_mm = roundi(lerpf(normal_max, float(fish.max_mm), pow(rng.randf(), EXTENDED_SIZE_EXPONENT)))
		fraction = 1.0
	else:
		length_mm = roundi(lerpf(float(fish.min_mm), normal_max, fraction))
	var weight_g: int = maxi(1, roundi(float(fish.anchor_g) * pow(float(length_mm) / float(fish.anchor_mm), 3.0) * rng.randf_range(0.91, 1.09)))
	var size_class: String = "标准"
	if fraction < 0.18: size_class = "小巧"
	elif fraction > 0.88: size_class = "巨物"
	elif fraction > 0.62: size_class = "大个体"
	return {"species_id":fish.species_id,"length_mm":length_mm,"weight_g":weight_g,"size_fraction":fraction,"size_class":size_class,"region_id":region,"spot_id":spot,"bait_id":bait,"equipment":gear_id,"game_time":0.0,"time_of_day":time,"weather":weather,"behavior":fish.behavior,"difficulty":clampf(fish.difficulty * 0.7 + fraction * 0.5, 0.15, 1.0),"caught_at":Time.get_datetime_string_from_system(false,true),"disposition":"pending","reward":25,"sale_value":0 if fish.release_only else maxi(10, roundi(12.0 + sqrt(float(weight_g)) * 0.9)),"release_only":fish.release_only,"conservation_note":fish.conservation_note}
