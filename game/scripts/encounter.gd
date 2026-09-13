class_name EncounterGenerator
extends RefCounted
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(fixed_seed: int = -1) -> void:
	if fixed_seed < 0:
		rng.randomize()
	else:
		rng.seed = fixed_seed

func candidates(catalog: ContentCatalog, spot_id: String, bait: String, gear_id: int, cast_power: float, time: String, weather: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not catalog.spots.has(spot_id):
		return result
	var spot: Dictionary = catalog.spots[spot_id]
	var max_depth: float = minf(float(spot.depth_max_m), float(catalog.gear[gear_id].max_depth_m))
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
		var weight: float = float(data.get("weight", 1.0)) * fish.weight_for("bait_weights", bait) * fish.weight_for("time_weights", time) * fish.weight_for("weather_weights", weather)
		if weight > 0.0:
			result.append({"fish":fish,"weight":weight})
	return result

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
	return make_individual(selected, spot_id, str(catalog.spots[spot_id].region_id), bait, gear_id, time, weather)

func make_individual(fish: FishDefinition, spot: String, region: String, bait: String, gear_id: int, time: String, weather: String) -> Dictionary:
	# Right-skewed size distribution: big individuals are rarer; body condition changes gently.
	var fraction: float = pow(rng.randf(), 1.9)
	var length_mm: int = roundi(lerpf(float(fish.min_mm), float(fish.max_mm), fraction))
	var weight_g: int = maxi(1, roundi(float(fish.anchor_g) * pow(float(length_mm) / float(fish.anchor_mm), 3.0) * rng.randf_range(0.91, 1.09)))
	var size_class: String = "标准"
	if fraction < 0.18: size_class = "小巧"
	elif fraction > 0.88: size_class = "巨物"
	elif fraction > 0.62: size_class = "大个体"
	return {"species_id":fish.species_id,"length_mm":length_mm,"weight_g":weight_g,"size_fraction":fraction,"size_class":size_class,"region_id":region,"spot_id":spot,"bait_id":bait,"equipment":gear_id,"game_time":0.0,"time_of_day":time,"weather":weather,"behavior":fish.behavior,"difficulty":clampf(fish.difficulty * 0.7 + fraction * 0.5, 0.15, 1.0),"caught_at":Time.get_datetime_string_from_system(false,true),"disposition":"pending","reward":25,"sale_value":maxi(10, roundi(12.0 + sqrt(float(weight_g)) * 0.9))}
