## Manages automatic game saves based on user settings and game state.
##
## Listens for changes to the autosave setting and triggers periodic
## saves when enabled. Automatically handles starting and stopping
## the autosave timer when a slot is loaded or settings change.
extends BaseManager

var _autosave_timer: Timer = Timer.new()
var _autosave_setting: bool = false

## Initializes the autosave manager.
## Subscribes to changes in the [code]gameplay/autosave[/code] setting
## and listens for when a save slot is loaded.
func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	add_child(_autosave_timer)
	EventBus.subscribe(
		SettingsManager.get_event("gameplay", "autosave"),
		_on_autosave_updated
	)
	EventBus.subscribe("slot_loaded", _on_slot_loaded)
	return OK


func _on_autosave_updated(value: bool) -> void:
	_autosave_setting = value
	_update_autosave()


func _on_slot_loaded() -> void:
	_update_autosave()


func _update_autosave() -> void:
	if _autosave_setting and GameState.get_loaded():
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
