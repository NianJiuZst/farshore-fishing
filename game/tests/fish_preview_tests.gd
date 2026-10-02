extends SceneTree
const Preview = preload("res://scripts/fish_preview_3d.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PREVIEW: ", detail)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var holder: Control = Control.new()
	root.add_child(holder)
	var preview: SubViewportContainer = Preview.new()
	preview.size = Vector2(600, 340)
	preview.set_species("common_carp")
	holder.add_child(preview)
	await process_frame
	check(preview.model is Node3D, "real model instantiated")
	check(preview.animator is AnimationPlayer and preview.animator.is_playing(), "real skeletal swim clip playing")
	check(preview.mouse_filter == Control.MOUSE_FILTER_IGNORE, "preview never consumes touch scroll")
	check(preview._viewport.own_world_3d and preview._viewport.transparent_bg and preview._viewport.gui_disable_input, "isolated transparent world without input forwarding")
	check(preview._camera is Camera3D and preview._camera.current, "dedicated 3D camera")
	var landmarks: Array[Vector2] = preview.measurement_endpoints()
	check(landmarks.size() == 2 and landmarks[0].x < landmarks[1].x, "two projected rest-length landmarks")
	check(landmarks[1].x - landmarks[0].x < preview.size.x, "ruler follows model span, not viewport width")
	preview.position = Vector2(40, 90)
	var moved: Array[Vector2] = preview.measurement_endpoints()
	check(moved[0].is_equal_approx(landmarks[0] + Vector2(40, 90)), "ruler landmarks include canvas position")
	var first: int = preview.model.get_instance_id()
	preview.set_species("common_carp")
	check(preview.model.get_instance_id() == first, "same species does not reload")
	preview.set_species("alligator_gar")
	check(preview.model != null and preview.model.get_instance_id() != first, "species changes real mesh")
	check(preview.animator.is_playing(), "replacement rig animates")
	preview.set_species("unknown")
	check(preview.model == null and preview.animator == null, "missing species never silently substitutes carp")
	for cycle: int in range(12):
		preview.set_species("common_carp" if cycle % 2 == 0 else "alligator_gar")
		check(preview._pivot.get_child_count() == 1, "one active model, no accumulating instances")
	var frame_before: float = preview.animator.current_animation_position
	preview.animator.advance(0.25)
	check(preview.animator.current_animation_position > frame_before, "skeleton clock advances")
	holder.free()
	await process_frame
	print("FISH_PREVIEW_TESTS: ", checks - failures, "/", checks, " passed")
	quit(0 if failures == 0 else 1)
