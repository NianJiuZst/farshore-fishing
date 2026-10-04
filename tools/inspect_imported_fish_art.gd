extends SceneTree
## Read-only isolated-import audit. Never edits manifest, PNGs or import metadata.
const Catalog = preload("res://scripts/catalog.gd")
const Art = preload("res://scripts/fish_art_catalog.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected frozen source snapshot and output report")
		quit(2)
		return
	var snapshot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var contract: Dictionary = snapshot.content.photo_art
	var catalog: ContentCatalog = Catalog.new()
	var art: FishArtCatalog = Art.new()
	var failures: Array[String] = []
	if not catalog.load_all(true): failures.append_array(catalog.errors)
	if not art.load_all(catalog): failures.append_array(art.errors)
	var ids: Array = catalog.fish.keys()
	ids.sort()
	var textures: Dictionary = {}
	for resource: String in contract.textures:
		var path: String = "res://" + resource
		var texture: Texture2D = load(path) as Texture2D
		if texture == null:
			failures.append("Cannot load " + path)
			continue
		var pixels: Image = texture.get_image()
		if pixels == null or pixels.is_empty():
			failures.append("Cannot read pixels " + path)
			continue
		if pixels.is_compressed() and pixels.decompress() != OK:
			failures.append("Cannot decode " + path)
			continue
		pixels.clear_mipmaps()
		pixels.convert(Image.FORMAT_RGBA8)
		var mapping: ConfigFile = ConfigFile.new()
		if mapping.load(path + ".import") != OK:
			failures.append("Cannot read import " + path)
			continue
		var target: String = str(mapping.get_value("remap", "path", ""))
		if not target.begins_with("res://.godot/imported/") or not FileAccess.file_exists(target):
			failures.append("Missing imported texture " + path)
			continue
		textures[resource] = {"source_sha256": FileAccess.get_sha256(path),
			"image_sha256": Art.image_digest(pixels), "width": pixels.get_width(), "height": pixels.get_height(),
			"alpha_bounds": Art.alpha_bounds(pixels), "import_mapping_sha256": FileAccess.get_sha256(path + ".import"),
			"target": target.trim_prefix("res://"), "payload_sha256": FileAccess.get_sha256(target),
			"payload_bytes": FileAccess.get_file_as_bytes(target).size()}
	var report: Dictionary = {"failures": failures, "species_ids": ids, "complete": art.complete,
		"manifest_sha256": FileAccess.get_sha256(Art.MANIFEST_PATH), "textures": textures,
		"scope": "Staged native Texture2D decoding, alpha bounds and anatomical manifest validation; no GPU/device claim"}
	var output: FileAccess = FileAccess.open(args[1], FileAccess.WRITE)
	if output == null:
		printerr("Cannot write imported photo audit")
		quit(2)
		return
	output.store_string(JSON.stringify(report, "  ") + "\n")
	output.close()
	for failure: String in failures: printerr(failure)
	print("Imported photos: ", textures.size(), "; complete: ", art.complete, "; failures: ", failures.size())
	quit(0 if failures.is_empty() and art.complete and textures.size() == int(contract.texture_count) else 1)
