extends SceneTree
## Formal release: preserve exact reviewed fight-function hashes and exercise
## current fight controls independently from the deliberately changed float.
## --historical-video retains the original strict beta2 capture/hash audit.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Controller = preload("res://tests/fishing_test_controller.gd")
const FIGHT_BASELINE_COMMIT: String = "1637653"
const FIGHT_HASHES: Dictionary = {
	"_surge_reset":"b8061671fd942812c9322f49f9f5de96b4e61f3a04304feba025cead34e76945",
	"_begin_fight":"994c8c3532daaba7a988571ebc2d96ef52e825544376b13f7d26a05d7b633167",
	"_set_phase":"4e78db0c7ee9a2cb6f8bc18d8a941f3748a35faf58bb6484ae5e1d3c15f452da",
	"_next_phase":"edfc4c0684b336f14bc1fa51bd4ed145d24e1cc9915ff20f9786b3ee2c3fd954",
	"_step_fight":"cd06437642bcc959b5ba782b59179b0adc215c74f60c9c851a5c7e8426863a69",
	"_step_line_wear":"6f33c0f5ae0772fcff2a5ac89b34f28440a9f4875f10c57f4390bc4e93bf3e51",
	"_finish":"e5b9259eac34268f3dc986e17b8faccfc7591c018d7080faec6a04b419383cf9",
}
var old_session: RefCounted
var new_session: FishingSession
var cast_time: float = 0.0
var cast_in_progress: bool = true
var different: Array[String] = []
var video_different: Array[int] = []
var compared_substeps: int = 0
var max_wear: float = 0.0
var capture: Dictionary = {}
var formal_checks: int = 0
var formal_failures: Array[String] = []

func _initialize() -> void:
	if "--historical-video" in OS.get_cmdline_user_args(): _run_historical()
	else: call_deferred("_run_formal")

func _formal_check(ok: bool, label: String) -> void:
	formal_checks += 1
	if not ok:
		formal_failures.append(label)
		printerr("FAIL FORMAL_FIGHT: ",label)

func _run_formal() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/fishing_session.gd")
	var observed_hashes: Dictionary = {}
	for name: String in FIGHT_HASHES:
		var pattern: RegEx = RegEx.new()
		pattern.compile("(?ms)^func " + name + "\\(.*?(?=^func |\\z)")
		var found: RegExMatch = pattern.search(source)
		var actual: String = "" if found == null else found.get_string().strip_edges().sha256_text()
		observed_hashes[name] = actual
		_formal_check(actual == FIGHT_HASHES[name],"reviewed fight function unchanged from " + FIGHT_BASELINE_COMMIT + ": " + name)
	var catalog: ContentCatalog = Catalog.new()
	_formal_check(catalog.load_all(false),"catalog loads")
	var rows: Array[Dictionary] = []
	for id: String in ["common_bream","rudd","roach"]:
		for fraction: float in [0.35,0.95]:
			for gear: int in [0,4]:
				for seed_value: int in [1103,2468]:
					for fps: int in [16,30,60]:
						for mode: String in ["always_pull","never_pull","metronome","tension_only","behavior_aware"]:
							rows.append(_combat_case(catalog,id,fraction,gear,seed_value,fps,mode))
	var output: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var report: Dictionary = {"scope":"Formal fight-only regression; exact reviewed function hashes plus current seeded controls. Starts FIGHT explicitly. Does not certify unchanged pre-hook timing or a historical rendered video.","baseline_commit":FIGHT_BASELINE_COMMIT,"expected_function_hashes":FIGHT_HASHES,"actual_function_hashes":observed_hashes,"current_source_sha256":source.sha256_text(),"checks":formal_checks,"failures":formal_failures,"runs":rows}
	if not output.is_empty():
		var file: FileAccess = FileAccess.open(output,FileAccess.WRITE)
		_formal_check(file != null,"write formal fight evidence")
		if file != null:
			report.checks = formal_checks
			file.store_string(JSON.stringify(report,"\t"))
			file.close()
	print("FISHING_GUARD_TRACE_TESTS: ",formal_checks-formal_failures.size(),"/",formal_checks," passed; formal_fight_cases=",rows.size(),"; unchanged_functions=",FIGHT_HASHES.size(),"; historical_video_not_revalidated=true")
	quit(0 if formal_failures.is_empty() else 1)

func _combat_case(catalog: ContentCatalog,id: String,fraction: float,gear: int,seed_value: int,fps: int,mode: String) -> Dictionary:
	var fish: FishDefinition = catalog.fish[id]
	var record: Dictionary = Encounter.new(seed_value).make_individual(fish,str(fish.spots()[0]),str(fish.regions()[0]),"worm",gear,"day","clear")
	record.size_fraction = fraction
	record.length_mm = roundi(lerpf(fish.min_mm,fish.max_mm,fraction))
	record.weight_g = roundi(fish.anchor_g*pow(float(record.length_mm)/fish.anchor_mm,3.0))
	record.difficulty = clampf(fish.difficulty*0.7+fraction*0.5,0.15,1.0)
	Encounter.new(seed_value).apply_float_presentation(record,catalog,0.6)
	var s: FishingSession = Session.new(seed_value)
	s.press()
	s.cast(record,catalog.gear[gear])
	s.set_state(Session.State.FIGHT)
	s.release()
	var endings: Array[bool] = []
	s.ended.connect(func(ok: bool,_record: Dictionary) -> void: endings.append(ok))
	var controller: RefCounted = Controller.new(mode)
	var delta: float = 1.0/fps
	var max_tension: float = 0.0
	while s.state == Session.State.FIGHT and s.fight_time < 420.0:
		var held: bool = controller.update(s,delta)
		if held and not s.reeling: s.press()
		elif not held and s.reeling: s.release()
		s.step(delta)
		max_tension = maxf(max_tension,s.tension)
	var label: String = "%s size=%.2f gear=%d seed=%d fps=%d strategy=%s" % [id,fraction,gear,seed_value,fps,mode]
	_formal_check(s.state in [Session.State.CAUGHT,Session.State.ESCAPED],"fight ends without timeout: " + label)
	if mode == "behavior_aware": _formal_check(s.state == Session.State.CAUGHT,"readable fight control catches: " + label)
	if mode in ["always_pull","never_pull"]: _formal_check(s.state == Session.State.ESCAPED,"unmodulated fight input loses: " + label)
	_formal_check(endings.size() == 1,"one terminal settlement: " + label)
	var outcome: int = s.state
	s._finish(s.state != Session.State.CAUGHT,"late opposite callback")
	s.step(10.0)
	_formal_check(endings.size() == 1 and s.state == outcome,"late callback cannot reverse or duplicate fight: " + label)
	return {"species":id,"size_fraction":fraction,"gear":gear,"seed":seed_value,"fps":fps,"strategy":mode,"caught":s.state == Session.State.CAUGHT,"seconds":s.fight_time,"max_tension":max_tension,"wear":s.line_wear,"reason":s.escape_reason}

func _run_historical() -> void:
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
