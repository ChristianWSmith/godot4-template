extends Node

func _ready() -> void:
	print("[%s] Starting initialization..." % name)

	if await InitManager.initialize() == OK:
		DebugManager.log_info(name, "Systems initialized successfully.")
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		# SceneManager.change_scene("res://scenes/main_menu.tscn", true)
	else:
		print("[%s] Initialization failed." % name)
