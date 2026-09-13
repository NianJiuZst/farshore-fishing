class_name FishDefinition
extends RefCounted

var species_id: String
var name: String
var scientific_name: String
var art: String
var thumb: String
var description: String
var morphology: String
var min_mm: int
var max_mm: int
var anchor_mm: int
var anchor_g: int
var behavior: String
var difficulty: float
var raw: Dictionary

func _init(value: Dictionary = {}) -> void:
	raw = value.duplicate(true)
	species_id = str(value.get("species_id", ""))
	name = str(value.get("name", ""))
	scientific_name = str(value.get("scientific_name", ""))
	art = str(value.get("art", ""))
	thumb = str(value.get("thumb", ""))
	description = str(value.get("description", ""))
	morphology = str(value.get("morphology", ""))
	min_mm = int(value.get("min_mm", 100))
	max_mm = int(value.get("max_mm", 500))
	anchor_mm = int(value.get("anchor_mm", 300))
	anchor_g = int(value.get("anchor_g", 400))
	behavior = str(value.get("behavior", "steady"))
	difficulty = float(value.get("difficulty", 0.4))

func regions() -> Array:
	return raw.get("region_ids", [])

func spots() -> Array:
	return raw.get("spot_ids", [])

func weight_for(kind: String, key: String) -> float:
	var weights: Dictionary = raw.get(kind, {})
	return maxf(0.0, float(weights.get(key, 1.0)))
