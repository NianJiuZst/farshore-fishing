class_name FishArtCatalog
extends RefCounted
## Final source requires 110 fish and one mammal master, derivatives and imported
## image hashes. Explicit false arguments are reserved for isolated tests.
## A missing/incomplete/mismatched final manifest blocks play rather than
## silently showing another species or falling back to a coarse 3D preview.
const REQUIRE_PHOTOREAL: bool = true
const MANIFEST_PATH: String = "res://data/fish_art.json"
const EXPECTED_COUNT: int = 111
const FULL_TEXTURE_CACHE_LIMIT: int = 4
var errors: Array[String] = []
var complete: bool = false
var _entries: Dictionary = {}
var _textures: Dictionary = {}
var _full_texture_order: Array[String] = []
var _blocked: bool = false

func load_all(catalog: ContentCatalog, manifest_path: String = MANIFEST_PATH, require_complete: bool = REQUIRE_PHOTOREAL) -> bool:
	errors.clear()
	_entries.clear()
	_textures.clear()
	_full_texture_order.clear()
	complete = false
	_blocked = false
	if not FileAccess.file_exists(manifest_path):
		if require_complete: errors.append("缺少完整写实鱼图清单")
		_blocked = not errors.is_empty()
		return not _blocked
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		errors.append("写实鱼图清单无法解析")
		_blocked = true
		return false
	return load_manifest(parsed,catalog,require_complete)

func load_manifest(data: Dictionary, catalog: ContentCatalog, require_complete: bool = REQUIRE_PHOTOREAL) -> bool:
	errors.clear()
	_entries.clear()
	_textures.clear()
	_full_texture_order.clear()
	complete = false
	var strict: bool = require_complete or bool(data.get("complete",false))
	if int(data.get("format_version",0)) != 1: errors.append("未知写实鱼图清单格式")
	var assets: Variant = data.get("assets",[])
	if not assets is Array:
		errors.append("写实鱼图条目格式无效")
		_blocked = true
		return false
	if int(data.get("asset_count",-1)) != assets.size(): errors.append("写实鱼图数量与清单不符")
	if strict and (not bool(data.get("complete",false)) or assets.size() != EXPECTED_COUNT or catalog.fish.size() != EXPECTED_COUNT):
		errors.append("写实图尚未完整覆盖110种鱼及蓝鲸")
	for value: Variant in assets:
		if not value is Dictionary:
			errors.append("写实鱼图条目无效")
			continue
		var info: Dictionary = value
		var id: String = str(info.get("species_id",""))
		if not catalog.fish.has(id) or _entries.has(id):
			errors.append("未知或重复写实鱼图: "+id)
			continue
		_entries[id] = info.duplicate(true)
		_validate_metadata(id,info)
		var fish: FishDefinition = catalog.fish[id]
		if fish.art != "res://assets/fish/"+id+".png" or fish.thumb != "res://assets/fish/"+id+"_thumb.png": errors.append("写实鱼图路径不属于当前鱼种: "+id)
		_validate_texture(fish.art,info,false,strict)
		_validate_texture(fish.thumb,info,true,strict)
	if strict:
		for id: String in catalog.fish:
			if not _entries.has(id): errors.append("缺少写实鱼图: "+id)
	_blocked = not errors.is_empty()
	complete = strict and not _blocked
	return not _blocked

func info_for(id: String) -> Dictionary:
	return (_entries.get(id,{}) as Dictionary).duplicate(true) if not _blocked else {}

func texture_for(fish: FishDefinition, thumbnail: bool = false) -> Texture2D:
	if _blocked: return null
	var path: String = fish.thumb if thumbnail else fish.art
	if not _textures.has(path):
		if not ResourceLoader.exists(path,"Texture2D"): return null
		_textures[path] = load(path) as Texture2D
	if not thumbnail:
		_full_texture_order.erase(path)
		_full_texture_order.append(path)
		while _full_texture_order.size() > FULL_TEXTURE_CACHE_LIMIT:
			# Active views own their textures; removing this cache reference never
			# lowers resolution or changes a displayed fish. Thumbnail cache stays.
			_textures.erase(_full_texture_order.pop_front())
	return _textures[path] as Texture2D

func _validate_metadata(id: String, info: Dictionary) -> void:
	var width: int = int(info.get("width",0))
	var height: int = int(info.get("height",0))
	if width <= 0 or height <= 0: errors.append("鱼图尺寸无效: "+id)
	var bbox: Array = _array(info,"subject_bbox_normalized")
	var px: Array = _array(info,"subject_bbox_px")
	if not _unit_values(bbox,4) or bbox.size() != 4 or float(bbox[0]) >= float(bbox[2]) or float(bbox[1]) >= float(bbox[3]):
		errors.append("鱼图主体边界无效: "+id)
		return
	if px.size() != 4:
		errors.append("鱼图像素边界缺失: "+id)
	else:
		for index: int in range(4):
			if absf(float(px[index])-float(bbox[index])*(width if index%2==0 else height)) > 1.0: errors.append("鱼图归一化边界不一致: "+id)
	for key: String in ["nose_normalized","tail_normalized"]:
		var point: Array = _array(info,key)
		if not _unit_values(point,2):
			errors.append("鱼图吻尾标记无效: "+id+"/"+key)
			continue
		if float(point[0]) < float(bbox[0]) or float(point[0]) > float(bbox[2]) or float(point[1]) < float(bbox[1]) or float(point[1]) > float(bbox[3]): errors.append("鱼图吻尾标记超出主体: "+id)
	var nose: Array = _array(info,"nose_normalized")
	var tail: Array = _array(info,"tail_normalized")
	if _unit_values(nose,2) and _unit_values(tail,2) and absf(float(tail[0])-float(nose[0])) < 0.1: errors.append("鱼图必须具有有效吻端至尾端体长: "+id)
	var extent: Array = _array(info,"ruler_extent_normalized")
	if not _unit_values(extent,2) or not _unit_values(nose,2) or not _unit_values(tail,2): errors.append("鱼图尺子标记缺失: "+id)
	elif absf(float(extent[0])-float(nose[0])) > 0.0001 or absf(float(extent[1])-float(tail[0])) > 0.0001: errors.append("鱼图尺子与吻尾标记不一致: "+id)
	if int(info.get("alpha_threshold_for_bbox",0)) != 24: errors.append("鱼图透明边缘审核阈值无效: "+id)

func _array(info: Dictionary, key: String) -> Array:
	var value: Variant = info.get(key,[])
	return value if value is Array else []

func _unit_values(value: Array, count: int) -> bool:
	if value.size() != count: return false
	for item: Variant in value:
		if (not item is int and not item is float) or not is_finite(float(item)) or float(item)<0.0 or float(item)>1.0: return false
	return true

func _valid_hash(value: String) -> bool:
	if value.length() != 64: return false
	for index: int in range(value.length()):
		if value[index] not in "0123456789abcdef": return false
	return true

func _validate_texture(path: String, info: Dictionary, thumbnail: bool, strict: bool) -> void:
	var label: String = str(info.get("species_id",""))+("/thumb" if thumbnail else "/art")
	var hash_key: String = "thumb_sha256" if thumbnail else "sha256"
	var image_hash_key: String = "thumb_image_sha256" if thumbnail else "image_sha256"
	var expected_hash: String = str(info.get(hash_key,""))
	if (strict or not expected_hash.is_empty()) and not _valid_hash(expected_hash): errors.append("鱼图源文件哈希缺失或无效: "+label)
	# Source PNGs exist in an editor checkout; exports may contain only .ctex.
	# The separate decoded-image digest below remains enforceable in an APK.
	if _valid_hash(expected_hash) and FileAccess.file_exists(path) and FileAccess.get_sha256(path) != expected_hash: errors.append("鱼图源文件哈希不符: "+label)
	if not ResourceLoader.exists(path,"Texture2D"):
		errors.append("缺少鱼图资源: "+label)
		return
	var source: Texture2D = load(path) as Texture2D
	if source == null:
		errors.append("鱼图无法加载: "+label)
		return
	# Validation does not retain all74 full-resolution GPU textures. Display
	# textures are loaded lazily by texture_for, after each image passes checks.
	var pixels: Image = source.get_image()
	if pixels == null or pixels.is_empty():
		errors.append("鱼图为空: "+label)
		return
	if pixels.is_compressed() and pixels.decompress() != OK:
		errors.append("鱼图无法解码: "+label)
		return
	pixels.clear_mipmaps()
	pixels.convert(Image.FORMAT_RGBA8)
	var expected_width: int = int(info.get("thumb_width" if thumbnail else "width",0))
	var expected_height: int = int(info.get("thumb_height" if thumbnail else "height",0))
	if (strict or expected_width > 0) and (pixels.get_width() != expected_width or pixels.get_height() != expected_height): errors.append("鱼图尺寸与清单不符: "+label)
	var bbox_key: String = "thumb_subject_bbox_px" if thumbnail else "subject_bbox_px"
	var expected_bounds: Array = _array(info,bbox_key)
	if strict or not expected_bounds.is_empty():
		var actual_bounds: Array[int] = alpha_bounds(pixels,24)
		if not bounds_match(actual_bounds,expected_bounds): errors.append("鱼图透明主体边界与清单不符: "+label)
	var used: Rect2i = pixels.get_used_rect()
	if used.size.x < 2 or used.size.y < 2 or pixels.detect_alpha() == Image.ALPHA_NONE: errors.append("鱼图为空或缺少透明背景: "+label)
	var image_hash: String = str(info.get(image_hash_key,""))
	if (strict or not image_hash.is_empty()) and not _valid_hash(image_hash): errors.append("鱼图导入像素哈希缺失或无效: "+label)
	elif _valid_hash(image_hash) and image_digest(pixels) != image_hash: errors.append("鱼图导入像素哈希不符: "+label)

static func image_digest(pixels: Image) -> String:
	var context: HashingContext = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(pixels.get_data())
	return context.finish().hex_encode()

static func alpha_bounds(pixels: Image, threshold: int = 24) -> Array[int]:
	# Four edge searches avoid traversing every scale inside a large opaque fish.
	# Alpha bytes are unmodified by Godot's transparent-RGB border repair.
	var bytes: PackedByteArray = pixels.get_data()
	var width: int = pixels.get_width()
	var used: Rect2i = pixels.get_used_rect()
	if used.size.x == 0 or used.size.y == 0: return []
	var left: int = used.position.x
	var right: int = used.end.x
	var top: int = used.position.y
	var bottom: int = used.end.y
	while top < bottom and not _row_has_alpha(bytes,width,top,left,right,threshold): top += 1
	if top == bottom: return []
	while bottom > top and not _row_has_alpha(bytes,width,bottom-1,left,right,threshold): bottom -= 1
	while left < right and not _column_has_alpha(bytes,width,left,top,bottom,threshold): left += 1
	while right > left and not _column_has_alpha(bytes,width,right-1,top,bottom,threshold): right -= 1
	return [left,top,right,bottom]

static func _row_has_alpha(bytes: PackedByteArray, width: int, y: int, left: int, right: int, threshold: int) -> bool:
	var row: int = y*width*4+3
	for x: int in range(left,right):
		if bytes[row+x*4] >= threshold: return true
	return false

static func _column_has_alpha(bytes: PackedByteArray, width: int, x: int, top: int, bottom: int, threshold: int) -> bool:
	var column: int = x*4+3
	for y: int in range(top,bottom):
		if bytes[y*width*4+column] >= threshold: return true
	return false

static func bounds_match(actual: Array[int], expected: Array) -> bool:
	if actual.size() != 4 or expected.size() != 4: return false
	for index: int in range(4):
		var value: Variant = expected[index]
		if (not value is int and not value is float) or not is_finite(float(value)) or float(value) != float(actual[index]): return false
	return true
