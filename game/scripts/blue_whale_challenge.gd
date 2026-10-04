class_name BlueWhaleChallenge
extends RefCounted
## A complete, input-driven fantasy encounter. The light tether connects to an
## echo ring, never the animal. This model has no bait, hooks, fish stamina,
## inventory, mass-based difficulty, catch reward, or landing state.
signal changed(state: int)
signal ended(success: bool, record: Dictionary)
signal link_completed(index: int)

enum State { IDLE, LINK, CURRENT, RESONANCE, SUCCESS, FAILED, CANCELLED, PAUSED }
const FIXED_STEP: float = 1.0 / 120.0
const BODY_LENGTH_MM: int = 26000
const LINK_MIN: float = 0.42
const LINK_MAX: float = 0.66
const LINK_SECONDS: float = 1.2
const CURRENT_TOLERANCE: float = 0.11
const CURRENT_SECONDS: float = 10.0
const TENSION_MIN: float = 0.38
const TENSION_MAX: float = 0.65
const RESONANCE_SECONDS: float = 8.0
const PHASE_LIMITS: Dictionary = {State.LINK: 30.0, State.CURRENT: 28.0, State.RESONANCE: 24.0}

var state: int = State.IDLE
var before_pause: int = State.IDLE
var challenge_id: String = ""
var elapsed: float = 0.0
var phase_elapsed: float = 0.0
var pulse: float = 0.14
var links: int = 0
var link_time: float = 0.0
var route_position: float = 0.25
var route_target: float = 0.5
var current_sync: float = 0.0
var tension: float = 0.46
var resonance_sync: float = 0.0
var danger_time: float = 0.0
var failure_reason: String = ""
var record: Dictionary = {}
var holding: bool = false
var direction: int = 0
var _accumulator: float = 0.0
var _terminal: bool = true
var _serial: int = 0
var _game_time: float = 0.0

func start(game_time: float = 0.0) -> bool:
	if state in [State.LINK, State.CURRENT, State.RESONANCE, State.PAUSED]: return false
	_serial += 1
	challenge_id = "whale-%d-%d-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), get_instance_id(), _serial]
	_game_time = maxf(0.0, game_time)
	elapsed = 0.0
	phase_elapsed = 0.0
	pulse = 0.14
	links = 0
	link_time = 0.0
	route_position = 0.25
	route_target = 0.5
	current_sync = 0.0
	tension = 0.46
	resonance_sync = 0.0
	danger_time = 0.0
	failure_reason = ""
	record = {}
	_accumulator = 0.0
	_terminal = false
	cancel_input()
	_set_state(State.LINK)
	return true

func set_hold(value: bool) -> void:
	holding = value and state in [State.LINK, State.RESONANCE]

func set_direction(value: int) -> void:
	direction = clampi(value, -1, 1) if state == State.CURRENT else 0

func cancel_input() -> void:
	holding = false
	direction = 0

func pause() -> void:
	if state not in [State.LINK, State.CURRENT, State.RESONANCE]: return
	cancel_input()
	before_pause = state
	_set_state(State.PAUSED, false)

func resume() -> void:
	if state != State.PAUSED: return
	cancel_input()
	_set_state(before_pause, false)

func cancel() -> void:
	if _terminal: return
	_terminal = true
	cancel_input()
	failure_reason = "已结束鲸影挑战。"
	_set_state(State.CANCELLED)
	ended.emit(false, {"challenge_id": challenge_id, "cancelled": true})

func is_active() -> bool:
	return state in [State.LINK, State.CURRENT, State.RESONANCE, State.PAUSED]

func progress() -> float:
	match state:
		State.LINK: return (float(links) + link_time / LINK_SECONDS) / 3.0
		State.CURRENT: return current_sync / CURRENT_SECONDS
		State.RESONANCE: return resonance_sync / RESONANCE_SECONDS
		State.SUCCESS: return 1.0
	return 0.0

func gauge_value() -> float:
	match state:
		State.LINK: return pulse
		State.CURRENT: return route_position
		State.RESONANCE: return tension
	return 0.5

func gauge_band() -> Vector2:
	match state:
		State.LINK: return Vector2(LINK_MIN, LINK_MAX)
		State.CURRENT: return Vector2(route_target - CURRENT_TOLERANCE, route_target + CURRENT_TOLERANCE)
		State.RESONANCE: return Vector2(TENSION_MIN, TENSION_MAX)
	return Vector2(0.0, 1.0)

func phase_title() -> String:
	match state:
		State.LINK: return "1 / 3 · 连起三道鲸影光环"
		State.CURRENT: return "2 / 3 · 跟随幻海潮流"
		State.RESONANCE: return "3 / 3 · 稳住能量线"
		State.SUCCESS: return "鲸影共鸣 · 挑战完成"
		State.FAILED: return "幻线消散 · 可以重试"
		State.PAUSED: return "鲸影挑战已暂停"
	return "鲸影共鸣"

func instruction() -> String:
	match state:
		State.LINK: return "按住上升，松手下降。把亮点留在绿带，点亮三道光环。"
		State.CURRENT: return "按住左 / 右，让亮点跟随移动绿带，累计同步 10 秒。"
		State.RESONANCE: return "按住收紧、松手放松。张力留在绿带累计 8 秒，避免极端张力。"
		State.SUCCESS: return "26 米鲸影在水中与你并行。共鸣已完成，保存独立纪录后可解锁蓝鲸自然图鉴。"
		State.PAUSED: return "继续后重新按下操作按钮；进度与计时保持原位。"
	return failure_reason

func step(delta: float) -> void:
	if not is_active() or state == State.PAUSED or not is_finite(delta) or delta <= 0.0: return
	_accumulator += delta
	while _accumulator + 0.000000001 >= FIXED_STEP and is_active() and state != State.PAUSED:
		_accumulator -= FIXED_STEP
		_step_fixed(FIXED_STEP)

func _step_fixed(delta: float) -> void:
	elapsed += delta
	phase_elapsed += delta
	match state:
		State.LINK:
			pulse = clampf(pulse + delta * (0.28 if holding else -0.21), 0.0, 1.0)
			if pulse >= LINK_MIN and pulse <= LINK_MAX:
				link_time += delta
			else:
				link_time = maxf(0.0, link_time - delta * 0.35)
			if link_time + 0.000001 >= LINK_SECONDS:
				links += 1
				link_time = 0.0
				pulse = 0.14
				link_completed.emit(links)
				if links == 3:
					cancel_input()
					_set_state(State.CURRENT)
		State.CURRENT:
			route_target = 0.5 + sin(phase_elapsed * 0.36) * 0.28
			route_position = clampf(route_position + float(direction) * delta * 0.27, 0.04, 0.96)
			if absf(route_position - route_target) <= CURRENT_TOLERANCE: current_sync += delta
			if current_sync + 0.000001 >= CURRENT_SECONDS:
				cancel_input()
				_set_state(State.RESONANCE)
		State.RESONANCE:
			tension = clampf(tension + delta * ((0.22 if holding else -0.17) + sin(phase_elapsed * 1.3) * 0.035), 0.0, 1.0)
			if tension >= TENSION_MIN and tension <= TENSION_MAX: resonance_sync += delta
			if tension < 0.08 or tension > 0.90: danger_time += delta
			else: danger_time = maxf(0.0, danger_time - delta * 2.0)
			if danger_time >= 2.2:
				_finish(false, "能量线张力过高，幻线消散。松手降张力后再尝试。" if tension > 0.9 else "能量线太松，鲸影共鸣中断。按住提高张力后再尝试。")
			elif resonance_sync + 0.000001 >= RESONANCE_SECONDS:
				_finish(true)
	if not _terminal and phase_elapsed >= float(PHASE_LIMITS.get(state, 100000.0)):
		_finish(false, "本阶段的潮流窗口结束。留意绿带和操作提示，再试一次。")

func _set_state(value: int, reset_phase: bool = true) -> void:
	state = value
	if reset_phase: phase_elapsed = 0.0
	changed.emit(state)

func _finish(success: bool, reason: String = "") -> void:
	if _terminal: return
	_terminal = true
	cancel_input()
	failure_reason = reason
	if success:
		record = {
			"challenge_id": challenge_id, "species_id": "blue_whale", "animal_kind": "mammal",
			"encounter_type": "fantasy_challenge", "region_id": "pacific_ocean", "spot_id": "pacific_bluewater",
			"completed_at": Time.get_datetime_string_from_system(true, false) + "Z",
			"duration_ms": maxi(1, roundi(elapsed * 1000.0)), "body_length_mm": BODY_LENGTH_MM,
			"links": links, "current_sync_ms": roundi(current_sync * 1000.0),
			"resonance_sync_ms": roundi(resonance_sync * 1000.0), "game_time": _game_time
		}
	_set_state(State.SUCCESS if success else State.FAILED)
	ended.emit(success, record.duplicate(true) if success else {"challenge_id": challenge_id, "reason": reason})
