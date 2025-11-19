## Handles the current game state, including scene-specific and global data.
##
## Manages loading and saving to named slots, retrieving and setting
## data, and tracking whether a slot is currently loaded.
extends BaseManager

var _current_slot: String = ""
var _current_data: Dictionary = {}
var _loaded: bool = false

## Initializes the game state manager.
## Resets internal state and subscribes to scene change events.
func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_reset_state()
	EventBus.subscribe("scene_changed", _on_scene_change)
	return OK


## Returns whether a game slot is currently loaded.
func get_loaded() -> bool:
	return _loaded


## Loads game data from the given [code]slot_name[/code].
## Emits [code]slot_loaded[/code] once complete and changes to the saved scene.
func load_from_slot(slot_name: String) -> void:
	_current_data = DictUtils.flatten(SaveManager.get_data(slot_name))
	_current_slot = slot_name
	_loaded = true
	EventBus.emit("slot_loaded")
	SceneManager.change_scene_async(_get_current_scene_external())


## Saves the current state to the currently loaded slot.
func save_to_current_slot() -> void:
	save_to_slot(_current_slot)


## Saves the current state to the specified [code]slot_name[/code].
func save_to_slot(slot_name: String) -> void:
	_save_to_slot_async.call_deferred(slot_name, DictUtils.unflatten(_current_data)) 


## Unloads the current slot, clearing all loaded state.s
func unload() -> void:
	_reset_state()


## Retrieves scene-specific data at [code]path[/code], returning [code]default[/code] if missing.
func get_scene_data(path: String, default: Variant = null) -> Variant:
	path = "scene_data/" + _get_current_scene_internal() + "/" + path
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, default)


## Sets scene-specific data at [code]path[/code] to [code]value[/code].
## Returns an error if no slot is loaded.
func set_scene_data(path: String, value: Variant) -> Error:
	path = "scene_data/" + _get_current_scene_internal() + "/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


## Retrieves global game data at [code]path[/code], returning [code]default[/code] if missing.
func get_global_data(path: String, default: Variant = null) -> Variant:
	path = "global_data/" + path
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, default)


## Sets global game data at [code]path[/code] to [code]value[/code].
## Returns an error if no slot is loaded.
func set_global_data(path: String, value: Variant) -> Error:
	path = "global_data/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


func _get_current_scene_internal() -> String:
	return _current_data.get("current_scene_uid", "")


func _get_current_scene_external() -> String:
	return ResourceUID.uid_to_path("uid://" + _current_data.get("current_scene_uid", ""))


func _on_scene_change(scene_path: String) -> void:
	_current_data["current_scene_uid"] = ResourceUID.path_to_uid(scene_path).replace("uid://", "")


func _save_to_slot_async(slot_name: String, data: Dictionary = {}) -> void:
	UIManager.show_throbber(true)
	SaveManager.save_data(slot_name, data)
	UIManager.show_throbber(false)


func _reset_state() -> void:
	_current_data = {}
	_current_slot = ""
	_loaded = false
