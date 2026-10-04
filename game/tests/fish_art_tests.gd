extends SceneTree
## Native art geometry and fail-closed metadata tests. No real saves are opened.
const View = preload("res://scripts/fish_art_view.gd")
const ArtCatalog = preload("res://scripts/fish_art_catalog.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Ruler = preload("res://scripts/measure_ruler.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FISH_ART: ",label)

func _run() -> void:
	var pixels: Image = Image.create(200,100,false,Image.FORMAT_RGBA8)
	pixels.fill(Color.TRANSPARENT)
	pixels.fill_rect(Rect2i(40,20,150,60),Color("5e8150"))
	# A long whisker is included in the visible crop, but not in body length.
	pixels.fill_rect(Rect2i(5,45,36,2),Color("5e8150"))
	pixels.set_pixel(0,0,Color(0.1,0.1,0.1,0.02))
	var source: Texture2D = ImageTexture.create_from_image(pixels)
	var info: Dictionary = {"subject_bbox_normalized":[0.025,0.2,0.95,0.8],"nose_normalized":[0.2,0.5],"tail_normalized":[0.945,0.5]}
	var holder: Control = Control.new()
	holder.position = Vector2(31,43)
	root.add_child(holder)
	var view: FishArtView = View.new()
	view.configure("test_catfish",source,info)
	view.position = Vector2(20,30)
	view.size = Vector2(600,300)
	holder.add_child(view)
	await process_frame
	_check(view.texture is AtlasTexture and view.texture.atlas == source,"native AtlasTexture retains original source pixels")
	_check(view.texture.region == Rect2(3,18,189,64),"subject crop includes two source pixels of fin-edge padding")
	_check(view.mouse_filter == Control.MOUSE_FILTER_IGNORE,"photo never captures page scrolling or taps")
	_check(view.material == null and not view.is_processing(),"discovered art has no movement shader or frame processor")
	_check(view.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"photo preserves body aspect")
	_check(view.painted_rect().size.is_equal_approx(Vector2(600,600.0*64.0/189.0)),"source gutter does not distort or squash body")
	var ends: Array[Vector2] = view.measurement_endpoints()
	var scale: float = 600.0/189.0
	_check(ends.size()==2 and is_equal_approx(ends[1].x-ends[0].x,149.0*scale),"ruler uses nose to tail, excluding long barbel")
	_check(is_equal_approx(ends[0].x,51.0+(40.0-3.0)*scale),"landmarks preserve full-canvas origin and control transforms")
	var first: Vector2 = ends[0]
	view.position += Vector2(13,17)
	_check(view.measurement_endpoints()[0].is_equal_approx(first+Vector2(13,17)),"moving a static photo moves ruler anchors identically")
	view.fit_width(325)
	await process_frame
	_check(is_equal_approx(view.custom_minimum_size.y,600.0*64.0/189.0),"adaptive minimum height keeps ruler close to a thin specimen")
	var ruler: CatchRuler = Ruler.new()
	ruler.specimen = view
	holder.add_child(ruler)
	await process_frame
	_check(not ruler.is_processing(),"static-photo ruler avoids the animated 3D redraw loop")
	var reverse: Dictionary = info.duplicate(true)
	reverse.nose_normalized=[0.945,0.5]
	reverse.tail_normalized=[0.2,0.5]
	view.configure("right_eyed_plaice",source,reverse)
	_check(view.measurement_endpoints()[0].x>view.measurement_endpoints()[1].x,"natural right-eyed flatfish orientation remains valid")
	view.configure("undiscovered",source,info,true)
	_check(view.material is ShaderMaterial and view.material.shader == View.SilhouetteShader,"undiscovered grid uses separate static silhouette shader")
	var shader: String = FileAccess.get_file_as_string("res://assets/fish_silhouette.gdshader")
	_check(not "void vertex" in shader and not "TIME *" in shader,"silhouette shader contains no motion warp")
	view.configure("missing",null,{},false)
	_check(view.texture == null and view.measurement_endpoints().is_empty(),"missing photo cannot leave stale art or ruler endpoints")
	_check(ArtCatalog.alpha_bounds(pixels)==[5,20,190,80],"alpha bound threshold excludes transparent residue")
	var invisible: Image = Image.create(12,12,false,Image.FORMAT_RGBA8)
	invisible.fill(Color(1,1,1,0.02))
	_check(ArtCatalog.alpha_bounds(invisible).is_empty(),"nonempty low-alpha bytes cannot masquerade as visible fish")
	var catalog: ContentCatalog = Catalog.new()
	_check(catalog.load_all(false),"canonical catalog data loads")
	_check(catalog.fish.size() == 111 and catalog.fish_species_count() == 110,"art catalog covers 110 fish and one blue whale")
	var art: FishArtCatalog = ArtCatalog.new()
	_check(not art.load_all(catalog,"res://data/not_a_manifest.json",true),"final gate rejects missing manifest")
	_check(art.texture_for(catalog.fish["common_carp"]) == null,"failed gate never silently uses historical art")
	_check(art.load_all(catalog,"res://data/not_a_manifest.json",false) and not art.complete,"prototype-only legacy path cannot claim all111 assets complete")
	_check(not art.load_manifest({"format_version":1,"complete":false,"asset_count":0,"assets":[]},catalog,true),"final gate rejects partial coverage")
	_check(not art.load_manifest({"format_version":1,"complete":true,"asset_count":111,"assets":[]},catalog,false),"claimed completeness also enables strict coverage validation")
	_check(not art.load_manifest({"format_version":1,"complete":true,"asset_count":111,"assets":{}},catalog,true),"malformed entry collection fails closed")
	var invalid: Dictionary = {"species_id":"common_carp","subject_bbox_normalized":"bad","subject_bbox_px":[],"nose_normalized":{},"tail_normalized":[]}
	_check(not art.load_manifest({"format_version":1,"complete":false,"asset_count":1,"assets":[invalid]},catalog,false),"malformed geometry fails closed without crashing")
	var meta: Dictionary = {"width":200,"height":100,"subject_bbox_normalized":[0.025,0.2,0.95,0.8],"subject_bbox_px":[5,20,190,80],"nose_normalized":[0.945,0.5],"tail_normalized":[0.2,0.5],"ruler_extent_normalized":[0.945,0.2],"alpha_threshold_for_bbox":24}
	art.errors.clear()
	art._validate_metadata("right_eyed_plaice",meta)
	_check(art.errors.is_empty(),"metadata accepts independent right-facing anatomical landmarks")
	meta.nose_normalized=[0.0,0.5]
	art._validate_metadata("bad_landmark",meta)
	_check(not art.errors.is_empty(),"nose landmark outside subject fails validation")
	_check(art._valid_hash(ArtCatalog.image_digest(pixels)) and not art._valid_hash("missing"),"decoded image digests are exact SHA-256 values")
	# Check real imported texture integrity without changing any canonical PNG.
	var original: Texture2D=load(catalog.fish["common_carp"].art)
	var imported: Image=original.get_image()
	if imported.is_compressed(): imported.decompress()
	imported.clear_mipmaps()
	imported.convert(Image.FORMAT_RGBA8)
	var integrity: Dictionary={"species_id":"common_carp","width":imported.get_width(),"height":imported.get_height(),"sha256":FileAccess.get_sha256(catalog.fish["common_carp"].art),"image_sha256":ArtCatalog.image_digest(imported),"subject_bbox_px":ArtCatalog.alpha_bounds(imported)}
	art.errors.clear()
	art._validate_texture(catalog.fish["common_carp"].art,integrity,false,true)
	_check(art.errors.is_empty(),"final texture validator accepts matching source/imported hashes and alpha bounds")
	var corrupt: Dictionary=integrity.duplicate(true)
	corrupt.sha256="0000000000000000000000000000000000000000000000000000000000000000"
	art.errors.clear()
	art._validate_texture(catalog.fish["common_carp"].art,corrupt,false,true)
	_check(not art.errors.is_empty(),"final texture validator rejects source PNG hash mismatch")
	corrupt=integrity.duplicate(true)
	corrupt.image_sha256="0000000000000000000000000000000000000000000000000000000000000000"
	art.errors.clear()
	art._validate_texture(catalog.fish["common_carp"].art,corrupt,false,true)
	_check(not art.errors.is_empty(),"final texture validator rejects imported/exportable pixel hash mismatch")
	corrupt=integrity.duplicate(true)
	corrupt.subject_bbox_px=[0,0,4,4]
	art.errors.clear()
	art._validate_texture(catalog.fish["common_carp"].art,corrupt,false,true)
	_check(not art.errors.is_empty(),"final texture validator rejects inaccurate alpha subject bounds")
	corrupt=integrity.duplicate(true)
	corrupt.erase("image_sha256")
	art.errors.clear()
	art._validate_texture(catalog.fish["common_carp"].art,corrupt,false,true)
	_check(not art.errors.is_empty(),"final texture validator rejects absent exported-image digest")
	_check(ArtCatalog.bounds_match([5,20,190,80],[5.0,20.0,190.0,80.0]),"JSON float arrays and integer alpha bounds compare numerically")
	holder.free()
	await process_frame
	print("FISH_ART_TESTS: ",checks-failures,"/",checks," passed; synthetic geometry and release-gate rejection tests; full111-art acceptance and Android validation are separate")
	quit(0 if failures == 0 else 1)
