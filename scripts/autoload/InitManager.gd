extends BaseManager

func initialize() -> Error:
	super()
	var result: Error
	
	result = EventBus.initialize()
	if result != OK:
		return result
	
	result = DebugManager.initialize()
	if result != OK:
		return result
	
	result = SteamManager.initialize()
	if result != OK:
		return result
	
	result = VideoManager.initialize()
	if result != OK:
		return result
	
	result = SaveManager.initialize()
	if result != OK:
		return result
	
	result = GameState.initialize()
	if result != OK:
		return result
	
	result = SettingsManager.initialize()
	if result != OK:
		return result
	
	return OK
