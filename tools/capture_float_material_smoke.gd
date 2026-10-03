extends SceneTree
## Short actual Main/Stage visual regression. Float pairs use explicit geometry
## fixtures, not a claim about the live encounter or Android performance.
const MainScene = preload("res://scenes/main.tscn")
var app: Control
var output: String
var hashes: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	output = ProjectSettings.globalize_path("res://../build/float-material-smoke")
	DirAccess.make_dir_recursive_absolute(output)
	for path: String in ["res://scripts/fishing_stage_3d.gd", "res://assets/shaders3d/float_lacquer.gdshader", "res://assets/3d/angler.glb"]: hashes[path] = FileAccess.get_sha256(path)
	root.size = Vector2i(720,1280)
	DisplayServer.window_set_size(root.size)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	var normal: Texture2D = app.scenery._water_material.get_shader_parameter("normal_texture")
	if normal.get_image() == null: await normal.changed
	assert(normal.get_image() != null and not normal.get_image().is_empty())
	for frame: int in 24:
		await process_frame
		await RenderingServer.frame_post_draw
	tick(1.2)
	await capture("human_lobby")
	app._show_prepare()
	app._enter_fishery()
	tick(2.0)
	app.session.start_charge()
	app.session.charge = 0.65
	var record: Dictionary = app.encounter.make_individual(app.catalog.fish["common_carp"],"lake_shore","lake","worm",2,"day","clear")
	assert(app.session.cast(record,app.catalog.gear[2]))
	app.store.begin_session(app.session.session_id)
	tick(0.90)
	await capture("human_cast_loading")
	tick(0.45)
	await capture("human_cast_release")
	tick(2.0)
	app.session.float_dip = 0.0
	app.session.float_lift = 0.0
	app.session.float_drag = Vector2.ZERO
	app.session.float_current = Vector2.ZERO
	app.session.float_tilt = 0.0
	app.scenery._process(0.0)
	await capture("float_neutral_fixture")
	var held_camera: Transform3D = app.scenery.camera.transform
	app.session.float_dip = 0.85
	app.scenery._process(0.0)
	await capture("float_sink_fixture")
	assert(app.scenery.camera.transform.is_equal_approx(held_camera))
	app.session.float_dip = 0.0
	app.session.float_lift = 0.80
	app.scenery._process(0.0)
	await capture("float_lift_fixture")
	assert(app.scenery.camera.transform.is_equal_approx(held_camera))
	var unchanged: bool = true
	for path: String in hashes: unchanged = unchanged and hashes[path] == FileAccess.get_sha256(path)
	var f := FileAccess.open(output.path_join("evidence.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"Actual desktop Godot4.6.3 Mobile software Vulkan; material/UV regression smoke; float geometry fixtures", "hashes":hashes,"sources_unchanged":unchanged,"normal_ready":true},"\t")+"\n")
	f.close()
	app.fish_art._textures.clear()
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	for frame: int in 6: await process_frame
	print("MATERIAL_SMOKE_COMPLETE sources_unchanged=",unchanged)
	quit()
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK)
	print("MATERIAL_SMOKE ",label)
func tick(seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.000001:
		var delta: float = minf(remaining,1.0/120.0)
		if not app.scenery._suspended: app.scenery._animator.advance(delta)
		app._process(delta)
		app.scenery._process(delta)
		remaining -= delta
