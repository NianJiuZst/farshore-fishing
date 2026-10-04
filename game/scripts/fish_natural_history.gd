class_name FishNaturalHistory
extends RefCounted
## Independent, offline natural-history facts. Never writes catches, inventory,
## gameplay size ranges or the historical species IDs used by saved records.
const FILES: Array[String] = ["res://data/encyclopedia_a.json", "res://data/encyclopedia_b.json", "res://data/encyclopedia_c.json", "res://data/encyclopedia_d.json", "res://data/encyclopedia_e.json", "res://data/encyclopedia_f.json"]
const TEXT_FIELDS: Array[String] = ["typical_size", "habitat", "distribution", "behavior", "diet"]
var entries: Dictionary = {}
var errors: Array[String] = []
var complete: bool = false

func load_all(catalog: ContentCatalog, require_complete: bool = true) -> bool:
	entries.clear()
	errors.clear()
	complete = false
	for path: String in FILES:
		if not FileAccess.file_exists(path):
			if require_complete: errors.append("缺少鱼类资料：" + path.get_file())
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or int(parsed.get("schema_version", -1)) != 1 or not parsed.get("entries") is Array:
			errors.append("鱼类资料格式不正确：" + path.get_file())
			continue
		for value: Variant in parsed.entries:
			if not value is Dictionary:
				errors.append("鱼类资料条目格式错误")
				continue
			var id: String = str(value.get("species_id", ""))
			if not catalog.fish.has(id) or entries.has(id):
				errors.append("鱼类资料标识未知或重复：" + id)
				continue
			var issues: Array[String] = validate_entry(value)
			for issue: String in issues: errors.append(id + "：" + issue)
			if issues.is_empty(): entries[id] = value.duplicate(true)
	for id: String in catalog.fish:
		if require_complete and not entries.has(id): errors.append("鱼类资料尚未完成：" + id)
	complete = errors.is_empty() and entries.size() == catalog.fish.size()
	return errors.is_empty() and (complete or not require_complete)

func get_entry(id: String) -> Dictionary:
	return (entries.get(id, {}) as Dictionary).duplicate(true)

func scientific_name(id: String, fallback: String) -> String:
	return str((entries.get(id, {}) as Dictionary).get("accepted_scientific_name", fallback))

static func safe_source_url(url: String) -> bool:
	if not url.begins_with("https://") or url.length() > 2048: return false
	for byte: int in url.to_utf8_buffer():
		if byte <= 32 or byte == 127: return false
	var authority: String = url.substr(8).get_slice("/", 0).get_slice("?", 0).get_slice("#", 0)
	if authority.is_empty() or "@" in authority or ":" in authority or "\\" in url: return false
	var host: RegEx = RegEx.create_from_string("^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$")
	return host.search(authority) != null and "." in authority

static func validate_entry(entry: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var species_id: Variant = entry.get("species_id", "")
	if not species_id is String or RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(str(species_id)) == null:
		result.append("鱼类标识必须为非空的小写字母、数字或下划线")
	var name: String = str(entry.get("accepted_scientific_name", "")).strip_edges()
	if RegEx.create_from_string("^[A-Z][a-z]+ [a-z][a-z-]+$").search(name) == null: result.append("接受学名应为完整双名")
	var source_ids: Dictionary = {}
	var sources: Variant = entry.get("sources", [])
	if not sources is Array or sources.size() < 2:
		result.append("至少需要两个已核实资料来源")
	else:
		for source: Variant in sources:
			if not source is Dictionary:
				result.append("资料来源格式错误")
				continue
			var id: String = str(source.get("id", ""))
			if id.is_empty() or source_ids.has(id): result.append("资料来源编号重复或缺失")
			source_ids[id] = true
			for key: String in ["title", "publisher", "accessed"]:
				if str(source.get(key, "")).strip_edges().is_empty(): result.append("资料来源缺少 " + key)
			if not safe_source_url(str(source.get("url", ""))): result.append("资料来源必须为不含凭据的 HTTPS 链接")
	var taxonomy: Variant = entry.get("taxonomy", {})
	if not taxonomy is Dictionary:
		result.append("缺少分类资料")
	else:
		for key: String in ["family_scientific", "family_zh", "genus_scientific", "genus_zh"]:
			if str(taxonomy.get(key, "")).strip_edges().is_empty(): result.append("分类资料缺少 " + key)
		if not name.begins_with(str(taxonomy.get("genus_scientific", "")) + " "): result.append("学名与属名不一致")
		_check_sources(taxonomy, source_ids, result, "分类")
	for key: String in TEXT_FIELDS:
		var field: Variant = entry.get(key, {})
		if not field is Dictionary or str(field.get("text", "")).strip_edges().is_empty(): result.append("缺少 " + key)
		else: _check_sources(field, source_ids, result, key)
	for pair: Array in [["max_length", "value_cm"], ["max_weight", "value_kg"]]:
		var field: Variant = entry.get(pair[0], {})
		if not field is Dictionary or not field.has(pair[1]) or str(field.get("text", "")).strip_edges().is_empty():
			result.append("缺少有单位和说明的 " + str(pair[0]))
			continue
		var number: Variant = field[pair[1]]
		if field.has("record_label") and (not field.record_label is String or str(field.record_label).strip_edges().is_empty()): result.append("记录范围标签必须为非空文字")
		if number != null and (not (number is int or number is float) or not is_finite(float(number)) or float(number) <= 0): result.append("生物尺寸必须为正数，缺值使用 null")
		if pair[0] == "max_length" and str(field.get("length_type", "")) not in ["TL", "FL", "SL", "unspecified"]: result.append("必须注明全长、叉长、标准体长或未注明量法")
		_check_sources(field, source_ids, result, str(pair[0]))
	var story: Variant = entry.get("story", {})
	if not story is Dictionary or str(story.get("title", "")).strip_edges().is_empty() or str(story.get("text", "")).strip_edges().is_empty(): result.append("缺少已核实的鱼类故事")
	else: _check_sources(story, source_ids, result, "故事")
	return result

static func _check_sources(field: Dictionary, source_ids: Dictionary, result: Array[String], label: String) -> void:
	var refs: Variant = field.get("source_ids", [])
	if not refs is Array or refs.is_empty():
		result.append(label + " 缺少字段级来源")
		return
	for id: Variant in refs:
		if not id is String or not source_ids.has(id): result.append(label + " 的来源编号未定义")
