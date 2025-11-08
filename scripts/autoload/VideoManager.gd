extends BaseManager

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	EventBus.subscribe(SettingsManager.get_section_event("video"), _on_video_settings_updated)
	return OK


func _on_video_settings_updated() -> void:
	var fullscreen: bool = SettingsManager.get_value("video", "fullscreen")
	var borderless: bool = SettingsManager.get_value("video", "borderless")
	var vsync: bool = SettingsManager.get_value("video", "vsync")
	var resolution: Vector2i = SettingsManager.get_value("video", "resolution")
	var max_fps: int = SettingsManager.get_value("video", "max_fps")
	
	var was_fullscreen_type: bool = DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_FULLSCREEN
		]
	
	Engine.max_fps = max_fps
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	elif borderless:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		if not was_fullscreen_type:
			var offset: Vector2i = DisplayServer.window_get_size() - resolution
			DisplayServer.window_set_position(DisplayServer.window_get_position() + offset / 2)
		DisplayServer.window_set_size.call_deferred(resolution)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	
	Log.info(self, "Display settings applied (mode=%s, res=%s)" %
		[DisplayServer.window_get_mode(), resolution])
