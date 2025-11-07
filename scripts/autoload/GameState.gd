extends BaseManager


var _current_slot: String = ""
var _current_data: Dictionary = {}
var _loaded: bool = false


func initialize() -> Error:
	super()
	Log.info(name, "Initializing...")
	_reset_state()
	return OK


func load_from_slot(slot_name: String) -> void:
	_current_data = DictUtils.flatten(SaveManager.get_data(slot_name))
	_current_slot = slot_name
	_loaded = true


func save_to_slot(slot_name: String) -> Error:
	return SaveManager.save_data(slot_name, DictUtils.unflatten(_current_data))


func get_data(path: String) -> Variant:
	if not _loaded:
		Log.warn(name, "No state data is loaded, data may be invalid (get): %s" % path)
	return _current_data.get(path, null)


func set_data(path: String, value: Variant) -> Error:
	_current_data[path] = value
	if not _loaded:
		Log.warn(name, "No state data is loaded, data may be invalid (set): %s" % path)
		return FAILED
	return OK


func _reset_state() -> void:
	_current_data = {}
	_current_slot = ""
	_loaded = false
