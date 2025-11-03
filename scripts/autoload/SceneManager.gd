extends Node

signal scene_about_to_change(from_scene: String, to_scene: String)
signal scene_changed(new_scene: String)

var current_scene_path: String = ""


func initialize() -> void:
	pass


func change_scene(path: String, fade: bool = true) -> void:
	pass


func reload_scene() -> void:
	pass


func get_current_scene() -> Node:
	return get_tree().current_scene
