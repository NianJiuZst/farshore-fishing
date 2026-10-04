extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Encounter = preload("res://scripts/encounter.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL OCEAN BALANCE: ",label)
func _run() -> void:
	var catalog = Catalog.new()
	check(catalog.load_all(false),"catalog loads: "+str(catalog.errors))
	var g = Encounter.new(1337)
	var wolf = catalog.fish.atlantic_wolffish
	check(not g.preparation_status(catalog,wolf,"norway_boat","shrimp",4).available,"powerful90m rod truthfully blocks100m wolffish")
	check(g.preparation_status(catalog,wolf,"norway_boat","shrimp",2).available,"180m rod admits wolffish")
	check("100 m" in str(g.preparation_status(catalog,wolf,"norway_boat","shrimp",4).reason),"preview gives exact depth remedy")
	var summary: Array = []
	var total_giants: int = 0
	var total_extended: int = 0
	var sample_count: int = 20000
	for fish in catalog.fish.values():
		if not catalog.is_fishing_species(fish): continue
		var normal: int = int(fish.raw.get("normal_max_mm",fish.max_mm))
		check(fish.min_mm < normal and normal < fish.max_mm,"separate ordinary and fictional extreme ranges: "+fish.species_id)
		var sum_length: float = 0.0
		var giants: int = 0
		var extended: int = 0
		var longest: int = 0
		var old_mean: float = float(fish.min_mm) + float(normal-fish.min_mm)/2.9
		var expected_mean: float = .98*(float(fish.min_mm)+float(normal-fish.min_mm)/2.55)+.02*(float(normal)+float(fish.max_mm-normal)/3.6)
		for index in sample_count:
			var r: Dictionary = g.make_individual(fish,str(fish.spots()[0]),str(fish.regions()[0]),"lure",2,"day","clear")
			check(int(r.length_mm)>=fish.min_mm and int(r.length_mm)<=fish.max_mm,"bounded length: "+fish.species_id)
			check(int(r.weight_g)>0 and int(r.weight_g)<=1000000000,"savable weight: "+fish.species_id)
			sum_length += float(r.length_mm)
			longest = maxi(longest,int(r.length_mm))
			if str(r.size_class)=="巨物": giants+=1
			if int(r.length_mm)>normal: extended+=1
		var mean_length: float = sum_length/sample_count
		check(absf(mean_length-expected_mean)<float(fish.max_mm-fish.min_mm)*.012,"observed mean follows documented mixture: "+fish.species_id)
		check(float(giants)/sample_count>.08 and float(giants)/sample_count<.115,"giants increase moderately while remaining uncommon: "+fish.species_id)
		check(extended>180 and extended<600,"rare extreme tail exists: "+fish.species_id)
		check(longest>normal+roundi((fish.max_mm-normal)*.75),"extreme length genuinely reachable: "+fish.species_id)
		summary.append({"species_id":fish.species_id,"samples":sample_count,"normal_max_mm":normal,"game_max_mm":fish.max_mm,"old_distribution_mean_mm":old_mean,"expected_new_mean_mm":expected_mean,"observed_mean_mm":mean_length,"giants":giants,"above_normal_max":extended,"largest_observed_mm":longest})
		total_giants+=giants
		total_extended+=extended
	var path: String = OS.get_environment("FARSHORE_BALANCE_REPORT")
	if not path.is_empty():
		var file = FileAccess.open(path,FileAccess.WRITE)
		check(file!=null,"report opens")
		if file: file.store_string(JSON.stringify({"species":summary,"total_samples":catalog.fish_species_count()*sample_count,"giants":total_giants,"extended":total_extended,"old_giant_probability":1.0-pow(.88,1.0/1.9),"new_giant_probability":.02+.98*(1.0-pow(.88,1.0/1.55)),"failures":failures},"  "))
	check(summary.size() == 110 and summary.size() == catalog.fish_species_count(), "all 110 ordinary fish sampled")
	print("OCEAN_BALANCE_TESTS: %d/%d passed; failures=%d; samples=%d; giants=%d; extended=%d" % [checks-failures,checks,failures,catalog.fish_species_count()*sample_count,total_giants,total_extended])
	quit(0 if failures==0 else 1)
