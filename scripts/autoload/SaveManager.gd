extends BaseManager

var _slots: Dictionary[String, Dictionary] = {}
var current_slot: String = ""

func initialize() -> bool:
	super()
	DebugManager.log_info(name, "Initializing SaveManager...")

	var dir: DirAccess = DirAccess.open(Constants.LOCAL_SAVE_BASE_PATH)
	if not dir.dir_exists(Constants.LOCAL_SAVE_SUBPATH):
		dir.make_dir_recursive(Constants.LOCAL_SAVE_SUBPATH)

	_load_local_manifest()

	if SteamManager.is_cloud_available():
		_sync_steam_cloud()

	DebugManager.log_info(name, "SaveManager initialized with slots: [%s]" % ", ".join(_slots.keys()))
	return true


func get_data(data_path: String) -> Variant:
	if current_slot == "" or not _slots.has(current_slot) or not _slots[current_slot].has("data"):
		DebugManager.log_warn(name, "Requested data from non-existent save slot: %s" % current_slot)
		return null
	var slot: Dictionary = _slots[current_slot]["data"]
	var result: Variant = slot
	for key in data_path.split("/"):
		if result is Dictionary and result.has(key):
			result = result[key]
		else:
			DebugManager.log_error(name, "Save slot did not contain data at path: '%s'" % data_path)
			return null
	return result


func set_data(data_path: String, value: Variant) -> bool:
	if current_slot == "" or not _slots.has(current_slot) or not _slots[current_slot].has("data"):
		DebugManager.log_warn(name, "Requested write to non-existent save slot: %s" % current_slot)
		return false
	var keys: Array[String]
	for key in data_path.split("/"):
		keys.append(key)
	if keys.size() == 0:
		DebugManager.log_warn(name, "Invalid data path")
		return false
	keys.reverse()
	var data: Dictionary = {keys.pop_front(): value}
	for key in keys:
		data = {key: data}
	_slots[current_slot]["data"].merge(data, true)
	DebugManager.log_debug(name, "Wrote data to save slot: %s" % data_path)
	return true


func set_current_slot(slot_name: String) -> bool:
	if slot_name == "" or not _slots.has(slot_name):
		DebugManager.log_warn(name, "Requested non-existent save slot: %s" % slot_name)
		return false
	current_slot = slot_name
	return true


func list_slots() -> Array[String]:
	return _slots.keys()


func new_slot(slot_name: String) -> bool:
	if slot_name == "" or _slots.has(slot_name):
		DebugManager.log_warn(name, "Requested duplicate or invalid save slot: %s" % slot_name)
		return false
	return _save(slot_name)
		

func save(persist_immediately: bool = true) -> bool:
	return _save(current_slot, persist_immediately)


func delete_slot(slot_name: String) -> bool:
	if _slots.has(slot_name):
		_slots.erase(slot_name)

	var local_file = "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
	if FileAccess.file_exists(local_file):
		if DirAccess.remove_absolute(local_file) != OK:
			DebugManager.log_warn(name, "Failed to delete local slot file: %s" % local_file)
		else:
			DebugManager.log_info(name, "Deleted local slot file: %s" % local_file)
	else:
		DebugManager.log_info(name, "Local slot file does not exist, cannot delete: %s" % local_file)
		

	if SteamManager.is_cloud_available():
		if not SteamManager.cloud_delete("%s.save" % slot_name):
			DebugManager.log_warn(name, "Failed to delete Steam Cloud slot: %s" % slot_name)
		else:
			DebugManager.log_info(name, "Deleted Steam Cloud slot: %s" % slot_name)
	else:
		DebugManager.log_info(name, "Steam Cloud not active, cannot delete: %s" % local_file)

	_save_local_manifest()
	return true


func _save(slot_name: String, persist_immediately: bool = true) -> bool:
	if not _slots.has(slot_name):
		_slots[slot_name] = Constants.DEFAULT_SAVE.duplicate(true)

	_slots[slot_name] = _stamp_slot(_slots[slot_name])

	if persist_immediately:
		return _persist_slot(slot_name)
	return true


func _persist_slot(slot_name: String) -> bool:
	if not _slots.has(slot_name):
		DebugManager.log_error(name, "Attempted to persist non-existent slot: %s" % slot_name)
		return false

	var slot: Dictionary = _slots[slot_name]
	var json_dict: Dictionary = {
		"meta": slot.get("meta", {"version": Constants.SAVE_VERSION, "timestamp": Time.get_unix_time_from_system()}),
		"data": slot.get("data", {})
	}
	var bytes: PackedByteArray = JSON.stringify(json_dict).to_utf8_buffer()

	var local_file: String = "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
	var file: FileAccess = FileAccess.open(local_file, FileAccess.WRITE)
	if file == null:
		DebugManager.log_error(name, "Failed to write local save file: %s" % local_file)
		return false

	file.store_buffer(bytes)
	file.close()
	DebugManager.log_debug(name, "Saved slot locally: %s" % slot_name)

	if SteamManager.is_cloud_available():
		if SteamManager.cloud_write("%s.save" % slot_name, bytes):
			DebugManager.log_info(name, "Saved slot to Steam Cloud: %s" % slot_name)
		else:
			DebugManager.log_warn(name, "Failed to save slot to Steam Cloud: %s" % slot_name)

	_save_local_manifest()
	return true


func _load_local_manifest() -> void:
	_slots.clear()

	if not FileAccess.file_exists(Constants.LOCAL_SAVE_MANIFEST_PATH):
		DebugManager.log_info(name, "No local save manifest found, starting fresh.")
		return

	var f := FileAccess.open(Constants.LOCAL_SAVE_MANIFEST_PATH, FileAccess.READ)
	if f == null:
		DebugManager.log_warn(name, "Failed to open local save manifest.")
		return

	var bytes := f.get_buffer(f.get_length())
	f.close()

	var manifest_json: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if typeof(manifest_json) != TYPE_DICTIONARY:
		DebugManager.log_warn(name, "Invalid manifest structure, starting fresh.")
		return

	for slot_name in manifest_json.keys():
		var meta: Dictionary = manifest_json[slot_name]
		if typeof(meta) == TYPE_DICTIONARY:
			_slots[slot_name] = { "meta": meta } # no data loaded yet
	DebugManager.log_info(name, "Loaded manifest with %d slots" % _slots.size())


func _save_local_manifest() -> void:
	var manifest := {}
	for slot_name in _slots.keys():
		if _slots[slot_name].has("meta"):
			manifest[slot_name] = _slots[slot_name]["meta"]

	var json_str := JSON.stringify(manifest)
	var file := FileAccess.open(Constants.LOCAL_SAVE_MANIFEST_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		DebugManager.log_debug(name, "Saved local save manifest.")
	else:
		DebugManager.log_warn(name, "Failed to write local save manifest.")


func _sync_steam_cloud() -> void:
	var cloud_files := SteamManager.cloud_list_files()
	for cloud_file in cloud_files:
		if not cloud_file.ends_with(".save"):
			continue

		var slot_name := cloud_file.replace(".save", "")
		var bytes := SteamManager.cloud_read(cloud_file)
		if bytes.size() == 0:
			continue

		var slot_json: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if typeof(slot_json) != TYPE_DICTIONARY:
			DebugManager.log_warn(name, "Failed to parse cloud slot %s, skipping" % cloud_file)
			continue

		var cloud_slot: Dictionary = _migrate_slot(slot_json)
		var cloud_ts: float = cloud_slot.get("meta", {}).get("timestamp", -1.0)

		if not _slots.has(slot_name) or cloud_ts > _slots[slot_name].get("meta", {}).get("timestamp", -1.0):
			_slots[slot_name] = cloud_slot
			DebugManager.log_info(name, "Updated local slot from Steam Cloud: %s" % slot_name)

			var local_file := "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
			var file := FileAccess.open(local_file, FileAccess.WRITE)
			if file:
				file.store_string(JSON.stringify(cloud_slot))
				file.close()

	_save_local_manifest()


func _migrate_slot(slot_data: Dictionary) -> Dictionary:
	var result := slot_data.duplicate(true)
	var did_migration := false
	
	while result.get("meta", {}).get("version", -1) != Constants.SAVE_VERSION:
		var current_version: int = result.get("meta", {}).get("version", -1)
		match current_version:
			_:
				did_migration = true
				DebugManager.log_warn(name, "Unknown save version %d, using default save." % current_version)
				result = _generate_defaults()
	
	if did_migration:
		result = _stamp_slot(result)
	
	return result


func _generate_defaults() -> Dictionary:
	var result := Constants.DEFAULT_SAVE.duplicate(true)
	return _stamp_slot(result)


func _stamp_slot(slot: Dictionary) -> Dictionary:
	var result := slot.duplicate(true)
	if not result.has("meta"):
		result["meta"] = {}
	result["meta"]["version"] = Constants.SAVE_VERSION
	result["meta"]["timestamp"] = Time.get_unix_time_from_system()
	return result
