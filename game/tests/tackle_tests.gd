extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Store = preload("res://scripts/save_store.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const TestController = preload("res://tests/fishing_test_controller.gd")
const NEW_BAITS: Array[String] = ["sweetcorn","dough","cut_fish","spinner"]
const BASE_CATEGORIES: Array[String] = ["grain","grain","shrimp","lure"]
const OLD_GEAR: Array[Dictionary] = [
	{"id":0.0,"name":"溪风 · 入门竿","description":"宽容的初次相遇，适合湖岸与小港","power":1.0,"tolerance":1.0,"reach":0.75,"max_depth_m":10.0,"price":0.0},
	{"id":1.0,"name":"海旅 · 旅行竿","description":"更远的落点、更稳的控鱼，开启礁岸","power":1.18,"tolerance":1.25,"reach":1.0,"max_depth_m":60.0,"price":180.0},
	{"id":2.0,"name":"远岸 · 探深竿","description":"前往峡湾深水，面对更大的身影","power":1.35,"tolerance":1.5,"reach":1.0,"max_depth_m":180.0,"price":480.0}
]
var checks: int = 0
var failures: int = 0
var catalog: ContentCatalog = Catalog.new()
var encounter: EncounterGenerator = Encounter.new(7853)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	_check(catalog.load_all(false),"expanded catalog validates: "+str(catalog.errors))
	_test_data_and_legacy_weights()
	_test_actual_gear_mechanics()
	_test_saves()
	print("TACKLE_TESTS: ",checks-failures,"/",checks," passed; failures=",failures)
	quit(0 if failures == 0 else 1)
func _test_data_and_legacy_weights() -> void:
	_check(catalog.gear.size()==5 and catalog.baits.size()==12,"five rods and twelve baits ship")
	_check(catalog.fish.size()==74 and catalog.regions.size()==9 and catalog.spots.size()==18,"all legacy fish/world entries remain")
	for id: int in range(3):
		_check(catalog.gear[id]==OLD_GEAR[id],"original rod entirely unchanged: "+str(id))
	for index: int in range(4):
		var expected: String = ["worm","grain","shrimp","lure"][index]
		_check(str(catalog.baits[index].bait_id)==expected and int(catalog.baits[index].price)==0,"old bait ID/order/free refill preserved: "+expected)
	for index: int in range(4):
		var id: String = NEW_BAITS[index]
		_check(str(catalog.baits[index+4].bait_id)==id and int(catalog.baits[index+4].price)==0,"new unlimited bait appended: "+id)
		_check(catalog.bait_category(id)==BASE_CATEGORIES[index],"explicit legacy bait category: "+id)
		var overrides: Dictionary=catalog.bait_definition(id).get("species_weights",{})
		for fish: FishDefinition in catalog.fish.values():
			var expected_weight: float=float(overrides.get(fish.species_id,fish.weight_for("bait_weights",BASE_CATEGORIES[index])))
			_check(is_equal_approx(catalog.bait_weight(fish,id),expected_weight),"new bait uses explicit species weight or unchanged category fallback: "+fish.species_id+"/"+id)
		for spot: String in catalog.spots:
			var a: Array[Dictionary] = encounter.candidates(catalog,spot,id,4,0.6,"day","clear")
			var correct: bool=true
			for entry: Dictionary in a:
				var fish: FishDefinition=entry.fish
				var expected_weight: float=float(fish.raw.get("weight",1.0))*catalog.bait_weight(fish,id)*fish.weight_for("time_weights","day")*fish.weight_for("weather_weights","clear")
				if not is_equal_approx(float(entry.weight),expected_weight): correct=false
			_check(correct,"real encounter consumes exact new bait weighting: "+spot+"/"+id)
	for bait_id: String in ["worm","grain","shrimp","lure"]:
		for fish: FishDefinition in catalog.fish.values():
			_check(is_equal_approx(catalog.bait_weight(fish,bait_id),fish.weight_for("bait_weights",bait_id)),"original four bait weights unchanged across44: "+bait_id+"/"+fish.species_id)
	_check(float(catalog.gear[3].power)>float(catalog.gear[1].power) and float(catalog.gear[3].tolerance)<float(catalog.gear[1].tolerance),"light spinning has genuine speed/control tradeoff")
	_check(float(catalog.gear[4].power)>float(catalog.gear[2].power) and float(catalog.gear[4].reach)<float(catalog.gear[2].reach) and float(catalog.gear[4].max_depth_m)<float(catalog.gear[2].max_depth_m),"heavy casting does not invalidate old deep rod's reach/depth")
	_check(float(catalog.gear[3].rod_length)<float(catalog.gear[4].rod_length) and float(catalog.gear[3].rod_radius)<float(catalog.gear[4].rod_radius),"new rods carry distinct real geometry profiles")
func _test_actual_gear_mechanics() -> void:
	var base_record: Dictionary = encounter.make_individual(catalog.fish["common_carp"],"lake_shore","lake","sweetcorn",0,"day","clear")
	base_record.difficulty=0.55
	base_record.behavior="steady"
	var times: Array[float] = []
	for id: int in range(5):
		var session: FishingSession = Session.new(2468)
		session.start_charge()
		_check(session.cast(base_record,catalog.gear[id]),"real Session accepts rod "+str(id))
		_check(is_equal_approx(session.gear_power,float(catalog.gear[id].power)) and is_equal_approx(session.tolerance,float(catalog.gear[id].tolerance)),"real fighting mechanics consume rod stats "+str(id))
		session.set_state(Session.State.FIGHT)
		var controller = TestController.new()
		for tick: int in range(18000):
			if session.state!=Session.State.FIGHT: break
			var desired: bool = controller.update(session, 1.0/60.0)
			if desired and not session.reeling: session.press()
			elif not desired and session.reeling: session.release()
			session.step(1.0/60.0)
		_check(session.state==Session.State.CAUGHT,"delayed visible-cue real fight is winnable with rod "+str(id))
		times.append(session.fight_time)
	_check(times[4]<times[2] and not is_equal_approx(times[3],times[1]),"new rods change actual controlled fight outcomes rather than labels only")
	var held: Array[Vector2] = []
	for id: int in [1,3]:
		var session: FishingSession = Session.new(2468)
		session.start_charge()
		session.cast(base_record,catalog.gear[id])
		session.set_state(Session.State.FIGHT)
		session.press()
		for frame: int in range(30): session.step(1.0/60.0)
		held.append(Vector2(session.progress,session.tension))
	_check(held[1].x>held[0].x and held[1].y>held[0].y,"light spinning retrieves faster while held but also raises tension faster")
	print("TACKLE_REAL_FIGHT_SECONDS ",times)
func _test_saves() -> void:
	var path: String = "/tmp/farshore-tackle-save-"+str(Time.get_ticks_usec())
	var store: SaveStore = Store.new()
	_check(store.initialize(path),"isolated existing-save fixture initializes")
	var index: int = 0
	for fish: FishDefinition in catalog.fish.values().slice(0,44):
		var spot: String = str(fish.spots()[0])
		var record: Dictionary = encounter.make_individual(fish,spot,str(catalog.spots[spot].region_id),"shrimp",2,"day","clear")
		record["session_id"]="old_tackle_session_"+str(index)
		record["catch_id"]="old_tackle_catch_"+str(index)
		store.begin_session(record.session_id)
		_check(bool(store.settle_catch(record).ok),"historical fixture settles "+fish.species_id)
		_check(bool(store.dispose_catch(record.catch_id,"released").ok),"historical fixture preserves released record "+fish.species_id)
		index+=1
	var original: Dictionary = store.state
	original.gear=2
	original.owned_gear=[0,1,2]
	original.unlocked_regions=["lake","japan","norway","med","bayou","yangtze"]
	original.favorites=["common_carp","alligator_gar","chinese_sturgeon"]
	original.selection={"region_id":"yangtze","spot_id":"yangtze_estuary","bait_id":"shrimp"}
	_check(store.commit_state(original),"old three-rod save commits without migration")
	original=store.state
	var old_reload: SaveStore = Store.new()
	_check(old_reload.initialize(path) and _same(old_reload.state,original),"old gear/selection/unlocks/all44 histories reload unchanged")
	var extended: Dictionary = store.state
	extended.owned_gear.append(3)
	extended.owned_gear.append(4)
	extended.gear=4
	extended.selection.bait_id="spinner"
	_check(store.commit_state(extended),"existing SaveStore accepts gear4 and new bait IDs without schema bump")
	var restart: SaveStore = Store.new()
	_check(restart.initialize(path) and restart.state.gear==4 and restart.state.owned_gear==[0,1,2,3,4] and restart.state.selection.bait_id=="spinner","five-rod/eight-bait choices persist after restart")
	_check(_same(restart.state.species_stats,original.species_stats) and restart.state.favorites==original.favorites and restart.state.unlocked_regions==original.unlocked_regions,"extension never wipes archival stats/favorites/unlocks")
	for bait: Dictionary in catalog.baits:
		var record: Dictionary = encounter.make_individual(catalog.fish["common_carp"],"lake_shore","lake",str(bait.bait_id),4,"day","clear")
		record["session_id"]="new_tackle_session_"+str(bait.bait_id)
		record["catch_id"]="new_tackle_catch_"+str(bait.bait_id)
		restart.begin_session(record.session_id)
		_check(bool(restart.settle_catch(record).ok),"new catch persists original selected bait and gear4: "+str(bait.bait_id))
		_check(str(restart.state.pending_catches[record.catch_id].bait_id)==str(bait.bait_id) and int(restart.state.pending_catches[record.catch_id].equipment)==4,"catch snapshot keeps actual tackle IDs: "+str(bait.bait_id))
		_check(bool(restart.dispose_catch(record.catch_id,"released").ok),"new tackle catch disposes transactionally: "+str(bait.bait_id))
	_check(restart.total_count()==56 and restart.discovered_count()==44,"twelve new records add to44 histories, without resetting discovery")
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL TACKLE: ",label)

func _same(left: Variant,right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left,"",true,true))==JSON.parse_string(JSON.stringify(right,"",true,true))
