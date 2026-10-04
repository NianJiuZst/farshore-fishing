extends SceneTree
const Registry = preload("res://scripts/fish_3d_registry.gd")
const Catalog = preload("res://scripts/catalog.gd")
var checks: int = 0
var failures: int = 0

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL 3D REGISTRY: ", detail)

func _initialize() -> void:
	var catalog: ContentCatalog = Catalog.new()
	check(catalog.load_all(false), "catalog loads")
	check(Registry.validate_catalog(catalog, false).is_empty(), "all required definitions match catalog")
	check(Registry.species_ids().size() == 111 and catalog.fish_species_count() == 110, "110 fish and one whale have distinct model definitions")
	check(Registry.model_path("unknown").is_empty(), "unknown species cannot fall back to carp")
	check(not Registry.is_available("unknown"), "unknown species unavailable")
	var available: int = 0
	for id: String in catalog.fish:
		check(Registry.model_path(id) == "res://assets/3d/" + id + ".glb", "unique named model " + id)
		check(is_equal_approx(float(Registry.model_info(id).rest_length_m), 1.0), "normalized rest length " + id)
		if Registry.is_available(id): available += 1
	check(bool(Registry.model_info("olive_flounder").asymmetric_flatfish), "left-eyed flatfish flagged")
	check(bool(Registry.model_info("european_plaice").asymmetric_flatfish), "right-eyed flatfish flagged")
	check(bool(Registry.model_info("pacific_halibut").get("asymmetric_flatfish", false)), "new right-eyed Pacific halibut flagged")
	check(bool(Registry.model_info("turbot").get("asymmetric_flatfish", false)), "new left-eyed turbot flagged")
	var detached: Dictionary = Registry.manifest()
	(detached.models as Dictionary).clear()
	check(Registry.species_ids().size() == 111, "callers cannot mutate registry")
	var missing: Array[String] = Registry.validate_catalog(catalog, true)
	check(missing.size() == 111 - available, "asset readiness is reported truthfully")
	var require_all: bool = "--require-all" in OS.get_cmdline_user_args()
	if require_all:
		for error: String in missing: check(false, error)
		check(available == 111, "release requires all111 actual imported assets")
	print("FISH_3D_REGISTRY_TESTS: ", checks - failures, "/", checks, "; imported models=", available, "/111 (110 fish + one whale); release_gate=", require_all)
	quit(0 if failures == 0 else 1)
