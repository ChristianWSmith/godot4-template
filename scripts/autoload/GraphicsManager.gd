extends BaseManager

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	EventBus.subscribe(SettingsManager.get_section_event("graphics"), _on_graphics_settings_updated)
	return OK


func _on_graphics_settings_updated() -> void:
	var ui_scale: float = SettingsManager.get_value("graphics", "ui_scale")
	UIManager.set_ui_scale(ui_scale)
