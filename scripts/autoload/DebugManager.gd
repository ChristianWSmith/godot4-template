extends Node

signal log_emitted(message: String, level: int)

enum LogLevel { INFO, WARNING, ERROR }

var debug_enabled: bool = true


func initialize() -> void:
	pass


func log(message: String, level: int = LogLevel.INFO) -> void:
	pass


func toggle_debug(enabled: bool) -> void:
	pass


func show_overlay() -> void:
	pass


func hide_overlay() -> void:
	pass
