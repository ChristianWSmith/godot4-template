extends Node

func _ready() -> void:
	print("[%s] Starting initialization..." % name)

	if InitManager.initialize():
		DebugManager.log_info(name, "Systems initialized successfully.")
		SceneManager.change_scene("res://scenes/main_menu.tscn", true)
	else:
		print("[%s] Initialization failed." % name)
