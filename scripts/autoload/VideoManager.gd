extends BaseManager

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	EventBus.subscribe(
		SettingsManager.get_event("video", "window_mode"),
		_on_window_mode_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("video", "vsync"),
		_on_vsync_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("video", "max_fps"),
		_on_max_fps_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("video", "resolution"),
		_on_resolution_updated
	)
	return OK


func _on_window_mode_updated(mode: SystemConstants.WindowMode) -> void:
	match mode:
		SystemConstants.WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		SystemConstants.WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		_: # SystemConstants.WindowMode.WINDOWED:
			var resolution: Vector2i = SettingsManager.get_value("video", "resolution")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size.call_deferred(resolution)
			Log.trace(self, "Settings resolution to %s" % resolution)
	Log.trace(self, "Window mode set to %s" % mode)


func _on_vsync_updated(value: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
	)
	Log.trace(self, "Vsync set to %s" % value)


func _on_max_fps_updated(value: int) -> void:
	Engine.max_fps = value
	Log.trace(self, "Max FPS set to %s" % value)


func _on_resolution_updated(value: Vector2i) -> void:
	if DisplayServer.window_get_mode() in [
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
				DisplayServer.WINDOW_MODE_FULLSCREEN
			]:
		return
	var offset: Vector2i = DisplayServer.window_get_size() - value
	DisplayServer.window_set_position(DisplayServer.window_get_position() + offset / 2)
	DisplayServer.window_set_size.call_deferred(value)
