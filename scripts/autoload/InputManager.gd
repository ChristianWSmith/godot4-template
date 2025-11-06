extends BaseManager

# Example:
# {
#  "jump": [
#      { "alt": false, "ctrl": false, "keycode": 0, "meta": false, "physical_keycode": 32, "shift": false, "type": "Key" },
#      { "button_index": 0, "device": -1, "type": "JoypadButton" }
#    ],
#  "up": [
#      { "alt": false, "ctrl": false, "keycode": 0, "meta": false, "physical_keycode": 87, "shift": false, "type": "Key" },
#      { "axis": 1, "axis_value": -1.0, "device": -1, "type": "JoypadMotion" }
#    ]
# }
var _bindings: Dictionary = {}

func initialize() -> Error:
	super()
	DebugManager.log_info(name, "Initializing InputManager...")
	EventBus.subscribe(SettingsManager.get_section_event("input"), _on_settings_updated)
	return OK


func apply_and_save(bindings: Dictionary) -> void:
	_apply_bindings(bindings)
	_save(bindings)


func dump_bindings() -> Dictionary:
	return _bindings.duplicate(true)


func get_pressed_event(action: String) -> String:
	return "just_pressed/" + action


func get_released_event(action: String) -> String:
	return "just_released/" + action


func _on_settings_updated() -> void:
	_apply_bindings(SettingsManager.get_value("input", "bindings") as Dictionary)


func _apply_bindings(bindings: Dictionary) -> void:
	_bindings = bindings

	if not _bindings or _bindings.is_empty():
		DebugManager.log_info(name, "No custom bindings found, using project defaults.")
		_save(_get_project_default_bindings())
		return

	for action_name in _bindings.keys():
		_register_action(action_name, _bindings[action_name])

	DebugManager.log_info(name, "Applied bindings for actions: %s" % ", ".join(_bindings.keys()))


func _save(bindings: Dictionary) -> void:
	var serialized := {}
	for action_name in bindings.keys():
		if action_name in Constants.INPUT_BUILT_IN_ACTIONS:
			continue
		var events := []
		for ev in InputMap.action_get_events(action_name):
			events.append(_serialize_input_event(ev))
		serialized[action_name] = events
	if serialized.size() != 0:
		SettingsManager.set_value("input", "bindings", serialized)


func _register_action(action_name: String, event_defs: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for evt in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, evt)

	for event_def in event_defs:
		var ev: InputEvent = _parse_event_def(event_def)
		if ev != null:
			InputMap.action_add_event(action_name, ev)


func _parse_event_def(event_def: Dictionary) -> InputEvent:
	var type_name: String = str(event_def.get("type", ""))
	match type_name:
		"Key":
			var evk: InputEventKey = InputEventKey.new()
			evk.physical_keycode = int(event_def.get("physical_keycode", 0)) as Key
			evk.keycode = int(event_def.get("keycode", 0)) as Key
			evk.alt_pressed = bool(event_def.get("alt", false))
			evk.shift_pressed = bool(event_def.get("shift", false))
			evk.ctrl_pressed = bool(event_def.get("ctrl", false))
			evk.meta_pressed = bool(event_def.get("meta", false))
			return evk

		"MouseButton":
			var evm: InputEventMouseButton = InputEventMouseButton.new()
			evm.button_index = int(event_def.get("button_index", MOUSE_BUTTON_LEFT)) as MouseButton
			return evm

		"JoypadButton":
			var ejb: InputEventJoypadButton = InputEventJoypadButton.new()
			ejb.button_index = int(event_def.get("button_index", 0)) as JoyButton
			ejb.device = int(event_def.get("device", 0))
			return ejb

		"JoypadMotion":
			var ejm: InputEventJoypadMotion = InputEventJoypadMotion.new()
			ejm.axis = int(event_def.get("axis", 0)) as JoyAxis
			ejm.axis_value = float(event_def.get("axis_value", 0.0))
			ejm.device = int(event_def.get("device", 0))
			return ejm

		_:
			DebugManager.log_warn(name, "Unknown event type in dict: %s" % type_name)
			return null


func _serialize_input_event(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {
			"type": "Key",
			"physical_keycode": ev.physical_keycode,
			"keycode": ev.keycode,
			"alt": ev.alt_pressed,
			"shift": ev.shift_pressed,
			"ctrl": ev.ctrl_pressed,
			"meta": ev.meta_pressed
		}
	elif ev is InputEventMouseButton:
		return {
			"type": "MouseButton",
			"button_index": ev.button_index
		}
	elif ev is InputEventJoypadButton:
		return {
			"type": "JoypadButton",
			"button_index": ev.button_index,
			"device": ev.device
		}
	elif ev is InputEventJoypadMotion:
		return {
			"type": "JoypadMotion",
			"axis": ev.axis,
			"axis_value": ev.axis_value,
			"device": ev.device
		}
	else:
		DebugManager.log_warn(name, "Cannot serialize unknown input event: %s" % ev)
		return {}


func _get_project_default_bindings() -> Dictionary:
	var defaults := {}
	for prop in ProjectSettings.get_property_list():
		if not prop.has("name"):
			continue
		var prop_name: String = prop["name"]
		if not prop_name.begins_with("input/"):
			continue

		var action_name: String = prop_name.get_slice("/", 1)
		var action_data: Variant = ProjectSettings.get_setting(prop_name)
		if typeof(action_data) == TYPE_DICTIONARY and action_data.has("events"):
			var serialized := []
			for ev in action_data["events"]:
				if ev is InputEvent:
					serialized.append(_serialize_input_event(ev))
			defaults[action_name] = serialized
	return defaults


func _input(event: InputEvent) -> void:
	for action in _bindings.keys():
		if not event.is_action(action):
			continue
		if event.is_action_pressed(action):
			EventBus.emit(get_pressed_event(action))
		elif event.is_action_released(action):
			EventBus.emit(get_released_event(action))
		break
