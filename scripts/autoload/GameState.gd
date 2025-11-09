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
	SceneManager.change_scene(_get_current_scene_external())


func save_to_current_slot() -> void:
	save_to_slot(_current_slot)


func save_to_slot(slot_name: String) -> void:
	_save_to_slot_async.call_deferred(slot_name, DictUtils.unflatten(_current_data)) 


func unload() -> void:
	_reset_state()


func get_scene_data(path: String, default: Variant = null) -> Variant:
	path = "scene_data/" + _get_current_scene_internal() + "/" + path
	print(path)
	print(_current_data)
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, default)


func set_scene_data(path: String, value: Variant) -> Error:
	path = "scene_data/" + _get_current_scene_internal() + "/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


func get_global_data(path: String, default: Variant = null) -> Variant:
	path = "global_data/" + path
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (get_scene_data): %s" % path)
	return _current_data.get(path, default)


func set_global_data(path: String, value: Variant) -> Error:
	path = "global_data/" + path
	_current_data[path] = value
	if not _loaded:
		Log.warn(self, "No state data is loaded, data may be invalid (set_scene_data): %s" % path)
		return FAILED
	return OK


func _get_current_scene_internal() -> String:
	return _current_data.get("current_scene", "")


func _get_current_scene_external() -> String:
	return _current_data.get("current_scene", "").replace("|", "/")


func _save_to_slot_async(slot_name: String, data: Dictionary = {}) -> void:
	SceneManager.show_throbber(true)
	SaveManager.save_data(slot_name, data)
	SceneManager.show_throbber(false)


func _on_scene_change(scene_path: String) -> void:
	_current_data["current_scene"] = scene_path.replace("/", "|")


func _reset_state() -> void:
	_current_data = {}
	_current_slot = ""
	_loaded = false
