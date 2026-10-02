extends SceneTree
## Structural audit of imported production assets; not a GPU/device render test.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _collect(node: Node, result: Dictionary) -> void:
	if node is Skeleton3D:
		result.skeletons += 1
		result.bones += node.get_bone_count()
	if node is MeshInstance3D and node.mesh != null:
		result.meshes += 1
		if node.skin != null: result.skinned_meshes += 1
	if node.name == "RodSocket":
		result.rod_sockets += 1
		if node.get_parent() is BoneAttachment3D: result.bone_attached_rod_sockets += 1
	if node is AnimationPlayer:
		result.animation_players += 1
		for name: StringName in node.get_animation_list():
			var clip: Animation = node.get_animation(name)
			result.animations[String(name)] = {"length":clip.length,"tracks":clip.get_track_count()}
	for child: Node in node.get_children():
		_collect(child, result)

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected frozen snapshot manifest and report path")
		quit(2)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var contract: Dictionary = manifest.content.three_d
	var models: Dictionary = {}
	for path: String in contract.glb_models:
		var packed: PackedScene = load("res://" + path) as PackedScene
		if packed == null:
			failures.append("Missing PackedScene: " + path)
			continue
		var instance: Node = packed.instantiate()
		var result: Dictionary = {"skeletons":0,"bones":0,"meshes":0,"skinned_meshes":0,"animation_players":0,"animations":{},"rod_sockets":0,"bone_attached_rod_sockets":0}
		result.resource_dependencies = Array(ResourceLoader.get_dependencies("res://" + path))
		_collect(instance, result)
		if result.meshes == 0: failures.append("No imported geometry: " + path)
		if path == "assets/3d/angler.glb" and (result.rod_sockets != 1 or result.bone_attached_rod_sockets != 1):
			failures.append("Expected one bone-attached RodSocket: " + path)
		if not contract.glb_models[path].required_clips.is_empty():
			if result.skeletons == 0 or result.skinned_meshes == 0 or result.animation_players == 0:
				failures.append("Missing imported rig/skin/AnimationPlayer: " + path)
			for clip: String in contract.glb_models[path].required_clips:
				if not result.animations.has(clip) or float(result.animations[clip].length) <= 0.0 or int(result.animations[clip].tracks) <= 0:
					failures.append("Missing or empty imported clip: " + path + "/" + clip)
		models[path] = result
		instance.free()
	var report: Dictionary = {"models":models,"required_scene_count":contract.glb_models.size(),"failures":failures,"scope":"Imported scene structure only; no GPU/device claim"}
	var output: FileAccess = FileAccess.open(args[1], FileAccess.WRITE)
	if output == null:
		printerr("Cannot write imported scene audit")
		quit(2)
		return
	output.store_string(JSON.stringify(report,"  ") + "\n")
	output.close()
	for failure: String in failures: printerr(failure)
	print("Imported 3D scenes: ", models.size(), "; failures: ", failures.size())
	quit(0 if failures.is_empty() else 1)
