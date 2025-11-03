extends Node

# No fixed signals — this is a dynamic bus.

func initialize() -> void:
	pass


func emit(event_name: String, data: Variant = null) -> void:
	pass


func subscribe(event_name: String, target: Object, method: String) -> void:
	pass


func unsubscribe(event_name: String, target: Object, method: String) -> void:
	pass
