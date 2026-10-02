extends SceneTree
## Headless asset contract checks. Optional: -- --model=/absolute/candidate.glb
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var source: String = ProjectSettings.globalize_path("res://assets/3d/angler.glb")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--model="):
			source = argument.trim_prefix("--model=")
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error: Error = document.append_from_file(source, state)
	_check(error == OK, "GLB imports")
	if error != OK:
		quit(1)
		return
	var model: Node = document.generate_scene(state)
	root.add_child(model)
	var skeletons: Array[Node] = model.find_children("*", "Skeleton3D", true, false)
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	_check(skeletons.size() == 1 and players.size() == 1 and meshes.size() == 1, "one skeleton, animation player and batched mesh")
	if skeletons.size() != 1 or players.size() != 1 or meshes.size() != 1:
		quit(1)
		return
	var skeleton := skeletons[0] as Skeleton3D
	var player := players[0] as AnimationPlayer
	var instance := meshes[0] as MeshInstance3D
	var socket := model.find_child("RodSocket", true, false) as Node3D
	_check(socket != null and socket.get_parent() is BoneAttachment3D, "animated BoneAttachment3D socket")
	_check(skeleton.get_bone_count() == 30 and instance.skin != null, "30-bone skin")
	if socket == null or instance.skin == null:
		quit(1)
		return
	var durations: Dictionary = {"idle": 3.2, "cast": 2.2, "wait": 4.0, "reel": 2.0, "lift": 2.0}
	for clip: String in durations:
		_check(player.has_animation(clip), "clip exists: " + clip)
		if player.has_animation(clip):
			_check(absf(player.get_animation(clip).length - float(durations[clip])) < 0.00001, "exact duration: " + clip)
	var needed: Array[String] = ["upper_arm.R", "forearm.R", "hand.R", "upper_arm.L", "forearm.L", "hand.L", "foot.R", "foot.L"]
	for bone: String in needed:
		_check(skeleton.find_bone(bone) >= 0, "named bone: " + bone)
	if failures > 0:
		quit(1)
		return
	var grip_error: float = 0.0
	var segment_error: float = 0.0
	var socket_error: float = 0.0
	var grounded_feet: Array[Vector3] = []
	var foot_error: float = 0.0
	for frame: int in range(67):
		player.play("cast")
		player.pause()
		player.seek(float(frame) / 30.0, true)
		skeleton.force_update_all_bone_transforms()
		await process_frame
		await process_frame
		for side: String in ["R", "L"]:
			var shoulder: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("upper_arm." + side)).origin
			var elbow: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("forearm." + side)).origin
			var wrist: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("hand." + side)).origin
			segment_error = maxf(segment_error, absf(shoulder.distance_to(elbow) - 0.305))
			segment_error = maxf(segment_error, absf(elbow.distance_to(wrist) - 0.270))
			_check(shoulder.is_finite() and elbow.is_finite() and wrist.is_finite(), "finite arm pose")
			var foot: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("foot." + side)).origin
			if frame == 0:
				grounded_feet.append(foot)
			else:
				foot_error = maxf(foot_error, foot.distance_to(grounded_feet[0 if side == "R" else 1]))
		var right: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).origin
		var left: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand.L")).origin
		socket_error = maxf(socket_error, right.distance_to(socket.global_position))
		grip_error = maxf(grip_error, left.distance_to(socket.global_position + socket.global_basis.z * 0.18))
	_check(segment_error < 0.0001, "bilaterally equal 30.5 cm upper arms / 27 cm forearms throughout cast")
	_check(socket_error < 0.0001 and grip_error < 0.0001, "both grips remain on shared handle throughout all 67 cast frames")
	_check(foot_error < 0.00001, "planted feet do not skate during cast")
	var reference: Array[Vector3] = []
	var maximum_motion: float = 0.0
	var maximum_weight_error: float = 0.0
	var minimum_y: float = INF
	var maximum_y: float = -INF
	for time: float in [0.0, 0.78]:
		player.play("cast")
		player.pause()
		player.seek(time, true)
		skeleton.force_update_all_bone_transforms()
		await process_frame
		await process_frame
		var positions: Array[Vector3] = []
		for surface: int in range(instance.mesh.get_surface_count()):
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for vertex: int in range(0, vertices.size(), 13):
				var position := Vector3.ZERO
				var weight_sum: float = 0.0
				for influence: int in range(4):
					var bind: int = joints[vertex * 4 + influence]
					var index: int = instance.skin.get_bind_bone(bind)
					if index < 0:
						index = skeleton.find_bone(instance.skin.get_bind_name(bind))
					var weight: float = weights[vertex * 4 + influence]
					weight_sum += weight
					position += (skeleton.get_bone_global_pose(index) * instance.skin.get_bind_pose(bind) * vertices[vertex]) * weight
				maximum_weight_error = maxf(maximum_weight_error, absf(weight_sum - 1.0))
				# Godot stores skin weights in normalized 16-bit channels.
				_check(position.is_finite() and absf(weight_sum - 1.0) < 0.0001, "finite normalized imported mesh vertex")
				positions.append(position)
				if time == 0.0:
					var world: Vector3 = skeleton.global_transform * position
					minimum_y = minf(minimum_y, world.y)
					maximum_y = maxf(maximum_y, world.y)
		if reference.is_empty():
			reference = positions
		else:
			for index: int in range(positions.size()):
				maximum_motion = maxf(maximum_motion, positions[index].distance_to(reference[index]))
	_check(maximum_motion > 0.20, "cast deforms real skinned vertices")
	_check(minimum_y >= -0.002 and minimum_y < 0.01 and maximum_y > 1.73 and maximum_y < 1.78, "ground contact and adult 1.75 m scale")
	print("ANGLER_METRICS segment_error_m=", segment_error, " grip_error_m=", grip_error, " foot_error_m=", foot_error, " skin_motion_m=", maximum_motion, " height_m=", maximum_y, " imported_weight_quantization_error=", maximum_weight_error)
	print("ANGLER_ANATOMY_TESTS: ", checks - failures, "/", checks, " passed; failures=", failures)
	model.queue_free()
	quit(0 if failures == 0 else 1)
