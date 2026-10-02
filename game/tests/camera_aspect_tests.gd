extends SceneTree
## Projection-level comparison to the original portrait16:9 camera. No asset,
## readiness, gameplay or physical-device state is fabricated by this test.
const Stage = preload("res://scripts/fishing_stage_3d.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL CAMERA ASPECT: ",label)
func run() -> void:
	check(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d",0))==2 and root.msaa_3d==Viewport.MSAA_4X,"root viewport carries requested4x MSAA configuration")
	check(str(ProjectSettings.get_setting("display/window/stretch/aspect","keep"))=="expand","production uses edge-to-edge expand")
	var reference: SubViewport=SubViewport.new()
	reference.size=Vector2i(720,1280)
	reference.own_world_3d=true
	root.add_child(reference)
	var old_camera: Camera3D=Camera3D.new()
	old_camera.keep_aspect=Camera3D.KEEP_HEIGHT
	reference.add_child(old_camera)
	var adaptive: SubViewport=SubViewport.new()
	adaptive.own_world_3d=true
	root.add_child(adaptive)
	var new_camera: Camera3D=Camera3D.new()
	new_camera.keep_aspect=Camera3D.KEEP_WIDTH
	adaptive.add_child(new_camera)
	for viewport_size: Vector2i in [Vector2i(720,1280),Vector2i(720,1584),Vector2i(1440,3168),Vector2i(900,1200)]:
		adaptive.size=viewport_size
		for angle: float in [36.0,42.0,46.0,51.0,54.0,55.0,59.0]:
			old_camera.fov=angle
			new_camera.fov=Stage._reference_horizontal_fov(angle)
			var old_projection: Projection=old_camera.get_camera_projection()
			var new_projection: Projection=new_camera.get_camera_projection()
			check(absf(old_projection.x.x-new_projection.x.x)<0.00001,"same horizontal projection at %s / %.1f degrees"%[str(viewport_size),angle])
			if viewport_size==Vector2i(720,1280):
				check(absf(old_projection.y.y-new_projection.y.y)<0.00001,"baseline vertical projection also unchanged / %.1f"%angle)
			if viewport_size.y>viewport_size.x*1280.0/720.0:
				check(new_projection.y.y<old_projection.y.y,"tall display adds vertical coverage rather than cropping / "+str(viewport_size))
		# Compare the full authored FOV transition rather than endpoints alone.
		var original_angle: float=54.0
		for step: int in 120:
			original_angle=lerpf(original_angle,36.0,1.0-exp(-0.025*2.3))
			old_camera.fov=original_angle
			new_camera.fov=Stage._reference_horizontal_fov(original_angle)
			check(absf(old_camera.get_camera_projection().x.x-new_camera.get_camera_projection().x.x)<0.00001,"horizontal transition invariant at %s frame%d"%[str(viewport_size),step])
	reference.queue_free()
	adaptive.queue_free()
	await process_frame
	print("CAMERA_ASPECT_TESTS: ",checks-failures,"/",checks," passed; failures=",failures,"; mathematical desktop projection, not device certification")
	quit(0 if failures==0 else 1)
