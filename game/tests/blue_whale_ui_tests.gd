extends SceneTree
## Real HUD buttons, native layout, whale scale and optional viewport images.
## No Main startup and no player SaveStore access.
const Challenge = preload("res://scripts/blue_whale_challenge.gd")
const UI = preload("res://scripts/whale_challenge_ui.gd")
var checks: int = 0
var failures: int = 0
var challenge: BlueWhaleChallenge
var hud: WhaleChallengeUI
var capture_dir: String = ""
var _captured: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL WHALE UI: ",label)

func _run() -> void:
	if not OS.get_environment("FARSHORE_ISOLATED_ROOT").is_empty():
		_check(not OS.get_user_data_dir().begins_with("/Users/"),"native game user directory stays in isolated test working directory")
		print("WHALE_UI_USER_DIR=",OS.get_user_data_dir(),"; ISOLATED_ROOT=",OS.get_environment("FARSHORE_ISOLATED_ROOT"))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		if not capture_dir.is_absolute_path() or not capture_dir.contains("blue-whale") or DisplayServer.get_name() == "headless":
			printerr("Whale captures require an explicit blue-whale audit directory and real renderer")
			quit(2)
			return
		DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(720,1280)
	root.content_scale_size = Vector2i(720,1280)
	var theme: Theme = Theme.new()
	var font: FontFile = load("res://assets/fonts/NotoSansCJK-Regular.ttc")
	font.set_face_index(0,2)
	theme.default_font = font
	theme.default_font_size = 24
	challenge = Challenge.new()
	challenge.start()
	hud = UI.new()
	hud.theme = theme
	hud.configure(challenge,Vector4(28,36,28,32))
	root.add_child(hud)
	await process_frame
	await process_frame
	_check(hud.stage.model != null and hud.stage.animator != null,"HUD displays real, animated blue-whale model")
	_check(hud._primary.visible and not hud._left.visible and not hud._right.visible,"link phase shows touch tuning button")
	_check(is_equal_approx(hud._cursor.size.x,8.0),"control gauge shows a precise eight-pixel cursor")
	hud._primary.button_down.emit()
	_check(challenge.holding,"touch down controls challenge pulse")
	hud._primary.mouse_exited.emit()
	_check(not challenge.holding,"pointer exit cancels held control")
	await _capture("01-link")
	_check_layout("link")
	var steps: int = 0
	while challenge.is_active() and steps < 10800:
		_press_policy()
		challenge.step(1.0 / 120.0)
		steps += 1
		if challenge.state == Challenge.State.CURRENT and not _captured.has("02-current"):
			await process_frame
			_check(not hud._primary.visible and hud._left.visible and hud._right.visible,"current phase changes to independent left/right touch buttons")
			hud._right.button_down.emit()
			_check(challenge.direction == 1,"right touch gives right direction")
			hud._right.mouse_exited.emit()
			_check(challenge.direction == 0,"exiting right control releases direction")
			await _capture("02-current")
			_check_layout("current")
			_captured["02-current"] = true
		elif challenge.state == Challenge.State.RESONANCE and not _captured.has("03-resonance"):
			await process_frame
			_check(hud._primary.visible and not hud._left.visible and not hud._right.visible,"resonance returns to hold/release tension button")
			await _capture("03-resonance")
			_check_layout("resonance")
			_captured["03-resonance"] = true
	_check(challenge.state == Challenge.State.SUCCESS,"all phases complete through actual HUD control signals")
	hud.set_settlement(true,"",true)
	await process_frame
	await _capture("04-success")
	_check_layout("success")
	_check(hud.stage.success_view and not hud._controls.visible and hud._terminal_controls.get_child_count() == 3,"success shows waterborne view plus notebook/retry/return actions")
	_check(hud._detail.text.contains("不计入鱼获数量"),"completion accurately labels independent whale record")
	hud.set_settlement(false,"Synthetic failed write")
	await process_frame
	_check(hud._terminal_controls.get_child_count() == 2 and hud._detail.text.contains("尚未保存"),"unsaved success exposes retry and explicit discard")
	await _capture("05-save-retry")
	_check_layout("save-retry")
	challenge.start()
	hud._primary.button_down.emit()
	challenge.step(1.1)
	challenge.pause()
	await process_frame
	_check(not challenge.holding and not hud._controls.visible and hud._terminal_controls.get_child_count() == 1,"paused HUD releases touch and provides resume")
	await _capture("06-paused")
	challenge.resume()
	challenge.cancel_input()
	challenge.step(31.0)
	await process_frame
	_check(challenge.state == Challenge.State.FAILED and hud._terminal_controls.get_child_count() == 2,"failed HUD offers retry and return")
	await _capture("07-failed")
	_check_layout("failed")
	hud.queue_free()
	await process_frame
	print("BLUE_WHALE_UI_TESTS: ",checks-failures,"/",checks," passed; failures=",failures)
	if not capture_dir.is_empty(): print("BLUE_WHALE_UI_CAPTURES=",capture_dir)
	quit(0 if failures == 0 else 1)

func _press_policy() -> void:
	match challenge.state:
		Challenge.State.LINK:
			if challenge.pulse < 0.48 and not challenge.holding: hud._primary.button_down.emit()
			elif challenge.pulse > 0.58 and challenge.holding: hud._primary.button_up.emit()
		Challenge.State.CURRENT:
			var error: float = challenge.route_target - challenge.route_position
			var target: int = 1 if error > 0.025 else (-1 if error < -0.025 else 0)
			if challenge.direction != target:
				hud._left.button_up.emit()
				hud._right.button_up.emit()
				if target == 1: hud._right.button_down.emit()
				elif target == -1: hud._left.button_down.emit()
		Challenge.State.RESONANCE:
			if challenge.tension < 0.46 and not challenge.holding: hud._primary.button_down.emit()
			elif challenge.tension > 0.58 and challenge.holding: hud._primary.button_up.emit()

func _check_layout(label: String) -> void:
	var extent: Rect2 = Rect2(Vector2.ZERO,Vector2(root.content_scale_size))
	for control: Control in [hud._title,hud._instruction,hud._phase_status,hud._detail]:
		_check(extent.encloses(control.get_global_rect()),label + " HUD text fits portrait safe area: " + control.text.left(12))
	for control: Control in [hud._primary,hud._left,hud._right]:
		if control.visible: _check(extent.encloses(control.get_global_rect()) and control.size.y >= 96.0,label + " visible controls fit with 96px touch targets")
	if hud._terminal_controls.visible:
		for control: Control in hud._terminal_controls.get_children(): _check(extent.encloses(control.get_global_rect()),label + " completion action fits")

func _capture(name: String) -> void:
	if capture_dir.is_empty(): return
	# Advance presentation while simulation remains deterministic and explicit.
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	_check(screenshot != null and not screenshot.is_empty(),"rendered screenshot available: " + name)
	if screenshot != null and not screenshot.is_empty():
		_check(screenshot.save_png(capture_dir.path_join(name + ".png")) == OK,"native whale frame saved: " + name)
