extends Node
class_name ValueStore

@export var _value: Variant

signal changed(Variant)

func get_value() -> Variant:
	return _value


func set_value(value: Variant) -> void:
	_value = value
	changed.emit(_value)
