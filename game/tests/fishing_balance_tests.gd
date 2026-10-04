extends SceneTree
## Independent simulations of the actual FishingSession at multiple input rates.
## No wall-clock sleeps, gameplay-formula clone, production save, or scene load.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Controller = preload("res://tests/fishing_test_controller.gd")
const STRATEGIES: Array[String] = ["always_pull", "never_pull", "metronome", "tension_only", "behavior_aware"]
const MAX_FIGHT_SECONDS: float = 420.0
var catalog: ContentCatalog = Catalog.new()
var checks: int = 0
var failed: Array[String] = []
var routes: Array[Dictionary] = []
var runs: Array[Dictionary] = []
var properties: Dictionary = {}
var quick: bool = false
var float_cases: Array[Dictionary] = []
var wear_cases: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed.append(message)
		printerr("FAIL FISHING BALANCE: ", message)

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	quick = "--quick" in args
	var output: String = ""
	for arg: String in args:
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	_check(not output.is_empty(), "explicit output path provided")
	_check(catalog.load_all(false), "actual catalog loads")
	for property: Dictionary in Session.new().get_property_list(): properties[str(property.name)] = true
	_build_routes()
	_regressions()
	if "--regressions-only" not in args:
		_matrix()
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("FAIL: cannot write evidence output ", output)
		quit(2)
		return
	file.store_string(JSON.stringify({"scope": "Quick 30fps grid" if quick else "All legal species/gear routes; min/mid/max endpoints; 16/30/60 fps; paired seeds; independently sampled random individuals", "legal_routes": routes, "float_cases": float_cases, "wear_cases": wear_cases, "regressions": {"checks": checks, "failed": failed}, "runs": runs}, "\t"))
	file.close()
	print("FISHING_BALANCE_TESTS: ", checks-failed.size(), "/", checks, "; simulations=", runs.size(), "; legal_routes=", routes.size())
	quit(0 if failed.is_empty() else 1)

func _build_routes() -> void:
	var generator: EncounterGenerator = Encounter.new(8142)
	var found: Dictionary = {}
	for spot_id: String in catalog.spots:
		var spot: Dictionary = catalog.spots[spot_id]
		for gear_id: int in catalog.gear.size():
			if gear_id < int(spot.min_gear): continue
			for fraction_index: int in range(1, 21):
				var cast_power: float = fraction_index * 0.05
				if cast_power > float(catalog.gear[gear_id].reach): continue
				for bait: Dictionary in catalog.baits:
					for time: String in ["day", "dusk"]:
						for weather: String in ["clear", "rain"]:
							for candidate: Dictionary in generator.candidates(catalog, spot_id, str(bait.bait_id), gear_id, cast_power, time, weather):
								var fish: FishDefinition = candidate.fish
								var key: String = "%s/%d" % [fish.species_id, gear_id]
								if not found.has(key):
									found[key] = true
									routes.append({"species": fish.species_id, "gear": gear_id, "spot": spot_id, "region": spot.region_id, "bait": bait.bait_id, "cast_power": cast_power, "time": time, "weather": weather})
	var seen: Dictionary = {}
	for route: Dictionary in routes: seen[route.species] = true
	_check(seen.size() == 74, "74 species have legal candidate routes")

func _specimen(route: Dictionary, seed_value: int, fraction: float = -1.0) -> Dictionary:
	var fish: FishDefinition = catalog.fish[route.species]
	var record: Dictionary = Encounter.new(seed_value).make_individual(fish, route.spot, route.region, route.bait, route.gear, route.time, route.weather)
	if fraction >= 0.0:
		# Boundary-value fixtures based on authoritative catalog size/weight anchors.
		# Random matrix below leaves the generated record completely untouched.
		record.size_fraction = fraction
		record.length_mm = roundi(lerpf(fish.min_mm, fish.max_mm, fraction))
		record.weight_g = maxi(1, roundi(fish.anchor_g * pow(float(record.length_mm) / fish.anchor_mm, 3.0)))
		record.difficulty = clampf(fish.difficulty * 0.7 + fraction * 0.5, 0.15, 1.0)
		record.size_class = "巨物" if fraction > 0.88 else ("小巧" if fraction < 0.18 else "标准")
	return record

func _route(id: String, gear: int = -1) -> Dictionary:
	for route: Dictionary in routes:
		if route.species == id and (gear < 0 or gear == route.gear): return route
	return {}

func _launch(record: Dictionary, gear_id: int, seed_value: int) -> FishingSession:
	var session: FishingSession = Session.new()
	session._rng.seed = seed_value
	session.press()
	session.step(0.2)
	if not session.cast(record, catalog.gear[gear_id]):
		_check(false, "generated record can cast")
	session.release()
	return session

func _advance(session: FishingSession, target: int, fps: int = 60) -> bool:
	for tick: int in int(40.0 * fps):
		if session.state == target: return true
		if session.state in [Session.State.CAUGHT, Session.State.ESCAPED]: return false
		session.step(1.0 / fps)
	return session.state == target

func _matrix() -> void:
	var frame_rates: Array = [30] if quick else [16, 30, 60]
	var seeds: Array = [101] if quick else [101, 7703]
	for route_index: int in routes.size():
		var route: Dictionary = routes[route_index]
		for size_index: int in 3:
			var fraction: float = [0.0, 0.5, 1.0][size_index]
			for seed_value: int in seeds:
				var record: Dictionary = _specimen(route, seed_value, fraction)
				for fps: int in frame_rates:
					for strategy: String in STRATEGIES:
						runs.append(_simulate(record, route, seed_value, fps, strategy, ["min", "mid", "max"][size_index], "boundary"))
		if route_index % 20 == 0: print("BALANCE PROGRESS routes=", route_index+1, "/", routes.size(), " runs=", runs.size())
	# Actual encounter records and independent session seeds catch interior-size
	# behavior missed by the deterministic endpoints. Stable seeds reproduce bugs.
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 972431
	for index: int in (88 if quick else 440):
		var route: Dictionary = routes[random.randi_range(0, routes.size()-1)]
		var specimen_seed: int = random.randi()
		var session_seed: int = random.randi()
		var record: Dictionary = _specimen(route, specimen_seed)
		for strategy: String in STRATEGIES:
			runs.append(_simulate(record, route, session_seed, 30, strategy, "random", "random"))

func _simulate(record: Dictionary, route: Dictionary, seed_value: int, fps: int, strategy: String, size_label: String, sample: String) -> Dictionary:
	var session: FishingSession = _launch(record, route.gear, seed_value)
	var ended: Array[bool] = []
	session.ended.connect(func(caught: bool, _record: Dictionary) -> void: ended.append(caught))
	# Isolate battle policies: everybody is given the same legitimate, correctly
	# timed visual strike rather than hiding battle weakness in early-hook failures.
	var reached_bite: bool = _advance(session, Session.State.BITE, fps)
	if reached_bite:
		session.step(0.22)
		session.press()
	session.release()
	var controller: RefCounted = Controller.new(strategy)
	var dt: float = 1.0 / fps
	var maximum_tension: float = session.tension
	var warning_time: float = -1.0
	var phases: Dictionary = {}
	for tick: int in int(MAX_FIGHT_SECONDS * fps):
		if session.state != Session.State.FIGHT: break
		_apply_control(session, controller.update(session, dt))
		session.step(dt)
		maximum_tension = maxf(maximum_tension, session.tension)
		phases[session.behavior_phase] = true
		if warning_time < 0.0 and properties.has("line_warning") and bool(session.get("line_warning")): warning_time = session.fight_time
	var reason: String = session.escape_reason
	if session.state == Session.State.FIGHT: reason = "timeout"
	return {"species": record.species_id, "gear": route.gear, "size": size_label, "fraction": record.size_fraction, "weight_g": record.weight_g, "seed": seed_value, "fps": fps, "strategy": strategy, "sample": sample, "behavior": record.behavior, "caught": session.state == Session.State.CAUGHT, "failure": "" if session.state == Session.State.CAUGHT else reason, "fight_seconds": snappedf(session.fight_time, 0.001), "max_tension": snappedf(maximum_tension, 0.001), "phase_count": phases.size(), "warning_time": snappedf(warning_time, 0.001), "warning_lead": snappedf(session.fight_time-warning_time, 0.001) if warning_time >= 0.0 else -1.0, "terminal_events": ended.size()}

func _apply_control(session: FishingSession, held: bool) -> void:
	if held and not session.reeling: session.press()
	elif not held and session.reeling: session.release()

func _snapshot(session: FishingSession) -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["elapsed", "charge", "tension", "progress", "fight_time", "slack_time", "overload_time", "wait_duration", "session_id", "float_dip", "float_lift", "float_tilt", "float_drag", "fish_stamina", "stamina", "line_wear", "line_warning", "fight_phase", "surge_warning", "surge_strength", "unloading_time"]:
		if properties.has(key): result[key] = session.get(key)
	result["rng_state"] = session._rng.state
	result["individual"] = session.individual.duplicate(true)
	return result

func _regressions() -> void:
	var route: Dictionary = _route("common_carp")
	var record: Dictionary = _specimen(route, 912, 0.5)
	for water_state: int in [Session.State.WAITING, Session.State.NIBBLE]:
		var early: FishingSession = _launch(record, route.gear, 772)
		_check(_advance(early, water_state), "reaches early-strike state " + str(water_state))
		var events: Array[bool] = []
		early.ended.connect(func(ok: bool, _record: Dictionary) -> void: events.append(ok))
		early.press()
		_check(early.state in [Session.State.ESCAPED, Session.State.IDLE], "early reel causes empty cast from water state " + str(water_state))
		for tick: int in 100:
			early.press()
			early.step(0.1)
		_check(not true in events and events.size() <= 1, "held early reel cannot later auto-hook or duplicate ending")
	var missed: FishingSession = _launch(record, route.gear, 221)
	_check(_advance(missed, Session.State.ESCAPED), "unstruck bite eventually misses")
	_check(missed.fight_time == 0.0, "late miss cannot become a fight")
	var cues: Array[String] = []
	var quiet: FishingSession = _launch(record, route.gear, 122)
	quiet.cue.connect(func(kind: String) -> void: cues.append(kind))
	_check(_advance(quiet, Session.State.BITE), "quiet waiting still reaches a real bite")
	_check(not "bite" in cues and not "nibble" in cues, "no nibble/bite audio event giveaway")
	for target: int in [Session.State.CASTING, Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.FIGHT]:
		var session: FishingSession = _launch(record, route.gear, 191)
		if target == Session.State.FIGHT:
			_advance(session, Session.State.BITE)
			session.press()
		else: _advance(session, target)
		var frozen: Dictionary = _snapshot(session)
		session.pause()
		for tick: int in 400:
			session.step(0.25)
			session.press()
		_check(session.state == Session.State.PAUSED and not session.reeling, "pause ignores held input " + str(target))
		_check(_snapshot(session) == frozen, "pause freezes RNG, float, stamina, timers " + str(target))
		session.pause()
		session.resume()
		_check(session.state == target and not session.reeling and _snapshot(session) == frozen, "resume restores exact paused state " + str(target))
		session.cancel_input()
		_check(not session.reeling, "background cancellation clears reel " + str(target))
		session.reset()
		_check(session.state == Session.State.IDLE and session.individual.is_empty() and not session.reeling, "reset abandons round cleanly " + str(target))
	var charge: FishingSession = Session.new()
	charge.press()
	charge.step(0.3)
	charge.cancel_input()
	_check(charge.state == Session.State.IDLE and not charge.cast(record, catalog.gear[route.gear]), "cancelled charge cannot cast on late release")
	# Full delta must be consumed, including 16fps calls longer than old 0.05 cap.
	var elapsed_values: Array[float] = []
	for fps: int in [16, 30, 60]:
		var clock_session: FishingSession = Session.new()
		clock_session.press()
		for tick: int in fps: clock_session.step(1.0/fps)
		elapsed_values.append(clock_session.elapsed)
	_check(absf(elapsed_values.max()-elapsed_values.min()) < 0.002 and absf(elapsed_values[0]-1.0) < 0.002, "16/30/60fps consume the same actual elapsed second")
	_terminal_regressions(route, record)
	_input_edge_regressions(route, record)
	_float_regressions(route, record)
	_wear_regressions()
	_fixed_step_regressions(route, record)

func _terminal_regressions(route: Dictionary, record: Dictionary) -> void:
	var session: FishingSession = _launch(record, route.gear, 288)
	var endings: Array[Dictionary] = []
	session.ended.connect(func(ok: bool, result: Dictionary) -> void: endings.append({"ok": ok, "record": result}))
	_advance(session, Session.State.BITE)
	session.press()
	session.release()
	var controller: RefCounted = Controller.new("behavior_aware")
	for tick: int in 24000:
		if session.state != Session.State.FIGHT: break
		_apply_control(session, controller.update(session, 1.0/60.0))
		session.step(1.0/60.0)
	_check(session.state == Session.State.CAUGHT and endings.size() == 1, "reactive real round catches with one event")
	var catch_id: String = str(session.individual.get("catch_id", ""))
	_check(not catch_id.is_empty() and str(session.individual.get("session_id", "")) == session.session_id, "catch identity linked to cast session")
	for tick: int in 100:
		session.press()
		session.release()
		session.step(1.0)
	session._finish(false, "duplicate")
	session._finish(true, "duplicate")
	_check(endings.size() == 1 and str(session.individual.get("catch_id", "")) == catch_id, "repeated input and finish cannot mutate or duplicate terminal catch")
	session.reset()
	session.press()
	session.cast(record, catalog.gear[route.gear])
	session.release()
	_check(str(session.individual.get("catch_id", "")) != catch_id, "next cast has a distinct catch ID")

func _input_edge_regressions(route: Dictionary, record: Dictionary) -> void:
	var session: FishingSession = _launch(record, route.gear, 402)
	_advance(session, Session.State.BITE)
	var hooks: Array[String] = []
	session.cue.connect(func(kind: String) -> void: hooks.append(kind))
	session.press()
	_check(session.state == Session.State.FIGHT, "fresh bite press hooks")
	var before: String = session.session_id
	for tick: int in 100: session.press()
	_check(hooks.count("hook") == 1 and session.session_id == before, "held/repeated press cannot perform multiple hook edges")
	session.release()
	_check(not session.reeling, "release clears reel immediately")

func _float_regressions(_route_value: Dictionary, _record: Dictionary) -> void:
	for key: String in ["float_dip", "float_lift", "float_tilt", "float_drag"]:
		_check(properties.has(key), "observable float contract includes " + key)
	var frame_rates: Array = [30] if quick else [16, 30, 60]
	var false_strikes: int = 0
	var missed_strikes: int = 0
	var signatures: Dictionary = {}
	for species: String in catalog.fish:
		var route: Dictionary = _route(species)
		for seed_value: int in [372, 991]:
			for fps: int in frame_rates:
				var session: FishingSession = _launch(_specimen(route, seed_value, 0.5), route.gear, seed_value)
				var sampled: float = 0.0
				var observed_at: float = -1.0
				var sustained: float = 0.0
				var max_nibble_dip: float = 0.0
				var max_nibble_lift: float = 0.0
				var cues: Array[String] = []
				session.cue.connect(func(kind: String) -> void: cues.append(kind))
				for tick: int in int(20.0*fps):
					# A human sees sustained dip/lift/drag, not the hidden state.
					var takes: bool = session.float_dip >= 0.48 or session.float_lift >= 0.32 or session.float_drag.length() >= 0.24
					sustained = sustained + 1.0/fps if takes else 0.0
					if sustained >= 0.10 and observed_at < 0.0: observed_at = sampled
					if observed_at >= 0.0 and sampled-observed_at >= 0.20:
						if session.state != Session.State.BITE: false_strikes += 1
						session.press()
						break
					if session.state == Session.State.ESCAPED: break
					if session.state == Session.State.NIBBLE:
						max_nibble_dip = maxf(max_nibble_dip, session.float_dip)
						max_nibble_lift = maxf(max_nibble_lift, session.float_lift)
					session.step(1.0/fps)
					sampled += 1.0/fps
				if session.state != Session.State.FIGHT: missed_strikes += 1
				_check(not "bite" in cues and not "nibble" in cues, "no audio bite giveaway " + species + "/" + str(fps))
				signatures["%.2f/%.2f" % [max_nibble_dip, max_nibble_lift]] = true
				float_cases.append({"species": species, "seed": seed_value, "fps": fps, "hooked_from_float": session.state == Session.State.FIGHT, "visual_detection_seconds": snappedf(observed_at, 0.001), "nibble_max_dip": snappedf(max_nibble_dip, 0.001), "nibble_max_lift": snappedf(max_nibble_lift, 0.001)})
	_check(false_strikes == 0, "sustained visible-float detector never mistakes nibble for bite: " + str(false_strikes))
	_check(missed_strikes == 0, "200ms-latency visible-float detector hooks every species: " + str(missed_strikes))
	_check(signatures.size() >= 5, "float motion has visibly distinct species/seed patterns")

func _wear_regressions() -> void:
	var route: Dictionary = _route("common_carp", 4)
	var record: Dictionary = _specimen(route, 872, 1.0)
	var broken: int = 0
	var early_breaks: int = 0
	for seed_value: int in range(16):
		var session: FishingSession = _launch(record, 4, seed_value)
		_advance(session, Session.State.BITE)
		session.press()
		session.release()
		var first_warning: float = -1.0
		# Deliberately low-pressure, non-landing stalemate. Every change is an
		# actual input edge, never a fabricated wear value or forced RNG result.
		while session.state == Session.State.FIGHT and session.fight_time < 500.0:
			var pull: bool = session.reeling
			if session.surge_warning >= 0.15 or session.surge_strength >= 0.08: pull = session.tension < 0.08
			elif session.tension < 0.11: pull = true
			elif session.tension > 0.16: pull = false
			_apply_control(session, pull)
			session.step(1.0/60.0)
			if session.line_warning and first_warning < 0.0: first_warning = session.fight_time
		var wear_break: bool = "磨损" in session.escape_reason
		if wear_break: broken += 1
		if wear_break and first_warning >= 0.0 and session.fight_time-first_warning <= 30.0: early_breaks += 1
		_check(not wear_break or first_warning >= 0.0 and session.fight_time-first_warning >= 8.0, "wear break has >=8 seconds of visible warning seed="+str(seed_value))
		wear_cases.append({"seed": seed_value, "warning_at": snappedf(first_warning, 0.001), "fight_seconds": snappedf(session.fight_time, 0.001), "wear_break": wear_break, "ongoing_at_horizon": session.state == Session.State.FIGHT, "line_wear": session.line_wear, "reason": session.escape_reason, "warning_lead": snappedf(session.fight_time-first_warning, 0.001) if first_warning >= 0 else -1.0})
	_check(broken > 0 and early_breaks > 0 and early_breaks < 8, "natural stale wear is occasional within30s of warning, never guaranteed immediately")

func _fixed_step_regressions(route: Dictionary, record: Dictionary) -> void:
	var endpoints: Array[Dictionary] = []
	for fps: int in [16, 30, 60]:
		var session: FishingSession = _launch(record, route.gear, 17011)
		_advance(session, Session.State.BITE, fps)
		session.press()
		session.release()
		# Clock-aligned input edges fall exactly on every tested frame rate.
		for second: int in 3:
			if second % 2 == 0: session.press()
			else: session.release()
			for tick: int in fps: session.step(1.0/fps)
		endpoints.append({"fight_time": session.fight_time, "tension": session.tension, "distance": session.fish_distance, "stamina": session.fish_stamina, "rng": session._rng.state, "wear": session.line_wear})
	for key: String in endpoints[0]:
		_check(endpoints[0][key] == endpoints[1][key] and endpoints[1][key] == endpoints[2][key], "identical elapsed input yields frame-invariant physics/RNG " + key)
