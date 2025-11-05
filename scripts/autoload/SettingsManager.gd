extends BaseManager

var _settings: Dictionary = {}

func initialize() -> Error:
	super()
	DebugManager.log_info(name, "Initializing...")
	if _load_settings() == OK:
		DebugManager.log_info(name, "Successfully initialized settings.")
		emit_changed()
		return OK
	DebugManager.log_error(name, "Failed to initialize settings.")
	return FAILED


func emit_changed() -> void:
	for section in _settings.keys():
		emit_section_changed(section)


func emit_section_changed(section: String) -> void:
	EventBus.emit(get_section_event(section))


func get_section_event(section: String) -> String:
	return Constants.SETTINGS_CHANGED_EVENT_PREFIX + "/" + section


func get_value(section: String, key: String) -> Variant:
	if _settings.has(section) and _settings[section].has(key):
		return _settings[section][key]
	DebugManager.log_warn(name, "Missing key: '%s/%s'" % [section, key])
	if Constants.DEFAULT_SETTINGS.has(section) and Constants.DEFAULT_SETTINGS[section].has(key):
		if not _settings.has(section):
			_settings[section] = {}
		_settings[section][key] = Constants.DEFAULT_SETTINGS[section][key]
		return Constants.DEFAULT_SETTINGS[section][key]
	DebugManager.log_fatal(name, "Default settings missing key: '%s/%s'" % [section, key])
	return null


func set_value(section: String, key: String, value: Variant, persist_immediately: bool = true) -> void:
	if not _settings.has(section):
		_settings[section] = {}
	_settings[section][key] = value

	DebugManager.log_debug(name, "Set %s/%s = %s" % [section, key, str(value)])
	emit_section_changed(section)

	if persist_immediately:
		save()


func set_values(section: String, keys: Array[String], values: Array[Variant], persist_immediately: bool = true) -> void:
	if keys.size() != values.size():
		print(keys.size(), keys)
		print(values.size(), values)
		DebugManager.log_error(name, "Attempted to set multiple values, but keys.size() != values.size()")
		return
	if not _settings.has(section):
		_settings[section] = {}
	
	for i in range(keys.size()):
		_settings[section][keys[i]] = values[i]

	DebugManager.log_debug(name, "Set values for section %s - %s = %s" % [section, keys, values])
	emit_section_changed(section)

	if persist_immediately:
		save()

func save() -> Error:
	var result: Error
	_settings = _stamp_settings(_settings)
	
	result = _save_local_settings()
	if result != OK:
		return result
	
	result = _save_steam_settings()
	if result != OK:
		return result
	
	return OK


func reset_to_default() -> void:
	DebugManager.log_info(name, "Resetting settings to default.")
	_settings = _generate_defaults()
	save()


func get_section(section: String) -> Dictionary:
	return _settings.get(section, {})


func _load_settings() -> Error:
	var steam_settings: Dictionary = _load_steam_settings()
	var local_settings: Dictionary = _load_local_settings()
	
	var steam_settings_timestamp: float = steam_settings.get("meta", {}).get("timestamp", -1.0)
	var local_settings_timestamp: float = local_settings.get("meta", {}).get("timestamp", -1.0)
	
	if steam_settings_timestamp > local_settings_timestamp:
		_settings = _migrate_settings(steam_settings)
		if _save_local_settings() == OK:
			DebugManager.log_info(name, "Updated local settings from Steam.")
			return OK
		else:
			DebugManager.log_error(name, "Failed to update local settings from Steam.")
			return FAILED
	elif steam_settings_timestamp < local_settings_timestamp:
		_settings = _migrate_settings(local_settings)
		if _save_steam_settings() == OK:
			DebugManager.log_info(name, "Updated Steam settings from local.")
			return OK
		else:
			if Constants.STEAM_REQUIRED:
				DebugManager.log_error(name, "Failed to update Steam settings from local, Steam is required.")
				return FAILED
			else:
				DebugManager.log_warn(name, "Failed to update Steam settings from local, but Steam is not required.")
				return OK
	else:
		_settings = _migrate_settings(local_settings)
		DebugManager.log_info(name, "Settings loaded successfully, Steam and local in sync.")
		return OK


func _migrate_settings(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	var did_migration: bool = false
	
	while result.get("meta", {}).get("version", -1) != Constants.SETTINGS_VERSION:
		match result.get("meta", {}).get("version", -1):
			_: 
				did_migration = true
				DebugManager.log_warn(name, "Unknown settings version encountered during migration, loading defaults.")
				result = _generate_defaults()
	
	if did_migration:
		result = _stamp_settings(result)
	
	return result


func _load_steam_settings() -> Dictionary:
	var steam_config: ConfigFile = ConfigFile.new()
	var steam_settings: Dictionary = {}

	if SteamManager.is_cloud_available():
		var bytes: PackedByteArray = SteamManager.cloud_read(Constants.CLOUD_SETTINGS_FILE)
		if bytes.size() > 0:
			var temp_file: FileAccess = FileAccess.create_temp(
				FileAccess.WRITE, 
				Constants.CLOUD_SETTINGS_FILE, 
				"tmp",
				false)
			if temp_file:
				temp_file.store_buffer(bytes)
				temp_file.close()
				if steam_config.load(temp_file.get_path()) == OK:
					DebugManager.log_info(name, "Loaded settings from Steam Cloud.")
					steam_settings = _parse_config(steam_config)
				else:
					DebugManager.log_warn(name, "Failed to parse Steam Cloud settings, using local file.")
			else:
				DebugManager.log_warn(name, "Failed to write temp cloud settings to disk.")
		else:
			DebugManager.log_debug(name, "Steam settings file was empty.")
	else:
		DebugManager.log_info(name, "Steam cloud not available, will not load.")
	return steam_settings


func _load_local_settings() -> Dictionary:
	var local_config: ConfigFile = ConfigFile.new()
	var local_settings: Dictionary = {}
	if local_config.load(Constants.LOCAL_SETTINGS_PATH) == OK:
		DebugManager.log_debug(name, "Local settings file found, loading.")
		local_settings = _parse_config(local_config)
	else:
		DebugManager.log_warn(name, "No local settings file found. Loading defaults.")
		_settings = _generate_defaults()
		save()
	return local_settings


func _save_local_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	for section in _settings.keys():
		for key in _settings[section].keys():
			config.set_value(section, key, _settings[section][key])

	if config.save(Constants.LOCAL_SETTINGS_PATH) != OK:
		DebugManager.log_error(name, "Failed to save local settings.")
		return FAILED

	DebugManager.log_debug(name, "Settings saved locally to %s" % Constants.LOCAL_SETTINGS_PATH)
	return OK


func _save_steam_settings() -> Error:
	if SteamManager.is_cloud_available():
		var local_file: FileAccess = FileAccess.open(Constants.LOCAL_SETTINGS_PATH, FileAccess.READ)
		if local_file:
			var bytes: PackedByteArray = local_file.get_buffer(local_file.get_length())
			local_file.close()
			if SteamManager.cloud_write(Constants.CLOUD_SETTINGS_FILE, bytes):
				DebugManager.log_info(name, "Settings uploaded to Steam Cloud.")
				return OK
			else:
				DebugManager.log_warn(name, "Failed to upload settings to Steam Cloud.")
		else:
			DebugManager.log_warn(name, "Failed to open local settings file for upload.")
	else:
		DebugManager.log_warn(name, "Steam cloud not available, skipping sync.")
	return FAILED


func _stamp_settings(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	if not result.has("meta"):
		result["meta"] = {}
	result["meta"]["version"] = Constants.SETTINGS_VERSION
	result["meta"]["timestamp"] = Time.get_unix_time_from_system()
	return result


func _generate_defaults() -> Dictionary:
	var result: Dictionary = Constants.DEFAULT_SETTINGS.duplicate(true)
	return _stamp_settings(result)


func _parse_config(config: ConfigFile) -> Dictionary:
	var config_settings: Dictionary = {}
	for section in config.get_sections():
		config_settings[section] = {}
		for key in config.get_section_keys(section):
			config_settings[section][key] = config.get_value(section, key, Constants.DEFAULT_SETTINGS.get(section, {}).get(key, null))
	return config_settings
