extends Node

signal systems_initialized

var _initialized: bool = false


func _ready() -> void:
	pass


func register_system(system_name: String, system_ref: Node) -> void:
	pass


func initialize_systems() -> void:
	pass


func are_systems_initialized() -> bool:
	return _initialized
