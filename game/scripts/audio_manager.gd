class_name FishingAudio
extends Node
var enabled: bool = true
var has_output: bool = true
var vibration: bool = true
var ambience: AudioStreamPlayer
var effect: AudioStreamPlayer

func _ready() -> void:
	has_output = DisplayServer.get_name() != "headless"
	ambience = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	add_child(ambience)
	add_child(effect)
	if has_output and ResourceLoader.exists("res://assets/audio/water.wav"):
		ambience.stream = load("res://assets/audio/water.wav")
		ambience.volume_db = -19
		ambience.finished.connect(func() -> void: ambience.play())
		ambience.play()

func apply(settings: Dictionary) -> void:
	enabled = bool(settings.get("sound",true))
	vibration = bool(settings.get("vibration",true))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001,float(settings.get("volume",0.6)))))
	AudioServer.set_bus_mute(0,not enabled)

func cue(kind: String) -> void:
	var path: String = "res://assets/audio/" + kind + ".wav"
	if has_output and ResourceLoader.exists(path) and enabled:
		effect.stream = load(path)
		effect.play()
	if vibration and OS.get_name() == "Android" and kind in ["bite","hook","catch"]:
		Input.vibrate_handheld(65 if kind == "bite" else 30)

func suspend(value: bool) -> void:
	if ambience: ambience.stream_paused = value
	if effect: effect.stream_paused = value
	if value and OS.get_name() == "Android": Input.vibrate_handheld(0)

func _exit_tree() -> void:
	if ambience:
		ambience.stop()
		ambience.stream = null
	if effect:
		effect.stop()
		effect.stream = null
