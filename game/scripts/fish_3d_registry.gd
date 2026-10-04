class_name Fish3DRegistry
extends RefCounted
## Full-catalog 3D presentation contract. Listing a model here is a requirement,
## never evidence that an unbuilt model exists. Final acceptance requires zero
## missing assets; presentation must never silently substitute another species.
const MANIFEST_PATH: String = "res://data/fish_3d.json"
static var _manifest: Dictionary = {}

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary: _manifest = parsed
	return _manifest.duplicate(true)

static func species_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in manifest().get("models", {}): result.append(id)
	return result

static func model_info(species_id: String) -> Dictionary:
	return (manifest().get("models", {}) as Dictionary).get(species_id, {})

static func model_path(species_id: String) -> String:
	return str(model_info(species_id).get("scene", ""))

static func is_available(species_id: String) -> bool:
	var path: String = model_path(species_id)
	return not path.is_empty() and ResourceLoader.exists(path, "PackedScene")

static func instantiate_fish(species_id: String) -> Node3D:
	if not is_available(species_id):
		push_error("Missing species-specific 3D fish: " + species_id)
		return null
	var packed: PackedScene = load(model_path(species_id)) as PackedScene
	if packed == null: return null
	return packed.instantiate() as Node3D

static func validate_catalog(catalog: ContentCatalog, require_assets: bool = true) -> Array[String]:
	var errors: Array[String] = []
	var data: Dictionary = manifest()
	if int(data.get("schema_version", 0)) != 1: errors.append("Unknown 3D manifest schema")
	var models: Dictionary = data.get("models", {})
	for id: String in catalog.fish:
		if not models.has(id):
			errors.append("No 3D definition: " + id)
			continue
		var info: Dictionary = models[id]
		if str(info.get("scene", "")) != "res://assets/3d/" + id + ".glb": errors.append("Non-species-specific 3D path: " + id)
		if float(info.get("rest_length_m", 0)) != 1.0: errors.append("Invalid normalized model length: " + id)
		if info.has("mouth_offset_normalized"):
			var mouth: Variant = info.mouth_offset_normalized
			if not mouth is Array or mouth.size() != 3:
				errors.append("Invalid normalized mouth landmark: " + id)
			else:
				for coordinate: Variant in mouth:
					if (not coordinate is int and not coordinate is float) or not is_finite(float(coordinate)) or absf(float(coordinate)) > 1.0:
						errors.append("Invalid normalized mouth coordinate: " + id)
		if require_assets and not is_available(id): errors.append("Missing 3D model: " + id)
	for id: String in models:
		if not catalog.fish.has(id): errors.append("Unknown 3D catalog species: " + id)
	return errors
