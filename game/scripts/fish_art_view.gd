class_name FishArtView
extends TextureRect
## Static, native 2D specimen. The texture is cropped only in an AtlasTexture;
## the original transparent PNG and the subject's proportions remain unchanged.
const SilhouetteShader = preload("res://assets/fish_silhouette.gdshader")
var species_id: String = ""
var silhouette: bool = false
var has_art_landmarks: bool = false
var _source_size: Vector2 = Vector2.ONE
var _subject: Rect2 = Rect2(Vector2.ZERO,Vector2.ONE)
var _region: Rect2 = Rect2(Vector2.ZERO,Vector2.ONE)
var _nose: Vector2 = Vector2.ZERO
var _tail: Vector2 = Vector2.ONE
var _fit_width: bool = false
var _preferred_width: float = 0.0
var _maximum_height: float = 0.0

func _init() -> void:
	name = "FishArtPreview"
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func configure(id: String, source: Texture2D, info: Dictionary = {}, hidden: bool = false) -> void:
	species_id = id
	silhouette = hidden
	texture = null
	material = null
	has_art_landmarks = false
	if source == null: return
	_source_size = source.get_size()
	if _source_size.x <= 0.0 or _source_size.y <= 0.0: return
	var bbox: Array = _array(info,"subject_bbox_normalized")
	if bbox.size() == 4:
		_subject = Rect2(Vector2(float(bbox[0]),float(bbox[1])) * _source_size,Vector2(float(bbox[2])-float(bbox[0]),float(bbox[3])-float(bbox[1])) * _source_size)
	else:
		# Legacy-only prototype fallback. Final photoreal validation requires
		# artist-supplied body landmarks and never uses a whisker's alpha extent.
		var pixels: Image = source.get_image()
		if pixels == null: return
		if pixels.is_compressed(): pixels.decompress()
		_subject = Rect2(pixels.get_used_rect())
	if _subject.size.x <= 0.0 or _subject.size.y <= 0.0: return
	_subject = _subject.intersection(Rect2(Vector2.ZERO,_source_size))
	if _subject.size.x <= 0.0 or _subject.size.y <= 0.0: return
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = source
	# Two original-image pixels protect antialiased fin edges without restoring
	# the large transparent gutters of the uncropped generation canvas.
	_region = _subject.grow(2.0).intersection(Rect2(Vector2.ZERO,_source_size))
	atlas.region = _region
	atlas.filter_clip = true
	texture = atlas
	var nose: Array = _array(info,"nose_normalized")
	var tail: Array = _array(info,"tail_normalized")
	has_art_landmarks = nose.size() == 2 and tail.size() == 2
	if has_art_landmarks:
		_nose = Vector2(float(nose[0]),float(nose[1])) * _source_size
		_tail = Vector2(float(tail[0]),float(tail[1])) * _source_size
	else:
		_nose = _subject.position + Vector2(0.0,_subject.size.y*0.5)
		_tail = _subject.position + Vector2(_subject.size.x,_subject.size.y*0.5)
	if silhouette:
		var shade: ShaderMaterial = ShaderMaterial.new()
		shade.shader = SilhouetteShader
		material = shade
	_update_fitted_height()

func fit_width(maximum_height: float, preferred_width: float = 0.0) -> void:
	# A container allocates width, then height follows the cropped art's aspect.
	# This avoids a floating ruler below a narrow fish in a tall empty viewport.
	_fit_width = true
	_maximum_height = maximum_height
	_preferred_width = preferred_width
	if not resized.is_connected(_update_fitted_height): resized.connect(_update_fitted_height)
	_update_fitted_height()

func _update_fitted_height() -> void:
	if not _fit_width or texture == null: return
	var available: float = size.x if size.x > 1.0 else _preferred_width
	if available <= 0.0: return
	custom_minimum_size.y = minf(_maximum_height,available * _region.size.y / _region.size.x)

func painted_rect() -> Rect2:
	if texture == null or _subject.size.x <= 0.0 or _subject.size.y <= 0.0: return Rect2()
	var fit: float = minf(size.x/_region.size.x,size.y/_region.size.y)
	var extent: Vector2 = _region.size*fit
	return Rect2((size-extent)*0.5,extent)

func measurement_endpoints() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if texture == null: return points
	var rect: Rect2 = painted_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0: return points
	var fit: float = rect.size.x/_region.size.x
	for point: Vector2 in [_nose,_tail]:
		points.append(get_global_transform_with_canvas() * (rect.position+(point-_region.position)*fit))
	return points

func _array(info: Dictionary, key: String) -> Array:
	var value: Variant = info.get(key,[])
	return value if value is Array else []
