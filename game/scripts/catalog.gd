class_name ContentCatalog
extends RefCounted
const Fish = preload("res://scripts/fish_definition.gd")
var fish: Dictionary = {}
var regions: Array = []
var spots: Dictionary = {}
var gear: Array = []
var baits: Array = []
var errors: Array[String] = []

func load_all(check_art: bool = true) -> bool:
	fish.clear()
	errors.clear()
	for file_name: String in ["fish_a.json", "fish_b.json", "fish_c.json", "fish_d.json"]:
		var entries: Variant = _json("res://data/" + file_name)
		if entries is not Array:
			continue
		for entry: Dictionary in entries:
			var f: FishDefinition = Fish.new(entry)
			if fish.has(f.species_id) or f.species_id.is_empty():
				errors.append("重复或空物种 ID: " + f.species_id)
			fish[f.species_id] = f
			if f.min_mm <= 0 or f.max_mm <= f.min_mm or f.anchor_mm <= 0 or f.anchor_g <= 0:
				errors.append("非法尺寸: " + f.species_id)
			if float(entry.get("weight", 1)) <= 0.0:
				errors.append("非法权重: " + f.species_id)
			if check_art and (not ResourceLoader.exists(f.art) or not ResourceLoader.exists(f.thumb)):
				errors.append("缺少插画: " + f.species_id)
	var world: Variant = _json("res://data/world.json")
	if world is Dictionary:
		regions = world.get("regions", [])
		gear = world.get("gear", [])
		baits = world.get("baits", [])
		spots.clear()
		for spot: Dictionary in world.get("spots", []):
			var id: String = str(spot.get("spot_id", ""))
			if spots.has(id):
				errors.append("重复钓点: " + id)
			spots[id] = spot
	var region_ids: Array[String] = []
	for region_value: Dictionary in regions:
		var region_key: String = str(region_value.get("region_id", ""))
		if region_key.is_empty() or region_key in region_ids: errors.append("地区 ID 无效: " + region_key)
		region_ids.append(region_key)
		if int(region_value.get("unlock_count", 0)) < 0 or int(region_value.get("unlock_cost", 0)) < 0: errors.append("地区解锁参数无效: " + region_key)
		for spot_key: String in region_value.get("spots", []):
			if not spots.has(spot_key) or str(spots[spot_key].get("region_id", "")) != region_key: errors.append("地区钓点引用失效: " + spot_key)
	for spot_key: String in spots:
		var spot_value: Dictionary = spots[spot_key]
		if str(spot_value.get("region_id", "")) not in region_ids: errors.append("未知钓点地区: " + spot_key)
		if float(spot_value.get("depth_min_m", -1)) < 0 or float(spot_value.get("depth_max_m", 0)) < float(spot_value.get("depth_min_m", 0)): errors.append("钓点水深非法: " + spot_key)
	for value: FishDefinition in fish.values():
		if value.behavior not in ["steady", "burst", "rest"]: errors.append("未知行为: " + value.species_id)
		if int(value.raw.get("min_gear", 0)) < 0 or int(value.raw.get("min_gear", 0)) >= gear.size(): errors.append("装备门槛无效: " + value.species_id)
		if float(value.raw.get("min_cast", 0)) > float(value.raw.get("max_cast", 1)): errors.append("落点范围非法: " + value.species_id)
		for group: String in ["bait_weights", "time_weights", "weather_weights"]:
			var modifiers: Dictionary = value.raw.get(group, {})
			for modifier: Variant in modifiers.values():
				if float(modifier) < 0 or not is_finite(float(modifier)): errors.append("负数/无效倍率: " + value.species_id)
		for region_key: String in value.regions():
			if region_key not in region_ids: errors.append("鱼种地区引用失效: " + value.species_id)
		if value.spots().is_empty():
			errors.append("无可达钓点: " + value.species_id)
		for id: String in value.spots():
			if not spots.has(id):
				errors.append("钓点引用失效: " + id)
	for id: String in spots:
		var count: int = 0
		for f: FishDefinition in fish.values():
			if id in f.spots():
				count += 1
		if count == 0:
			errors.append("空钓点: " + id)
	return errors.is_empty()

func _json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("缺少配置: " + path)
		return null
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append("配置无法解析: " + path)
		return null
	return parser.data

func region(id: String) -> Dictionary:
	for value: Dictionary in regions:
		if value.get("region_id") == id:
			return value
	return {}

func fish_at(spot_id: String) -> Array[FishDefinition]:
	var result: Array[FishDefinition] = []
	for value: FishDefinition in fish.values():
		if spot_id in value.spots():
			result.append(value)
	return result

func bait_name(id: String) -> String:
	for value: Dictionary in baits:
		if value.get("bait_id") == id:
			return str(value.get("name"))
	return id
