## Coordinates the initialization of all core systems after the main scene
## has loaded. Ensures that each subsystem manager is initialized in order
## and triggers a scene reload once initialization completes successfully.
##
## If any system fails to initialize, the process stops and the failure is logged.
extends BaseManager

func _ready() -> void:
	if ResourceUID.path_to_uid(get_tree().current_scene.scene_file_path) != \
		ProjectSettings.get("application/run/main_scene"):
		
		print("[%s] Starting initialization..." % name)

		if initialize() == OK:
			Log.info(self, "Systems initialized successfully.")
			SceneManager.reload_scene_async()
		else:
			print("[%s] Initialization failed." % name)


## Initializes this manager and all registered subsystems.
## Returns an [code]Error[/code] indicating success ([code]OK[/code]) or the
## specific subsystem failure.
## Overrides BaseManager.initialize() to perform multi-system setup.
func initialize() -> Error:
	super()
	var result: Error
	
	for system in systems():
		result = system.initialize()
		if result != OK:
			return result
	
	return OK


## Returns an array of all subsystem managers to be initialized.
## Each element must extend [code]BaseManager[/code].
func systems() -> Array[BaseManager]: 
	return [
		EventBus,
		Log,
		Traits,
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
	
