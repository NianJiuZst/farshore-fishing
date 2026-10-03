class_name FishingSession
extends RefCounted
## Authoritative, seedable session. Presentation reads the float and fight values;
## it must never turn the hidden NIBBLE/BITE states into a button/camera cue.
signal changed(state: int)
signal ended(success: bool, record: Dictionary)
signal cue(kind: String)
enum State { IDLE, CHARGING, CASTING, WAITING, NIBBLE, BITE, FIGHT, CAUGHT, ESCAPED, PAUSED }
const FloatModel = preload("res://scripts/float_encounter.gd")
const FIXED_STEP: float = 1.0 / 120.0
var state: int = State.IDLE
var before_pause: int = State.IDLE
var session_id: String = ""
var individual: Dictionary = {}
var charge: float = 0.0
var tension: float = 0.35
var progress: float = 0.0
var reeling: bool = false
var elapsed: float = 0.0
var fight_time: float = 0.0
var wait_duration: float = 0.0 # Diagnostic first approach only; never a hook window.
var slack_time: float = 0.0
var overload_time: float = 0.0
var gear_power: float = 1.0
var tolerance: float = 1.0
var behavior_phase: String = "平稳游动"
var escape_reason: String = ""
# Continuous surface observations, available before the fish is hooked.
var float_dip: float = 0.0
var float_lift: float = 0.0
var float_drag: Vector2 = Vector2.ZERO
var float_tilt: float = 0.0
var float_activity: float = 0.0
var float_water_height: float = 0.0
var float_current: Vector2 = Vector2.ZERO
var float_clock: float = 0.0
var float_encounter: FloatEncounter = FloatModel.new()
# Normalized fish energy/distance and physically signalled fight state.
var fish_stamina: float = 1.0
var fatigue: float = 0.0
var fish_distance: float = 1.0
var fight_phase: String = "recovery"
var phase_progress: float = 0.0
var surge_strength: float = 0.0
var surge_warning: float = 0.0
var line_wear: float = 0.0
var line_warning: bool = false
var unloading_time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _terminal: bool = true
var _serial: int = 0
var _pressed: bool = false
var _accumulator: float = 0.0
var _surface_time: float = 0.0
var _behavior: String = "steady"
var _difficulty: float = 0.4
var _size: float = 0.3
var _giant: float = 0.0
var _species_trait: float = 0.5
var _endurance: float = 20.0
var _phase_time: float = 0.0
var _phase_duration: float = 2.0
var _cycle_force: float = 0.5
var _brace: float = 0.0
var _surge_brace: float = 0.0
var _wear_warning_time: float = 0.0
var _break_hazard: float = 0.0
var _break_threshold: float = 1.0
var _stall_time: float = 0.0
var _control_window_time: float = 0.0
var _control_window_start: float = 0.0
var _control_stalling: bool = false

func _init(fixed_seed: int = -1) -> void:
	set_seed(fixed_seed)

func set_seed(fixed_seed: int) -> void:
	if fixed_seed < 0: _rng.randomize()
	else: _rng.seed = fixed_seed

func set_state(value: int) -> void:
	if state == value: return
	state = value
	elapsed = 0.0
	if value == State.FIGHT: _begin_fight()
	changed.emit(state)

func start_charge() -> void:
	if state != State.IDLE: return
	charge = 0.0
	set_state(State.CHARGING)

func cast(fish: Dictionary, equipment: Dictionary) -> bool:
	if state != State.CHARGING: return false
	_pressed = false # A cast is the release of the charging gesture.
	reeling = false
	if fish.is_empty():
		set_state(State.IDLE)
		return false
	_serial += 1
	session_id = "%s-%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), get_instance_id(), _serial]
	individual = fish.duplicate(true)
	individual["session_id"] = session_id
	individual["catch_id"] = session_id + ":catch"
	_terminal = false
	gear_power = clampf(float(equipment.get("power", 1.0)), 0.5, 2.0)
	tolerance = clampf(float(equipment.get("tolerance", 1.0)), 0.5, 2.0)
	_behavior = str(individual.get("behavior", "steady"))
	_difficulty = clampf(float(individual.get("difficulty", 0.4)), 0.0, 1.0)
	_size = clampf(float(individual.get("size_fraction", 0.3)), 0.0, 1.0)
	# Relative trophy size matters even for a small species; physically massive
	# fish also carry endurance. Neither rarity nor a species name grants a win.
	_giant = maxf(clampf((_size - 0.80) / 0.20, 0.0, 1.0), clampf((float(individual.get("weight_g", 0)) - 12000.0) / 40000.0, 0.0, 1.0))
	_species_trait = float(absi(str(individual.get("species_id", "fish")).hash()) % 997) / 996.0
	_endurance = (11.0 + 10.0 * _difficulty + 8.0 * _size + 48.0 * _giant) * lerpf(0.93, 1.08, _species_trait)
	_surface_time = 0.0
	float_encounter.configure(individual, _rng.randi())
	wait_duration = float_encounter.first_approach_seconds
	_accumulator = 0.0
	tension = 0.34
	progress = 0.0
	fish_stamina = 1.0
	fatigue = 0.0
	fish_distance = 1.0
	slack_time = 0.0
	overload_time = 0.0
	unloading_time = 0.0
	fight_time = 0.0
	line_wear = 0.0
	line_warning = false
	_wear_warning_time = 0.0
	_break_hazard = 0.0
	# One exponentially distributed threshold; hazard integrates real elapsed
	# time instead of making a new random roll per rendered frame.
	_break_threshold = -log(maxf(0.000001, 1.0 - _rng.randf()))
	_stall_time = 0.0
	_control_window_time = 0.0
	_control_window_start = 0.0
	_control_stalling = false
	_brace = 0.0
	_surge_reset()
	escape_reason = ""
	_reset_float()
	set_state(State.CASTING)
	cue.emit("cast")
	return true

func press() -> void:
	if state == State.PAUSED or _pressed: return
	_pressed = true
	match state:
		State.IDLE: start_charge()
		State.WAITING, State.NIBBLE, State.BITE:
			# The hook's physical occupation of the mouth determines success.
			# No elapsed-window lookup or success roll happens at this input edge.
			if not float_encounter.can_hook():
				_finish(false, "空竿收回，钩饵没有留在鱼嘴里。留意浮漂偏离水面节奏后的持续变化")
				return
			reeling = false
			set_state(State.FIGHT)
			if state == State.FIGHT and _pressed: reeling = true
			cue.emit("hook")
		State.FIGHT: reeling = true

func release() -> void:
	_pressed = false
	reeling = false

func cancel_input() -> void:
	release()
	if state == State.CHARGING: set_state(State.IDLE)

func pause() -> void:
	if state == State.PAUSED: return
	cancel_input()
	before_pause = state
	state = State.PAUSED
	changed.emit(state)

func resume() -> void:
	if state != State.PAUSED: return
	release()
	state = before_pause
	changed.emit(state)

func reset() -> void:
	release()
	_terminal = true # Late callbacks cannot settle an abandoned/reset round.
	individual = {}
	session_id = ""
	before_pause = State.IDLE
	_accumulator = 0.0
	elapsed = 0.0
	charge = 0.0
	tension = 0.34
	fight_time = 0.0
	slack_time = 0.0
	overload_time = 0.0
	unloading_time = 0.0
	escape_reason = ""
	behavior_phase = "平稳游动"
	fish_stamina = 1.0
	fatigue = 0.0
	fish_distance = 1.0
	progress = 0.0
	line_wear = 0.0
	line_warning = false
	_surge_reset()
	_reset_float()
	set_state(State.IDLE)

func step(delta: float) -> void:
	if state in [State.PAUSED, State.IDLE, State.CAUGHT, State.ESCAPED]: return
	if not is_finite(delta) or delta <= 0.0: return
	# Preserve every elapsed second, including 16fps and occasional long frames.
	# The remainder survives pause/resume, so pausing never changes RNG/physics.
	_accumulator += delta
	while _accumulator + 0.000000001 >= FIXED_STEP:
		_accumulator -= FIXED_STEP
		_step_fixed(FIXED_STEP)
		if state in [State.IDLE, State.PAUSED, State.CAUGHT, State.ESCAPED]:
			_accumulator = maxf(0.0, _accumulator)
			break

func _step_fixed(delta: float) -> void:
	elapsed += delta
	match state:
		State.CHARGING:
			charge = minf(1.0, charge + delta * 0.48)
		State.CASTING:
			if elapsed >= 0.85: set_state(State.WAITING)
		State.WAITING, State.NIBBLE, State.BITE:
			_surface_time += delta
			float_encounter.step(delta)
			_update_float()
			if float_encounter.departed:
				_finish(false, "浮漂恢复了原来的水线，鱼已松口离开。可以重新抛竿")
			elif float_encounter.can_hook(): set_state(State.BITE)
			elif float_encounter.is_contacting(): set_state(State.NIBBLE)
			else: set_state(State.WAITING)
		State.FIGHT:
			_step_fight(delta)

func _reset_float() -> void:
	float_dip = 0.0
	float_lift = 0.0
	float_drag = Vector2.ZERO
	float_tilt = 0.0
	float_activity = 0.0
	float_water_height = 0.0
	float_current = Vector2.ZERO
	float_clock = 0.0

func _update_float() -> void:
	float_dip = float_encounter.dip
	float_lift = float_encounter.lift
	float_drag = float_encounter.drag
	float_tilt = float_encounter.tilt
	float_activity = float_encounter.activity
	float_water_height = float_encounter.water_height
	float_current = float_encounter.current
	float_clock = float_encounter.clock

func _surge_reset() -> void:
	surge_strength = 0.0
	surge_warning = 0.0
	phase_progress = 0.0
	fight_phase = "recovery"

func _begin_fight() -> void:
	reeling = false
	_set_phase("recovery", _rng.randf_range(1.4, 2.1))

func _set_phase(value: String, duration: float) -> void:
	fight_phase = value
	_phase_time = 0.0
	_phase_duration = duration
	phase_progress = 0.0
	surge_warning = 0.0
	surge_strength = 0.0
	match value:
		"cruise": behavior_phase = "沉稳游动" if _behavior == "steady" else "贴底游动" if _behavior == "rest" else "侧身游动"
		"windup":
			behavior_phase = "鱼身转向，水纹收紧"
			_brace = 0.0
			_cycle_force = _rng.randf_range(0.78, 1.18) * (0.55 + _difficulty * 0.30 + _giant * 0.18)
		"surge":
			behavior_phase = "连续冲刺" if _behavior == "burst" else "沉底猛拽" if _behavior == "rest" else "摆尾拉扯"
			_surge_brace = _brace
		"recovery": behavior_phase = "冲势放缓" if _behavior == "burst" else "短暂歇息" if _behavior == "rest" else "转向回游"

func _next_phase() -> void:
	match fight_phase:
		"recovery": _set_phase("cruise", _rng.randf_range(1.0, 2.5) * (1.35 if _behavior == "steady" else 0.8 if _behavior == "burst" else 1.0))
		"cruise": _set_phase("windup", _rng.randf_range(0.68, 0.98))
		"windup": _set_phase("surge", _rng.randf_range(0.85, 1.45) * (1.35 if _behavior == "steady" else 1.1 if _behavior == "rest" else 1.0))
		"surge": _set_phase("recovery", _rng.randf_range(1.7, 2.8) * (1.35 if _behavior == "rest" else 0.9 if _behavior == "burst" else 1.0))

func _step_fight(delta: float) -> void:
	fight_time += delta
	_phase_time += delta
	if _phase_time >= _phase_duration: _next_phase()
	phase_progress = clampf(_phase_time / _phase_duration, 0.0, 1.0)
	surge_warning = smoothstep(0.0, 0.75, phase_progress) if fight_phase == "windup" else 0.0
	surge_strength = clampf(_cycle_force * (0.5 + 0.5 * sin(phase_progress * PI)), 0.0, 1.0) if fight_phase == "surge" else 0.0
	if fight_phase == "windup":
		_brace = clampf(_brace + delta * (-3.0 if reeling else 1.8), 0.0, 1.0)
	var forgiveness: float = pow(tolerance, 0.55)
	var power: float = pow(gear_power, 0.65)
	var force: float = (0.105 + _difficulty * 0.065) * (0.60 + fish_stamina * 0.40)
	var tension_rate: float = (0.095 + force) / forgiveness if reeling else -0.235
	if fight_phase == "recovery": tension_rate *= 0.80 if reeling else 1.0
	elif fight_phase == "windup": tension_rate += 0.035 * surge_warning
	elif fight_phase == "surge":
		# A visible windup gives time to lower the rod. Releasing only after the
		# meter spikes does not absorb the whole surge; strength gear helps but
		# cannot erase the consequences of pulling straight against a fresh fish.
		tension_rate += surge_strength * (0.62 if reeling else lerpf(0.56, 0.19, _surge_brace)) / forgiveness
	tension = clampf(tension + tension_rate * delta, 0.0, 1.18)
	var pressure: float = clampf((tension - 0.10) / 0.26, 0.0, 1.0)
	if reeling:
		unloading_time = 0.0
		var effort: float = (0.98 + power * 0.12) * pressure
		if fight_phase == "surge": effort *= 0.60
		fish_stamina = maxf(0.0, fish_stamina - delta * effort / _endurance)
		var retrieve: float = 0.092 * power * (0.20 + fatigue * 0.80) * pressure
		if fight_phase == "surge": retrieve *= 0.12
		fish_distance -= delta * retrieve
	else:
		unloading_time += delta
		if fight_phase == "surge":
			fish_stamina = maxf(0.0, fish_stamina - delta * (0.65 + 0.35 * _surge_brace) / _endurance)
			fish_distance += delta * (0.019 + _giant * 0.012)
		else:
			fish_stamina = minf(1.0, fish_stamina + delta * 0.10 / _endurance)
			fish_distance += delta * (0.007 + maxf(0.0, unloading_time - 1.5) * 0.016)
	fatigue = 1.0 - fish_stamina
	# A strong fish can come closer but cannot be dragged through a landing gate
	# while still fresh. Distance AND exhaustion determine the actual landing.
	fish_distance = clampf(maxf(fish_distance, fish_stamina * 0.48 - 0.015), 0.0, 1.0)
	progress = 1.0 - fish_distance
	if tension > 0.96:
		overload_time += delta * (1.0 + surge_strength * 0.8)
	else: overload_time = maxf(0.0, overload_time - delta * 1.8)
	if tension < 0.075: slack_time += delta
	else: slack_time = maxf(0.0, slack_time - delta * 1.5)
	_step_line_wear(delta)
	if overload_time > 0.62 * forgiveness:
		_finish(false, "迎着冲势猛拉，鱼线绷断了。留意鱼身转向和竿梢蓄力")
	elif slack_time > 2.15 or unloading_time > 4.4 + _giant * 0.5:
		_finish(false, "松手太久，鱼带着松线挣脱了")
	elif line_wear > 0.78 and _wear_warning_time >= 8.0 and _break_hazard >= _break_threshold:
		_finish(false, "僵持后的鱼线磨损越来越重，终于断开了")
	elif fish_distance <= 0.001 and fish_stamina <= 0.025:
		progress = 1.0
		_finish(true, "")

func _step_line_wear(delta: float) -> void:
	var control: float = fatigue * 0.65 + progress * 0.35
	_control_window_time += delta
	if _control_window_time >= 10.0:
		_control_stalling = control - _control_window_start < 0.025
		_control_window_start = control
		_control_window_time -= 10.0
		if not _control_stalling: _stall_time = 0.0
	if _control_stalling: _stall_time += delta
	# Ten-second progress windows distinguish a genuinely prolonged stalemate
	# from an actively tiring giant; tiny periodic gains cannot reset wear forever.
	# Slowly accumulating strain; ordinary, active fights remain well below the
	# warning. Stalling and repeated high-load pulls wear the same physical line.
	var wear_rate: float = 0.0008
	if tension > 0.80 and reeling: wear_rate += (tension - 0.80) * 0.10
	if fight_phase == "surge" and reeling: wear_rate += 0.010 * surge_strength
	if _stall_time > 18.0: wear_rate += 0.012
	line_wear = minf(1.0, line_wear + delta * wear_rate)
	line_warning = line_wear >= 0.55
	if line_warning: _wear_warning_time += delta
	if line_wear > 0.78 and _wear_warning_time >= 8.0:
		_break_hazard += delta * 0.012 * clampf((line_wear - 0.78) / 0.22, 0.0, 1.0)

func _finish(success: bool, reason: String) -> void:
	if _terminal or session_id.is_empty() or individual.is_empty(): return
	_terminal = true
	if success: individual["caught_at"] = Time.get_datetime_string_from_system(false, true)
	release()
	escape_reason = reason
	set_state(State.CAUGHT if success else State.ESCAPED)
	ended.emit(success, individual.duplicate(true))
