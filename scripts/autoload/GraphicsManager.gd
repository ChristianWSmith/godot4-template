extends BaseManager

func initialize() -> Error:
	super()
	Log.info(name, "Initializing...")
	EventBus.subscribe(SettingsManager.get_section_event("graphics"), _on_graphics_settings_updated)
	return OK


func _on_graphics_settings_updated() -> void:
	pass
