extends BaseManager

func initialize() -> bool:
	super()
	if not EventBus.initialize():
		return false
		
	if not DebugManager.initialize():
		return false
		
	if not SteamManager.initialize():
		return false

	return true
