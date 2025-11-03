extends Node

func _ready() -> void:
	print("Boot: Starting initialization...")

	# Kick off global system init
	InitManager.initialize_systems()

	# Wait for all systems to finish
	await InitManager.systems_initialized

	print("Boot: Systems initialized successfully.")

	# Transition to main menu
	SceneManager.change_scene("res://scenes/main_menu.tscn", true)
