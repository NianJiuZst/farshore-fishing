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
	for file_name: String in ["fish_a.json", "fish_b.json", "fish_c.json", "fish_d.json", "fish_e.json", "fish_f.json"]:
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
	# Gear IDs are stable numeric positions; append new options, never reorder old ones.
	for index: int in range(gear.size()):
		var item: Dictionary = gear[index]
		if float(item.get("id",-1)) != float(index) or str(item.get("name","")).is_empty(): errors.append("钓竿标识无效或顺序改变：" + str(index))
		for key: String in ["power","tolerance","max_depth_m"]:
			var value: float = float(item.get(key,0.0))
			if not is_finite(value) or value <= 0.0: errors.append("钓竿参数无效：" + str(index) + "/" + key)
		var reach: float = float(item.get("reach",0.0))
		if not is_finite(reach) or reach < 0.05 or reach > 1.0: errors.append("钓竿抛投范围无效：" + str(index))
		var price: float = float(item.get("price",-1.0))
		if not is_finite(price) or price < 0.0: errors.append("钓竿价格无效：" + str(index))
	var bait_ids: Array[String] = []
	for bait: Dictionary in baits:
		var id: String = str(bait.get("bait_id",""))
		if id.is_empty() or id in bait_ids: errors.append("鱼饵标识无效或重复：" + id)
		bait_ids.append(id)
		if str(bait.get("legacy_category",id)) not in ["worm","grain","shrimp","lure"]: errors.append("鱼饵兼容分类无效：" + id)
		var price: float = float(bait.get("price",-1.0))
		if not is_finite(price) or price < 0.0: errors.append("鱼饵价格无效：" + id)
		var overrides: Variant = bait.get("species_weights",{})
		if not overrides is Dictionary:
			errors.append("鱼饵偏好映射无效：" + id)
		else:
			for species_id: Variant in overrides:
				if not species_id is String or not fish.has(str(species_id)): errors.append("鱼饵偏好引用未知鱼种：" + id)
				var modifier: Variant = overrides[species_id]
				if (not modifier is float and not modifier is int) or not is_finite(float(modifier)) or float(modifier) < 0.0: errors.append("鱼饵偏好权重无效：" + id)

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

func bait_definition(id: String) -> Dictionary:
	for bait: Dictionary in baits:
		if str(bait.get("bait_id","")) == id: return bait
	return {}

func bait_category(id: String) -> String:
	var bait: Dictionary = bait_definition(id)
	return str(bait.get("legacy_category",id))

func bait_weight(species: FishDefinition, id: String) -> float:
	# Explicit additions are game balance, not feeding measurements. Old four
	# definitions have no overrides and preserve all original species weights.
	var bait: Dictionary = bait_definition(id)
	var overrides: Dictionary = bait.get("species_weights",{})
	if overrides.has(species.species_id): return maxf(0.0,float(overrides[species.species_id]))
	return species.weight_for("bait_weights",bait_category(id))
