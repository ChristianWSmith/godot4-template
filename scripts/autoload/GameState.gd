extends Node

signal state_changed(key: String, value: Variant)

var session_data: Dictionary = {}


func initialize() -> void:
	pass


func get_value(key: String, default_value: Variant = null) -> Variant:
	return session_data.get(key, default_value)


func set_value(key: String, value: Variant) -> void:
	pass


func clear_session() -> void:
	pass
