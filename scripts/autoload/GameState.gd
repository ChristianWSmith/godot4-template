extends BaseManager


var _current_slot: String = ""
var _current_data: Dictionary = {}
var _loaded: bool = false


func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_reset_state()
	EventBus.subscribe("scene_changed", _on_scene_change)
	return OK


func get_loaded() -> bool:
	return _loaded


func load_from_slot(slot_name: String) -> void:
	_current_data = DictUtils.flatten(SaveManager.get_data(slot_name))
	_current_slot = slot_name
	_loaded = true
	EventBus.emit("slot_loaded")


func save_to_slot(slot_name: String) -> Error:
	_current_data["current_scene"] = SceneManager.get_current_scene()
	return SaveManager.save_data(slot_name, DictUtils.unflatten(_current_data))


func get_scene_data(path: String) -> Variant:
	path = "scene_data/" + _current_data["current_scene"] + "/" + path
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, null)


func set_scene_data(path: String, value: Variant) -> Error:
	path = "scene_data/" + _current_data["current_scene"] + "/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


func get_global_data(path: String) -> Variant:
	path = "global_data/" + path
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, null)


func set_global_data(path: String, value: Variant) -> Error:
	path = "global_data/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


func _on_scene_change(scene_path: String) -> void:
	_current_data["current_scene"] = scene_path


func _reset_state() -> void:
	_current_data = {}
	_current_slot = ""
	_loaded = false
