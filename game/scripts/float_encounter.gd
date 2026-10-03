class_name FloatEncounter
extends RefCounted
## A fish investigates and handles bait. The float reports transmitted load, not
## a countdown. No input-time random roll: a hook either occupies the mouth or it
## does not. This is a readable game abstraction, not a universal fishing rule.
# Automatic presentation weights for this game's mixed catalog; not a claim
# that every member always feeds at the bottom or produces a lift indication.
const BOTTOM_FEEDERS: Array[String] = ["common_carp", "crucian_carp", "tench", "common_bream", "channel_catfish", "flathead_catfish", "southern_catfish", "longsnout_catfish", "chinese_sturgeon", "olive_flounder", "european_plaice"]
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var phase: String = "approach"
var clock: float = 0.0
var age: float = 0.0
var mouth_depth: float = 0.0
var bait_in_mouth: bool = false
var hook_ready: bool = false
var departed: bool = false
var attempt: int = 0
var signature: String = "sink"
var dip: float = 0.0
var lift: float = 0.0
var drag: Vector2 = Vector2.ZERO
var tilt: float = 0.0
var activity: float = 0.0
var water_height: float = 0.0
var current: Vector2 = Vector2.ZERO
var possession_time: float = 0.0
var first_approach_seconds: float = 0.0
var successful_pickups: int = 0
var rejected_pickups: int = 0
var _behavior: String = "steady"
var _bottom: bool = false
var _difficulty: float = 0.4
var _trait: float = 0.5
var _appetite: float = 0.6
var _approach_distance: float = 1.0
var _approach_speed: float = 0.3
var _inspection_cycles: float = 1.0
var _jaw_frequency: float = 1.0
var _intake_speed: float = 1.0
var _mouth_capacity: float = 2.0
var _irritation: float = 0.0
var _committed: bool = false
var _max_attempts: int = 4
var _direction: Vector2 = Vector2.RIGHT
var _swim_speed: float = 0.1
var _load: float = 0.0
var _load_velocity: float = 0.0
var _target_load: float = 0.0
var _drag_target: Vector2 = Vector2.ZERO
var _ambient_phase: float = 0.0
var _weather_strength: float = 1.0
var _return_distance: float = 0.0
var rig_mode: String = "suspended"
var bait_depth_m: float = 3.0
var _bait_bulk: float = 1.0
var _bait_affinity: float = 1.0
var _contact_strength: float = 0.18
var _line_response: float = 95.0

func configure(record: Dictionary, seed_value: int) -> void:
	rng.seed = seed_value
	_behavior = str(record.get("behavior", "steady"))
	_bottom = str(record.get("species_id", "")) in BOTTOM_FEEDERS
	var water_depth: float = maxf(0.5, float(record.get("water_depth_m", 4.0)))
	bait_depth_m = clampf(float(record.get("bait_depth_m", minf(water_depth, 3.0))), 0.3, water_depth)
	var bait: String = str(record.get("bait_id", "worm"))
	# The game automatically presents soft food near the bottom where practical.
	# Artificial lures and deep/open-water casts use a suspended abstraction.
	rig_mode = str(record.get("float_rig", "near_bottom" if _bottom and water_depth <= 8.0 and bait not in ["spinner", "lure"] else "suspended"))
	_bottom = rig_mode == "near_bottom"
	_bait_bulk = 1.2 if bait in ["cut_fish", "dough"] else 0.86 if bait in ["worm", "insect"] else 1.0
	_bait_affinity = clampf(float(record.get("bait_affinity", 1.0)), 0.3, 2.5)
	_line_response = lerpf(105.0, 76.0, clampf(bait_depth_m / 25.0, 0.0, 1.0))
	_difficulty = clampf(float(record.get("difficulty", 0.4)), 0.0, 1.0)
	_trait = float(absi(str(record.get("species_id", "fish")).hash()) % 997) / 996.0
	_weather_strength = 1.4 if str(record.get("weather", "clear")) in ["wind", "rain", "storm"] else 0.8
	_ambient_phase = rng.randf_range(0.0, TAU)
	_appetite = rng.randf_range(0.45, 0.85)
	_max_attempts = rng.randi_range(3, 5)
	clock = 0.0
	_load = 0.0
	_load_velocity = 0.0
	drag = Vector2.ZERO
	_drag_target = Vector2.ZERO
	departed = false
	attempt = 0
	successful_pickups = 0
	rejected_pickups = 0
	_start_approach(true)
	first_approach_seconds = _approach_distance / _approach_speed

func _enter(value: String) -> void:
	phase = value
	age = 0.0

func _start_approach(first: bool) -> void:
	attempt += 1
	bait_in_mouth = false
	hook_ready = false
	mouth_depth = 0.0
	possession_time = 0.0
	_irritation = 0.0
	_target_load = 0.0
	_direction = Vector2.from_angle(rng.randf_range(0.0, TAU))
	_approach_speed = rng.randf_range(0.18, 0.43)
	_approach_distance = rng.randf_range(0.55, 2.5) if first else rng.randf_range(0.25, 1.15)
	_inspection_cycles = float(rng.randi_range(1, 3))
	_jaw_frequency = rng.randf_range(1.0, 1.65)
	_intake_speed = rng.randf_range(0.95, 1.55) * (1.32 if _behavior == "burst" else 0.9 if _bottom else 1.0) / _bait_bulk
	_mouth_capacity = rng.randf_range(1.8, 3.3) * (1.2 if _bottom else 1.0) - 0.30 * _difficulty + (_bait_affinity - 1.0) * 0.18
	_swim_speed = rng.randf_range(0.07, 0.14) * (1.25 if _behavior == "burst" else 1.0)
	_contact_strength = rng.randf_range(0.18, 0.34)
	_committed = rng.randf() < _appetite
	# Supporting a bottom shot can lift a float. A suspended bait or a fish
	# swimming away loads the line instead. Species does not guarantee a cue.
	var choice: float = rng.randf()
	signature = "soft" if choice < 0.18 else "lift" if _bottom and choice < 0.60 else "travel" if (_behavior == "burst" and choice < 0.64) or choice > 0.77 else "sink"
	_enter("approach")

func step(delta: float) -> void:
	if departed: return
	clock += delta
	age += delta
	water_height = (sin(clock * 1.1 + _ambient_phase) * 0.004 + sin(clock * 0.63) * 0.002) * _weather_strength
	current = Vector2(sin(clock * 0.18 + _ambient_phase), sin(clock * 0.13)) * 0.018 * _weather_strength
	_target_load = 0.0
	match phase:
		"approach":
			_approach_distance -= _approach_speed * delta
			if _approach_distance <= 0.0:
				# Some fish take straight away. Others touch and leave several times.
				_enter("mouth" if _committed and rng.randf() < 0.24 else "contact")
		"contact":
			var jaw: float = maxf(0.0, sin(age * _jaw_frequency * TAU))
			_target_load = pow(jaw, 5.0) * _contact_strength
			if age * _jaw_frequency >= _inspection_cycles:
				if _committed: _enter("mouth")
				else:
					rejected_pickups += 1
					_appetite = minf(0.92, _appetite + rng.randf_range(0.06, 0.15))
					_begin_return()
		"mouth":
			bait_in_mouth = true
			mouth_depth = minf(1.0, mouth_depth + _intake_speed * delta)
			# Partial lip contact produces only a brief nudge; hook seating is
			# gradual and deterministic. Taking tension rises after seating.
			_target_load = mouth_depth * 0.14
			hook_ready = mouth_depth >= 0.62
			if mouth_depth >= 1.0:
				successful_pickups += 1
				_enter("carry")
		"carry":
			bait_in_mouth = true
			hook_ready = true
			possession_time += delta
			_irritation += delta * (0.85 + _difficulty * 0.35 + absf(_load) * 0.14)
			var take: float = smoothstep(0.0, 0.38, age)
			# A fish turns against the tether before travelling out of the fixed
			# observation view. Preserve position/velocity; never clamp/teleport.
			if _drag_target.length() > 0.42:
				_direction = _direction.lerp(-_drag_target.normalized(), 1.0 - exp(-delta * 5.0)).normalized()
			if signature == "lift":
				_target_load = -0.82 * take
				# Fish lifts the bottom shot, then moves while still holding bait.
				if age > 0.55: _drag_target += _direction * _swim_speed * 0.42 * delta
			elif signature == "soft":
				# A restrained but held displacement overlaps exploratory peak
				# amplitude. Its duration/continuity matters more than its size.
				_target_load = 0.24 * take
				_drag_target += _direction * _swim_speed * 0.28 * take * delta
			elif signature == "travel":
				_target_load = 0.33 * take
				_drag_target += _direction * _swim_speed * take * delta
			else:
				_target_load = (0.84 + 0.07 * _trait) * take
				_drag_target += _direction * _swim_speed * 0.2 * take * delta
			if _irritation >= _mouth_capacity:
				bait_in_mouth = false
				hook_ready = false
				mouth_depth = 0.0
				_enter("spit")
		"spit":
			# Released load returns the antenna to its previous waterline.
			# No popup/camera cue; a late strike physically has no fish to hook.
			if absf(_load) < 0.10 and age > 0.45: _begin_return()
		"return":
			_return_distance -= _approach_speed * delta
			if _return_distance <= 0.0:
				if attempt >= _max_attempts or clock > 48.0:
					departed = true
					_enter("departed")
				else: _start_approach(false)
	if phase != "carry":
		# The weighted leader and shoreward line gently relax after release.
		_drag_target = _drag_target.move_toward(Vector2.ZERO, delta * 0.04)
	# Damped buoyancy. No abrupt teleport at phase boundaries and no synthetic
	# lateral sine-wave wiggle. Signals all originate in the same bait load.
	_load_velocity += ((_target_load - _load) * _line_response - _load_velocity * 19.0) * delta
	_load += _load_velocity * delta
	dip = maxf(0.0, _load)
	lift = maxf(0.0, -_load)
	drag = drag.lerp(_drag_target, 1.0 - exp(-delta * 8.0))
	tilt = clampf(drag.length() * 0.9, 0.0, 0.38) * signf(_direction.x) + sin(clock * 1.1 + _ambient_phase) * 0.012 * _weather_strength
	activity = absf(_load_velocity) * 0.06 + drag.distance_to(_drag_target)

func _begin_return() -> void:
	bait_in_mouth = false
	hook_ready = false
	mouth_depth = 0.0
	_return_distance = rng.randf_range(0.15, 0.48)
	_enter("return")

func can_hook() -> bool:
	return not departed and bait_in_mouth and hook_ready and mouth_depth >= 0.62

func is_contacting() -> bool:
	return phase in ["contact", "mouth", "carry", "spit"]

func observation() -> Dictionary:
	## Public visual values only. Useful for a test controller which cannot see
	## fish possession, RNG, phase, species or remaining hold time.
	return {"dip":dip,"lift":lift,"drag":drag,"tilt":tilt,"water_height":water_height,"current":current}
