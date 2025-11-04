extends BaseManager

var _settings: Dictionary = {}

func initialize() -> bool:
	super()
	DebugManager.log_info(name, "Initializing settings...")
	return _load_settings()


func get_value(section: String, key: String) -> Variant:
	if _settings.has(section) and _settings[section].has(key):
		return _settings[section][key]
	DebugManager.log_warn(name, "Missing key: '%s/%s'" % [section, key])
	return Constants.DEFAULT_SETTINGS[section][key]


func set_value(section: String, key: String, value: Variant, persist_immediately: bool = true) -> void:
	if not _settings.has(section):
		_settings[section] = {}
	_settings[section][key] = value

	DebugManager.log_debug(name, "Set %s/%s = %s" % [section, key, str(value)])
	EventBus.emit("settings_changed", {"section": section, "key": key, "value": value})

	if persist_immediately:
		_save_settings()


func save() -> void:
	_save_settings()


func reset_to_default() -> void:
	DebugManager.log_info(name, "Resetting settings to default.")
	_settings = Constants.DEFAULT_SETTINGS.duplicate(true)
	_save_settings()


func _load_settings() -> bool:
	var config: ConfigFile = ConfigFile.new()

	if SteamManager.is_active():
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
				if config.load(temp_file.get_path()) == OK:
					DebugManager.log_info(name, "Loaded settings from Steam Cloud.")
					_parse_config(config)
					return true
				else:
					DebugManager.log_warn(name, "Failed to parse Steam Cloud settings, using local file.")
			else:
				DebugManager.log_warn(name, "Failed to write temp cloud settings to disk.")
		else:
			DebugManager.log_debug(name, "Steam settings file was empty.")
	else:
		DebugManager.log_info(name, "Steam not active, will not load.")

	var err: Error = config.load(Constants.SETTINGS_PATH)
	if err != OK:
		DebugManager.log_warn(name, "No local settings file found. Loading Constants.DEFAULT_SETTINGS.")
		_settings = Constants.DEFAULT_SETTINGS.duplicate(true)
		_save_settings()
		return true

	_parse_config(config)
	DebugManager.log_info(name, "Settings loaded successfully.")
	return true


func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	for section in _settings.keys():
		for key in _settings[section].keys():
			config.set_value(section, key, _settings[section][key])

	var err: Error = config.save(Constants.SETTINGS_PATH)
	if err != OK:
		DebugManager.log_error(name, "Failed to save local settings.")
		return

	DebugManager.log_debug(name, "Settings saved locally to %s" % Constants.SETTINGS_PATH)

	if SteamManager.is_active():
		var local_file: FileAccess = FileAccess.open(Constants.SETTINGS_PATH, FileAccess.READ)
		if local_file:
			var bytes: PackedByteArray = local_file.get_buffer(local_file.get_length())
			local_file.close()
			if SteamManager.cloud_write(Constants.CLOUD_SETTINGS_FILE, bytes):
				DebugManager.log_info(name, "Settings uploaded to Steam Cloud.")
			else:
				DebugManager.log_warn(name, "Failed to upload settings to Steam Cloud.")
		else:
			DebugManager.log_warn(name, "Failed to open local settings file for upload.")
	else:
		DebugManager.log_info(name, "Steam not active, skipping sync.")


func _parse_config(config: ConfigFile) -> void:
	_settings.clear()
	for section in Constants.DEFAULT_SETTINGS.keys():
		_settings[section] = {}
		for key in Constants.DEFAULT_SETTINGS[section].keys():
			_settings[section][key] = config.get_value(section, key, Constants.DEFAULT_SETTINGS[section][key])


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
