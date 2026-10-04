extends SceneTree
const Stage = preload("res://scripts/fishing_stage_3d.gd")
var stage: Node3D
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1600,900)
	stage = Stage.new()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.set_visual_quality("high")
	var destination: String = ProjectSettings.globalize_path("res://assets/scenery")
	var evidence: String = ProjectSettings.globalize_path("res://../build/ocean-visual")
	DirAccess.make_dir_recursive_absolute(evidence)
	for rid: String in ["pacific_ocean","atlantic_ocean","indian_ocean"]:
		var first: String = "atlantic_shelf" if rid=="atlantic_ocean" else rid.trim_suffix("_ocean")+"_reef"
		assert(stage.set_location(rid,first),"load"+rid)
		stage.set_mode("fishing")
		stage.set_time_of_day("day")
		stage.camera.position = Vector3(4.4,4.0,7.4)
		stage.camera.look_at(Vector3(-17,1.9,-75),Vector3.UP)
		stage.camera.fov = 65.0
		await _settle()
		await _capture(destination.path_join(rid+".png"))
		for sid: String in [first,rid.trim_suffix("_ocean")+"_bluewater"]:
			assert(stage.set_location(rid,sid),"load"+sid)
			for dims: Vector2i in [Vector2i(720,1280),Vector2i(720,1584)]:
				root.size = dims
				stage._update_camera(100.0)
				await _settle()
				await _capture(evidence.path_join(sid+"_"+str(dims.y)+".png"))
		root.size=Vector2i(1600,900)
	stage.free()
	await process_frame
	print("OCEAN_VIEWS_COMPLETE:3region previews+12portrait views; desktop Mobile/Vulkan only")
	quit()
func _settle() -> void:
	for i in range(7): await process_frame
	await RenderingServer.frame_post_draw
func _capture(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	assert(image.save_png(path)==OK,"save"+path)
	print("OCEAN_CAPTURE=",path)
