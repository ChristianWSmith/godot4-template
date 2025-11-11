extends BaseManager

func _ready() -> void:
	if ResourceUID.path_to_uid(get_tree().current_scene.scene_file_path) != \
		ProjectSettings.get("application/run/main_scene"):
		
		print("[%s] Starting initialization..." % name)

		if initialize() == OK:
			Log.info(self, "Systems initialized successfully.")
			SceneManager.reload_scene()
		else:
			print("[%s] Initialization failed." % name)


func initialize() -> Error:
	super()
	var result: Error
	
	for system in _systems():
		result = system.initialize()
		if result != OK:
			return result
	
	return OK


func _systems() -> Array[BaseManager]: 
	return [
		EventBus,
		Log,
		SteamManager,
		VideoManager,
		SaveManager,
		GameState,
		InputManager,
		AudioManager,
		SceneManager,
		UIManager,
		GameplayManager,
		GraphicsManager,
		SettingsManager
	]
	
