extends Node

signal save_loaded(slot: int)
signal save_saved(slot: int)
signal save_deleted(slot: int)

var current_slot: int = 0
var save_data: Dictionary = {}


func initialize() -> void:
	pass


func load_save(slot: int) -> void:
	pass


func save_game(slot: int) -> void:
	pass


func delete_save(slot: int) -> void:
	pass


func get_save_slots() -> Array[int]:
	return []
