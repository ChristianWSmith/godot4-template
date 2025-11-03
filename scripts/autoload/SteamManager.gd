extends BaseManager

func initialize() -> bool:
	super()
	var response: Dictionary = Steam.steamInitEx( Constants.STEAM_APP_ID, false )
	var status: int = response.get("status", -1)
	var message: String
	var active: bool = false
	match status:
		0:
			message = "Steamworks active"
			active = true
		1:
			message = "Failed (generic)"
		2:
			message = "Cannot connect to Steam, client probably isn't running"
		3:
			message = "Steam client appears to be out of date"
		_: 
			message = "Unkonwn error"
	
	if active:
		DebugManager.log_info(name, message)
		return true
	elif Constants.STEAM_REQUIRED:
		DebugManager.log_fatal(name, message)
		return false
	else:
		DebugManager.log_warn(name, message)
		return true

func _process(_delta: float) -> void:
	Steam.run_callbacks()
