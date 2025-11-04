extends BaseManager

var _settings: Dictionary = {}

func initialize() -> bool:
	super()
	DebugManager.log_info(name, "Initializing settings...")
	if _load_settings():
		DebugManager.log_info(name, "Successfully initialized settings.")
		emit_changed()
		return true
	DebugManager.log_error(name, "Failed to initialize settings.")
	return false


func emit_changed() -> void:
	for section in _settings.keys():
		emit_section_changed(section)


func emit_section_changed(section: String) -> void:
	EventBus.emit(Constants.SETTINGS_CHANGED_EVENT_PREFIX + "/" + section)


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


func save() -> bool:
	var result: bool = true
	_settings = _stamp_settings(_settings)
	result = result and _save_local_settings()
	result = result and _save_steam_settings()
	return result


func reset_to_default() -> void:
	DebugManager.log_info(name, "Resetting settings to default.")
	_settings = _generate_defaults()
	save()


func _load_settings() -> bool:
	var steam_settings: Dictionary = _load_steam_settings()
	var local_settings: Dictionary = _load_local_settings()
	
	var steam_settings_timestamp: float = steam_settings.get("meta", {}).get("timestamp", -1.0)
	var local_settings_timestamp: float = local_settings.get("meta", {}).get("timestamp", -1.0)
	
	if steam_settings_timestamp > local_settings_timestamp:
		_settings = steam_settings
		if _save_local_settings():
			DebugManager.log_info(name, "Updated local settings from Steam.")
			return true
		else:
			DebugManager.log_error(name, "Failed to update local settings from Steam.")
			return false
	elif steam_settings_timestamp < local_settings_timestamp:
		_settings = local_settings
		if _save_steam_settings():
			DebugManager.log_info(name, "Updated Steam settings from local.")
			return true
		else:
			if Constants.STEAM_REQUIRED:
				DebugManager.log_error(name, "Failed to update Steam settings from local, Steam is required.")
				return false
			else:
				DebugManager.log_warn(name, "Failed to update Steam settings from local, but Steam is not required.")
				return true
	else:
		_settings = local_settings
		DebugManager.log_info(name, "Settings loaded successfully.")
		return true


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
		local_settings = _generate_defaults()
	return local_settings


func _save_local_settings() -> bool:
	var config: ConfigFile = ConfigFile.new()
	for section in _settings.keys():
		for key in _settings[section].keys():
			config.set_value(section, key, _settings[section][key])

	if config.save(Constants.LOCAL_SETTINGS_PATH) != OK:
		DebugManager.log_error(name, "Failed to save local settings.")
		return false

	DebugManager.log_debug(name, "Settings saved locally to %s" % Constants.LOCAL_SETTINGS_PATH)
	return true


func _save_steam_settings() -> bool:
	if SteamManager.is_cloud_available():
		var local_file: FileAccess = FileAccess.open(Constants.LOCAL_SETTINGS_PATH, FileAccess.READ)
		if local_file:
			var bytes: PackedByteArray = local_file.get_buffer(local_file.get_length())
			local_file.close()
			if SteamManager.cloud_write(Constants.CLOUD_SETTINGS_FILE, bytes):
				DebugManager.log_info(name, "Settings uploaded to Steam Cloud.")
				return true
			else:
				DebugManager.log_warn(name, "Failed to upload settings to Steam Cloud.")
		else:
			DebugManager.log_warn(name, "Failed to open local settings file for upload.")
	else:
		DebugManager.log_warn(name, "Steam cloud not available, skipping sync.")
	return false


func _stamp_settings(settings: Dictionary) -> Dictionary:
	var result: Dictionary = settings.duplicate(true)
	if not result.has("meta"):
		result["meta"] = {"version": Constants.SETTINGS_VERSION}
	result["meta"]["timestamp"] = Time.get_unix_time_from_system()
	return result


func _generate_defaults() -> Dictionary:
	var result: Dictionary = Constants.DEFAULT_SETTINGS.duplicate(true)
	return _stamp_settings(result)


func _parse_config(config: ConfigFile) -> Dictionary:
	var config_settings: Dictionary = {}
	for section in Constants.DEFAULT_SETTINGS.keys():
		config_settings[section] = {}
		for key in Constants.DEFAULT_SETTINGS[section].keys():
			config_settings[section][key] = config.get_value(section, key, Constants.DEFAULT_SETTINGS[section][key])
	return config_settings


func apply_display_settings() -> void:
	var fullscreen: bool = get_value("video", "fullscreen")
	var borderless: bool = get_value("video", "borderless")
	var vsync: bool = get_value("video", "vsync")
	var resolution: Vector2i = get_value("video", "resolution")
	var max_fps: int = get_value("video", "max_fps")
	
	Engine.max_fps = max_fps
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

	DebugManager.log_info(name, "Display settings applied (mode=%s, res=%s)" %
		[DisplayServer.window_get_mode(), resolution])
