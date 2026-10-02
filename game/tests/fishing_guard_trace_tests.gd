extends SceneTree
## Compare the pre-guard recovery source and current session using the actual
## capture's seeded ordinary encounter, 20fps input policy and 0.025s substeps.
## This is a session trace comparison, not a new rendered-video certification.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
var old_session: RefCounted
var new_session: FishingSession
var cast_time: float = 0.0
var cast_in_progress: bool = true
var different: Array[String] = []
var video_different: Array[int] = []
var compared_substeps: int = 0
var max_wear: float = 0.0
var capture: Dictionary = {}

func _initialize() -> void:
	var old_path: String = ""
	var video_path: String = ProjectSettings.globalize_path("res://").path_join("../docs/evidence/1.2.0-beta.2/recovered/fishing_observation_capture.json")
	var output_path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--old-source="): old_path = arg.trim_prefix("--old-source=")
		if arg.begins_with("--capture="): video_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--output="): output_path = arg.trim_prefix("--output=")
	var old_source: String = FileAccess.get_file_as_string(old_path) if not old_path.is_empty() else FileAccess.get_file_as_string("res://scripts/fishing_session.gd").replace("\telif line_wear > 0.78 and _wear_warning_time >= 8.0 and _break_hazard >= _break_threshold:", "\telif _break_hazard >= _break_threshold:")
	if old_path.is_empty():
		old_source = old_source.replace("\t\t\treeling = false\n\t\t\tset_state(State.FIGHT)\n\t\t\t# A genuine new bite press may continue as a held reel. A gesture\n\t\t\t# held before the bite never reaches this branch; pause can cancel it.\n\t\t\tif state == State.FIGHT and _pressed: reeling = true\n\t\t\tcue.emit(\"hook\")", "\t\t\treeling = false # Hooking is one deliberate edge, not held auto-reeling.\n\t\t\tset_state(State.FIGHT)\n\t\t\tcue.emit(\"hook\")")
	# Reverse only the reviewed hazard guard and held-hook input changes.
	# Hash verification prevents silent drift and requires no .git or capsule.
	var old_hash: String = old_source.sha256_text()
	if old_hash != "130fd17c3a86b058da18a98f8b2e5c95599b7cbacd040ad14a381298175493cb":
		printerr("FAIL: pre-guard source is not the exact recovered source")
		quit(2)
		return
	capture = JSON.parse_string(FileAccess.get_file_as_string(video_path))
	var old_code: GDScript = GDScript.new()
	# Only the global class declaration is omitted to allow both revisions to
	# coexist. The script body and all production formulas remain unchanged.
	old_code.source_code = old_source.replace("class_name FishingSession\n", "")
	if old_code.reload() != OK:
		printerr("FAIL: old session cannot compile")
		quit(2)
		return
	old_session = old_code.new(2468)
	new_session = Session.new(2468)
	var catalog: ContentCatalog = Catalog.new()
	if not catalog.load_all(false):
		quit(2)
		return
	old_session.press()
	new_session.press()
	for tick: int in 46:
		old_session.step(0.025)
		new_session.step(0.025)
	var record: Dictionary = Encounter.new(20261002).generate(catalog, "lake_shore", "worm", 0, new_session.charge, "day", "clear")
	old_session.cast(record, catalog.gear[0])
	new_session.cast(record, catalog.gear[0])
	old_session.release()
	new_session.release()
	var traces: Array[Dictionary] = []
	for frame: int in int(capture.frames):
		if new_session.state == Session.State.BITE and new_session.elapsed > 0.58:
			old_session.press()
			new_session.press()
			old_session.release()
			new_session.release()
		if new_session.state == Session.State.FIGHT:
			if new_session.surge_warning > 0.12 or new_session.tension > 0.63:
				old_session.release()
				new_session.release()
			elif new_session.tension < 0.46:
				old_session.press()
				new_session.press()
		for substep: int in 2:
			if cast_in_progress:
				cast_time += 0.025
				if cast_time >= 2.20:
					cast_in_progress = false
					old_session.set_state(Session.State.WAITING)
					new_session.set_state(Session.State.WAITING)
			if not cast_in_progress:
				old_session.step(0.025)
				new_session.step(0.025)
			_compare(frame, substep)
		var observed: Dictionary = capture.capture_rows[frame]
		var same_video: bool = int(observed.state) == new_session.state and str(observed.phase) == new_session.fight_phase and is_equal_approx(float(observed.warning), new_session.surge_warning) and is_equal_approx(float(observed.dip), new_session.float_dip) and is_equal_approx(float(observed.lift), new_session.float_lift) and str(observed.drag) == str(new_session.float_drag)
		if not same_video: video_different.append(frame)
		traces.append({"frame":frame,"state":new_session.state,"phase":new_session.fight_phase,"warning":new_session.surge_warning,"dip":new_session.float_dip,"lift":new_session.float_lift,"drag":str(new_session.float_drag),"tension":new_session.tension,"stamina":new_session.fish_stamina,"wear":new_session.line_wear})
	var report: Dictionary = {"scope":"Actual old/new production sessions; captured ordinary seed/input trace at20fps, not a new rendering run", "old_source_sha256":old_hash,"new_source_sha256":FileAccess.get_sha256("res://scripts/fishing_session.gd"),"capture_sha256":FileAccess.get_sha256(video_path),"frames":traces.size(),"simulated_seconds":traces.size()*0.05,"compared_substeps":compared_substeps,"old_new_differences":different,"capture_session_observation_mismatch_frames":video_different,"max_line_wear":max_wear,"specimen":{"species_id":record.species_id,"size_fraction":record.size_fraction,"length_mm":record.length_mm,"weight_g":record.weight_g},"passed":different.is_empty() and video_different.is_empty(),"traces":traces}
	if not output_path.is_empty():
		var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(report,"\t"))
			file.close()
	print("FISHING_GUARD_TRACE_TESTS: old_new_differences=",different.size()," capture_mismatches=",video_different.size()," frames=",traces.size()," substeps=",compared_substeps," max_wear=",max_wear)
	quit(0 if bool(report.passed) else 1)

func _compare(frame: int, substep: int) -> void:
	compared_substeps += 1
	for key: String in ["state","elapsed","charge","reeling","tension","progress","fight_time","slack_time","overload_time","fish_stamina","fish_distance","fatigue","fight_phase","phase_progress","surge_warning","surge_strength","line_wear","line_warning","float_dip","float_lift","float_drag","float_tilt","float_activity"]:
		if old_session.get(key) != new_session.get(key): different.append("frame=%d step=%d property=%s" % [frame,substep,key])
	if old_session._rng.state != new_session._rng.state: different.append("RNG state differs")
	max_wear = maxf(max_wear,new_session.line_wear)
