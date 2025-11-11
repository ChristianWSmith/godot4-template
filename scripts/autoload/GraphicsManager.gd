extends BaseManager

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	EventBus.subscribe(
		SettingsManager.get_event("graphics", "ui_scale"),
		_on_ui_scale_updated
	)
	return OK


func _on_ui_scale_updated(ui_scale: float) -> void:
	UIManager.set_ui_scale(ui_scale)
