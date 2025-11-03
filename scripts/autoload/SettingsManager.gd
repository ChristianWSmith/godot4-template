extends Node

signal settings_loaded
signal settings_saved
signal setting_changed(name: String, value: Variant)

var settings: Dictionary = {}


func _ready() -> void:
	pass


func initialize() -> void:
	pass


func load_settings() -> void:
	pass


func save_settings() -> void:
	pass


func apply_settings() -> void:
	pass


func get_setting(name: String, default_value: Variant = null) -> Variant:
	return settings.get(name, default_value)


func set_setting(name: String, value: Variant) -> void:
	pass
