extends SceneTree
## Run after importing the final canonical all44 PNGs. Source-art metadata keeps
## its master SHA-256; this audit adds Godot's decoded-image hashes so the same
## integrity contract can be checked when Android contains imported .ctex only.
## Never makes an incomplete artist manifest complete and never changes the
## REQUIRE_PHOTOREAL gate. No output is written unless the final audit passes.
const Catalog = preload("res://scripts/catalog.gd")
const Art = preload("res://scripts/fish_art_catalog.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var source_path: String=""
	var output_path: String=""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--input="): source_path=arg.trim_prefix("--input=")
		if arg.begins_with("--output="): output_path=arg.trim_prefix("--output=")
	if source_path.is_empty() or output_path.is_empty():
		printerr("FISH_ART_IMPORT_AUDIT: --input=<complete artist manifest> --output=<audited manifest> required")
		quit(2)
		return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	if not data is Dictionary or not data.get("assets") is Array or not bool(data.get("complete",false)):
		printerr("FISH_ART_IMPORT_AUDIT: artist manifest is not complete; no output written")
		quit(1)
		return
	var catalog: ContentCatalog=Catalog.new()
	if not catalog.load_all(true):
		printerr("FISH_ART_IMPORT_AUDIT: canonical content failed ",catalog.errors)
		quit(1)
		return
	var errors: Array[String]=[]
	for value: Variant in data.assets:
		if not value is Dictionary:
			errors.append("Malformed asset entry")
			continue
		var entry: Dictionary=value
		var id: String=str(entry.get("species_id",""))
		if not catalog.fish.has(id):
			errors.append("Unknown species: "+id)
			continue
		var fish: FishDefinition=catalog.fish[id]
		for thumbnail: bool in [false,true]:
			var path: String=fish.thumb if thumbnail else fish.art
			var texture: Texture2D=load(path) as Texture2D
			if texture == null:
				errors.append("Cannot load imported texture: "+path)
				continue
			var pixels: Image=texture.get_image()
			if pixels == null or pixels.is_empty():
				errors.append("Imported texture is empty: "+path)
				continue
			if pixels.is_compressed() and pixels.decompress()!=OK:
				errors.append("Cannot decode imported texture: "+path)
				continue
			pixels.clear_mipmaps()
			pixels.convert(Image.FORMAT_RGBA8)
			entry["thumb_image_sha256" if thumbnail else "image_sha256"]=Art.image_digest(pixels)
	var audit: FishArtCatalog=Art.new()
	if not audit.load_manifest(data,catalog,true): errors.append_array(audit.errors)
	if not errors.is_empty():
		for error: String in errors: printerr("FISH_ART_IMPORT_AUDIT: ",error)
		printerr("FISH_ART_IMPORT_AUDIT: rejected; no output written")
		quit(1)
		return
	var file: FileAccess=FileAccess.open(output_path,FileAccess.WRITE)
	if file == null:
		printerr("FISH_ART_IMPORT_AUDIT: output could not be opened ",output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(data,"\t",true,true)+"\n")
	file.close()
	print("FISH_ART_IMPORT_AUDIT: complete44 master/thumbnail source hashes, decoded-image hashes, alpha bounds and anatomical landmarks passed: ",output_path)
	quit(0)
