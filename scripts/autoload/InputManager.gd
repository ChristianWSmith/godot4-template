extends Node

signal action_pressed(action: String)
signal action_released(action: String)
signal action_rebound(action: String, new_event: InputEvent)

var _action_strengths: Dictionary[String, float] = {}
var _just_pressed: Dictionary[String, bool] = {}
var _just_released: Dictionary[String, bool] = {}


func initialize() -> void:
	pass


func _input(event: InputEvent) -> void:
	pass


func is_pressed(action: String) -> bool:
	return _action_strengths.get(action, 0.0) > 0.0


func is_just_pressed(action: String) -> bool:
	return _just_pressed.get(action, false)


func is_just_released(action: String) -> bool:
	return _just_released.get(action, false)


func get_axis(negative_action: String, positive_action: String) -> float:
	return 0.0


func rebind_action(action: String, new_event: InputEvent) -> void:
	pass
