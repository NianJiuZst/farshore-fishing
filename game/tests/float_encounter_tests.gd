extends SceneTree
## Float-observation QA. SurfaceReader receives only four rendered observables.
## Hidden possession/state diagnostics and the oracle are deliberately separate.
const Catalog = preload("res://scripts/catalog.gd")
const Generator = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const FightReader = preload("res://tests/fishing_test_controller.gd")
const MODES: Array[String] = ["fixed_5", "fixed_8", "fixed_11", "fixed_14", "earliest_motion", "amplitude_only", "visual_reactive", "hidden_oracle"]
const MAX_WAIT: float = 90.0
const MAX_FIGHT: float = 420.0

class SurfaceReader extends RefCounted:
	var history: Array[Dictionary] = []
	var elapsed: float = 0.0
	var confirmed: float = 0.0
	var queued_at: float = -1.0
	var detected_at: float = -1.0
	var motion: String = ""
	var confirmation_seconds: float = 0.35
	func _init(confirmation: float = 0.35) -> void:
		confirmation_seconds = confirmation
	func update(surface: Dictionary, delta: float, earliest: bool = false) -> bool:
		elapsed += delta
		var sample: Dictionary = {"t":elapsed, "dip":float(surface.dip), "lift":float(surface.lift), "drag":surface.drag, "tilt":float(surface.tilt)}
		history.append(sample)
		while history.size() > 2 and float(history[0].t) < elapsed - 0.30: history.pop_front()
		var oldest: Dictionary = history[0]
		var span: float = maxf(delta, elapsed - float(oldest.t))
		var travel: Vector2 = (sample.drag as Vector2) - (oldest.drag as Vector2)
		var speed: float = travel.length() / span
		# Sustained displacement and directed travel are observable. No species,
		# phase, possession, RNG, or future timing reaches this controller.
		var vertical: bool = maxf(float(sample.dip), float(sample.lift)) >= 0.22
		var directed: bool = speed >= 0.045 and span >= 0.16
		var has_signal: bool = vertical or directed
		if earliest: has_signal = maxf(float(sample.dip), float(sample.lift)) >= 0.045 or speed >= 0.025 or absf(float(sample.tilt)) >= 0.045
		if has_signal: confirmed += delta
		else:
			confirmed = 0.0
			# A recovered touch is visible evidence to abandon a queued strike.
			# The earliest-motion baseline deliberately remains impulsive.
			if not earliest: queued_at = -1.0
		if queued_at < 0.0 and confirmed >= (delta if earliest else confirmation_seconds):
			detected_at = elapsed
			queued_at = elapsed + 0.18
			motion = "lift" if float(sample.lift) > float(sample.dip) else "travel" if directed and not vertical else "sink"
		return queued_at >= 0.0 and elapsed + 0.000001 >= queued_at

var catalog: ContentCatalog = Catalog.new()
var checks: int = 0
var failed: Array[String] = []
var routes: Array[Dictionary] = []
var runs: Array[Dictionary] = []
var traces: Array[Dictionary] = []
var skip_fights: bool = false
var seed_sweep: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed.append(label)
		printerr("FAIL FLOAT_ENCOUNTER: ", label)

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output: String = ""
	var count: int = 8
	skip_fights = "--skip-fights" in args
	for arg: String in args:
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--seeds="): count = maxi(1, int(arg.trim_prefix("--seeds=")))
	_check(catalog.load_all(false), "catalog loads")
	_build_routes()
	_regressions()
	if "--regressions-only" not in args:
		if "--quick" not in args: seed_sweep = _seed_coverage()
		for route: Dictionary in routes:
			for index: int in count:
				var seed_value: int = 70219 + index * 1009
				var record: Dictionary = _record(route, seed_value, index)
				traces.append(_passive_trace(record, int(route.gear), seed_value))
				for fps: int in ([30] if "--quick" in args else [16, 30, 60]):
					for mode: String in MODES:
						runs.append(_trial(record, int(route.gear), seed_value, fps, mode))
			print("FLOAT_MATRIX_PROGRESS species=", route.species, " gear=", route.gear, " runs=", runs.size())
	var evidence: Dictionary = {"scope":"Real production GDScript; seeded 110-fish legal routes; observation-only pre-hook controls; unchanged fight controller; independent mammal challenge excluded; headless, no visual/device claim", "matrix_executed":"--regressions-only" not in args, "quick_matrix":"--quick" in args, "regressions":{"checks":checks,"failed":failed}, "routes":routes, "runs":runs, "traces":traces, "seed_sweep":seed_sweep, "controller_contract":{"inputs":["dip","lift","drag","tilt"],"reaction_seconds":0.18,"history_seconds":0.30,"sustained_seconds":0.35,"cancel_on_recovery":true,"vertical_threshold":0.22,"travel_speed_threshold":0.045,"oracle":"Separate validation control only; never evidence of readability"}}
	if not output.is_empty():
		var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
		_check(file != null, "write evidence output")
		if file != null:
			evidence.regressions.checks = checks
			file.store_string(JSON.stringify(evidence, "\t"))
			file.close()
	print("FLOAT_ENCOUNTER_TESTS: ", checks - failed.size(), "/", checks, " passed; failures=", failed.size(), "; simulations=", runs.size(), "; passive_traces=", traces.size())
	quit(0 if failed.is_empty() else 1)

func _build_routes() -> void:
	var gen: EncounterGenerator = Generator.new(815)
	for id: String in catalog.fish:
		var fish: FishDefinition = catalog.fish[id]
		if not catalog.is_fishing_species(fish): continue
		var baits: Array = catalog.baits.duplicate()
		baits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return catalog.bait_weight(fish, str(a.bait_id)) > catalog.bait_weight(fish, str(b.bait_id)))
		var legal: Array[Dictionary] = []
		for gear: int in catalog.gear.size():
			var found: bool = false
			for spot: String in fish.spots():
				if found or gear < int(catalog.spots[spot].min_gear): continue
				for power_index: int in range(1, 21):
					var power: float = power_index * 0.05
					if found or power > float(catalog.gear[gear].reach): continue
					for candidate: Dictionary in gen.candidates(catalog, spot, str(baits[0].bait_id), gear, power, "day", "clear"):
						if candidate.fish.species_id == id:
							legal.append({"species":id,"gear":gear,"spot":spot,"region":catalog.spots[spot].region_id,"power":power,"baits":[baits[0].bait_id,baits[1].bait_id]})
							found = true
		_check(not legal.is_empty(), "legal equipment/spot/bait route: " + id)
		# Starter/minimum, strongest legal equipment, spinning and heavy rods
		# where available. Deep-only species retain their legal deep equipment.
		for route: Dictionary in legal:
			if route == legal[0] or route == legal.back() or int(route.gear) in [3,4]: routes.append(route)
	var species: Dictionary = {}
	var gears: Dictionary = {}
	for route: Dictionary in routes:
		species[route.species] = true
		gears[route.gear] = true
	_check(species.size() == 110 and species.size() == catalog.fish_species_count() and not species.has("blue_whale"), "matrix covers all 110 ordinary fish")
	_check(gears.size() == 6, "matrix includes all six equipment types where legal")

func _record(route: Dictionary, seed_value: int, index: int = 0) -> Dictionary:
	var generator: EncounterGenerator = Generator.new(seed_value)
	var record: Dictionary = generator.make_individual(catalog.fish[route.species], route.spot, route.region, route.baits[index % 2], route.gear, "day" if index % 2 == 0 else "dusk", "clear" if index % 4 < 2 else "rain")
	generator.apply_float_presentation(record,catalog,float(route.power))
	return record

func _launch(record: Dictionary, gear: int, seed_value: int) -> FishingSession:
	var s: FishingSession = Session.new(seed_value)
	s.press()
	s.cast(record, catalog.gear[gear])
	return s

func _surface(s: FishingSession) -> Dictionary:
	return {"dip":s.float_dip,"lift":s.float_lift,"drag":s.float_drag,"tilt":s.float_tilt}

func _identity(record: Dictionary, gear: int, seed_value: int) -> Dictionary:
	return {"species":record.species_id,"gear":gear,"bait":record.bait_id,"spot":record.spot_id,"weather":record.weather,"seed":seed_value,"size":record.size_fraction,"difficulty":record.difficulty,"rig":record.float_rig,"water_depth_m":record.water_depth_m,"bait_depth_m":record.bait_depth_m}

func _trial(record: Dictionary, gear: int, seed_value: int, fps: int, mode: String) -> Dictionary:
	var s: FishingSession = _launch(record, gear, seed_value)
	var reader: SurfaceReader = SurfaceReader.new()
	var fight: RefCounted = FightReader.new()
	var delta: float = 1.0 / fps
	var elapsed: float = 0.0
	var pressed: bool = false
	var hooked: bool = false
	var hook_time: float = -1.0
	var first_ready: float = -1.0
	var result: Dictionary = _identity(record, gear, seed_value)
	result.merge({"fps":fps,"strategy":mode,"strike_seconds":-1.0,"strike_can_hook":false,"strike_phase":"","signal":"","motion_seconds":-1.0})
	while elapsed < MAX_WAIT + MAX_FIGHT and s.state not in [Session.State.CAUGHT,Session.State.ESCAPED]:
		if s.state == Session.State.FIGHT:
			var desired: bool = fight.update(s, delta)
			if desired and not s.reeling: s.press()
			elif not desired and s.reeling: s.release()
		else:
			if s.float_encounter.can_hook() and first_ready < 0.0: first_ready = elapsed
			var strike: bool = false
			if mode.begins_with("fixed_"): strike = elapsed + 0.000001 >= float(mode.trim_prefix("fixed_"))
			elif mode == "hidden_oracle": strike = s.float_encounter.can_hook()
			elif mode == "amplitude_only": strike = maxf(s.float_dip,s.float_lift) >= 0.22
			else: strike = reader.update(_surface(s), delta, mode == "earliest_motion")
			if strike and not pressed:
				pressed = true
				result.strike_seconds = elapsed
				result.strike_can_hook = s.float_encounter.can_hook()
				result.strike_phase = s.float_encounter.phase
				result.signal = reader.motion
				result.motion_seconds = reader.detected_at
				s.press()
				hooked = s.state == Session.State.FIGHT
				if hooked:
					hook_time = elapsed
					s.release()
					if skip_fights: break
			if elapsed > MAX_WAIT: break
		s.step(delta)
		elapsed += delta
	result.merge({"hooked":hooked,"caught":s.state == Session.State.CAUGHT,"fight_tested":not skip_fights,"first_ready_seconds":first_ready,"hook_latency_seconds":hook_time-first_ready if hooked else -1.0,"fight_seconds":s.fight_time,"total_seconds":elapsed,"failure":s.escape_reason,"timeout":s.state not in [Session.State.CAUGHT,Session.State.ESCAPED] and not (skip_fights and hooked)})
	return result

func _passive_trace(record: Dictionary, gear: int, seed_value: int) -> Dictionary:
	var s: FishingSession = _launch(record, gear, seed_value)
	var delta: float = 1.0 / 120.0
	var result: Dictionary = _identity(record, gear, seed_value)
	var phase_before: String = ""
	var previous: Dictionary = _surface(s)
	var transitions: Array[Dictionary] = []
	var takes: Array[Dictionary] = []
	var take: Dictionary = {}
	var bins: Dictionary = {"below_0_12":{"ready":0,"not_ready":0},"0_12_to_0_22":{"ready":0,"not_ready":0},"0_22_to_0_45":{"ready":0,"not_ready":0},"above_0_45":{"ready":0,"not_ready":0}}
	var strong_false: float = 0.0
	var max_delta: float = 0.0
	var max_tilt_delta: float = 0.0
	var max_drag: float = 0.0
	var max_drag_delta: float = 0.0
	var phase_peaks: Dictionary = {}
	var contact_pulses: Array[float] = []
	var contact_raised: float = 0.0
	var signatures: Dictionary = {}
	while s.float_clock < MAX_WAIT and s.state != Session.State.ESCAPED:
		s.step(delta)
		if s.state == Session.State.CASTING: continue
		var m: FloatEncounter = s.float_encounter
		if m.phase != phase_before:
			transitions.append({"at":s.float_clock,"phase":m.phase,"attempt":m.attempt,"ready":m.can_hook()})
			phase_before = m.phase
		var amplitude: float = maxf(s.float_dip,s.float_lift)
		phase_peaks[m.phase] = maxf(float(phase_peaks.get(m.phase,0.0)),amplitude)
		if m.phase == "contact" and amplitude >= 0.20:
			contact_raised += delta
		elif contact_raised > 0.0:
			contact_pulses.append(contact_raised)
			contact_raised = 0.0
		var bin_name: String = "below_0_12" if amplitude < 0.12 else "0_12_to_0_22" if amplitude < 0.22 else "0_22_to_0_45" if amplitude < 0.45 else "above_0_45"
		bins[bin_name]["ready" if m.can_hook() else "not_ready"] += 1
		if amplitude >= 0.22 and not m.can_hook(): strong_false += delta
		max_delta = maxf(max_delta,maxf(absf(s.float_dip-float(previous.dip)),absf(s.float_lift-float(previous.lift))))
		max_tilt_delta = maxf(max_tilt_delta,absf(s.float_tilt-float(previous.tilt)))
		max_drag = maxf(max_drag,s.float_drag.length())
		max_drag_delta = maxf(max_drag_delta,s.float_drag.distance_to(previous.drag as Vector2))
		previous = _surface(s)
		if m.can_hook():
			signatures[m.signature] = true
			if take.is_empty(): take = {"start":s.float_clock,"end":0.0,"visible_at":-1.0,"peak":0.0,"signature":m.signature}
			take.peak = maxf(float(take.peak),amplitude)
			if amplitude >= 0.22 and float(take.visible_at) < 0.0: take.visible_at = s.float_clock
		elif not take.is_empty():
			take.end = s.float_clock
			takes.append(take)
			take = {}
	_check(s.state == Session.State.ESCAPED,"ignored cast eventually departs: %s/%s/%s" % [record.species_id,gear,seed_value])
	_check(max_drag <= 0.60,"uninterrupted float remains inside 0.60m tether envelope: %s/%s/%s" % [record.species_id,gear,seed_value])
	_check(max_delta < 0.075 and max_drag_delta < 0.01,"no position teleport during repeats/releases: %s/%s/%s" % [record.species_id,gear,seed_value])
	_check(max_tilt_delta < 0.05,"no tilt sign snap during fish turn or reapproach: %s/%s/%s" % [record.species_id,gear,seed_value])
	result.merge({"departed":s.state == Session.State.ESCAPED,"seconds":s.float_clock,"attempts":s.float_encounter.attempt,"pickups":s.float_encounter.successful_pickups,"rejections":s.float_encounter.rejected_pickups,"transitions":transitions,"takes":takes,"amplitude_bins":bins,"strong_false_seconds":strong_false,"max_vertical_step":max_delta,"max_tilt_step":max_tilt_delta,"max_drag":max_drag,"max_drag_step":max_drag_delta,"phase_peaks":phase_peaks,"contact_pulses_above_0_20_seconds":contact_pulses,"signatures":signatures.keys()})
	return result

func _seed_coverage() -> Dictionary:
	var empty: Array[Dictionary] = []
	var initial_times: Array[float] = []
	var direct: int = 0
	var contact_first: int = 0
	var total: int = 0
	var route: Dictionary = routes[0]
	for index: int in 512:
		var seed_value: int = 330001 + index * 7919
		var trace: Dictionary = _passive_trace(_record(route,seed_value,index),route.gear,seed_value)
		total += 1
		if (trace.takes as Array).is_empty(): empty.append({"seed":seed_value,"attempts":trace.attempts,"seconds":trace.seconds,"transitions":trace.transitions})
		else: initial_times.append(float(trace.takes[0].start))
		var transitions: Array = trace.transitions
		if transitions.size() > 1:
			if str(transitions[1].phase) == "mouth": direct += 1
			elif str(transitions[1].phase) == "contact": contact_first += 1
	_check(not empty.is_empty(),"broad independent seed sweep includes a contact-only cast with no hittable take")
	_check(direct > 0 and contact_first > 0,"broad independent seed sweep includes both direct takes and exploratory starts")
	return {"species":route.species,"gear":route.gear,"casts":total,"no_take_casts":empty,"direct_first_takes":direct,"contact_first_casts":contact_first,"first_take_seconds":initial_times}

func _snapshot(s: FishingSession) -> Array:
	var m: FloatEncounter = s.float_encounter
	return [s.state,s.elapsed,s._accumulator,s._rng.state,s.session_id,s.fight_time,s.tension,s.fish_stamina,s.float_clock,s.float_dip,s.float_lift,s.float_drag,m.rng.state,m.phase,m.age,m.attempt,m.mouth_depth,m.bait_in_mouth,m.hook_ready,m.clock,m.possession_time]

func _regressions() -> void:
	var route: Dictionary = routes[0]
	var record: Dictionary = _record(route,7291)
	# Every pre-hook phase: press agrees with possession; callbacks settle once.
	var phase_samples: Dictionary = {}
	var phase_target: Array[String] = ["approach","contact","mouth","carry","spit","return"]
	for seed_value: int in range(80,100):
		var s: FishingSession = _launch(record,route.gear,seed_value)
		while s.float_clock < MAX_WAIT and s.state != Session.State.ESCAPED:
			s.step(1.0/120.0)
			if s.state in [Session.State.CASTING,Session.State.ESCAPED]: continue
			var key: String = s.float_encounter.phase + ("_ready" if s.float_encounter.can_hook() else "_empty")
			if phase_samples.has(key): continue
			phase_samples[key] = true
			var expected: bool = s.float_encounter.can_hook()
			var before: Array = _snapshot(s)
			s.pause()
			var frozen: Array = _snapshot(s)
			s.press()
			s.step(120.0)
			_check(_snapshot(s) == frozen and not s.reeling, "freeze mouth/load/RNG exactly during " + key)
			s.resume()
			_check(_snapshot(s) == before and not s.reeling, "resume retains same signal/possession during " + key)
			var endings: Array = []
			s.ended.connect(func(ok: bool, result: Dictionary) -> void: endings.append([ok,result]))
			s.press()
			_check((s.state == Session.State.FIGHT) == expected,"fresh strike equals possession during " + key)
			if not expected:
				_check(s.state == Session.State.ESCAPED and endings.size() == 1,"invalid strike is exactly one empty cast during " + key)
				s._finish(true,"late success")
				s.step(120.0)
				_check(endings.size() == 1 and s.state == Session.State.ESCAPED,"invalid cast never later catches during " + key)
			else:
				s.cancel_input()
				_check(s.state == Session.State.FIGHT and not s.reeling,"cancel releases legitimate hook without reroll during " + key)
			break
	for phase_name: String in phase_target:
		_check(phase_samples.has(phase_name+"_empty") or phase_samples.has(phase_name+"_ready"),"exercise real phase " + phase_name)
	_check(phase_samples.has("mouth_empty") and phase_samples.has("mouth_ready"),"exercise both sides of actual seating threshold")
	# A held CASTING input cannot transform itself into a strike.
	var held: FishingSession = _launch(record,route.gear,148)
	held.press()
	for tick: int in 10800:
		held.step(1.0/120.0)
		if held.float_encounter.can_hook(): break
	_check(held.float_encounter.can_hook(),"held-input fixture finds real possession")
	held.press()
	_check(held.state != Session.State.FIGHT and not held.reeling,"repeated held input never auto-hooks")
	held.release()
	held.press()
	_check(held.state == Session.State.FIGHT,"release and fresh edge hooks held bait")
	var old_id: String = held.session_id
	held.reset()
	held._finish(true,"stale")
	_check(held.state == Session.State.IDLE and held.individual.is_empty(),"reset rejects stale success")
	held.press()
	held.cast(record,catalog.gear[route.gear])
	_check(held.session_id != old_id,"new cast has unique session id")
	# Render frame rate changes observation cadence, never the physics trajectory.
	var references: Array = []
	for fps: int in [16,30,60]:
		var s: FishingSession = _launch(record,route.gear,919)
		var trajectory: Array = []
		for second: int in 35:
			for frame: int in fps: s.step(1.0/fps)
			var snap: Array = _snapshot(s)
			snap.remove_at(4) # globally unique ID is deliberately not deterministic
			snap[2] = snappedf(float(snap[2]),0.00000001)
			trajectory.append(snap)
		references.append(trajectory)
	_check(references[0] == references[1] and references[1] == references[2],"16/30/60fps identical full pre-hook trajectory at equal elapsed times")
	var fine: FishingSession = _launch(record,route.gear,330)
	var stalled: FishingSession = _launch(record,route.gear,330)
	for tick: int in 1200: fine.step(1.0/120.0)
	stalled.step(10.0)
	_check(fine.float_encounter.rng.state == stalled.float_encounter.rng.state and fine.float_dip == stalled.float_dip and fine.float_encounter.phase == stalled.float_encounter.phase,"long frame consumes all fixed ticks without reroll")
