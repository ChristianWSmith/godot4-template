extends BaseManager

func initialize() -> bool:
	super()
	DebugManager.log_info(name, "Initializing Steam...")
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

func is_cloud_available() -> bool:
	return is_active() and Steam.isCloudEnabledForAccount() and Steam.isCloudEnabledForApp()

func is_active() -> bool:
	return Steam.isSteamRunning() and Steam.loggedOn()

func cloud_write(file_path: String, data: PackedByteArray) -> bool:
	if not is_active():
		return false
	return Steam.fileWrite(file_path, data)

func cloud_read(file_path: String) -> PackedByteArray:
	if not is_active() or not Steam.fileExists(file_path):
		return PackedByteArray()
	return Steam.fileRead(file_path, Steam.getFileSize(file_path)).get("buf", PackedByteArray())
