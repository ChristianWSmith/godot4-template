extends BaseManager

func initialize() -> Error:
	super()
	DebugManager.log_info(name, "Initializing...")
	EventBus.subscribe(SettingsManager.get_section_event("gameplay"), _on_gameplayer_settings_updated)
	return OK


func _on_gameplayer_settings_updated() -> void:
	pass
