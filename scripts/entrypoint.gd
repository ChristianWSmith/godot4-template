extends Node

func _ready() -> void:
	print("[%s] Starting initialization..." % name)

	if InitManager.initialize() == OK:
		Log.info(name, "Systems initialized successfully.")
		SceneManager.change_scene("res://scenes/main_menu.tscn")
	else:
		print("[%s] Initialization failed." % name)
