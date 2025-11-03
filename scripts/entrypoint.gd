extends Node

func _ready() -> void:
	print("[%s] Starting initialization..." % name)

	# Kick off global system init
	InitManager.initialize_systems()
	
	# Wait for all systems to finish
	await InitManager.systems_initialized

	print("[%s] Systems initialized successfully." % name)

	# Transition to main menu
	SceneManager.change_scene("res://scenes/main_menu.tscn", true)
