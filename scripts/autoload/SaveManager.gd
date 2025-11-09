extends BaseManager

var _slots: Dictionary[String, Dictionary] = {}

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")

	var dir: DirAccess = DirAccess.open(Constants.LOCAL_SAVE_BASE_PATH)
	if dir == null:
		dir = DirAccess.open("user://")
	if dir.make_dir_recursive(Constants.LOCAL_SAVE_SUBPATH) != OK:
		Log.error(self, "Failed to create local save directory: %s" % Constants.LOCAL_SAVE_PATH)

	_load_local_slots()

	if SteamManager.is_cloud_available():
		_sync_steam_cloud()

	Log.info(self, "Initialized with slots: [%s]" % ", ".join(_slots.keys()))
	return OK


func list_slots() -> Array[String]:
	return _slots.keys()


func new_slot(slot_name: String) -> Error:
	return save_data(slot_name)


func save_data(slot_name: String, data: Dictionary = {}) -> Error:
	if not _slots.has(slot_name):
		_slots[slot_name] = Constants.DEFAULT_SAVE.duplicate(true)
	
	if not data.is_empty():
		_slots[slot_name]["data"] = data
	
	_slots[slot_name] = _stamp_slot(_slots[slot_name])

	return _persist_slot(slot_name)


func get_data(slot_name: String) -> Dictionary:
	if not _slots.has(slot_name) or not _slots[slot_name].has("data"):
		Log.error(self, "Slot does not exist or is empty: %s" % slot_name)
		return {}
	return _slots[slot_name]["data"]


func delete_slot(slot_name: String) -> Error:
	var result: Error = FAILED
	
	if _slots.has(slot_name):
		_slots.erase(slot_name)

	var local_file: String = "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
	if FileAccess.file_exists(local_file):
		if DirAccess.remove_absolute(local_file) == OK:
			Log.info(self, "Deleted local slot file: %s" % local_file)
			result = OK
		else:
			Log.error(self, "Failed to delete local slot file: %s" % local_file)
	else:
		Log.warn(self, "Local slot file does not exist, cannot delete: %s" % local_file)

	if SteamManager.is_cloud_available():
		if SteamManager.cloud_delete("%s.save" % slot_name) == OK:
			Log.debug(self, "Deleted Steam Cloud slot: %s" % slot_name)
		else:
			Log.warn(self, "Failed to delete Steam Cloud slot, will retry: %s" % slot_name)
	else:
		Log.warn(self, "Steam Cloud not active, cannot delete, will retry: %s" % slot_name)
	
	return result


func _persist_slot(slot_name: String) -> Error:
	if not _slots.has(slot_name):
		Log.error(self, "Attempted to persist non-existent slot: %s" % slot_name)
		return FAILED

	var slot: Dictionary = _slots[slot_name]
	var dict: Dictionary = {
		"meta": slot.get("meta", {"version": Constants.SAVE_VERSION, "timestamp": Time.get_unix_time_from_system()}),
		"data": slot.get("data", {})
	}
	var bytes: PackedByteArray = var_to_bytes_with_objects(dict)

	var local_file: String = "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
	var file: FileAccess = FileAccess.open(local_file, FileAccess.WRITE)
	if file == null:
		Log.error(self, "Failed to write local save file: %s" % local_file)
		return FAILED

	file.store_buffer(bytes)
	file.close()
	Log.debug(self, "Saved slot locally: %s" % slot_name)

	if SteamManager.is_cloud_available():
		if SteamManager.cloud_write("%s.save" % slot_name, bytes) == OK:
			Log.debug(self, "Saved slot to Steam Cloud: %s" % slot_name)
		else:
			Log.warn(self, "Failed to save slot to Steam Cloud: %s" % slot_name)

	return OK


func _load_local_slots() -> void:
	_slots.clear()
	var dir: DirAccess = DirAccess.open(Constants.LOCAL_SAVE_PATH)
	if dir == null:
		Log.info(self, "No local save directory found, starting fresh.")
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var local_path: String = "%s/%s" % [Constants.LOCAL_SAVE_PATH, file_name]
			var file: FileAccess = FileAccess.open(local_path, FileAccess.READ)
			if file:
				var parsed: Variant = bytes_to_var_with_objects(file.get_buffer(file.get_length()))
				file.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					var migrated := _migrate_slot(parsed)
					var slot_name := file_name.replace(".save", "")
					_slots[slot_name] = migrated
					Log.debug(self, "Loaded local save slot: %s" % slot_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _sync_steam_cloud() -> void:
	var cloud_files: Array[String] = SteamManager.cloud_list_files()
	for cloud_file in cloud_files:
		if not cloud_file.ends_with(".save"):
			continue

		var slot_name: String = cloud_file.replace(".save", "")
		var bytes: PackedByteArray = SteamManager.cloud_read(cloud_file)
		if bytes.is_empty():
			continue

		var slot_dict: Variant = bytes_to_var_with_objects(bytes)
		if typeof(slot_dict) != TYPE_DICTIONARY:
			Log.warn(self, "Failed to parse cloud slot %s, skipping" % cloud_file)
			continue

		var cloud_slot: Dictionary = _migrate_slot(slot_dict)
		var cloud_ts: float = cloud_slot.get("meta", {}).get("timestamp", -1.0)
		var local_ts: float = -1.0
		if _slots.has(slot_name):
			local_ts = _slots[slot_name].get("meta", {}).get("timestamp", -1.0)

		if cloud_ts > local_ts:
			_slots[slot_name] = cloud_slot
			Log.debug(self, "Updated local slot from Steam Cloud: %s" % slot_name)

			var local_file := "%s/%s.save" % [Constants.LOCAL_SAVE_PATH, slot_name]
			var file := FileAccess.open(local_file, FileAccess.WRITE)
			if file:
				file.store_buffer(var_to_bytes_with_objects(cloud_slot))
				file.close()


func _migrate_slot(slot_data: Dictionary) -> Dictionary:
	var result: Dictionary = slot_data.duplicate(true)
	var did_migration := false
	
	while result.get("meta", {}).get("version", -1) != Constants.SAVE_VERSION:
		var current_version: int = result.get("meta", {}).get("version", -1)
		match current_version:
			_:
				did_migration = true
				Log.warn(self, "Unknown save version %d, using default save." % current_version)
				result = _generate_defaults()
	
	if did_migration:
		result = _stamp_slot(result)
	
	return result


func _generate_defaults() -> Dictionary:
	var result: Dictionary = Constants.DEFAULT_SAVE.duplicate(true)
	return _stamp_slot(result)


func _stamp_slot(slot: Dictionary) -> Dictionary:
	var result: Dictionary = slot.duplicate(true)
	if not result.has("meta"):
		result["meta"] = {}
	result["meta"]["version"] = Constants.SAVE_VERSION
	result["meta"]["timestamp"] = Time.get_unix_time_from_system()
	return result
