extends SceneTree
## Endpoint/guard regressions complement organic seeded wear trials in the matrix.
## Boundary fixtures deliberately inject hazard fields; they do not estimate RNG
## probabilities or replace the natural low-pressure stalemate simulations.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
var catalog: ContentCatalog = Catalog.new()
var checks: int = 0
var failed: Array[String] = []
var cases: Array[Dictionary] = []

func _initialize() -> void:
	_check(catalog.load_all(false), "catalog loads")
	var zero_endpoint: float = -log(maxf(0.000001, 1.0 - 0.0))
	_check(zero_endpoint == 0.0, "inverse-CDF zero RNG endpoint is exactly zero")
	_case("fresh_zero_threshold", 0.0, 0.0, 0.0, zero_endpoint, false)
	_case("insufficient_wear", 0.77, 20.0, 1.0, zero_endpoint, false)
	_case("unwarned_severe_wear", 0.90, 0.0, 1.0, zero_endpoint, false)
	_case("warning_grace_not_finished", 0.90, 7.98, 1.0, zero_endpoint, false)
	_case("warned_eligible_zero_threshold", 0.90, 8.0, 0.0, zero_endpoint, true)
	_case("warned_hazard_below_positive_threshold", 0.90, 8.0, 0.0, 0.50, false)
	_case("warned_hazard_reaches_positive_threshold", 0.90, 8.0, 0.50, 0.50, true)
	var report: Dictionary = {"scope": "Focused injected boundary values; organic probability is tested separately", "checks": checks, "failed": failed, "cases": cases}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			var file: FileAccess = FileAccess.open(arg.trim_prefix("--output="), FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(report, "\t"))
				file.close()
	print("FISHING_HAZARD_BOUNDARY_TESTS: ", checks-failed.size(), "/", checks, "; cases=", cases.size())
	quit(0 if failed.is_empty() else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed.append(label)
		printerr("FAIL HAZARD BOUNDARY: ", label)

func _launch() -> FishingSession:
	var record: Dictionary = Encounter.new(42).make_individual(catalog.fish.common_carp, "lake_shore", "lake", "worm", 0, "day", "clear")
	var session: FishingSession = Session.new(2468)
	session.press()
	session.cast(record, catalog.gear[0])
	session.release()
	for tick: int in 2400:
		if session.state == Session.State.BITE: break
		session.step(1.0/60.0)
	session.press()
	session.release()
	_check(session.state == Session.State.FIGHT, "fixture legitimately hooks")
	return session

func _case(label: String, wear: float, warning_seconds: float, hazard: float, threshold: float, should_break: bool) -> void:
	var session: FishingSession = _launch()
	var events: Array[bool] = []
	session.ended.connect(func(caught: bool, _record: Dictionary) -> void: events.append(caught))
	session.line_wear = wear
	session.line_warning = wear >= 0.55
	session._wear_warning_time = warning_seconds
	session._break_hazard = hazard
	session._break_threshold = threshold
	session.step(Session.FIXED_STEP)
	var broke: bool = session.state == Session.State.ESCAPED and "磨损" in session.escape_reason
	_check(broke == should_break, label + ": expected wear break=" + str(should_break))
	_check(events.size() == (1 if should_break else 0), label + ": terminal event count")
	if not should_break: _check(session.state == Session.State.FIGHT, label + ": fight remains active")
	cases.append({"case": label, "expected_break": should_break, "actual_break": broke, "fight_seconds": session.fight_time, "line_wear": session.line_wear, "line_warning": session.line_warning, "warning_seconds": session._wear_warning_time, "break_hazard": session._break_hazard, "break_threshold": session._break_threshold, "escape_reason": session.escape_reason})
