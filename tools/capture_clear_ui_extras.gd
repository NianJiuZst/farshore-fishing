extends SceneTree
const MainScene=preload("res://scenes/main.tscn")
var app: Control
var output: String
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(OS.get_environment("XDG_DATA_HOME").begins_with("/tmp/farshore-"))
	assert(DisplayServer.get_name()!="headless")
	output=OS.get_environment("FARSHORE_REVISION_CAPTURE")
	root.size=Vector2i(720,1584)
	app=MainScene.instantiate()
	root.add_child(app)
	while not app._startup_complete: await process_frame
	app.set_process(false)
	app.scenery.set_process(false)
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	for route: String in ["home","prepare","travel","gear","catalog","favorites","settings","backup","pause"]:
		app.call("_show_"+route)
		await capture(route+"_tall")
	app._show_catalog()
	for i: int in 6: await process_frame
	var choice: OptionButton=app._overlay.find_child("NotebookRegionFilter",true,false)
	choice.show_popup()
	for i: int in 6: await process_frame
	assert(choice.get_popup().visible)
	assert(app._overlay.get_node("OverlayMargin").modulate.a==0.0)
	await capture("catalog_region_popup")
	choice.get_popup().hide()
	await process_frame
	assert(app._overlay.get_node("OverlayMargin").modulate.a==1.0)
	choice=app._overlay.find_child("NotebookDiscoveryFilter",true,false)
	choice.show_popup()
	await capture("catalog_discovery_popup")
	choice.get_popup().hide()
	await process_frame
	app._show_species("chinese_sturgeon")
	await capture("protected_species_tall")
	app._show_lobby_exit()
	await capture("confirmation_tall")
	app.queue_free()
	for i: int in 6: await process_frame
	print("CLEAR_UI_EXTRAS_COMPLETE")
	quit()
func capture(label: String) -> void:
	for i: int in 10: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label+".png"))==OK)
	print("CLEAR_UI_CAPTURE ",label)
