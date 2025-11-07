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
	
	Engine.max_fps = max_fps
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

	Log.info(self, "Display settings applied (mode=%s, res=%s)" %
		[DisplayServer.window_get_mode(), resolution])
