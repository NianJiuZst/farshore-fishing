extends SceneTree
## Real imported meshes, production landing transforms and portrait projection.
## No replicated camera or synthetic fish bounds; not Android hardware evidence.
const Stage = preload("res://scripts/fishing_stage_3d.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL OCEAN LANDING: ",label)
func _meshes(node: Node, found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: found.append(node)
	for child: Node in node.get_children(): _meshes(child,found)
func _run() -> void:
	var catalog = Catalog.new()
	_check(catalog.load_all(false),"real74 catalog loads without using UI assets")
	var stage = Stage.new()
	root.add_child(stage)
	stage.set_process(false)
	stage.set_mode("fishing")
	for viewport_size: Vector2i in [Vector2i(720,1280),Vector2i(720,1584)]:
		root.size = viewport_size
		await process_frame
		for id: String in catalog.fish:
			var fish: FishDefinition = catalog.fish[id]
			for length_mm: int in [fish.min_mm,fish.max_mm]:
				stage.cancel_landing()
				stage.suspend(false)
				stage.play_landing({"species_id":id,"length_mm":length_mm,"catch_id":"ocean-landing-%s-%d-%d"%[id,length_mm,viewport_size.y]})
				if stage._animator: stage._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				if stage._fish_animator: stage._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				await process_frame
				for frame: int in 120:
					if stage._animator: stage._animator.advance(0.025)
					if stage._fish_animator: stage._fish_animator.advance(0.025)
					stage._process(0.025)
				var label: String = "%s %dmm %s" % [id,length_mm,str(viewport_size)]
				_check(stage._fish_id==id and stage._fish.scale.is_equal_approx(Vector3.ONE*float(length_mm)/1000.0),label+" actual species and exact physical scale")
				var meshes: Array[MeshInstance3D] = []
				_meshes(stage._fish,meshes)
				var bounds: Rect2 = Rect2(Vector2(8,8),Vector2(viewport_size)-Vector2(16,16))
				var clipped: int = 0
				var sampled: int = 0
				var low: float = INF
				var high: float = -INF
				for mesh: MeshInstance3D in meshes:
					if not mesh.visible or mesh.mesh==null: continue
					for corner: int in 8:
						var point: Vector3 = mesh.global_transform*mesh.get_aabb().get_endpoint(corner)
						sampled += 1
						low=minf(low,point.y); high=maxf(high,point.y)
						if stage.camera.is_position_behind(point) or not bounds.has_point(stage.camera.unproject_position(point)): clipped += 1
				_check(sampled>0 and clipped==0,label+" complete imported mesh framing; clipped="+str(clipped))
				if length_mm>2800:
					_check(is_equal_approx(stage._fish_root.position.y,0.08) and stage._fish_root.position.z < -4.0,label+" giant observed beside boat")
					_check(low<0.0 and high>0.0,label+" giant geometry crosses water surface")
				else:
					_check(stage._fish_root.position.y>0.9,label+" ordinary fish retains lifted presentation")
	stage.queue_free()
	await process_frame
	print("OCEAN_LANDING_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; 74 species x2 extreme lengths x2 portrait viewports; actual imported geometry")
	quit(0 if failures==0 else 1)
