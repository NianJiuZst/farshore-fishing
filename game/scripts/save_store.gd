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
const PRE_IMPORT_NAME: String = "save.before-import.json"
const TRANSFER_FORMAT: String = "farshore-fishing-backup"
const TRANSFER_VERSION: int = 1
# JSON escaping can double an existing save; leave bounded space for the envelope.
const MAX_TRANSFER_BYTES: int = MAX_SAVE_BYTES * 2 + 4096

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
	var record: Dictionary = pending[catch_id]
	# Enforce conservation in the transaction layer, even for stale/forged UI calls.
	if action == "sold" and bool(record.get("release_only", false)):
		return _result_error(failure, "保护观察物种不可出售，请放归；图鉴与历史纪录会保留。")
	var candidate: Dictionary = _state.duplicate(true)
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
	if int(_state["save_revision"]) >= MAX_COUNTER:
		return _fail("存档修订次数已达安全上限，请导出备份并使用更新版本游戏。")
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

## Portable text requires no Android storage permission. Keep it outside the app
## before uninstalling: Android normally removes user:// together with the app.
func export_save_text() -> Dictionary:
	_mutex.lock()
	var result: Dictionary
	if not _initialized or read_only:
		result = _transfer_error("当前存档未能完整读取或处于保护模式，无法导出。请保留原应用数据，勿卸载或清除数据。")
	else:
		result = _encode_transfer(_state)
	_mutex.unlock()
	return result

## A preview never changes live state or writes a file. Legacy raw JSON is also
## accepted; only the new envelope can detect accidental changes to the text.
func inspect_save_text(text: String) -> Dictionary:
	_mutex.lock()
	var decoded: Dictionary = _decode_transfer(text)
	var result: Dictionary = _transfer_summary(decoded)
	_mutex.unlock()
	return result

## expected_revision is the current local revision when the preview is shown,
## not the backup revision. Delayed confirmation cannot discard newer progress.
func import_save_text(text: String, expected_revision: int) -> Dictionary:
	_mutex.lock()
	var decoded: Dictionary = _decode_transfer(text)
	var result: Dictionary = _import_decoded_locked(decoded, expected_revision)
	_mutex.unlock()
	return result

func has_previous_save() -> bool:
	_mutex.lock()
	var available: bool = not _root.is_empty() and bool(_read_save(_path(PRE_IMPORT_NAME)).get("ok", false))
	_mutex.unlock()
	return available

func export_previous_save_text() -> Dictionary:
	_mutex.lock()
	var previous: Dictionary = _read_save(_path(PRE_IMPORT_NAME)) if not _root.is_empty() else {}
	var result: Dictionary
	if not bool(previous.get("ok", false)):
		result = _transfer_error("尚无可读取的恢复前快照。")
	else:
		result = _encode_transfer(previous["state"])
	_mutex.unlock()
	return result

## Undo uses the same transaction as import. The current state becomes the new
## pre-import snapshot, so undo itself remains reversible.
func restore_previous_save(expected_revision: int) -> Dictionary:
	_mutex.lock()
	var previous: Dictionary = _read_save(_path(PRE_IMPORT_NAME)) if not _root.is_empty() else {}
	var result: Dictionary
	if not bool(previous.get("ok", false)):
		result = _transfer_error("恢复前快照不可用，当前进度未更改。")
	else:
		result = _import_decoded_locked(previous, expected_revision)
	_mutex.unlock()
	return result

func _encode_transfer(value: Dictionary) -> Dictionary:
	var payload: String = JSON.stringify(value, "", true, true)
	if payload.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _transfer_error("存档超过安全大小限制，无法导出。")
	var envelope: Dictionary = {
		"format": TRANSFER_FORMAT, "format_version": TRANSFER_VERSION,
		"created_at": Time.get_datetime_string_from_system(true),
		"sha256": payload.sha256_text(), "payload": payload
	}
	var text: String = JSON.stringify(envelope, "", true, true)
	if text.to_utf8_buffer().size() > MAX_TRANSFER_BYTES:
		return _transfer_error("备份文本超过安全大小限制。")
	error_message = ""
	return {"ok": true, "error": "", "text": text}

func _decode_transfer(text: String) -> Dictionary:
	# Check characters first, before allocating a second, UTF-8-sized buffer.
	if text.length() > MAX_TRANSFER_BYTES or text.to_utf8_buffer().size() > MAX_TRANSFER_BYTES:
		return _transfer_error("备份文本过大，未读取或覆盖进度。")
	var content: String = text.strip_edges()
	if content.begins_with("\uFEFF"):
		content = content.substr(1).strip_edges()
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK or not parser.data is Dictionary:
		return _transfer_error("备份不是有效的 JSON 文本，请完整复制后重试。")
	var raw: Dictionary = parser.data
	var verified: bool = false
	if raw.has("format") or raw.has("format_version") or raw.has("payload") or raw.has("sha256"):
		if str(raw.get("format", "")) != TRANSFER_FORMAT:
			return _transfer_error("这不是远岸钓记的备份文本。")
		var transfer_version: Variant = raw.get("format_version")
		if _is_future_version(transfer_version, TRANSFER_VERSION):
			return _transfer_error("备份来自较新版本游戏，请升级游戏后再恢复。")
		if not _integer_in_range(transfer_version, 1, TRANSFER_VERSION):
			return _transfer_error("备份格式版本无效。")
		if not raw.get("payload") is String or not raw.get("sha256") is String:
			return _transfer_error("备份缺少存档内容或完整性校验。")
		var payload: String = raw["payload"]
		if payload.length() > MAX_SAVE_BYTES or payload.to_utf8_buffer().size() > MAX_SAVE_BYTES:
			return _transfer_error("备份内的存档超过安全大小限制。")
		if str(raw["sha256"]).length() != 64 or payload.sha256_text() != str(raw["sha256"]).to_lower():
			return _transfer_error("备份完整性校验失败，文本可能不完整或被修改；当前进度未更改。")
		if parser.parse(payload) != OK or not parser.data is Dictionary:
			return _transfer_error("备份中的存档内容无效。")
		raw = parser.data
		verified = true
	elif content.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _transfer_error("旧版存档超过安全大小限制。")
	# A random JSON object must never be interpreted as a fresh save and replace
	# the player's progress merely because normalization supplies default fields.
	if not raw.has("currency") or not raw.has("species_stats"):
		return _transfer_error("文本缺少金币或图鉴字段，不是完整存档。")
	var version: Variant = raw.get("schema_version", 1)
	if _is_future_version(version, SCHEMA_VERSION):
		return _transfer_error("存档来自较新版本游戏，当前版本不会覆盖它。")
	var checked: Dictionary = _normalize_state(raw)
	if not bool(checked.get("ok", false)):
		return _transfer_error("存档校验失败：%s" % str(checked.get("error", "未知错误")))
	checked["version"] = int(version)
	checked["checksum_verified"] = verified
	error_message = ""
	return checked

func _transfer_summary(decoded: Dictionary) -> Dictionary:
	if not bool(decoded.get("ok", false)):
		return decoded
	var imported: Dictionary = decoded["state"]
	var total: int = 0
	var discovered: int = 0
	for value: Variant in (imported["species_stats"] as Dictionary).values():
		var count: int = int((value as Dictionary).get("catch_count", 0))
		total += count
		if count > 0:
			discovered += 1
	return {"ok": true, "error": "", "schema_version": int(decoded.get("version", SCHEMA_VERSION)),
		"save_revision": int(imported["save_revision"]), "currency": int(imported["currency"]),
		"catch_count": total, "discovered_count": discovered,
		"pending_count": (imported["pending_catches"] as Dictionary).size(),
		"checksum_verified": bool(decoded.get("checksum_verified", false)),
		"state": imported.duplicate(true)}

func _import_decoded_locked(decoded: Dictionary, expected_revision: int) -> Dictionary:
	if not bool(decoded.get("ok", false)):
		return decoded
	if not _initialized or read_only:
		return _transfer_error("当前存档处于保护模式，不能恢复或覆盖进度。")
	if _writing or not _active_session.is_empty() or not _retry_record.is_empty():
		return _transfer_error("请先结束当前钓鱼并保存钓获，再恢复备份。")
	if expected_revision < 0 or expected_revision != int(_state["save_revision"]):
		return _transfer_error("当前进度已变化，请重新预览备份后再确认恢复。")
	if int(_state["save_revision"]) >= MAX_COUNTER:
		return _transfer_error("存档修订次数已达安全上限，当前进度与恢复快照均未改动。")
	# Never replace a file written by a newer game. Normal commits recheck the
	# primary and rolling backup immediately before persistence as well.
	for name: String in [PRIMARY_NAME, BACKUP_NAME, PRE_IMPORT_NAME]:
		if bool(_read_save(_path(name)).get("future", false)):
			return _transfer_error("发现更高版本存档或恢复快照，已保护原文件。")
	var candidate: Dictionary = (decoded["state"] as Dictionary).duplicate(true)
	# Revisions belong to this installation, not to the source backup.
	candidate["save_revision"] = int(_state["save_revision"])
	if not _preserve_before_import():
		return {"ok": false, "error": error_message}
	if not _commit_locked(candidate):
		return {"ok": false, "error": error_message}
	_active_session = ""
	_retry_record = {}
	status_message = "备份已恢复；恢复前的进度已另存，可在设置中撤销。"
	var result: Dictionary = _transfer_summary(decoded)
	result["save_revision"] = int(_state["save_revision"])
	result["state"] = _state.duplicate(true)
	return result

func _preserve_before_import() -> bool:
	var destination: String = _path(PRE_IMPORT_NAME)
	var temp: String = _path("save.before-import.tmp.json")
	var previous: Dictionary = _read_save(destination)
	if bool(previous.get("future", false)):
		return _fail("恢复前快照来自较新版本，未覆盖任何进度。")
	if not _write_verified_json(temp, _state):
		return false
	if bool(previous.get("exists", false)) and not bool(previous.get("ok", false)):
		if not _preserve_corrupt(destination):
			return false
	if not _replace_file(temp, destination):
		return false
	var verified: Dictionary = _read_save(destination)
	if not bool(verified.get("ok", false)) or not _same_json(verified["state"], _state):
		return _fail("恢复前快照验证失败，当前进度未替换。")
	return true

func _transfer_error(message: String) -> Dictionary:
	error_message = message
	return {"ok": false, "error": message}

func _is_future_version(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) > maximum

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
	if not raw.has("currency") or not raw.has("species_stats"):
		return {"ok": false, "error": "缺少金币或图鉴字段，不能视为空白存档"}
	# Keep compatible extension fields when migrating or round-tripping backups.
	# Defaults fill absent fields only; existing progress is never reset.
	var result: Dictionary = raw.duplicate(true)
	result.merge(default_state(), false)
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
	for key: String in ["ambience_volume", "effects_volume"]:
		if settings.has(key):
			if not settings[key] is int and not settings[key] is float:
				return {"ok": false, "error": "声音设置无效：" + key}
			if float(settings[key]) < 0.0 or float(settings[key]) > 1.0:
				return {"ok": false, "error": "声音设置超出范围：" + key}
	if settings.has("reduce_motion") and not settings["reduce_motion"] is bool:
		return {"ok": false, "error": "动态效果设置无效"}
	if settings.has("visual_quality") and (not settings["visual_quality"] is String or settings["visual_quality"] not in ["low", "balanced", "high"]):
		return {"ok": false, "error": "画质设置无效"}
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
