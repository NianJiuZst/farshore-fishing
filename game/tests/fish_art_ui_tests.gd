extends SceneTree
## Focused production-page QA, optionally using externally supplied photo
## fixtures. A partial fixture is explicitly labeled; no canonical PNG or
## release-readiness flags are replaced by this test.
const Main = preload("res://scenes/main.tscn")
const Store = preload("res://scripts/save_store.gd")
const View = preload("res://scripts/fish_art_view.gd")
const ArtCatalog = preload("res://scripts/fish_art_catalog.gd")
const Ruler = preload("res://scripts/measure_ruler.gd")
var checks: int = 0
var failures: int = 0
var app: Control
var fixture_ids: Array[String] = []
var capture_dir: String = ""
var manifest_path: String = ""
var tall: bool = false
var reference_perch: bool = false
var selected_ids: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PHOTO_UI: ",label)

func _run() -> void:
	var isolated: String = OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/farshore-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-") or not OS.get_user_data_dir().begins_with(isolated+"/"):
		printerr("PHOTO_UI: refusing non-isolated save environment")
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--photo-fixtures="): manifest_path=arg.trim_prefix("--photo-fixtures=")
		if arg.begins_with("--output="): capture_dir=arg.trim_prefix("--output=")
		if arg == "--tall": tall=true
		if arg == "--reference-perch": reference_perch=true
		if arg.begins_with("--species="):
			selected_ids.assign(arg.trim_prefix("--species=").split(",",false))
	root.size = Vector2i(720,1584 if tall else 1280)
	# Opaque static-page QA needs the real 2D renderer but not the hidden 3D
	# background. Other suites own inworld rendering; the real stage is still built.
	root.disable_3d = true
	app = Main.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	_check(app._content_ok and app._models_complete,"production catalog and real3D assets remain valid")
	_check(ArtCatalog.REQUIRE_PHOTOREAL and app.fish_art.complete,"production final gate requires all74 validated photo masters and thumbnails")
	var save: SaveStore = Store.new()
	_check(save.initialize(isolated.path_join("photo-ui-%s" % Time.get_ticks_usec())),"isolated legitimate save fixture")
	app.store=save
	app.encounter.rng.seed=20261002
	if not manifest_path.is_empty(): _load_photo_fixtures()
	var ids: Array[String] = fixture_ids.duplicate()
	if ids.is_empty():
		if app.fish_art.complete: ids.assign(app.catalog.fish.keys())
		else: ids.assign(["common_carp","alligator_gar","chinese_sturgeon","olive_flounder"])
	if not selected_ids.is_empty(): ids=selected_ids.duplicate()
	for id: String in ids:
		if not app.catalog.fish.has(id):
			printerr("PHOTO_UI: unknown requested species ",id)
			app.free()
			quit(2)
			return
	var scope: String = "external-photo-fixtures-%d" % fixture_ids.size() if not fixture_ids.is_empty() else ("canonical-photoreal-74" if app.fish_art.complete else "canonical-legacy-art")
	print("PHOTO_UI_SCOPE: ",scope,"; production native pages; no release gate override; not Android validation")
	app._show_catalog()
	await _layout()
	var grid_views: Array[FishArtView] = _photos(app._overlay)
	_check(grid_views.size()==74,"undiscovered catalog contains all74 native fish textures")
	for view: FishArtView in grid_views:
		_check(view.silhouette and view.material is ShaderMaterial,"undiscovered grid retains a static discovery mask: "+view.species_id)
	app._show_species(ids[0])
	await _layout()
	var undiscovered: FishArtView = _one_photo(ids[0],"undiscovered detail")
	_check(undiscovered != null and not undiscovered.silhouette,"detail retains the previous always-visible species art behavior")
	for id: String in ids:
		var fish: FishDefinition=app.catalog.fish[id]
		var sid: String=str(fish.spots()[0])
		var rid: String=str(app.catalog.spots[sid].region_id)
		var record: Dictionary=app.encounter.make_individual(fish,sid,rid,"worm",2,"day","clear")
		if reference_perch and id=="european_perch":
			# Explicit review-only specimen reproduces the user's original
			# reference measurements. It never touches a player save or fish data.
			record["length_mm"]=331
			record["weight_g"]=585
			record["size_fraction"]=0.3
			record["size_class"]="标准"
			record["sale_value"]=34
		record["session_id"]="photo_ui_"+id
		record["catch_id"]="photo_ui_catch_"+id
		save.begin_session(record.session_id)
		var settled: Dictionary=save.settle_catch(record)
		_check(bool(settled.get("ok",false)),"fixture settles a real catch: "+id+str(settled))
		app._last_record=record
		app._last_settlement=settled
		app._save_ok=true
		app._landing_pending=false
		app._show_result()
		await _layout()
		var photo: FishArtView=_one_photo(id,"settlement")
		var ruler: CatchRuler=_find_ruler(app._overlay)
		_check(photo != null and ruler != null and ruler.specimen==photo,"settlement ruler references the actual new2D fish")
		if photo != null and ruler != null:
			var endpoints: Array[Vector2]=photo.measurement_endpoints()
			_check(endpoints.size()==2,"settlement supplies anatomical length anchors: "+id)
			var bounds: Rect2=photo.get_global_rect()
			for point: Vector2 in endpoints:
				_check(point.x>=bounds.position.x and point.x<=bounds.end.x,"ruler endpoint is inside fish crop: "+id)
			var painted_bottom: float=photo.global_position.y+photo.painted_rect().end.y
			_check(ruler.global_position.y-painted_bottom>=0 and ruler.global_position.y-painted_bottom<18,"ruler sits closely below subject without transparent gutter: "+id)
			_check(ruler.length_mm==int(record.length_mm),"actual caught length reaches the ruler unchanged: "+id)
			_check(photo.has_art_landmarks == (id in fixture_ids or app.fish_art.complete),"partial metadata is never mistaken for complete photoreal coverage: "+id)
		await _capture(scope+"_"+id+"_catch")
		_check(bool(save.dispose_catch(record.catch_id,"released").get("ok",false)),"release preserves legitimate catch record: "+id)
		app._last_record={}
		app._show_species(id)
		await _layout()
		_one_photo(id,"species detail")
		await _capture(scope+"_"+id+"_detail")
		app._show_zoom(id)
		await _layout()
		_one_photo(id,"zoom")
		await _capture(scope+"_"+id+"_zoom")
	var candidate: Dictionary=save.state.duplicate(true)
	candidate.favorites=ids.slice(0,6)
	_check(save.commit_state(candidate),"favorites fixture commits using production SaveStore")
	app._show_favorites()
	await _layout()
	var favorites: Array[FishArtView]=_photos(app._overlay)
	_check(favorites.size()==mini(6,ids.size()),"favorites use a native photo for each selected fish")
	for photo: FishArtView in favorites: _check(not photo.silhouette and photo.material==null,"favorite texture has no fake swimming shader")
	await _capture(scope+"_favorites")
	app._search=""
	app._discovery_filter=1
	app._show_catalog()
	await _layout()
	var discovered: Array[FishArtView]=_photos(app._overlay)
	_check(discovered.size()==ids.size(),"catalog filter retains real discovered counts")
	for photo: FishArtView in discovered: _check(not photo.silhouette,"discovered catalog reveals photo: "+photo.species_id)
	await _capture(scope+"_catalog")
	for repeat: int in range(3):
		app._show_species(ids[repeat%ids.size()])
		await _layout()
		app._show_zoom(ids[(repeat+1)%ids.size()])
		await _layout()
		_one_photo(ids[(repeat+1)%ids.size()],"repeated replace")
		_check(app._overlay.find_children("PageScroll","ScrollContainer",true,false).size()==1,"replacement keeps existing touchscreen page scroller")
	_check(app.scenery is Node3D and app.scenery.camera is Camera3D,"static art migration leaves actual inworld3D scene and camera intact")
	# Release fixture texture caches before orderly deferred scene teardown.
	app.fish_art._textures.clear()
	app.queue_free()
	app=null
	for frame: int in range(4): await process_frame
	print("FISH_ART_UI_TESTS: ",checks-failures,"/",checks," passed; ",scope,"; ",root.size," desktop layout")
	# Let the coroutine release its last Image/RefCounted locals before exit.
	call_deferred("quit",0 if failures==0 else 1)

func _load_photo_fixtures() -> void:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	_check(data is Dictionary and data.get("assets") is Array,"external fixture manifest parses")
	if not data is Dictionary or not data.get("assets") is Array: return
	var folder: String=manifest_path.get_base_dir()
	for entry: Dictionary in data.assets:
		var id: String=str(entry.species_id)
		_check(app.catalog.fish.has(id),"photo fixture is an unchanged canonical species: "+id)
		if not app.catalog.fish.has(id): continue
		app.fish_art.errors.clear()
		app.fish_art._validate_metadata(id,entry)
		_check(app.fish_art.errors.is_empty(),"actual fixture landmarks pass geometry validation: "+id+str(app.fish_art.errors))
		app.fish_art._entries[id]=entry.duplicate(true)
		for thumbnail: bool in [false,true]:
			var path: String=folder.path_join(str(entry.get("thumb" if thumbnail else "runtime","")))
			var image: Image=Image.load_from_file(path)
			_check(image != null and not image.is_empty(),"actual generated PNG decoded: "+id)
			if image==null or image.is_empty(): continue
			image.convert(Image.FORMAT_RGBA8)
			var source_hash: String=str(entry.get("thumb_sha256" if thumbnail else "sha256",""))
			_check(source_hash.length()==64 and FileAccess.get_sha256(path)==source_hash,"actual fixture PNG matches artist SHA-256: "+id+(" thumb" if thumbnail else " art"))
			var bbox: Array=entry.get("thumb_subject_bbox_px" if thumbnail else "subject_bbox_px",[])
			_check(ArtCatalog.bounds_match(ArtCatalog.alpha_bounds(image),bbox),"actual fixture alpha bounds match artist pixels: "+id+(" thumb" if thumbnail else " art"))
			var fish: FishDefinition=app.catalog.fish[id]
			app.fish_art._textures[fish.thumb if thumbnail else fish.art]=ImageTexture.create_from_image(image)
		fixture_ids.append(id)
	# This fixture only injects explicit textures into the test instance. It
	# does not write game/assets, install a manifest, or mark final art complete.
	_check(not app.fish_art.complete or fixture_ids.size()==74,"external fixture cannot turn partial coverage into production completion")

func _photos(node: Node) -> Array[FishArtView]:
	var result: Array[FishArtView]=[]
	if node.get_script()==View: result.append(node as FishArtView)
	for child: Node in node.get_children(): result.append_array(_photos(child))
	return result
func _one_photo(id: String,label: String) -> FishArtView:
	var photos: Array[FishArtView]=_photos(app._overlay)
	_check(photos.size()==1,label+" has exactly one native2D specimen")
	_check(app._overlay.find_children("*","SubViewportContainer",true,false).is_empty(),label+" has no coarse3D fish viewport")
	if photos.size()!=1: return null
	var photo: FishArtView=photos[0]
	_check(photo.species_id==id and photo.texture != null,label+" shows exact species bitmap")
	_check(photo.texture is AtlasTexture and photo.mouse_filter==Control.MOUSE_FILTER_IGNORE,label+" preserves source aspect and touch scrolling")
	_check(photo.material==null and not photo.silhouette,label+" photo stays static and fully visible")
	return photo
func _find_ruler(node: Node) -> CatchRuler:
	if node.get_script()==Ruler: return node as CatchRuler
	for child: Node in node.get_children():
		var found: CatchRuler=_find_ruler(child)
		if found != null: return found
	return null
func _layout() -> void:
	for frame: int in range(5): await process_frame
func _capture(label: String) -> void:
	if capture_dir.is_empty(): return
	if DisplayServer.get_name()=="headless":
		_check(false,"screenshots require a real rendering driver")
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	var picture: Image=root.get_texture().get_image()
	_check(picture.save_png(capture_dir.path_join(label+("_tall" if tall else "")+".png"))==OK,"real rendered capture saved: "+label)
	picture=null
