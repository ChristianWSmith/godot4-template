extends BaseManager


var current_slot: String = ""
var current_data: Dictionary = {}
var loaded: bool = false


func initialize() -> Error:
	_reset_state()
	return OK


func load_from_slot(slot_name: String) -> void:
	current_data = SaveManager.get_data(slot_name)
	current_slot = slot_name
	loaded = true


func save_to_slot(slot_name: String) -> Error:
	return SaveManager.save_data(slot_name, current_data)


func get_data(path: String) -> Variant:
	if not loaded:
		DebugManager.log_warn(name, "No state data is loaded, skipping get: %s" % path)
		return null
	var node: Dictionary = current_data
	for key in path.split("/"):
		if node.has(key):
			node = node[key]
		else:
			DebugManager.log_warn(name, "Data not found: %s" % path)
			return null
	return node


func set_data(path: String, value: Variant) -> Error:
	if not loaded:
		DebugManager.log_warn(name, "No state data is loaded, skipping set: %s" % path)
		return FAILED
	var keys: Array = path.split("/")
	var last: String = keys.pop_back()
	var node: Dictionary = current_data
	for key in keys:
		if not node.has(key):
			node[key] = {}
		node = node[key]
	node[last] = value
	return OK


func _reset_state() -> void:
	current_data = {}
	current_slot = ""
	loaded = false
