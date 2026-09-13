class_name FishingSession
extends RefCounted
signal changed(state: int)
signal ended(success: bool, record: Dictionary)
signal cue(kind: String)
enum State { IDLE, CHARGING, CASTING, WAITING, NIBBLE, BITE, FIGHT, CAUGHT, ESCAPED, PAUSED }
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
var wait_duration: float = 5.0
var slack_time: float = 0.0
var overload_time: float = 0.0
var gear_power: float = 1.0
var tolerance: float = 1.0
var behavior_phase: String = "平稳游动"
var escape_reason: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _terminal: bool = false
var _serial: int = 0

func _init() -> void:
	_rng.randomize()

func set_state(value: int) -> void:
	state = value
	elapsed = 0.0
	changed.emit(state)

func start_charge() -> void:
	if state != State.IDLE: return
	charge = 0.0
	set_state(State.CHARGING)

func cast(fish: Dictionary, equipment: Dictionary) -> bool:
	if state != State.CHARGING: return false
	if fish.is_empty():
		set_state(State.IDLE)
		return false
	_serial += 1
	session_id = "%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), _serial]
	individual = fish.duplicate(true)
	individual["session_id"] = session_id
	individual["catch_id"] = session_id + ":catch"
	_terminal = false
	gear_power = float(equipment.get("power", 1.0))
	tolerance = float(equipment.get("tolerance", 1.0))
	wait_duration = _rng.randf_range(3.8, 8.8)
	tension = 0.34
	progress = 0.0
	slack_time = 0.0
	overload_time = 0.0
	fight_time = 0.0
	set_state(State.CASTING)
	cue.emit("cast")
	return true

func press() -> void:
	match state:
		State.IDLE: start_charge()
		State.BITE:
			reeling = false
			set_state(State.FIGHT)
			cue.emit("hook")
		State.FIGHT: reeling = true

func release() -> void:
	reeling = false

func cancel_input() -> void:
	reeling = false
	if state == State.CHARGING: set_state(State.IDLE)

func pause() -> void:
	cancel_input()
	if state == State.PAUSED: return
	before_pause = state
	state = State.PAUSED
	changed.emit(state)

func resume() -> void:
	if state != State.PAUSED: return
	reeling = false
	state = before_pause
	changed.emit(state)

func reset() -> void:
	reeling = false
	individual = {}
	set_state(State.IDLE)

func step(delta: float) -> void:
	if state == State.PAUSED: return
	delta = minf(delta, 0.05)
	elapsed += delta
	match state:
		State.CHARGING:
			charge = minf(1.0, charge + delta * 0.48)
		State.CASTING:
			if elapsed > 0.85: set_state(State.WAITING)
		State.WAITING:
			if elapsed >= wait_duration - 1.4:
				set_state(State.NIBBLE)
				cue.emit("nibble")
		State.NIBBLE:
			if elapsed > 1.4:
				set_state(State.BITE)
				cue.emit("bite")
		State.BITE:
			if elapsed > lerpf(3.6, 2.2, float(individual.difficulty)):
				_finish(false, "错过提竿时机，小鱼回到了水中")
		State.FIGHT:
			_step_fight(delta)

func _step_fight(delta: float) -> void:
	fight_time += delta
	var difficulty: float = float(individual.get("difficulty", 0.4))
	var behavior: String = str(individual.get("behavior", "steady"))
	var force: float = 0.055 + difficulty * 0.045
	var phase: float = fmod(fight_time, 6.8)
	behavior_phase = "持续拉扯"
	if behavior == "burst":
		if phase < 1.6:
			force *= 2.1
			behavior_phase = "短促冲刺 · 松手卸力"
		else:
			force *= 0.65
			behavior_phase = "冲刺间隙 · 稳稳收线"
	elif behavior == "rest":
		if phase > 3.6:
			force *= 0.2
			behavior_phase = "间歇休息 · 把握机会"
		else:
			force *= 1.3
			behavior_phase = "沉底拉扯"
	if reeling:
		tension += delta * (0.075 + force) / tolerance
		var efficiency: float = clampf(1.0 - absf(tension - 0.52) * 0.6, 0.6, 1.0)
		progress += delta * (0.080 * gear_power / (0.85 + difficulty * 0.35)) * efficiency
	else:
		tension += delta * (force * 0.33 - 0.20)
		progress = maxf(0.0, progress - delta * 0.009)
	tension = clampf(tension, 0.0, 1.15)
	if tension > 0.97:
		overload_time += delta
	else: overload_time = maxf(0.0, overload_time - delta * 2.0)
	if tension < 0.08:
		slack_time += delta
	else: slack_time = maxf(0.0, slack_time - delta * 2.0)
	if overload_time > 1.1:
		_finish(false, "张力持续过高，鱼线断了。危险时松手卸力")
	elif slack_time > 5.0:
		_finish(false, "鱼线松弛太久，鱼脱钩了。低张力时按住收线")
	elif progress >= 1.0:
		_finish(true, "")

func _finish(success: bool, reason: String) -> void:
	if _terminal: return
	_terminal = true
	if success: individual["caught_at"] = Time.get_datetime_string_from_system(false,true)
	reeling = false
	escape_reason = reason
	set_state(State.CAUGHT if success else State.ESCAPED)
	ended.emit(success, individual.duplicate(true))
