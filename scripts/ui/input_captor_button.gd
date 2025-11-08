extends Button
class_name InputCaptorButton

@export var key_allowed: bool = true
@export var mouse_button_allowed: bool = true
@export var joypad_button_allowed: bool = true
@export var joypad_motion_allowed: bool = true

# Examples:
#   { "type": "Key", "alt": false, "ctrl": false, "keycode": 0, "meta": false, "physical_keycode": 32, "shift": false },
#   { "type": "MouseButton", "button_index": 1 }
#   { "type": "JoypadButton" , "button_index": 0, "device": -1 }
#   { "type": "JoypadMotion", "axis": 1, "axis_value": -1.0, "device": -1 }
var _binding: Dictionary = {}

func _ready() -> void:
	pressed.connect(_on_pressed)


func set_binding(binding: Dictionary) -> void:
	# TODO: update text of the button based on the binding we're given
	_binding = binding


func get_binding() -> Dictionary:
	return _binding


func _on_pressed() -> void:
	# TODO: capture the next appropriate input as dicated by out flags, then set
	# our _binding accordingly, leveraging set_binding
	pass
