extends SceneTree
const Session = preload("res://scripts/fishing_session.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
var checks: int = 0
var failures: int = 0
var catalog: ContentCatalog = Catalog.new()
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL SESSION_OBSERVATION: ", label)
func _record(id: String = "common_carp", size: float = 0.35) -> Dictionary:
	var f: FishDefinition = catalog.fish[id]
	var result: Dictionary = Encounter.new(123).make_individual(f, str(f.spots()[0]), str(f.regions()[0]), "worm", 2, "day", "clear")
	result.size_fraction = size
	result.length_mm = roundi(lerpf(f.min_mm, f.max_mm, size))
	result.weight_g = roundi(f.anchor_g * pow(float(result.length_mm) / f.anchor_mm, 3.0))
	result.difficulty = clampf(f.difficulty * 0.7 + size * 0.5, 0.15, 1.0)
	return result
func _launch(seed_value: int = 431, id: String = "common_carp", size: float = 0.35) -> FishingSession:
	var s: FishingSession = Session.new(seed_value)
	s.press()
	s.cast(_record(id, size), catalog.gear[2])
	return s
func _advance(s: FishingSession, target: int) -> bool:
	for tick: int in 5000:
		if s.state == target: return true
		if s.state in [Session.State.CAUGHT, Session.State.ESCAPED]: return false
		s.step(1.0 / 120.0)
	return false
func _snapshot(s: FishingSession) -> Array:
	return [s.elapsed, s.fight_time, s.fish_stamina, s.fish_distance, s.tension, s.line_wear, s._rng.state, s._accumulator, s.float_dip, s.float_drag, s._phase_time]
func _run() -> void:
	_check(catalog.load_all(false), "catalog loads")
	for target: int in [Session.State.WAITING, Session.State.NIBBLE]:
		var s: FishingSession = _launch()
		var endings: Array = []
		s.ended.connect(func(ok: bool, record: Dictionary) -> void: endings.append([ok, record]))
		_check(_advance(s, target), "reach early-press state")
		s.press()
		_check(s.state == Session.State.ESCAPED and s.escape_reason.begins_with("空竿"), "early press returns empty cast")
		_check(endings.size() == 1 and not endings[0][0], "empty cast emits one failure only")
		s.press()
		s.step(25.0)
		s._finish(true, "duplicate")
		_check(endings.size() == 1, "empty cast cannot later settle")
	var edge: FishingSession = _launch()
	var cues: Array[String] = []
	edge.cue.connect(func(kind: String) -> void: cues.append(kind))
	edge.press() # held throughout CASTING: cannot become a hook when bite arrives
	_check(_advance(edge, Session.State.BITE), "reach bite while old cast press held")
	edge.press()
	_check(edge.state == Session.State.BITE and not edge.reeling, "held/repeated press cannot auto-hook")
	edge.release()
	edge.press()
	_check(edge.state == Session.State.FIGHT and not edge.reeling, "fresh bite edge hooks but does not reel")
	edge.press()
	_check(not edge.reeling, "repeated hook edge cannot reel")
	edge.release()
	edge.press()
	_check(edge.reeling, "fresh post-hook edge reels")
	_check(cues == ["hook"], "nibble and bite have no audio/haptic cues")
	for target: int in [Session.State.WAITING, Session.State.NIBBLE, Session.State.BITE, Session.State.FIGHT]:
		var s: FishingSession = _launch()
		_advance(s, Session.State.BITE if target == Session.State.FIGHT else target)
		if target == Session.State.FIGHT: s.press()
		s.step(0.013)
		s.pause()
		var before: Array = _snapshot(s)
		s.press()
		s.step(120.0)
		s.pause()
		_check(_snapshot(s) == before and not s.reeling, "pause preserves exact simulation including remainder")
		s.resume()
		_check(s.state == target and _snapshot(s) == before and not s.reeling, "resume preserves outcome and clears input")
	var late: FishingSession = _launch()
	_advance(late, Session.State.BITE)
	late.step(5.0)
	_check(late.state == Session.State.ESCAPED, "unobserved bite escapes")
	var old_id: String = late.session_id
	late.reset()
	late._finish(true, "late reset callback")
	_check(late.state == Session.State.IDLE and late.individual.is_empty(), "reset blocks stale completion")
	_check(late.fight_time == 0.0 and late.slack_time == 0.0 and late.overload_time == 0.0 and late.escape_reason.is_empty(), "reset clears previous-round timers and messages")
	late.press()
	late.cast(_record(), catalog.gear[2])
	_check(late.session_id != old_id, "new cast creates a distinct session ID")
	_test_fixed_step()
	_test_float_observation()
	_test_wear_warning()
	print("SESSION_OBSERVATION_TESTS: ", checks-failures, "/", checks, " passed; failures=", failures)
	quit(0 if failures == 0 else 1)
func _test_fixed_step() -> void:
	var snapshots: Array = []
	for fps: int in [16, 30, 60]:
		var s: FishingSession = _launch(149)
		s.set_state(Session.State.FIGHT)
		# Identical input history aligned every half-second at all frame rates.
		for half: int in 6:
			s.release()
			if half % 2 == 0: s.press()
			for frame: int in fps / 2: s.step(1.0 / fps)
		snapshots.append([s.state, s.fight_time, s.tension, s.fish_stamina, s.fish_distance, s._rng.state, s.line_wear])
	_check(snapshots[0] == snapshots[1] and snapshots[1] == snapshots[2], "16/30/60fps identical elapsed physics and random sequence")
	var one: FishingSession = _launch(149)
	var many: FishingSession = _launch(149)
	one.step(2.0)
	for tick: int in 240: many.step(1.0 / 120.0)
	_check(one.state == many.state and is_equal_approx(one.elapsed, many.elapsed) and one._rng.state == many._rng.state, "long frame consumes every second without delta cap")
func _test_float_observation() -> void:
	var patterns: Dictionary = {}
	for id: String in catalog.fish:
		var s: FishingSession = _launch(793, id)
		_advance(s, Session.State.NIBBLE)
		var nibble: float = 0.0
		while s.state == Session.State.NIBBLE:
			s.step(1.0 / 60.0)
			if s.state == Session.State.NIBBLE: nibble = maxf(nibble, maxf(s.float_dip, s.float_lift))
		_check(nibble > 0.12 and nibble < 0.5, "species has restrained but visible nibble: " + id)
		s.step(0.55)
		_check(maxf(s.float_dip, s.float_lift) > 0.45 and s.float_drag.length() > 0.035, "bite is readable from real float movement: " + id)
		patterns["%.3f/%.3f/%.3f" % [s.float_dip, s.float_lift, s.float_drag.length()]] = true
	_check(patterns.size() >= 3, "species traits yield distinct dip/lift/tow patterns")
func _test_wear_warning() -> void:
	var s: FishingSession = _launch()
	s.set_state(Session.State.FIGHT)
	s.line_wear = 0.79
	s._break_threshold = 0.000001
	s._step_line_wear(7.9)
	_check(s.line_warning and s._break_hazard == 0.0, "wear warning precedes any line-break hazard by at least eight seconds")
	s._step_line_wear(0.2)
	_check(s._break_hazard > 0.0, "warned worn line eventually has elapsed-time break risk")
	var slow: FishingSession = _launch(719)
	var fast: FishingSession = _launch(719)
	slow.line_wear = 0.80
	fast.line_wear = 0.80
	for i: int in 160: slow._step_line_wear(1.0 / 16.0)
	for i: int in 600: fast._step_line_wear(1.0 / 60.0)
	_check(absf(slow._break_hazard - fast._break_hazard) < 0.001, "elapsed-time wear hazard is independent of render frequency")
