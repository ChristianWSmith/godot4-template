extends BaseManager

var _settings: Dictionary = {}

func initialize() -> Error:
	super()
	Log.info(name, "Initializing...")
	if _load_settings() == OK:
		Log.info(name, "Successfully initialized settings.")
		emit_changed()
		return OK
	Log.error(name, "Failed to initialize settings.")
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
	Log.warn(name, "Missing key: '%s/%s'" % [section, key])
	if Constants.DEFAULT_SETTINGS.has(section) and Constants.DEFAULT_SETTINGS[section].has(key):
		if not _settings.has(section):
			_settings[section] = {}
		_settings[section][key] = Constants.DEFAULT_SETTINGS[section][key]
		return Constants.DEFAULT_SETTINGS[section][key]
	Log.fatal(name, "Default settings missing key: '%s/%s'" % [section, key])
	return null


func set_value(section: String, key: String, value: Variant, persist_immediately: bool = true) -> void:
	if not _settings.has(section):
		_settings[section] = {}
	_settings[section][key] = value

	Log.debug(name, "Set %s/%s = %s" % [section, key, str(value)])
	emit_section_changed(section)

	if persist_immediately:
		save()


func set_values(section: String, keys: Array[String], values: Array[Variant], persist_immediately: bool = true) -> void:
	if keys.size() != values.size():
		print(keys.size(), keys)
		print(values.size(), values)
		Log.error(name, "Attempted to set multiple values, but keys.size() != values.size()")
		return
	if not _settings.has(section):
		_settings[section] = {}
	
	for i in range(keys.size()):
		_settings[section][keys[i]] = values[i]

	Log.debug(name, "Set values for section %s - %s = %s" % [section, keys, values])
	emit_section_changed(section)

	if persist_immediately:
		save()


func save() -> Error:
	var result: Error
	_settings = _stamp_settings(_settings)
	
	result = _save_local_settings(_settings)
	if result != OK:
		return result
	
	result = _save_steam_settings()
	if result != OK:
		return result
	
	return OK


func reset_to_default() -> void:
	Log.info(name, "Resetting settings to default.")
	_settings = Constants.DEFAULT_SETTINGS.duplicate(true)
	save()


func get_section(section: String) -> Dictionary:
	return _settings.get(section, {})


func _load_settings() -> Error:
	var steam_settings: Dictionary = _load_steam_settings()
	var local_settings: Dictionary = _load_local_settings()
	
	var steam_settings_timestamp: float = steam_settings.get("meta", {}).get("timestamp", -1.0)
	var local_settings_timestamp: float = local_settings.get("meta", {}).get("timestamp", -1.0)
	
	var steam_fresher: bool = steam_settings_timestamp > local_settings_timestamp
	var local_fresher: bool = local_settings_timestamp > steam_settings_timestamp
	
	if steam_fresher:
		Log.info(name, "Steam settings are fresher.")
		_settings = steam_settings
	else:
		Log.info(name, "Local settings are fresher or tied.")
		_settings = local_settings
		
	var migrated_settings: Dictionary = _migrate_settings(_settings)
	var migrated: bool = not _settings.recursive_equal(migrated_settings, -1)
	
	if migrated:
		Log.info(name, "Migrated settings, saving...")
		_settings = migrated_settings
		return save()
	
	if steam_fresher and _save_local_settings(_settings) == OK:
		Log.info(name, "Updated local settings from Steam.")
		return OK
	elif local_fresher:
		if _save_steam_settings() == OK:
			Log.info(name, "Updated Steam settings from local.")
			return OK
		else:
			Log.warn(name, "Failed to update Steam settings from local.")
			return OK
	else:
		Log.info(name, "Local and Steam settings are in sync.")
		return OK
		


func _migrate_settings(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	var did_migration: bool = false
	
	while result.get("meta", {}).get("version", -1) != Constants.SETTINGS_VERSION:
		match result.get("meta", {}).get("version", -1):
			_: 
				did_migration = true
				Log.warn(name, "Unknown settings version encountered during migration, loading defaults.")
				result = Constants.DEFAULT_SETTINGS.duplicate(true)
	
	if did_migration:
		result = _stamp_settings(result)
	
	result.merge(Constants.DEFAULT_SETTINGS.duplicate(true), false)
	
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
					Log.info(name, "Loaded settings from Steam Cloud.")
					steam_settings = _parse_config(steam_config)
				else:
					Log.warn(name, "Failed to parse Steam Cloud settings, using local file.")
			else:
				Log.warn(name, "Failed to write temp cloud settings to disk.")
		else:
			Log.debug(name, "Steam settings file was empty.")
	else:
		Log.info(name, "Steam cloud not available, will not load.")
	return steam_settings


func _load_local_settings() -> Dictionary:
	var local_config: ConfigFile = ConfigFile.new()
	var local_settings: Dictionary = {}
	if local_config.load(Constants.LOCAL_SETTINGS_PATH) == OK:
		Log.debug(name, "Local settings file found, loading.")
		local_settings = _parse_config(local_config)
	else:
		Log.warn(name, "No local settings file found. Loading defaults.")
		local_settings = Constants.DEFAULT_SETTINGS.duplicate(true)
		_save_local_settings(local_settings)
	return local_settings


func _save_local_settings(settings: Dictionary) -> Error:
	var config: ConfigFile = ConfigFile.new()
	
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])

	if config.save(Constants.LOCAL_SETTINGS_PATH) != OK:
		Log.error(name, "Failed to save local settings.")
		return FAILED

	Log.debug(name, "Settings saved locally to %s" % Constants.LOCAL_SETTINGS_PATH)
	return OK


func _save_steam_settings() -> Error:
	if SteamManager.is_cloud_available():
		var local_file: FileAccess = FileAccess.open(Constants.LOCAL_SETTINGS_PATH, FileAccess.READ)
		if local_file:
			var bytes: PackedByteArray = local_file.get_buffer(local_file.get_length())
			local_file.close()
			if SteamManager.cloud_write(Constants.CLOUD_SETTINGS_FILE, bytes) == OK:
				Log.info(name, "Settings uploaded to Steam Cloud.")
				return OK
			else:
				Log.warn(name, "Failed to upload settings to Steam Cloud.")
		else:
			Log.warn(name, "Failed to open local settings file for upload.")
	else:
		Log.warn(name, "Steam cloud not available, skipping sync.")
	Log.warn(name, "Failed to upload settings to Steam, will retry.")
	return OK


func _stamp_settings(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	if not result.has("meta"):
		result["meta"] = {}
	result["meta"]["version"] = Constants.SETTINGS_VERSION
	result["meta"]["timestamp"] = Time.get_unix_time_from_system()
	return result


func _parse_config(config: ConfigFile) -> Dictionary:
	var config_settings: Dictionary = {}
	for section in config.get_sections():
		config_settings[section] = {}
		for key in config.get_section_keys(section):
			config_settings[section][key] = config.get_value(section, key, Constants.DEFAULT_SETTINGS.get(section, {}).get(key, null))
	return config_settings
