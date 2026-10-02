extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
func _initialize() -> void:
	var catalog: ContentCatalog = Catalog.new()
	if not catalog.load_all(false):
		printerr("FAIL: catalog did not load")
		quit(2)
		return
	var record: Dictionary = Encounter.new(42).make_individual(catalog.fish.common_carp, "lake_shore", "lake", "worm", 0, "day", "clear")
	var session: FishingSession = Session.new(2468)
	session.press()
	session.cast(record, catalog.gear[0])
	session.release()
	while session.state != Session.State.BITE:
		session.step(1.0/60.0)
	session.press()
	session.release()
	# Valid inverse-CDF endpoint: -log(1 - 0.0) = 0.0.
	# Isolate the endpoint directly instead of searching billions of RNG seeds.
	session._break_threshold = 0.0
	session.step(Session.FIXED_STEP)
	var ok: bool = session.state == Session.State.FIGHT and not session.line_warning
	print(JSON.stringify({"check":"zero-threshold fresh fight must remain active until severe wear and warning grace", "passed":ok, "state":session.state, "fight_seconds":session.fight_time, "line_wear":session.line_wear, "line_warning":session.line_warning, "warning_seconds":session._wear_warning_time, "break_hazard":session._break_hazard, "break_threshold":session._break_threshold, "escape_reason":session.escape_reason}))
	if not ok: printerr("FAIL: zero-threshold fresh fight broke before severe wear or warning grace")
	quit(0 if ok else 1)
