class_name SaveStore
extends RefCounted
## One synchronous writer per save root. Callers receive detached state snapshots.
## No cross-platform atomicity or power-loss durability guarantee is claimed.

const SCHEMA_VERSION: int = 2
const MAX_PENDING: int = 64
const MAX_RECENT_IDS: int = 256
const MAX_FAVORITES: int = 6
const MAX_SAVE_BYTES: int = 8 * 1024 * 1024
const MAX_COUNTER: int = 1000000000
const MAX_CURRENCY: int = 1000000000000
const PRIMARY_NAME: String = "save.json"
const BACKUP_NAME: String = "save.backup.json"

var error_message: String = ""
var status_message: String = ""
var read_only: bool = false
var state: Dictionary:
	get:
		_mutex.lock()
		var snapshot: Dictionary = _state.duplicate(true)
		_mutex.unlock()
		return snapshot

var _state: Dictionary = {}
var _root: String = ""
var _active_session: String = ""
var _retry_record: Dictionary = {}
var _initialized: bool = false
var _writing: bool = false
var _mutex: Mutex = Mutex.new()

static func default_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION, "save_revision": 0,
		"currency": 120, "gear": 0, "owned_gear": [0],
		"unlocked_regions": ["lake"], "species_stats": {},
		"favorites": [], "pending_catches": {}, "recent_ids": [],
		"settings": {"sound": true, "vibration": true, "volume": 0.6},
		"selection": {"region_id": "lake", "spot_id": "lake_shore", "bait_id": "worm"},
		"game_clock": 0.0
	}

func initialize(optional_root: String = "user://") -> bool:
	_mutex.lock()
	var result: bool = _initialize_locked(optional_root)
	_mutex.unlock()
	return result

func _initialize_locked(optional_root: String) -> bool:
	error_message = ""
	status_message = ""
	read_only = false
	_initialized = false
	_active_session = ""
	_retry_record = {}
	_state = default_state()
	_root = ProjectSettings.globalize_path(optional_root).simplify_path()
	if not _root.is_absolute_path():
		return _fail("存档目录必须是本地绝对路径。")
	var make_error: Error = DirAccess.make_dir_recursive_absolute(_root)
	if make_error != OK:
		return _fail("无法创建存档目录（%s）。" % error_string(make_error))
	var primary: Dictionary = _read_save(_path(PRIMARY_NAME))
	var backup: Dictionary = _read_save(_path(BACKUP_NAME))
	# Never downgrade either known save, even when another older file is readable.
	if bool(primary.get("future", false)) or bool(backup.get("future", false)):
		read_only = true
		return _fail("发现更高版本的存档，已保护原文件。请使用较新版本游戏。")
	if bool(primary.get("ok", false)):
		_state = (primary["state"] as Dictionary).duplicate(true)
		_initialized = true
		status_message = "已读取本地存档。"
		if int(primary["version"]) < SCHEMA_VERSION:
			status_message = "旧版存档已在内存中迁移，下次成功保存时写入新版；历史数量和纪录保留。"
		return true
	if bool(backup.get("ok", false)):
		_state = (backup["state"] as Dictionary).duplicate(true)
		_initialized = true
		status_message = "主存档缺失或损坏，已从有效备份恢复；最近一次提交可能不在备份中。原损坏文件将被保留。"
		return true
	if bool(primary["exists"]) or bool(backup["exists"]):
		read_only = true
		return _fail("主存档和备份均不可用，已保留原文件，未创建空白存档。请保留应用数据并寻求恢复。")
	_initialized = true
	if not _persist_candidate(_state):
		return false
	status_message = "已创建本地存档。"
	return true

func begin_session(session_id: String) -> void:
	_mutex.lock()
	if not _initialized or read_only:
		_fail("存档不可写，无法开始新的钓鱼结算。")
	elif not _valid_id(session_id):
		_fail("钓鱼会话标识不合法。")
	elif not _retry_record.is_empty() and session_id != _active_session:
		_fail("上一条钓获尚未保存，请先重试或明确放弃该会话。")
	else:
		_active_session = session_id
		error_message = ""
	_mutex.unlock()

func abandon_session(session_id: String) -> void:
	_mutex.lock()
	if session_id == _active_session:
		_active_session = ""
		_retry_record = {}
	_mutex.unlock()

func settle_catch(record: Dictionary) -> Dictionary:
	_mutex.lock()
	var result: Dictionary = _settle_locked(record)
	_mutex.unlock()
	return result

func _settle_locked(record: Dictionary) -> Dictionary:
	var failure: Dictionary = {"ok": false, "error": "", "new_species": false,
		"new_length": false, "new_weight": false, "duplicate": false}
	if not _initialized or read_only:
		return _result_error(failure, "存档不可写；本次钓获尚未保存。")
	var catch_id: String = str(record.get("catch_id", ""))
	if (_state["recent_ids"] as Array).has(catch_id) or (_state["pending_catches"] as Dictionary).has(catch_id):
		failure["duplicate"] = true
		return _result_error(failure, "该钓获已结算，不会重复计数或奖励。")
	if _active_session.is_empty() or str(record.get("session_id", "")) != _active_session:
		return _result_error(failure, "钓鱼会话已结束或已过期；旧结果未结算。")
	if not _valid_catch(record):
		return _result_error(failure, "钓获数据不合法；本次钓获尚未保存。")
	if not _retry_record.is_empty() and _retry_record != record:
		return _result_error(failure, "保存重试必须使用同一条原始钓获，不能更换结果。")
	if (_state["pending_catches"] as Dictionary).size() >= MAX_PENDING:
		return _result_error(failure, "待处理鱼已达 %d 条，请先出售或放生，再重试保存。" % MAX_PENDING)
	var candidate: Dictionary = _state.duplicate(true)
	var snapshot: Dictionary = record.duplicate(true)
	var species_id: String = str(record["species_id"])
	var species_stats: Dictionary = candidate["species_stats"]
	var is_new: bool = not species_stats.has(species_id) or int((species_stats[species_id] as Dictionary).get("catch_count", 0)) == 0
	var stats: Dictionary = species_stats.get(species_id, {"catch_count": 0, "first": {},
		"last": {}, "max_length": {}, "max_weight": {}, "regions": {}})
	var length_record: Dictionary = stats["max_length"]
	var weight_record: Dictionary = stats["max_weight"]
	var new_length: bool = length_record.is_empty() or int(record["length_mm"]) > int(length_record["length_mm"])
	var new_weight: bool = weight_record.is_empty() or int(record["weight_g"]) > int(weight_record["weight_g"])
	stats["catch_count"] = int(stats["catch_count"]) + 1
	if (stats["first"] as Dictionary).is_empty():
		stats["first"] = snapshot.duplicate(true)
	stats["last"] = snapshot.duplicate(true)
	if new_length:
		stats["max_length"] = snapshot.duplicate(true)
	if new_weight:
		stats["max_weight"] = snapshot.duplicate(true)
	var regions: Dictionary = stats["regions"]
	var region_id: String = str(record["region_id"])
	regions[region_id] = int(regions.get(region_id, 0)) + 1
	species_stats[species_id] = stats
	candidate["currency"] = int(candidate["currency"]) + int(record.get("reward", 25))
	(candidate["pending_catches"] as Dictionary)[catch_id] = snapshot.duplicate(true)
	var recent: Array = candidate["recent_ids"]
	recent.append(catch_id)
	while recent.size() > MAX_RECENT_IDS:
		recent.pop_front()
	_retry_record = snapshot.duplicate(true)
	if not _commit_locked(candidate):
		failure["error"] = error_message
		return failure
	_active_session = ""
	_retry_record = {}
	return {"ok": true, "error": "", "new_species": is_new, "new_length": new_length,
		"new_weight": new_weight, "duplicate": false}

func dispose_catch(catch_id: String, action: String) -> Dictionary:
	_mutex.lock()
	var result: Dictionary = _dispose_locked(catch_id, action)
	_mutex.unlock()
	return result

func _dispose_locked(catch_id: String, action: String) -> Dictionary:
	var failure: Dictionary = {"ok": false, "error": "", "duplicate": false}
	if not _initialized or read_only:
		return _result_error(failure, "存档不可写；鱼尚未处理。")
	if action != "sold" and action != "released":
		return _result_error(failure, "处理方式必须是出售或放生。")
	var pending: Dictionary = _state["pending_catches"]
	if not pending.has(catch_id):
		failure["duplicate"] = true
		return _result_error(failure, "该鱼已处理或不存在，不会重复发放收益。")
	var candidate: Dictionary = _state.duplicate(true)
	var record: Dictionary = pending[catch_id]
	var value: int = int(record.get("sale_value", 20)) if action == "sold" else 8
	candidate["currency"] = int(candidate["currency"]) + value
	(candidate["pending_catches"] as Dictionary).erase(catch_id)
	if not _commit_locked(candidate):
		failure["error"] = error_message
		return failure
	return {"ok": true, "error": "", "duplicate": false}

func commit_state(candidate: Dictionary) -> bool:
	_mutex.lock()
	var result: bool = _commit_locked(candidate)
	_mutex.unlock()
	return result

func _commit_locked(candidate: Dictionary) -> bool:
	if not _initialized or read_only:
		return _fail("存档处于保护模式，未写入任何更改。")
	if _writing:
		return _fail("存档正在写入，请稍后重试。")
	if int(candidate.get("save_revision", -1)) != int(_state["save_revision"]):
		return _fail("状态已更新，请重新读取当前状态后再保存。")
	var checked: Dictionary = _normalize_state(candidate.duplicate(true))
	if not bool(checked.get("ok", false)):
		return _fail("存档状态不合法：%s" % str(checked.get("error", "未知错误")))
	var committed: Dictionary = checked["state"]
	committed["save_revision"] = int(_state["save_revision"]) + 1
	_writing = true
	var success: bool = _persist_candidate(committed)
	_writing = false
	if not success:
		return false
	_state = committed
	error_message = ""
	return true

func total_count() -> int:
	_mutex.lock()
	var total: int = 0
	for item: Variant in (_state.get("species_stats", {}) as Dictionary).values():
		total += int((item as Dictionary).get("catch_count", 0))
	_mutex.unlock()
	return total

func discovered_count() -> int:
	_mutex.lock()
	var count: int = 0
	for item: Variant in (_state.get("species_stats", {}) as Dictionary).values():
		if int((item as Dictionary).get("catch_count", 0)) > 0:
			count += 1
	_mutex.unlock()
	return count

func _persist_candidate(candidate: Dictionary) -> bool:
	var primary_path: String = _path(PRIMARY_NAME)
	var backup_path: String = _path(BACKUP_NAME)
	var temp_path: String = _path("save.tmp.json")
	var backup_temp: String = _path("save.backup.tmp.json")
	# Recheck files in case they changed since initialization. Never overwrite future data.
	var primary: Dictionary = _read_save(primary_path)
	var backup: Dictionary = _read_save(backup_path)
	if bool(primary.get("future", false)) or bool(backup.get("future", false)):
		read_only = true
		return _fail("发现更高版本存档，已停止写入并保护原文件。")
	if not _write_verified_json(temp_path, candidate):
		return false
	if bool(primary["exists"]) and not bool(primary.get("ok", false)):
		if not _preserve_corrupt(primary_path):
			return false
	if bool(backup["exists"]) and not bool(backup.get("ok", false)):
		if not _preserve_corrupt(backup_path):
			return false
	if bool(primary.get("ok", false)):
		# Backup is the last fully readable primary, not an uncommitted new result.
		if not _copy_verified(primary_path, backup_temp):
			return false
		if not _replace_file(backup_temp, backup_path):
			return false
	elif not bool(backup.get("ok", false)):
		# First save has a valid baseline backup too.
		if not _write_verified_json(backup_temp, candidate):
			return false
		if not _replace_file(backup_temp, backup_path):
			return false
	# rename-over-existing is checked rather than emulated with delete-then-rename.
	if not _replace_file(temp_path, primary_path):
		return false
	var verify: Dictionary = _read_save(primary_path)
	if not bool(verify.get("ok", false)) or not _same_json(verify["state"], candidate):
		read_only = true
		return _fail("存档替换后的校验失败，结果不确定。已停止继续写入，请重启后核对，勿清除应用数据。")
	return true

func _write_verified_json(path: String, value: Dictionary) -> bool:
	var text: String = JSON.stringify(value, "", true, true)
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _fail("存档超过安全大小限制，未覆盖原文件。")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入临时存档（%s）。请检查存储空间；本次结果尚未保存，可重试。" % error_string(FileAccess.get_open_error()))
	file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return _fail("写入或刷新临时存档失败（%s）；原存档未替换。" % error_string(write_error))
	var file_text: Dictionary = _read_text(path)
	if not bool(file_text.get("ok", false)) or str(file_text.get("text", "")) != text:
		return _fail("临时存档读取校验失败；原存档未替换。")
	var check: Dictionary = _read_save(path)
	if not bool(check.get("ok", false)) or not _same_json(check["state"], value):
		return _fail("临时存档内容校验失败（%s）；原存档未替换。" % str(check.get("error", "内容不一致")))
	return true

func _copy_verified(source: String, destination: String) -> bool:
	var result: Error = DirAccess.copy_absolute(source, destination)
	if result != OK:
		return _fail("备份复制失败（%s）；原存档未替换。" % error_string(result))
	var before: Dictionary = _read_text(source)
	var after: Dictionary = _read_text(destination)
	if not bool(before.get("ok", false)) or not bool(after.get("ok", false)) or before["text"] != after["text"]:
		return _fail("备份复制校验失败；原存档未替换。")
	return true

func _replace_file(source: String, destination: String) -> bool:
	var result: Error = DirAccess.rename_absolute(source, destination)
	if result != OK:
		return _fail("存档替换失败（%s）；已保存的文件与备份保留，可重试。" % error_string(result))
	return true

func _preserve_corrupt(path: String) -> bool:
	var archive: String = "%s.corrupt-%s-%s" % [path, str(Time.get_unix_time_from_system()).replace(".", "_"), str(Time.get_ticks_usec())]
	return _copy_verified(path, archive)

func _read_text(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": error_string(FileAccess.get_open_error())}
	var length: int = file.get_length()
	if length > MAX_SAVE_BYTES:
		file.close()
		return {"ok": false, "error": "文件超过安全大小"}
	var content: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return {"ok": false, "error": error_string(read_error)}
	return {"ok": true, "text": content}

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "ok": false}
	var read: Dictionary = _read_text(path)
	if not bool(read.get("ok", false)):
		return {"exists": true, "ok": false, "error": read.get("error", "读取失败")}
	var parser: JSON = JSON.new()
	if parser.parse(str(read["text"])) != OK or not parser.data is Dictionary:
		return {"exists": true, "ok": false, "error": "JSON 无效"}
	var raw: Dictionary = parser.data
	var raw_version: Variant = raw.get("schema_version", 1)
	if (raw_version is int or raw_version is float) and is_finite(float(raw_version)) and float(raw_version) == floor(float(raw_version)) and float(raw_version) > SCHEMA_VERSION:
		return {"exists": true, "ok": false, "future": true}
	if not _integer_in_range(raw_version, 1, SCHEMA_VERSION):
		return {"exists": true, "ok": false, "error": "版本号无效"}
	var version: int = int(raw_version)
	var checked: Dictionary = _normalize_state(raw)
	checked["exists"] = true
	checked["version"] = version
	return checked

func _normalize_state(raw: Dictionary) -> Dictionary:
	if not _integer_in_range(raw.get("schema_version", 1), 1, SCHEMA_VERSION):
		return {"ok": false, "error": "不支持的版本"}
	if not _json_safe(raw, 0):
		return {"ok": false, "error": "数据类型或结构不合法"}
	var result: Dictionary = default_state()
	for key: String in result:
		if raw.has(key):
			result[key] = raw[key]
	result["schema_version"] = SCHEMA_VERSION
	for key: String in ["save_revision", "currency", "gear"]:
		if not _integer_in_range(result[key], 0, MAX_CURRENCY if key == "currency" else MAX_COUNTER):
			return {"ok": false, "error": "数值字段无效：" + key}
		result[key] = int(result[key])
	if not result["game_clock"] is float and not result["game_clock"] is int:
		return {"ok": false, "error": "游戏时间无效"}
	if not is_finite(float(result["game_clock"])) or float(result["game_clock"]) < 0.0:
		return {"ok": false, "error": "游戏时间无效"}
	for key: String in ["owned_gear", "unlocked_regions", "favorites", "recent_ids"]:
		if not result[key] is Array:
			return {"ok": false, "error": "列表字段无效：" + key}
	for key: String in ["species_stats", "pending_catches", "settings", "selection"]:
		if not result[key] is Dictionary:
			return {"ok": false, "error": "映射字段无效：" + key}
	if (result["owned_gear"] as Array).is_empty() or (result["owned_gear"] as Array).size() > 32:
		return {"ok": false, "error": "装备列表无效"}
	var normalized_gear: Array = []
	for gear: Variant in result["owned_gear"]:
		if not _integer_in_range(gear, 0, MAX_COUNTER) or normalized_gear.has(int(gear)):
			return {"ok": false, "error": "装备标识无效或重复"}
		normalized_gear.append(int(gear))
	result["owned_gear"] = normalized_gear
	if not (result["owned_gear"] as Array).has(result["gear"]):
		return {"ok": false, "error": "未拥有当前装备"}
	for key: String in ["unlocked_regions", "favorites", "recent_ids"]:
		var seen: Dictionary = {}
		for id: Variant in result[key]:
			if not id is String or not _valid_id(str(id)) or seen.has(id):
				return {"ok": false, "error": "列表标识无效或重复：" + key}
			seen[id] = true
	if (result["favorites"] as Array).size() > MAX_FAVORITES or (result["unlocked_regions"] as Array).size() > 128:
		return {"ok": false, "error": "列表超过数量限制"}
	var recent: Array = result["recent_ids"]
	while recent.size() > MAX_RECENT_IDS:
		recent.pop_front()
	var settings: Dictionary = default_state()["settings"]
	settings.merge(result["settings"], true)
	if not settings["sound"] is bool or not settings["vibration"] is bool:
		return {"ok": false, "error": "音效或震动设置无效"}
	if not settings["volume"] is int and not settings["volume"] is float:
		return {"ok": false, "error": "音量无效"}
	if float(settings["volume"]) < 0.0 or float(settings["volume"]) > 1.0:
		return {"ok": false, "error": "音量超出范围"}
	result["settings"] = settings
	var selection: Dictionary = default_state()["selection"]
	selection.merge(result["selection"], true)
	for key: String in ["region_id", "spot_id", "bait_id"]:
		if not selection[key] is String or not _valid_id(str(selection[key])):
			return {"ok": false, "error": "选点标识无效"}
	result["selection"] = selection
	var species_stats: Dictionary = result["species_stats"]
	if species_stats.size() > 4096:
		return {"ok": false, "error": "物种统计超过安全限制"}
	for species: Variant in species_stats:
		if not species is String or not _valid_id(str(species)) or not species_stats[species] is Dictionary:
			return {"ok": false, "error": "物种统计无效"}
		var stats: Dictionary = (species_stats[species] as Dictionary).duplicate(true)
		# Schema 1 used count/region_counts; schema 2 uses catch_count/regions.
		if int(raw.get("schema_version", 1)) == 1:
			if not stats.has("catch_count"):
				stats["catch_count"] = stats.get("count", 0)
			if not stats.has("regions"):
				stats["regions"] = stats.get("region_counts", {})
			stats.erase("count")
			stats.erase("region_counts")
		if not _integer_in_range(stats.get("catch_count", 0), 0, MAX_COUNTER):
			return {"ok": false, "error": "累计数量无效"}
		stats["catch_count"] = int(stats.get("catch_count", 0))
		for key: String in ["first", "last", "max_length", "max_weight"]:
			if not stats.has(key):
				stats[key] = {}
			if not _valid_snapshot(stats[key]):
				return {"ok": false, "error": "钓获纪录无效：" + key}
			stats[key] = _normalize_record(stats[key])
		if not stats.get("regions", {}) is Dictionary:
			return {"ok": false, "error": "分区数量无效"}
		var regions: Dictionary = stats.get("regions", {})
		var regional_total: int = 0
		for region: Variant in regions:
			if not region is String or not _valid_id(str(region)) or not _integer_in_range(regions[region], 0, MAX_COUNTER):
				return {"ok": false, "error": "分区统计无效"}
			regions[region] = int(regions[region])
			regional_total += int(regions[region])
		if regional_total > int(stats["catch_count"]):
			return {"ok": false, "error": "分区数量超过累计数量"}
		stats["regions"] = regions
		species_stats[species] = stats
	var pending: Dictionary = result["pending_catches"]
	if pending.size() > MAX_PENDING:
		return {"ok": false, "error": "待处理鱼超过安全限制，未丢弃原数据"}
	for id: Variant in pending:
		if not pending[id] is Dictionary or not _valid_catch(pending[id]) or str((pending[id] as Dictionary)["catch_id"]) != str(id):
			return {"ok": false, "error": "待处理鱼无效"}
		if not species_stats.has((pending[id] as Dictionary)["species_id"]):
			return {"ok": false, "error": "待处理鱼缺少物种统计"}
		pending[id] = _normalize_record(pending[id])
	for favorite: Variant in result["favorites"]:
		if not species_stats.has(favorite):
			return {"ok": false, "error": "收藏引用了未发现物种"}
	return {"ok": true, "state": result.duplicate(true)}

func _valid_catch(record: Dictionary) -> bool:
	if not _json_safe(record, 0) or record.size() > 32:
		return false
	for key: String in ["catch_id", "session_id", "species_id", "region_id", "spot_id", "bait_id"]:
		if not record.get(key) is String or not _valid_id(str(record[key])):
			return false
	if not _valid_snapshot(record) or str(record.get("disposition", "pending")) != "pending":
		return false
	if not record.get("caught_at") is String or str(record["caught_at"]).is_empty() or str(record["caught_at"]).length() > 64:
		return false
	if not record.get("weather") is String or str(record["weather"]).length() > 64:
		return false
	if not record.get("game_time") is float and not record.get("game_time") is int:
		return false
	if not is_finite(float(record["game_time"])) or float(record["game_time"]) < 0.0:
		return false
	if not record.has("equipment"):
		return false
	return _integer_in_range(record.get("reward", 25), 0, 1000000) and _integer_in_range(record.get("sale_value", 20), 0, 1000000)

func _valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var record: Dictionary = value
	if record.is_empty():
		return true
	return _integer_in_range(record.get("length_mm"), 1, 10000000) and _integer_in_range(record.get("weight_g"), 1, 1000000000)

func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	if not value is int and not value is float:
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= minimum and number <= maximum

func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 128:
		return false
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 95 or code == 45 or code == 46 or code == 58):
			return false
	return true

func _json_safe(value: Variant, depth: int) -> bool:
	if depth > 12:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_STRING:
			return str(value).length() <= 2048
		TYPE_ARRAY:
			if (value as Array).size() > 4096:
				return false
			for child: Variant in value:
				if not _json_safe(child, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if (value as Dictionary).size() > 4096:
				return false
			for key: Variant in value:
				if not key is String or str(key).length() > 128 or not _json_safe(value[key], depth + 1):
					return false
			return true
	return false

func _path(file_name: String) -> String:
	return _root.path_join(file_name)

func _fail(message: String) -> bool:
	error_message = message
	return false

func _result_error(result: Dictionary, message: String) -> Dictionary:
	error_message = message
	result["error"] = message
	return result

func _same_json(left: Variant, right: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(left, "", true, true)) == JSON.parse_string(JSON.stringify(right, "", true, true))

func _normalize_record(record: Dictionary) -> Dictionary:
	var normalized: Dictionary = record.duplicate(true)
	for key: String in ["length_mm", "weight_g", "reward", "sale_value"]:
		if normalized.has(key):
			normalized[key] = int(normalized[key])
	return normalized
