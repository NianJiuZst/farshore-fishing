extends SceneTree
## Real encounter/session checks. All bait tuning is fictional game balance.
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Session = preload("res://scripts/fishing_session.gd")
const Controller = preload("res://tests/fishing_test_controller.gd")
const LEGACY_IDS: Array[String] = ["worm", "grain", "shrimp", "lure", "sweetcorn", "dough", "cut_fish", "spinner"]
const LARGE_IDS: Array[String] = ["large_fish_chunk", "whole_mackerel", "large_squid", "large_surface_lure"]
const SAMPLE_COUNT: int = 8000
var catalog: ContentCatalog = Catalog.new()
var checks: int = 0
var failures: Array[String] = []
var routes: Dictionary = {}
var report: Dictionary = {"scope":"Headless game logic only; not fishing advice, natural-history evidence, UI or device certification", "size_samples":[], "selectivity":[], "fights":[]}

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("FAIL GIANT BAIT: ",detail)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# This intentionally happens before load_all: direct specimen tools must use
	# the very same world.json tuning as real generate() encounters.
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	for bait: Dictionary in world.baits:
		check(Catalog.bait_size_exponent(str(bait.bait_id),Encounter.SIZE_EXPONENT) == float(bait.get("size_exponent",Encounter.SIZE_EXPONENT)),"cold configured size lookup: "+str(bait.bait_id))
	check(catalog.load_all(false),"catalog loads: "+str(catalog.errors))
	check(catalog.baits.size()==12 and catalog.fish.size()==74 and catalog.regions.size()==9 and catalog.spots.size()==18,"12 baits / 74 species / 9 regions / 18 spots")
	_legacy_regression(world)
	_configuration_validation()
	_legal_routes()
	_selectivity()
	_size_distribution()
	_hook_and_fight()
	report["giant_probability_original"] = Encounter.EXTENDED_SIZE_CHANCE+(1.0-Encounter.EXTENDED_SIZE_CHANCE)*(1.0-pow(0.88,1.0/Encounter.SIZE_EXPONENT))
	var path: String = OS.get_environment("FARSHORE_GIANT_BAIT_REPORT")
	if not path.is_empty():
		var output: FileAccess = FileAccess.open(path,FileAccess.WRITE)
		check(output!=null,"report file writable")
		report["checks"] = checks
		report["failures"] = failures
		if output: output.store_string(JSON.stringify(report,"  ",true)+"\n")
	print("GIANT_BAIT_TESTS: %d/%d; failures=%d; bait/species routes=%d/888; size samples=%d" % [checks-failures.size(),checks,failures.size(),routes.size(),catalog.fish.size()*LARGE_IDS.size()*SAMPLE_COUNT])
	quit(0 if failures.is_empty() else 1)

func _legacy_regression(world: Dictionary) -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/giant_bait_legacy_baseline.json"))
	for path: String in fixture.source_sha256:
		check(FileAccess.get_sha256(path)==str(fixture.source_sha256[path]),"fish/natural-history source frozen: "+path)
	world = world.duplicate(true)
	world.erase("baits")
	check(JSON.stringify(world,"",true).sha256_text()==str(fixture.world_without_baits_sha256),"all non-bait world data remains exact")
	for index: int in LEGACY_IDS.size():
		var id: String = LEGACY_IDS[index]
		check(catalog.baits[index]==fixture.legacy_baits[index] and str(catalog.baits[index].bait_id)==id,"legacy bait definition/order preserved: "+id)
		check(Catalog.bait_size_exponent(id,Encounter.SIZE_EXPONENT)==Encounter.SIZE_EXPONENT,"legacy size exponent unchanged: "+id)
		var g: EncounterGenerator = Encounter.new(int(fixture.seed))
		var hash_context: HashingContext = HashingContext.new()
		hash_context.start(HashingContext.HASH_SHA256)
		for fish: FishDefinition in catalog.fish.values():
			check(catalog.bait_weight(fish,id)==float(fixture.attraction_weights[fish.species_id][index]),"legacy weight exact: "+id+"/"+fish.species_id)
			for sample: int in int(fixture.samples_per_species_per_bait):
				var record: Dictionary = g.make_individual(fish,str(fish.spots()[0]),str(fish.regions()[0]),id,2,"day","clear")
				record.erase("caught_at")
				hash_context.update(JSON.stringify(record,"",true).to_utf8_buffer())
		check(hash_context.finish().hex_encode()==str(fixture.legacy_rng_signatures[id].records_sha256),"all seeded record fields exact: "+id)
		check(str(g.rng.state)==str(fixture.legacy_rng_signatures[id].rng_state),"RNG sequence unchanged: "+id)
	report["legacy_records_verified"] = LEGACY_IDS.size()*catalog.fish.size()*int(fixture.samples_per_species_per_bait)

func _configuration_validation() -> void:
	for index: int in LARGE_IDS.size():
		var id: String = LARGE_IDS[index]
		var bait: Dictionary = catalog.bait_definition(id)
		check(str(catalog.baits[index+8].bait_id)==id,"new bait appended at stable position: "+id)
		check(float(bait.price)==0.0 and not str(bait.name).is_empty() and "游戏设定" in str(bait.hint),"free bait with clear game-only hint: "+id)
		check(str(bait.name).length()<=4,"concise name fits existing HUD caption: "+id)
		check(Catalog.bait_tuning_errors(bait).is_empty(),"valid bait tuning: "+id)
		for fish: FishDefinition in catalog.fish.values():
			check(is_finite(catalog.bait_weight(fish,id)) and catalog.bait_weight(fish,id)>0.0,"finite positive weight: "+id+"/"+fish.species_id)
	for value: Variant in [0.0,-1.0,0.74,2.01,INF,NAN,"0.88",null,{},[]]:
		check(not Catalog.bait_tuning_errors({"bait_id":"invalid","size_exponent":value}).is_empty(),"invalid size exponent rejected: "+str(value))
	for value: Variant in [-0.01,1.01,INF,NAN,"0.10",null,{},[]]:
		check(not Catalog.bait_tuning_errors({"bait_id":"invalid","fallback_weight_scale":value}).is_empty(),"invalid fallback scale rejected: "+str(value))
	check(Catalog.bait_size_exponent("unknown_bait",Encounter.SIZE_EXPONENT)==Encounter.SIZE_EXPONENT,"unknown ID retains safe legacy size default")

func _legal_routes() -> void:
	var g: EncounterGenerator = Encounter.new(99074)
	# Keep the highest-probability legal route for each actual species/bait pair.
	for spot_id: String in catalog.spots:
		var spot: Dictionary = catalog.spots[spot_id]
		for gear: Dictionary in catalog.gear:
			if int(gear.id)<int(spot.min_gear): continue
			for bait: Dictionary in catalog.baits:
				var id: String = str(bait.bait_id)
				for step: int in range(1,21):
					var power: float = step*0.05
					if power>float(gear.reach): continue
					for time: String in ["day","dusk"]:
						for weather: String in ["clear","rain"]:
							var candidates: Array[Dictionary] = g.candidates(catalog,spot_id,id,int(gear.id),power,time,weather)
							var total: float = 0.0
							for item: Dictionary in candidates: total+=float(item.weight)
							for item: Dictionary in candidates:
								var fish: FishDefinition = item.fish
								var key: String = id+"/"+fish.species_id
								var probability: float = float(item.weight)/total
								if not routes.has(key) or probability>float(routes[key].probability):
									routes[key]={"bait":id,"species":fish.species_id,"spot":spot_id,"region":str(spot.region_id),"gear":int(gear.id),"power":power,"time":time,"weather":weather,"probability":probability}
	var draws: int = 0
	var largest_wait: int = 0
	for bait: Dictionary in catalog.baits:
		for fish: FishDefinition in catalog.fish.values():
			var key: String = str(bait.bait_id)+"/"+fish.species_id
			check(routes.has(key),"legal candidates route: "+key)
			if not routes.has(key): continue
			var route: Dictionary = routes[key]
			check(bool(g.preparation_status(catalog,fish,route.spot,route.bait,route.gear).available),"preparation agrees: "+key)
			var found: bool = false
			var count: int = 0
			while not found and count<30000:
				var record: Dictionary = g.generate(catalog,route.spot,route.bait,route.gear,route.power,route.time,route.weather)
				count+=1
				if record.is_empty(): break
				found = str(record.species_id)==fish.species_id
				if found:
					check(str(record.bait_id)==str(bait.bait_id) and int(record.equipment)==int(route.gear),"generated exact bait/rod identity: "+key)
					check(float(record.bait_affinity)==catalog.bait_weight(fish,str(bait.bait_id)),"float receives actual affinity: "+key)
					if str(bait.bait_id)=="large_surface_lure": check(str(record.float_rig)=="suspended","surface lure never bottom-rigged: "+key)
			check(found,"actual generate reaches species/bait: "+key)
			draws+=count
			largest_wait=maxi(largest_wait,count)
	report["legal_bait_species_pairs"] = routes.size()
	report["reachability_draws"] = draws
	report["maximum_draws_to_reach_species"] = largest_wait
	for id: String in LARGE_IDS:
		check(g.candidates(catalog,"pacific_bluewater",id,0,0.3,"day","clear").is_empty(),"large bait never bypasses ocean rod gate: "+id)
		check(not bool(g.preparation_status(catalog,catalog.fish.atlantic_wolffish,"norway_boat",id,4).available),"large bait never bypasses depth gate: "+id)
		check(not g.candidates(catalog,"unknown_spot",id,2,0.8,"day","clear").size(),"unknown spot stays unavailable: "+id)

func _selectivity() -> void:
	var cases: Array[Dictionary] = [
		{"bait":"large_fish_chunk","other":"whole_mackerel","species":"alligator_gar"},
		{"bait":"large_fish_chunk","other":"large_surface_lure","species":"giant_grouper"},
		{"bait":"whole_mackerel","other":"large_surface_lure","species":"great_white_shark"},
		{"bait":"large_squid","other":"whole_mackerel","species":"swordfish"},
		{"bait":"large_squid","other":"large_surface_lure","species":"opah"},
		{"bait":"large_surface_lure","other":"large_squid","species":"giant_trevally"},
		{"bait":"large_surface_lure","other":"whole_mackerel","species":"indo_pacific_sailfish"}]
	for item: Dictionary in cases:
		var fish: FishDefinition = catalog.fish[item.species]
		check(catalog.bait_weight(fish,item.bait)>catalog.bait_weight(fish,item.other)*5.0,"different target species weights: "+str(item.species))
		var route: Dictionary = routes[str(item.bait)+"/"+str(item.species)]
		var counts: Array[int] = []
		var probabilities: Array[float] = []
		for id: String in [str(item.bait),str(item.other)]:
			var g: EncounterGenerator = Encounter.new(18174)
			var target: int = 0
			var total_weight: float = 0.0
			var target_weight: float = 0.0
			for candidate: Dictionary in g.candidates(catalog,route.spot,id,route.gear,route.power,route.time,route.weather):
				total_weight+=float(candidate.weight)
				if candidate.fish.species_id==str(item.species): target_weight=float(candidate.weight)
			var probability: float = target_weight/total_weight
			for sample: int in 12000:
				var record: Dictionary = g.generate(catalog,route.spot,id,route.gear,route.power,route.time,route.weather)
				if str(record.species_id)==str(item.species): target+=1
			check(absf(float(target)/12000.0-probability)<0.022,"actual species mix matches weighting: "+id+"/"+str(item.species))
			counts.append(target)
			probabilities.append(probability)
		check(counts[0]>counts[1]*2,"matched-route selectivity is meaningful in real generate: "+str(item.species))
		report.selectivity.append({"species":item.species,"bait":item.bait,"comparison_bait":item.other,"spot":route.spot,"samples_each":12000,"target_count":counts[0],"comparison_count":counts[1],"expected_target_share":probabilities[0],"expected_comparison_share":probabilities[1]})

func _size_distribution() -> void:
	var baseline_probability: float = 0.02+0.98*(1.0-pow(0.88,1.0/Encounter.SIZE_EXPONENT))
	var summary: Array[Dictionary] = []
	for id: String in LARGE_IDS:
		var exponent: float = Catalog.bait_size_exponent(id,Encounter.SIZE_EXPONENT)
		var expected_giant_probability: float = 0.02+0.98*(1.0-pow(0.88,1.0/exponent))
		check(expected_giant_probability>=0.14 and expected_giant_probability<=0.18,"bounded theoretical giant probability: "+id)
		var total_giants: int = 0
		var total_extended: int = 0
		var total_small: int = 0
		for fish: FishDefinition in catalog.fish.values():
			var route: Dictionary = routes[id+"/"+fish.species_id]
			var g: EncounterGenerator = Encounter.new(752411+int(fish.species_id.hash() & 65535))
			var baseline: EncounterGenerator = Encounter.new(752411+int(fish.species_id.hash() & 65535))
			var normal: float = float(fish.raw.normal_max_mm)
			var expected_mean: float = 0.98*(fish.min_mm+(normal-fish.min_mm)/(1.0+exponent))+0.02*(normal+(fish.max_mm-normal)/(1.0+Encounter.EXTENDED_SIZE_EXPONENT))
			var giants: int = 0
			var extended: int = 0
			var small: int = 0
			var sum_length: float = 0.0
			var longest: int = 0
			for sample: int in SAMPLE_COUNT:
				var r: Dictionary = g.make_individual(fish,route.spot,route.region,id,route.gear,route.time,route.weather)
				check(int(r.length_mm)>=fish.min_mm and int(r.length_mm)<=fish.max_mm,"length stays within game cap: "+id+"/"+fish.species_id)
				check(int(r.weight_g)>0 and int(r.weight_g)<=1000000000,"weight stays savable: "+id+"/"+fish.species_id)
				check(is_equal_approx(float(r.difficulty),clampf(fish.difficulty*0.7+float(r.size_fraction)*0.5,0.15,1.0)),"size retains fight difficulty: "+id+"/"+fish.species_id)
				if sample<128:
					var old: Dictionary = baseline.make_individual(fish,route.spot,route.region,"lure",route.gear,route.time,route.weather)
					check(g.rng.state==baseline.rng.state,"large bait uses same random draw count: "+id+"/"+fish.species_id)
					check(int(r.length_mm)>=int(old.length_mm) and float(r.difficulty)>=float(old.difficulty),"paired size boost never weakens fight: "+id+"/"+fish.species_id)
					if float(r.size_fraction)==1.0:
						check(int(r.length_mm)==int(old.length_mm) and int(r.weight_g)==int(old.weight_g),"extended tail remains exactly paired: "+id+"/"+fish.species_id)
				sum_length+=float(r.length_mm)
				longest=maxi(longest,int(r.length_mm))
				if str(r.size_class)=="巨物": giants+=1
				if int(r.length_mm)>int(normal): extended+=1
				if str(r.size_class)=="小巧": small+=1
			var rate: float = float(giants)/SAMPLE_COUNT
			check(absf(rate-expected_giant_probability)<0.022,"within-species rate follows configured model: "+id+"/"+fish.species_id)
			check(rate>baseline_probability+0.025 and rate<0.20,"meaningful but bounded same-species giant boost: "+id+"/"+fish.species_id)
			check(absf(sum_length/SAMPLE_COUNT-expected_mean)<float(fish.max_mm-fish.min_mm)*0.015,"mean follows exact mixture: "+id+"/"+fish.species_id)
			check(extended>80 and extended<240 and longest>int(normal),"same rare extended tail still reachable: "+id+"/"+fish.species_id)
			check(small>100,"large bait can still produce small fish: "+id+"/"+fish.species_id)
			report.size_samples.append({"bait":id,"species":fish.species_id,"samples":SAMPLE_COUNT,"giants":giants,"extended":extended,"small":small,"expected_giant_probability":expected_giant_probability,"observed_giant_probability":rate,"expected_mean_mm":expected_mean,"observed_mean_mm":sum_length/SAMPLE_COUNT,"longest_mm":longest,"game_max_mm":fish.max_mm})
			total_giants+=giants
			total_extended+=extended
			total_small+=small
		var samples: int = catalog.fish.size()*SAMPLE_COUNT
		var aggregate_rate: float = float(total_giants)/samples
		check(aggregate_rate>=0.14 and aggregate_rate<=0.18 and absf(aggregate_rate-expected_giant_probability)<0.003,"aggregate giant rate is bounded and accurate: "+id)
		summary.append({"bait":id,"size_exponent":exponent,"samples":samples,"expected_giant_probability":expected_giant_probability,"observed_giant_probability":aggregate_rate,"extended_rate":float(total_extended)/samples,"small_rate":float(total_small)/samples})
		print("GIANT BAIT SIZE: ",id," probability=",aggregate_rate," samples=",samples)
	report["size_summary"] = summary

func _launch(record: Dictionary, gear_id: int, seed_value: int) -> FishingSession:
	var session: FishingSession = Session.new(seed_value)
	session.press()
	session.step(0.2)
	check(session.cast(record,catalog.gear[gear_id]),"real session accepts generated record")
	session.release()
	return session

func _hook_and_fight() -> void:
	var targets: Array[String] = ["alligator_gar","great_white_shark","swordfish","giant_trevally"]
	for index: int in LARGE_IDS.size():
		var id: String = LARGE_IDS[index]
		var route: Dictionary = routes[id+"/"+targets[index]]
		var fish: FishDefinition = catalog.fish[route.species]
		var g: EncounterGenerator = Encounter.new(471612)
		var giant: Dictionary = {}
		var ordinary: Dictionary = {}
		for attempt: int in 2000:
			var record: Dictionary = g.make_individual(fish,route.spot,route.region,id,route.gear,route.time,route.weather)
			g.apply_float_presentation(record,catalog,route.power)
			if str(record.size_class)=="巨物" and giant.is_empty(): giant=record
			if float(record.size_fraction)<0.35 and ordinary.is_empty(): ordinary=record
			if not giant.is_empty() and not ordinary.is_empty(): break
		check(not giant.is_empty() and not ordinary.is_empty(),"both giant and ordinary individuals exist: "+id)
		if giant.is_empty() or ordinary.is_empty(): continue
		var giant_session: FishingSession = _launch(giant,route.gear,7703)
		var ordinary_session: FishingSession = _launch(ordinary,route.gear,7703)
		check(giant_session._endurance>ordinary_session._endurance and giant_session._difficulty>ordinary_session._difficulty,"giant retains tougher real-session endurance/difficulty: "+id)
		for tick: int in 60:
			giant_session.step(1.0/60.0)
			if giant_session.state==Session.State.WAITING: break
		check(not giant_session.float_encounter.can_hook(),"large bait has no hook guarantee at first approach: "+id)
		giant_session.press()
		check(giant_session.state==Session.State.ESCAPED,"early strike still fails for giant bait: "+id)
		for strategy: String in ["never_pull","always_pull","behavior_aware"]:
			var session: FishingSession = _launch(giant,route.gear,7703)
			for tick: int in 5400:
				if session.state in [Session.State.BITE,Session.State.CAUGHT,Session.State.ESCAPED]: break
				session.step(1.0/60.0)
			check(session.state==Session.State.BITE,"legitimate hookable take exists: "+id)
			session.press()
			session.release()
			check(session.state==Session.State.FIGHT,"correctly timed hook starts real fight: "+id)
			var controller: RefCounted = Controller.new(strategy)
			for tick: int in 25200:
				if session.state!=Session.State.FIGHT: break
				var held: bool = controller.update(session,1.0/60.0)
				if held and not session.reeling: session.press()
				elif not held and session.reeling: session.release()
				session.step(1.0/60.0)
			check(session.state in [Session.State.CAUGHT,Session.State.ESCAPED],"fight terminates within bounded simulation: "+id+"/"+strategy)
			check(session.fight_time>1.0,"large bait does not skip fighting: "+id+"/"+strategy)
			if strategy in ["never_pull","always_pull"]:
				check(session.state==Session.State.ESCAPED,"unmanaged giant can still escape: "+id+"/"+strategy)
			else:
				check(session.state==Session.State.CAUGHT,"visible-cue control can land a generated giant: "+id)
			report.fights.append({"bait":id,"species":fish.species_id,"size_fraction":giant.size_fraction,"strategy":strategy,"caught":session.state==Session.State.CAUGHT,"fight_seconds":session.fight_time,"escape_reason":session.escape_reason,"gear":route.gear,"difficulty":giant.difficulty})
