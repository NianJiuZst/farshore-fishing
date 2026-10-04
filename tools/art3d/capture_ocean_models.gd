extends SceneTree
## Native GPU evidence for the new GLBs. Run after the game's regular import.
## --script <this file> -- <profiles.json absolute> <output directory absolute>
## This standalone studio does not instantiate or modify game/save/UI systems.
var studio: Node3D
var camera: Camera3D
var report: Dictionary = {"scope":"Godot imported rig/material structure and native GPU model studio; does not claim Android device QA", "models":{}, "errors":[]}

func _initialize() -> void:
	call_deferred("_run")

func _collect(node: Node, result: Dictionary) -> void:
	if node is Skeleton3D:
		result.bones += node.get_bone_count()
		result.skeletons += 1
		for i: int in node.get_bone_count(): result.bone_names.append(node.get_bone_name(i))
	if node is MeshInstance3D and node.mesh != null:
		result.meshes += 1
		if node.skin != null: result.skinned_meshes += 1
		for i: int in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(i)
			result.materials.append({"name":material.resource_name if material else "missing", "class":material.get_class() if material else "missing"})
		var bounds: AABB = node.global_transform * node.get_aabb()
		if result.bounds.size == Vector3.ZERO: result.bounds = bounds
		else: result.bounds = result.bounds.merge(bounds)
	if node is AnimationPlayer:
		result.animator = node
		for name: StringName in node.get_animation_list():
			if String(name) == "RESET": continue
			var clip: Animation = node.get_animation(name)
			result.clips[String(name)] = {"length":clip.length, "tracks":clip.get_track_count()}
	for child: Node in node.get_children(): _collect(child, result)

func _setup() -> void:
	studio = Node3D.new()
	root.add_child(studio)
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.025,0.050,0.065)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.76,0.83,0.86)
	world.environment.ambient_light_energy = 0.68
	world.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	studio.add_child(world)
	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42,-28,0)
	key.light_color = Color(1.0,0.93,0.81)
	key.light_energy = 1.5
	studio.add_child(key)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,144,0)
	fill.light_color = Color(0.57,0.76,1.0)
	fill.light_energy = 0.6
	studio.add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.01
	camera.far = 15.0
	studio.add_child(camera)
	camera.current = true

func _frame(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty(): report.errors.append("No GPU pixels: " + path)
	else:
		var error: Error = image.save_png(path)
		if error != OK: report.errors.append("Cannot save GPU frame: " + path)

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected profiles.json and output directory")
		quit(2)
		return
	var profiles: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var destination: String = args[1]
	DirAccess.make_dir_recursive_absolute(destination)
	_setup()
	await process_frame
	for profile: Dictionary in profiles.species:
		var id: String = profile.id
		var packed: PackedScene = load("res://assets/3d/" + id + ".glb") as PackedScene
		if packed == null:
			report.errors.append("Cannot import " + id)
			continue
		var animal: Node3D = packed.instantiate() as Node3D
		studio.add_child(animal)
		var result: Dictionary = {"bones":0,"skeletons":0,"bone_names":[],"meshes":0,"skinned_meshes":0,"materials":[],"clips":{},"bounds":AABB(),"animator":null}
		_collect(animal, result)
		var bounds: AABB = result.bounds
		var center: Vector3 = bounds.get_center()
		camera.size = maxf(0.83,bounds.size.y*1.22)
		var animator: AnimationPlayer = result.animator
		if animator == null or result.skeletons != 1 or result.skinned_meshes < 1:
			report.errors.append("Missing imported skin/rig/animator: " + id)
		var frames: Array[String] = []
		if animator:
			for clip: String in ["swim","struggle","breach","landed"]:
				if not animator.has_animation(clip):
					report.errors.append("Missing imported clip " + id + "/" + clip)
					continue
				animator.play(clip)
				animator.advance(animator.get_animation(clip).length*0.23)
				animator.pause()
				camera.position = center + Vector3(0.35,0.21,1.6)
				if profile.kind in ["ray","flatfish"]: camera.position = center+Vector3(0.3,1.20,1.0)
				camera.look_at(center,Vector3.UP)
				var path: String = destination.path_join(id+"_"+clip+".png")
				await _frame(path)
				frames.append(path)
			animator.play("swim")
			animator.advance(0.0)
			animator.pause()
		for angle: String in ["top","underside"]:
			if angle == "top":
				camera.size = maxf(0.83,bounds.size.z*1.28)
				camera.position = center+Vector3(0.12,1.6,0.18)
				# Keep +X horizontal on a top shot; world UP becomes singular
				# near the viewing direction and clips long bodies diagonally.
				camera.look_at(center,Vector3(0,0,-1))
			else:
				camera.size = maxf(0.83,bounds.size.y*1.22)
				camera.position = center+Vector3(0.32,-0.68,1.35)
				camera.look_at(center,Vector3.UP)
			var path: String = destination.path_join(id+"_"+angle+".png")
			await _frame(path)
			frames.append(path)
		result.erase("animator")
		result.bounds = {"position":[bounds.position.x,bounds.position.y,bounds.position.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]}
		result.frames = frames
		report.models[id] = result
		animal.queue_free()
		await process_frame
		print("OCEAN_MODEL_GPU_FRAME ",id," clips=",result.clips.size()," bones=",result.bones)
	report.engine = Engine.get_version_info()
	report.rendering_method = RenderingServer.get_current_rendering_method()
	report.rendering_driver = RenderingServer.get_current_rendering_driver_name()
	report.model_count = report.models.size()
	var file: FileAccess = FileAccess.open(destination.path_join("godot_model_studio.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  ")+"\n")
	file.close()
	for error: String in report.errors: printerr(error)
	print("OCEAN_MODELS_GPU_REVIEW: ",report.models.size(),"/37; errors=",report.errors.size())
	quit(0 if report.errors.is_empty() and report.models.size() == 37 else 1)
