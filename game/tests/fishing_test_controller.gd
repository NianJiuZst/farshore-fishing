extends RefCounted
## Delayed visible-cue controller, reusable by integration and balance tests.
## update() returns desired held state; it never mutates a session or UI.
## Caller releases immediately after hooking, then dispatches press/release edges.
var strategy: String
var clock: float = 0.0
var next_observation: float = 0.0
var actions: Array[Dictionary] = []
var intended: bool = false
var held: bool = false

func _init(mode: String = "behavior_aware") -> void:
	strategy = mode

func update(session: FishingSession, delta: float) -> bool:
	clock += delta
	if strategy == "always_pull": return true
	if strategy == "never_pull": return false
	if strategy == "metronome": return fmod(clock, 2.0) < 1.0
	if clock >= next_observation:
		next_observation += 1.0 / 15.0
		var desired: bool = intended
		if strategy == "tension_only":
			if session.tension < 0.45: desired = true
			elif session.tension > 0.64: desired = false
		else:
			# These current-phase values drive visible rod/fish animations. They
			# reveal no next-phase timing, RNG, stamina target, or wear hazard.
			if session.surge_warning >= 0.15 or session.surge_strength >= 0.08:
				desired = session.tension < 0.16
			elif session.tension > 0.76:
				desired = false
			elif session.tension < 0.30 or session.fight_phase == "recovery" and session.tension < 0.70:
				desired = true
		intended = desired
		actions.append({"at": clock + 0.17, "pull": desired})
	while not actions.is_empty() and float(actions[0].at) <= clock:
		held = bool(actions.pop_front().pull)
	return held
