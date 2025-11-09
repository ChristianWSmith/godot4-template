extends BaseManager

var _autosave_timer: Timer = Timer.new()

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	add_child(_autosave_timer)
	EventBus.subscribe(
		SettingsManager.get_section_event("gameplay"), 
		_on_gameplayer_settings_updated)
	EventBus.subscribe("slot_loaded", _on_slot_loaded)
	return OK


func _on_gameplayer_settings_updated() -> void:
	_update_autosave()


func _on_slot_loaded() -> void:
	_update_autosave()


func _update_autosave() -> void:
	if SettingsManager.get_value("gameplay", "autosave") and \
		GameState.get_loaded():
		if not _autosave_timer.timeout.is_connected(_autosave):
			_autosave_timer.timeout.connect(_autosave)
		_autosave_timer.start(SystemConstants.AUTOSAVE_INTERVAL)
	else:
		_autosave_timer.stop()
		if _autosave_timer.timeout.is_connected(_autosave):
			_autosave_timer.timeout.disconnect(_autosave)


func _autosave() -> void:
	GameState.save_to_slot("Autosave %s" % Time.get_datetime_string_from_system())
	_autosave_timer.start(SystemConstants.AUTOSAVE_INTERVAL)
