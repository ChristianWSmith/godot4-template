extends BaseManager

func initialize() -> bool:
	super()
	
	if not EventBus.initialize():
		return false
		
	if not DebugManager.initialize():
		return false
		
	if not SteamManager.initialize():
		return false
		
	if not VideoManager.initialize():
		return false
		
	if not SaveManager.initialize():
		return false
		
	if not SettingsManager.initialize():
		return false
	
	return true
