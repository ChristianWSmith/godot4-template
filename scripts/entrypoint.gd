extends Node

@onready var timer: Timer = %Timer

func _ready() -> void:
	print("[%s] Starting initialization..." % name)
	
	timer.start(SystemConstants.SCENE_LOAD_SCREEN_MINIMUM_TIME)

	if InitManager.initialize() == OK:
		Log.info(self, "Systems initialized successfully.")
		if not timer.is_stopped():
			await timer.timeout
		SceneManager.change_scene_async("res://scenes/main_menu.tscn")
	else:
		print("[%s] Initialization failed." % name)
