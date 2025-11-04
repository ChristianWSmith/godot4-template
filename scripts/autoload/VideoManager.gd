extends BaseManager

func initialize() -> bool:
	super()
	DebugManager.log_info(name, "Initializing...")
	EventBus.subscribe(SettingsManager.get_section_event("video"), apply)
	return true


func apply() -> void:
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

	DebugManager.log_info(name, "Display settings applied (mode=%s, res=%s)" %
		[DisplayServer.window_get_mode(), resolution])
