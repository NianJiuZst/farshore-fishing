extends SceneTree
## Actual Main/scenery with the isolated component; integration captured separately.
const Main = preload("res://scenes/main.tscn")
const Modal = preload("res://scripts/fishing_failure_modal.gd")
var app: Control
var modal: Control
var output: String

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if not OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"):
		printerr("Failure modal preview requires isolated /tmp/farshore- data")
		quit(2)
		return
	root.size = Vector2i(720,1584) if "--tall" in OS.get_cmdline_user_args() else Vector2i(720,1280)
	output = ProjectSettings.globalize_path("res://../build/beta3-modal-preview-"+str(root.size.y))
	DirAccess.make_dir_recursive_absolute(output)
	app = Main.instantiate()
	root.add_child(app)
	if not app._content_ok or not app._models_complete:
		printerr("Actual Main content/model readiness failed")
		quit(2)
		return
	app._enter_fishery()
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._process(0.025)
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	var reasons: Dictionary = {"empty":"空竿收回，鱼还没有咬牢。下次再多观察一会儿浮漂","slack":"松手太久，鱼带着松线挣脱了","line-break":"迎着冲势猛拉，鱼线绷断了。留意鱼身转向和竿梢蓄力","wear-break":"僵持后的鱼线磨损越来越重，终于断开了","escaped":"鱼逃走了"}
	for key: String in reasons:
		if is_instance_valid(modal):
			app.remove_child(modal)
			modal.queue_free()
		modal = Modal.new()
		modal.animate_open = false
		modal.configure(reasons[key])
		app.add_child(modal)
		for frame: int in range(6): await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		var path: String = output.path_join(key+".png")
		if picture.save_png(path) != OK:
			printerr("Failed to save preview: ",path)
			quit(2)
			return
		print("MODAL_PREVIEW ",path," panel=",modal.get_panel_rect()," renderer=",RenderingServer.get_current_rendering_method())
		picture = null
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	app = null
	modal = null
	await process_frame
	await process_frame
	call_deferred("quit")
