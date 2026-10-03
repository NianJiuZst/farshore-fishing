extends SceneTree
const C = preload("res://scripts/catalog.gd")
const G = preload("res://scripts/encounter.gd")
const S = preload("res://scripts/fishing_session.gd")
const QA = preload("res://tests/float_encounter_tests.gd")
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var c: ContentCatalog = C.new()
 c.load_all(false)
 var rows: Array = []
 var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/evidence/1.2.0/float/observation-first/raw.json"))
 for id: String in ["common_carp","japanese_horse_mackerel","atlantic_wolffish"]:
  var route: Dictionary = {}
  for value: Dictionary in source.routes:
   if value.species == id:
    route = value
    break
  for index: int in 128:
   for fps: int in [16,30,60]:
    for confirm: float in [0.25,0.35,0.45]:
     var seed_value: int = 990101 + index * 3571
     var gen: EncounterGenerator = G.new(seed_value)
     var record: Dictionary = gen.make_individual(c.fish[id],route.spot,route.region,route.baits[index%2],route.gear,"day","rain" if index%2 else "clear")
     gen.apply_float_presentation(record,c,float(route.power))
     var s: FishingSession = S.new(seed_value)
     s.press()
     s.cast(record,c.gear[route.gear])
     var reader: QA.SurfaceReader = QA.SurfaceReader.new(confirm)
     var time: float = 0.0
     var result: Dictionary = {"fps":fps,"confirmation_seconds":confirm,"ever_ready":false,"species":id,"seed":seed_value,"hooked":false,"strike_phase":"","strike_time":-1.0}
     while time < 90.0 and s.state != S.State.ESCAPED:
      if s.float_encounter.can_hook(): result.ever_ready = true
      if reader.update({"dip":s.float_dip,"lift":s.float_lift,"drag":s.float_drag,"tilt":s.float_tilt},1.0/fps):
       result.strike_phase = s.float_encounter.phase
       result.strike_time = time
       result.dip = s.float_dip
       result.lift = s.float_lift
       s.press()
       result.hooked = s.state == S.State.FIGHT
       break
      s.step(1.0/fps)
      time += 1.0/fps
     rows.append(result)
 print("BROAD_READER_SWEEP=",JSON.stringify(rows))
 quit()
