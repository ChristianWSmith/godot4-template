extends BaseManager

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
	
