class_name FishingAudio
extends Node
## Bounded, layered soundscape. Presentation sends only visible fight values;
## waiting/nibble/bite intentionally have no audio or haptic side channel.
const VOICE_COUNT: int = 5
const SILENCE: float = 0.0005
const LOOP_NAMES: Array[String] = ["water", "current", "wind", "rain", "reel", "drag"]
const CUE_NAMES: Array[String] = ["cast", "splash", "hook", "catch", "escape", "release"]
const CUE_GAIN: Dictionary = {"cast": 0.70, "splash": 0.74, "hook": 0.62, "catch": 0.85, "escape": 0.34, "release": 0.64}

var enabled: bool = true
var has_output: bool = true
var vibration: bool = true
# Keep these aliases for callers that explicitly stop the base ambience/effect.
var ambience: AudioStreamPlayer
var effect: AudioStreamPlayer
var _layers: Array[AudioStreamPlayer] = []
var _voices: Array[AudioStreamPlayer] = []
var _clips: Dictionary = {}
var _levels: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _voice_gains: PackedFloat32Array = PackedFloat32Array()
var _next_voice: int = 0
var _suspended: bool = false
var _low_power: bool = false
var _mobile: bool = false
var _master: float = 0.6
var _ambient_volume: float = 0.75
var _effects_volume: float = 0.85
var _spot_id: String = ""
var _weather: String = ""
var _time_key: String = ""
var _water_gain: float = 0.32
var _current_gain: float = 0.0
var _wind_gain: float = 0.10
var _rain_gain: float = 0.0
var _fighting: bool = false
var _reeling: bool = false
var _tension: float = 0.0
var _surge: float = 0.0
var _mix_time: float = 0.0
var _focus_seconds: float = 0.0
var _duck: float = 1.0
var _haptic_wait: float = 0.0
var _danger_armed: bool = true
var _surge_armed: bool = true
var _variant: int = 0

func _ready() -> void:
	has_output = DisplayServer.get_name() != "headless"
	_mobile = OS.get_name() == "Android"
	for clip_name: String in LOOP_NAMES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Layer_" + clip_name
		player.volume_db = -80.0
		add_child(player)
		_layers.append(player)
		if has_output:
			player.stream = _load_clip(clip_name, true)
	ambience = _layers[0]
	for index: int in range(VOICE_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Effect_%d" % index
		add_child(player)
		_voices.append(player)
		_voice_gains.append(1.0)
	effect = _voices[0]
	if has_output:
		for clip_name: String in CUE_NAMES:
			var clip: AudioStream = _load_clip(clip_name, false)
			if clip != null: _clips[clip_name] = clip
	set_environment("lake_shore", "clear", "day")

func _load_clip(clip_name: String, looping: bool) -> AudioStream:
	var path: String = "res://assets/audio/" + clip_name + ".wav"
	if not ResourceLoader.exists(path): return null
	var stream: AudioStream = load(path) as AudioStream
	if looping and stream is AudioStreamWAV:
		# A private playback resource makes looping independent of import options,
		# and never changes a resource used by another preview or player.
		var loop: AudioStreamWAV = stream.duplicate() as AudioStreamWAV
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_begin = 0
		loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
		return loop
	return stream

func apply(settings: Dictionary) -> void:
	enabled = bool(settings.get("sound", true))
	vibration = bool(settings.get("vibration", true))
	_master = _unit(float(settings.get("volume", 0.6)), 0.6)
	_ambient_volume = _unit(float(settings.get("ambience_volume", 0.75)), 0.75)
	_effects_volume = _unit(float(settings.get("effects_volume", 0.85)), 0.85)
	if not vibration: _cancel_haptics()
	# Muting takes effect immediately. Do not mutate the global Master bus:
	# another scene/player must not inherit a stale mute after this node exits.
	if not enabled or _master <= SILENCE:
		for player: AudioStreamPlayer in _layers: player.stop()
		for player: AudioStreamPlayer in _voices: player.stop()
		_levels.fill(0.0)
	else:
		for index: int in range(_voices.size()):
			if _effects_volume <= SILENCE: _voices[index].stop()
			_voices[index].volume_db = linear_to_db(maxf(SILENCE, _voice_gains[index] * _master * _effects_volume))

func set_environment(spot_id: String, weather: String, time_key: String = "day") -> void:
	if _spot_id == spot_id and _weather == weather and _time_key == time_key: return
	_spot_id = spot_id
	_weather = weather
	_time_key = time_key
	var sea: bool = spot_id.begins_with("japan") or spot_id.begins_with("norway") or spot_id.begins_with("med") or spot_id == "yangtze_estuary" or spot_id.begins_with("pacific_") or spot_id.begins_with("atlantic_") or spot_id.begins_with("indian_")
	var river: bool = spot_id == "bayou_channel" or spot_id == "yangtze_river"
	var exposed: bool = spot_id.ends_with("boat") or spot_id.ends_with("reef") or spot_id.ends_with("estuary") or spot_id.ends_with("bluewater") or spot_id.ends_with("shelf")
	_water_gain = 0.40 if sea else 0.30
	_current_gain = 0.23 if river else 0.0
	_wind_gain = 0.20 if exposed else 0.13 if sea else 0.07
	if time_key == "dusk": _wind_gain *= 0.80
	_rain_gain = 0.24 if weather == "rain" else 0.0
	if weather == "rain": _wind_gain += 0.04

func set_low_power(value: bool) -> void:
	_low_power = value

func update_fishing(_delta: float, fighting: bool, reeling: bool, tension: float, surge_strength: float = 0.0) -> void:
	_fighting = fighting and not _suspended
	_reeling = reeling and _fighting
	_tension = _unit(tension, 0.0) if _fighting else 0.0
	_surge = _unit(surge_strength, 0.0) if _fighting else 0.0
	if not _fighting:
		_danger_armed = true
		_surge_armed = true
		return
	# A single quiet pulse accompanies a visible strain threshold. Hysteresis
	# and a shared cooldown prevent a noisy vibration loop near the boundary.
	if _tension < 0.70: _danger_armed = true
	if _surge < 0.25: _surge_armed = true
	if _tension > 0.86 and _danger_armed:
		_danger_armed = false
		_pulse(16, 0.35)
	elif _surge > 0.65 and _surge_armed:
		_surge_armed = false
		_pulse(11, 0.24)

func cue(kind: String) -> void:
	# No sound, vibration, ducking, RNG or playback change may disclose an
	# unhooked fish. Unknown requests are ignored just as early.
	if kind == "nibble" or kind == "bite" or not CUE_GAIN.has(kind): return
	if _suspended: return
	if enabled and has_output and _master > SILENCE and _effects_volume > SILENCE and _clips.has(kind):
		# Find a free preallocated voice; only steal the oldest round-robin slot
		# when the bounded pool is full. A splash no longer cuts off a cast.
		var index: int = _next_voice
		for offset: int in range(VOICE_COUNT):
			var candidate: int = (_next_voice + offset) % VOICE_COUNT
			if not _voices[candidate].playing:
				index = candidate
				break
		var player: AudioStreamPlayer = _voices[index]
		player.stop()
		player.stream = _clips[kind]
		_variant = (_variant + 1) % 7
		player.pitch_scale = 0.97 + float(_variant) * 0.01
		_voice_gains[index] = float(CUE_GAIN[kind])
		player.volume_db = linear_to_db(maxf(SILENCE, _voice_gains[index] * _master * _effects_volume))
		player.play()
		_next_voice = (index + 1) % VOICE_COUNT
		_focus_seconds = 0.65
	match kind:
		"cast": _pulse(7, 0.18)
		"hook": _pulse(22, 0.45)
		"catch": _pulse(38, 0.50)
		"splash", "release": _pulse(8, 0.18)
		"escape": _pulse(10, 0.20)

func suspend(value: bool, finish_cue_tail: bool = false) -> void:
	_suspended = value
	_mix_time = 0.0
	if value:
		_reeling = false
		_fighting = false
		_tension = 0.0
		_surge = 0.0
		_focus_seconds = 0.0
		_cancel_haptics()
		for index: int in range(4, 6):
			_levels[index] = 0.0
			_layers[index].stop()
	for player: AudioStreamPlayer in _layers: player.stream_paused = value
	# Only a terminal failure panel may let its current short cue finish.
	# Normal pause/background always stops it, so stale effects never resume.
	if value and not finish_cue_tail:
		for player: AudioStreamPlayer in _voices: player.stop()

func _process(delta: float) -> void:
	if _suspended or not is_finite(delta) or delta <= 0.0: return
	_haptic_wait = maxf(0.0, _haptic_wait - delta)
	_focus_seconds = maxf(0.0, _focus_seconds - delta)
	if not enabled or not has_output or _master <= SILENCE: return
	_mix_time += delta
	# Audio plays at its native rate; only low-cost volume control is throttled.
	if _mix_time < (1.0 / 20.0 if _low_power else 1.0 / 40.0): return
	var step: float = minf(_mix_time, 0.15)
	_mix_time = 0.0
	var duck_target: float = 0.68 if _fighting else 0.78 if _focus_seconds > 0.0 else 1.0
	_duck = lerpf(_duck, duck_target, 1.0 - exp(-step * 3.0))
	var bed: float = _master * _ambient_volume * _duck
	_drive_layer(0, _water_gain * bed, 0.92 if _spot_id.begins_with("norway") else 1.0, step, false)
	_drive_layer(1, _current_gain * bed, 1.0, step, false)
	_drive_layer(2, _wind_gain * bed, 0.92, step, false)
	_drive_layer(3, _rain_gain * bed, 1.0, step, false)
	var mechanical: float = _master * _effects_volume
	var reel_gain: float = (0.12 + _tension * 0.15) if _reeling else 0.0
	var drag_gain: float = maxf(0.0, _tension - 0.64) * (0.32 + _surge * 0.42) if _fighting else 0.0
	_drive_layer(4, reel_gain * mechanical, 0.95 + (1.0 - _tension) * 0.23, step, true)
	_drive_layer(5, drag_gain * mechanical, 0.83 + _surge * 0.32, step, true)

func _drive_layer(index: int, target: float, pitch: float, delta: float, immediate: bool) -> void:
	var player: AudioStreamPlayer = _layers[index]
	var blend: float = 1.0 - exp(-delta * (12.0 if immediate else 1.25))
	_levels[index] = lerpf(_levels[index], target, blend)
	if _levels[index] <= SILENCE and target <= SILENCE:
		if player.playing: player.stop()
		return
	if player.stream == null: return
	player.volume_db = linear_to_db(maxf(SILENCE, _levels[index]))
	player.pitch_scale = lerpf(player.pitch_scale, pitch, minf(1.0, delta * 6.0))
	if not player.playing: player.play()

func _pulse(milliseconds: int, amplitude: float) -> void:
	if not vibration or not _mobile or _suspended: return
	if _haptic_wait > 0.0 and milliseconds < 20: return
	Input.vibrate_handheld(milliseconds, amplitude)
	_haptic_wait = 0.75 if milliseconds >= 20 else 1.2

func _cancel_haptics() -> void:
	if _mobile: Input.vibrate_handheld(0)
	_haptic_wait = 0.0

func _unit(value: float, fallback: float) -> float:
	return clampf(value, 0.0, 1.0) if is_finite(value) else fallback

func _exit_tree() -> void:
	_cancel_haptics()
	for player: AudioStreamPlayer in _layers:
		player.stop()
		player.stream = null
	for player: AudioStreamPlayer in _voices:
		player.stop()
		player.stream = null
	_clips.clear()
