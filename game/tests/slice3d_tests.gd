extends SceneTree
## Actual production 3D slice. No replica state machine, fake actor, or save mock.
const MainScene = preload("res://scenes/main.tscn")
const Main = preload("res://scripts/main.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Store = preload("res://scripts/save_store.gd")
const Stage = preload("res://scripts/fishing_stage_3d.gd")
const Trial = preload("res://scripts/trial_fishery.gd")
var app: Control
var checks: int = 0
var failures: int = 0
var test_root: String
var cast_events: Array[int] = []
var landing_events: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL 3D: ", label)

func _run() -> void:
	var data: String = OS.get_environment("XDG_DATA_HOME")
	if not data.begins_with("/tmp/farshore-slice3d-") or not OS.get_environment("HOME").begins_with("/tmp/farshore-slice3d-") or not OS.get_user_data_dir().begins_with(data + "/"):
		printerr("SLICE3D_TESTS: refusing non-isolated HOME/XDG_DATA_HOME")
		quit(2)
		return
	test_root = data.path_join("fixtures")
	root.size = Vector2i(720,1280)
	app = MainScene.instantiate()
	root.add_child(app)
	app.set_process(false)
	app.scenery.set_process(false)
	app.scenery._animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	app.sound.apply({"sound":false,"vibration":false,"volume":0.0})
	app.sound.suspend(true)
	var fixture: SaveStore = Store.new()
	_check(fixture.initialize(test_root), "isolated production SaveStore initializes")
	app.store = fixture
	app.encounter.rng.seed = 20261002
	app.session._rng.seed = 2468
	app.scenery.cast_presentation_finished.connect(func() -> void: cast_events.append(1))
	app.scenery.landing_finished.connect(func(record: Dictionary) -> void: landing_events.append(record.duplicate(true)))
	await _layout()
	_test_configuration()
	_test_world_and_rigs()
	_test_weather_presentation()
	await _test_lobby_and_prepare()
	_test_input_cancel()
	await _test_species_flow("common_carp", true)
	await _test_species_flow("alligator_gar", false)
	_test_restart_pending()
	_test_extreme_landing_framing()
	app.sound.suspend(true)
	app.sound.ambience.stream = null
	app.sound.effect.stream = null
	app.queue_free()
	await process_frame
	await process_frame
	print("SLICE3D_TESTS: ", checks-failures, "/", checks, " passed; failures=", failures, "; cast events=", cast_events.size(), "; landing events=", landing_events.size())
	quit(0 if failures == 0 else 1)

func _layout() -> void:
	for frame: int in 4: await process_frame

func _tick(seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.00001:
		var delta: float = minf(remaining, 0.025)
		if not app.scenery._suspended:
			if app.scenery._animator: app.scenery._animator.advance(delta)
			if app.scenery._fish_animator:
				app.scenery._fish_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
				app.scenery._fish_animator.advance(delta)
		app.scenery._process(delta)
		app._process(delta)
		remaining -= delta

func _find_button(node: Node, value: String) -> Button:
	if node is Button and node.text == value: return node as Button
	for child: Node in node.get_children():
		var result: Button = _find_button(child,value)
		if result != null: return result
	return null

func _find_all(node: Node, class_name_value: String, values: Array[Node]) -> void:
	if node.is_class(class_name_value): values.append(node)
	for child: Node in node.get_children(): _find_all(child,class_name_value,values)

func _test_configuration() -> void:
	_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "mobile", "native Mobile rendering is the production default")
	_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "mobile", "Android retains Mobile rendering without a compatibility downgrade")
	_check(app._content_ok and app.catalog.fish.size() == 44 and app.catalog.spots.size() == 12, "all legacy catalog data survives the two-fish slice")
	_check(Trial.PLAYABLE_SPECIES == ["common_carp","alligator_gar"], "exactly the two authorized species are playable in this slice")

func _test_world_and_rigs() -> void:
	_check(app.scenery is Node3D and app.scenery.camera is Camera3D and app.scenery.camera.current, "production scene has an active real 3D world camera")
	var meshes: Array[Node] = []
	_find_all(app.scenery,"MeshInstance3D",meshes)
	_check(meshes.size() >= 20, "production environment contains real retained meshes")
	var sprites: Array[Node] = []
	_find_all(app.scenery,"Sprite3D",sprites)
	_find_all(app.scenery,"AnimatedSprite3D",sprites)
	_check(sprites.is_empty(), "no billboard actor/fish substitutes exist in the world")
	_check(app.scenery._rod_socket != null and str(app.scenery._rod_socket.name) == "RodSocket", "rod uses authored right-hand socket, not temporary fallback")
	_check(app.scenery._rod.get_parent() == app.scenery._rod_socket, "actual rod geometry follows the character hand socket")
	_audit_rig(app.scenery._angler,"angler",["idle","cast","wait","reel","lift"],16)
	var cast: Animation = _clip(app.scenery._animator,"cast")
	_check(cast != null and is_equal_approx(cast.length,Stage.CAST_DURATION), "cast presentation duration matches the loaded character clip")
	_check(Stage.RELEASE_TIME > 0 and Stage.RELEASE_TIME < Stage.CAST_DURATION, "release event occurs inside the authored cast clip")
	for species: String in Trial.PLAYABLE_SPECIES:
		app.scenery._ensure_fish({"species_id":species,"length_mm":850})
		_audit_rig(app.scenery._fish,species,["swim","struggle","breach","landed"],6)
		_check(app.scenery._fish_id == species, "live fish switches to the actual species mesh: " + species)
		app.scenery._ensure_fish({"species_id":species,"length_mm":500})
		var short_scale: Vector3 = app.scenery._fish.scale
		app.scenery._ensure_fish({"species_id":species,"length_mm":1200})
		_check(app.scenery._fish.scale.x > short_scale.x and is_equal_approx(short_scale.x,0.5) and is_equal_approx(app.scenery._fish.scale.x,1.2), species + " actual mesh scale follows the production millimeter measurement")
	app.scenery._fish_root.visible = false

func _clip(player: AnimationPlayer, suffix: String) -> Animation:
	if player == null: return null
	for name_value: StringName in player.get_animation_list():
		if str(name_value).get_file() == suffix: return player.get_animation(name_value)
	return null

func _audit_rig(actor: Node3D, label: String, clips: Array, minimum_bones: int) -> void:
	_check(actor != null, label + " real actor instance exists")
	if actor == null: return
	var skeletons: Array[Node] = []
	var meshes: Array[Node] = []
	var players: Array[Node] = []
	_find_all(actor,"Skeleton3D",skeletons)
	_find_all(actor,"MeshInstance3D",meshes)
	_find_all(actor,"AnimationPlayer",players)
	_check(skeletons.size() == 1 and skeletons[0].get_bone_count() >= minimum_bones, label + " has one actual multibone skeleton")
	_check(players.size() == 1, label + " has an actual imported AnimationPlayer")
	var skinned: int = 0
	var weighted_vertices: int = 0
	for node: MeshInstance3D in meshes:
		if node.skin == null: continue
		skinned += 1
		_check(node.skin.get_bind_count() >= minimum_bones, label + " skin has actual skeleton bindings")
		_check(node.get_node_or_null(node.skeleton) is Skeleton3D, label + " skinned mesh resolves its live Skeleton3D")
		for surface: int in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			_check(weights.size() >= vertices.size()*4 and bones.size() == weights.size(), label + " mesh has actual vertex bone/weight arrays")
			var nonzero: int = 0
			for weight: float in weights:
				if weight > 0.001: nonzero += 1
			_check(nonzero >= vertices.size(), label + " vertices have effective nonzero skin weights")
			weighted_vertices += vertices.size()
	_check(skinned >= 1 and weighted_vertices >= 250, label + " renders substantial weighted geometry, not a rig with an unbound prop")
	if players.is_empty(): return
	var player: AnimationPlayer = players[0] as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip_name: String in clips:
		var animation: Animation = _clip(player,clip_name)
		_check(animation != null and animation.length >= 1.0 and animation.get_track_count() >= 3, label + " imported animated clip exists: " + clip_name)
		if animation == null: continue
		var skeletal_tracks: int = 0
		for track: int in animation.get_track_count():
			if animation.track_get_type(track) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D] and animation.track_get_key_count(track) >= 2: skeletal_tracks += 1
		_check(skeletal_tracks >= 3, label + " clip contains real skeletal transform keyframes: " + clip_name)
	# Animation tracks alone could target missing nodes. Drive the actual imported
	# skeleton and require its live bone poses to move in every advertised clip.
	var previous: String = player.assigned_animation
	if not skeletons.is_empty():
		var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
		for clip_name: String in clips:
			var resolved: String = ""
			for name_value: StringName in player.get_animation_list():
				if str(name_value).get_file() == clip_name: resolved = str(name_value)
			if resolved.is_empty(): continue
			player.play(resolved)
			player.seek(0.10,true)
			var poses: Array[Transform3D] = []
			for bone: int in skeleton.get_bone_count(): poses.append(skeleton.get_bone_pose(bone))
			player.seek(player.get_animation(resolved).length * 0.48,true)
			var changed: int = 0
			for bone: int in skeleton.get_bone_count():
				if not poses[bone].is_equal_approx(skeleton.get_bone_pose(bone)): changed += 1
			_check(changed >= 2, label + " clip changes at least two actual live bone poses: " + clip_name)
	if not previous.is_empty(): player.play(previous)
	else: player.stop()
	print("3D_RIG ",label," meshes=",meshes.size()," skinned=",skinned," weighted_vertices=",weighted_vertices," clips=",player.get_animation_list())

func _test_lobby_and_prepare() -> void:
	var selection: Dictionary = app.store.state.selection.duplicate(true)
	_check(app._mode == "lobby" and app._screen == "home" and not app._safe.visible, "startup is a proper lobby without the fishing HUD")
	_check(not app._action.is_visible_in_tree(), "lobby has no visible casting action")
	app._action_down()
	app._action_up()
	_check(app.session.state == Session.State.PAUSED and app.session.individual.is_empty(), "lobby rejects casting even through action callbacks")
	var start: Button = _find_button(app._overlay,"开始钓鱼")
	_check(start != null and not start.disabled, "lobby exposes the actual start control")
	if start: start.pressed.emit()
	await _layout()
	_check(app._screen == "prepare" and app._mode == "lobby", "start opens preparation before any cast")
	app._set_trial_target("alligator_gar")
	_check(app._trial_target == "alligator_gar" and app.store.state.selection == selection, "trial target is ephemeral and preserves the saved legacy selection")
	var enter: Button = _find_button(app._overlay,"进入钓点")
	_check(enter != null and not enter.disabled, "preparation exposes the actual enter-fishery action")
	if enter: enter.pressed.emit()
	await _layout()
	_check(app._mode == "fishing" and app._overlay == null and app.session.state == Session.State.IDLE and app._action.is_visible_in_tree(), "entering fishery makes the ready-to-cast HUD visible")
	_check(app.store.state.selection == selection, "entering the managed river does not overwrite legacy region or spot")

func _test_input_cancel() -> void:
	app._action_down()
	_tick(0.4)
	_check(app.session.state == Session.State.CHARGING and app.session.charge > 0, "production action starts charge")
	app._action_cancel()
	app._action_up()
	_check(app.session.state == Session.State.IDLE and not app.scenery.cast_in_progress and app.session.individual.is_empty(), "cancelled hold cannot release into an unintended cast")

func _test_species_flow(species: String, interruptions: bool) -> void:
	app._show_prepare()
	app._set_trial_target(species)
	app._enter_fishery()
	var selection: Dictionary = app.store.state.selection.duplicate(true)
	var before_count: int = app.store.total_count()
	var before_cast_events: int = cast_events.size()
	var before_land_events: int = landing_events.size()
	var camera_before: Transform3D = app.scenery.camera.global_transform
	app._action_down()
	_tick(0.8)
	app._action_up()
	_check(app.session.state == Session.State.CASTING and app.scenery.cast_in_progress, species + " actual action release starts character cast presentation")
	_check(str(app.session.individual.species_id) == species and str(app.session.individual.region_id) == Trial.REGION_ID, species + " is reachable through actual production trial generation")
	var identity: String = app.session.session_id
	var individual: Dictionary = app.session.individual.duplicate(true)
	_tick(0.65)
	_check(not app.scenery._bobber.visible and app.session.elapsed == 0, species + " lure stays in hand and logical waiting stays gated before release")
	if interruptions: await _interrupt_presentation("cast")
	_tick(0.65)
	_check(app.scenery._bobber.visible and app.scenery._line.visible and app.scenery.cast_in_progress, species + " timed release shows the actual lure and 3D fishing line")
	_tick(0.80)
	_check(app.scenery.cast_in_progress and app.session.state == Session.State.CASTING and cast_events.size() == before_cast_events, species + " full cast clip is not cut short by the legacy cast timer")
	_tick(0.15)
	_check(not app.scenery.cast_in_progress and cast_events.size() == before_cast_events+1, species + " cast completion fires exactly once after the clip")
	for tick: int in 800:
		if app.session.state == Session.State.BITE: break
		_tick(0.025)
	_check(app.session.state == Session.State.BITE and app.scenery._fish_root.visible, species + " actual wait and nibble reach a visible fish bite")
	_check(app.scenery.camera.global_transform != camera_before and app.scenery.camera.position.distance_to(camera_before.origin) > 0.25, species + " camera transition moves the actual 3D view")
	_check(app.session.session_id == identity and app.session.individual == individual, species + " cast/wait/pause preserve the exact encounter")
	app._action_down()
	app._action_up()
	_check(app.session.state == Session.State.FIGHT and not app.session.reeling, species + " actual hook action begins fight without latched input")
	app._action_down()
	_tick(0.2)
	app._action_cancel()
	_check(not app.session.reeling, species + " pointer cancel releases active reel input")
	for tick: int in 3000:
		if app.session.state != Session.State.FIGHT: break
		if app.session.tension < 0.46: app._action_down()
		elif app.session.tension > 0.58: app._action_up()
		_tick(0.025)
	_check(app.session.state == Session.State.CAUGHT and app._landing_pending and app._save_ok, species + " balanced production fight catches and begins landing")
	_check(app._screen != "result" and app.store.total_count() == before_count+1, species + " save is immediate while results wait for the 3D landing")
	var record: Dictionary = app._last_record.duplicate(true)
	var catch_id: String = str(record.get("catch_id",""))
	_check(app.store.state.pending_catches.has(catch_id), species + " catch is durable before presentation completion")
	var fresh: SaveStore = Store.new()
	_check(fresh.initialize(test_root) and fresh.state.pending_catches.has(catch_id), species + " process restart during landing can recover the exact pending catch")
	var underwater_y: float = app.scenery._fish_root.position.y
	_tick(0.55)
	_check(app.scenery._fish_root.position.y > 0 and app.scenery._fish_root.position.y > underwater_y, species + " fish geometry breaches the actual world water plane")
	if interruptions: await _interrupt_presentation("landing")
	var count_snapshot: int = app.store.total_count()
	var money_snapshot: int = int(app.store.state.currency)
	app._fishing_ended(true,record)
	_check(app.store.total_count() == count_snapshot and int(app.store.state.currency) == money_snapshot, species + " duplicate terminal callback cannot duplicate count or currency")
	_tick(2.5)
	_check(app._landing_pending and app._screen != "result", species + " result does not truncate the breach/lift presentation")
	_check_landing_framing(species)
	# BoneAttachment3D updates on the scene frame; allow it to settle before
	# checking the line and rod meshes against the current imported hand pose.
	await process_frame
	app.scenery._process(0.0)
	_check_line_connected(species)
	_tick(0.5)
	_check(not app._landing_pending and app._screen == "result" and landing_events.size() == before_land_events+1, species + " finished landing exposes result exactly once")
	_check(app.scenery._fish_root.position.y > 0.9, species + " landed fish is lifted to the character's presentation plane")
	app._fishing_ended(true,record)
	_check(not app._landing_pending and app._screen == "result" and app.store.total_count() == count_snapshot, species + " repeated already-presented completion cannot re-arm a stuck landing")
	for repeat: int in 3: app._handle_back()
	_check(app._screen == "result" and app._last_record == record and app.store.state.pending_catches.has(catch_id), species + " repeated result Back preserves the exact pending catch")
	if species == "common_carp":
		app._dispose_result("released")
		_check(app.session.state == Session.State.IDLE and app._last_record.is_empty() and app.store.total_count() == count_snapshot, "real result disposition returns to fishing without losing history")
	_check(app.store.state.selection == selection, species + " fishing and presentation preserve archived location selection")

func _interrupt_presentation(label: String) -> void:
	var before_time: float = app.scenery._cast_time if label == "cast" else app.scenery._landing_time
	var before_camera: Transform3D = app.scenery.camera.global_transform
	var before_fish: Transform3D = app.scenery._fish_root.transform
	var before_elapsed: float = app.session.elapsed
	var before_clock: float = app.game_clock
	app._notification(Main.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	_check(app._screen == "pause" and app.session.state == Session.State.PAUSED and app.scenery._suspended, label + " focus loss pauses both gameplay and presentation")
	_tick(2.0)
	_check((app.scenery._cast_time if label == "cast" else app.scenery._landing_time) == before_time and app.scenery.camera.global_transform == before_camera and app.scenery._fish_root.transform == before_fish, label + " pause freezes world animation timers, fish and camera")
	_check(app.session.elapsed == before_elapsed and app.game_clock == before_clock and not app.session.reeling, label + " pause freezes session/world clock and clears held input")
	app._show_settings()
	_tick(1.0)
	app._handle_back()
	_check(app._overlay == null and not app.scenery._suspended, label + " settings Back resumes the same presentation")
	app._handle_back()
	app._handle_back()
	_check(app._overlay == null and (app.scenery._cast_time if label == "cast" else app.scenery._landing_time) == before_time, label + " repeated system Back preserves presentation progress")

func _test_restart_pending() -> void:
	var expected: Dictionary = app._last_record.duplicate(true)
	var catch_id: String = str(expected.get("catch_id",""))
	var before: int = app.store.total_count()
	var fresh: SaveStore = Store.new()
	_check(fresh.initialize(test_root) and fresh.state.pending_catches.has(catch_id), "restart retains final unhandled gar catch")
	_check(fresh.total_count() == before, "restart does not settle the catch twice")
	var duplicate: Dictionary = fresh.settle_catch(expected)
	_check(not bool(duplicate.get("ok",false)) and bool(duplicate.get("duplicate",false)) and fresh.total_count() == before, "durable idempotency rejects duplicate reward on the same catch")
	_check(fresh.state.selection == app.store.state.selection, "restart preserves the original legacy selection")

func _check_landing_framing(species: String) -> void:
	var meshes: Array[Node] = []
	_find_all(app.scenery._fish,"MeshInstance3D",meshes)
	var clipped: int = 0
	var sample_count: int = 0
	var bounds: Rect2 = Rect2(Vector2(8,8),Vector2(root.size)-Vector2(16,16))
	for mesh: MeshInstance3D in meshes:
		if not mesh.visible or mesh.mesh == null: continue
		var box: AABB = mesh.get_aabb()
		for corner: int in 8:
			var point: Vector3 = mesh.global_transform * box.get_endpoint(corner)
			sample_count += 1
			if app.scenery.camera.is_position_behind(point) or not bounds.has_point(app.scenery.camera.unproject_position(point)): clipped += 1
	_check(sample_count > 0 and clipped == 0, species + " lifted fish mesh bounds fit inside the portrait viewport; clipped=" + str(clipped))

func _test_extreme_landing_framing() -> void:
	var saved: Dictionary = app.store.state.duplicate(true)
	for row: Array in [["common_carp",180],["common_carp",900],["alligator_gar",650],["alligator_gar",2400]]:
		var species: String = str(row[0])
		var length_mm: int = int(row[1])
		app.scenery.cancel_landing()
		app.scenery.suspend(false)
		app.scenery.play_landing({"species_id":species,"length_mm":length_mm,"catch_id":"framing-"+species+"-"+str(length_mm)})
		for frame: int in 120:
			if app.scenery._animator: app.scenery._animator.advance(0.025)
			if app.scenery._fish_animator: app.scenery._fish_animator.advance(0.025)
			app.scenery._process(0.025)
		_check_landing_framing(species + " " + str(length_mm) + "mm")
	app.scenery.cancel_landing()
	_check(app.store.state == saved, "presentation-only framing checks cannot change saved catches or selection")

func _check_line_connected(species: String) -> void:
	var rod: MeshInstance3D = app.scenery._rod_mesh
	var line: MeshInstance3D = app.scenery._line
	_check(rod.mesh != null and line.mesh != null, species + " visible landing rod and line have actual meshes")
	if rod.mesh == null or line.mesh == null: return
	var rod_vertices: PackedVector3Array = rod.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var line_vertices: PackedVector3Array = line.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var tip: Vector3 = Vector3.ZERO
	var start: Vector3 = Vector3.ZERO
	for index: int in range(rod_vertices.size()-6,rod_vertices.size()): tip += rod.global_transform * rod_vertices[index] / 6.0
	for index: int in 4: start += line.global_transform * line_vertices[index] / 4.0
	_check(tip.distance_to(start) < 0.01, species + " actual line geometry meets the animated rod tip within one centimeter")

func _test_weather_presentation() -> void:
	var rain: GPUParticles3D = app.scenery._rain
	_check(rain != null and rain.amount > 0 and rain.amount <= 256, "weather has a bounded actual 3D precipitation system")
	if rain == null: return
	app.game_clock = 0.0
	app._update_conditions()
	_check(app.weather == "clear" and not rain.visible and not rain.emitting, "clear production weather hides and stops rain")
	app.game_clock = 240.0
	app._update_conditions()
	_check(app.weather == "rain" and rain.visible and rain.emitting, "production rainy clock state enables actual precipitation")
	app.scenery.suspend(true)
	var frozen: float = app.scenery._time
	app.scenery._process(1.0)
	_check(rain.speed_scale == 0.0 and app.scenery._time == frozen, "paused rain and its world animation clock stay frozen")
	app.scenery.suspend(false)
	_check(rain.speed_scale == 1.0 and rain.emitting, "resuming preserves the current rain without restarting the encounter")
	app.game_clock = 0.0
	app._update_conditions()
	_check(not rain.visible and not rain.emitting, "returning to clear weather removes precipitation")
