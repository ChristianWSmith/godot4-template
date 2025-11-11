extends Button
class_name InputCaptorButton

@export var key_allowed: bool = true
@export var mouse_button_allowed: bool = true
@export var joypad_button_allowed: bool = true
@export var joypad_motion_allowed: bool = true

signal binding_updated

# Examples: 
#   { "type": "Key", "alt": false, "ctrl": false, "keycode": 0, "meta": false, "physical_keycode": 32, "shift": false }
#   { "type": "MouseButton", "button_index": 1 }
#   { "type": "JoypadButton" , "button_index": 0, "device": -1 }
#   { "type": "JoypadMotion", "axis": 1, "axis_value": -1.0, "device": -1 }
var _binding: Dictionary = {}
var _capturing: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)
	text = _get_binding_text()


func set_binding(binding: Dictionary) -> void:
	_binding = binding
	text = _get_binding_text()


func get_binding() -> Dictionary:
	return _binding


func _on_pressed() -> void:
	if _capturing:
		return
	_capturing = true
	text = "Waiting for input..."
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not _capturing:
		return
		
	get_viewport().set_input_as_handled()

	# KEYBOARD
	if key_allowed and event is InputEventKey and event.pressed and not event.echo:
		_binding = {
			"type": "Key",
			"physical_keycode": event.physical_keycode,
			"keycode": event.keycode,
			"alt": event.alt_pressed,
			"ctrl": event.ctrl_pressed,
			"shift": event.shift_pressed,
			"meta": event.meta_pressed
		}
		_stop_capture()
		return

	# MOUSE BUTTON
	if mouse_button_allowed and event is InputEventMouseButton and event.pressed:
		_binding = {
			"type": "MouseButton",
			"button_index": event.button_index
		}
		_stop_capture()
		return

	# JOYPAD BUTTON
	if joypad_button_allowed and event is InputEventJoypadButton and event.pressed:
		_binding = {
			"type": "JoypadButton",
			"button_index": event.button_index,
			"device": event.device
		}
		_stop_capture()
		return

	# JOYPAD MOTION (axis movement)
	if joypad_motion_allowed and event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.5:
			_binding = {
				"type": "JoypadMotion",
				"axis": event.axis,
				"axis_value": sign(event.axis_value),
				"device": event.device
			}
			_stop_capture()
			return


func _stop_capture() -> void:
	_capturing = false
	set_process_input(false)
	text = _get_binding_text()
	AudioManager.play_ui(SystemConstants.UI_CLICK_STREAM)
	binding_updated.emit()


func _get_binding_text() -> String:
	if _capturing:
		return "Waiting for input..."

	if _binding.is_empty():
		return "..."

	match _binding.get("type", ""):
		"Key":
			var key_name: String = OS.get_keycode_string(_binding.get("physical_keycode", 0))
			return key_name if key_name != "" else "Unknown Key"
		"MouseButton":
			return "Mouse Button %d" % _binding.get("button_index", -1)
		"JoypadButton":
			return "Joypad Button %d" % _binding.get("button_index", -1)
		"JoypadMotion":
			var axis = _binding.get("axis", -1)
			var axis_value = _binding.get("axis_value", 0.0)
			return "Joypad Axis %d (%s)" % [axis, "+" if axis_value > 0 else "-"]
		_:
			return "Unknown"
