extends BaseManager

func initialize() -> Error:
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
		return OK
	elif Constants.STEAM_REQUIRED:
		DebugManager.log_fatal(name, message)
		return FAILED
	else:
		DebugManager.log_warn(name, message)
		return OK


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func is_cloud_available() -> bool:
	return is_active() and Steam.isCloudEnabledForAccount() and Steam.isCloudEnabledForApp()


func is_active() -> bool:
	return Steam.isSteamRunning() and Steam.loggedOn()


func cloud_write(file_path: String, data: PackedByteArray) -> Error:
	if not is_cloud_available():
		DebugManager.log_warn(name, "Steam cloud not available, won't write file: %s" % file_path)
		return FAILED
	return OK if Steam.fileWrite(file_path, data) else FAILED


func cloud_read(file_path: String) -> PackedByteArray:
	if not is_cloud_available() or not Steam.fileExists(file_path):
		DebugManager.log_warn(name, "Steam cloud not available, won't read file: %s" % file_path)
		return PackedByteArray()
	return Steam.fileRead(file_path, Steam.getFileSize(file_path)).get("buf", PackedByteArray())


func cloud_delete(filename: String) -> Error:
	if not is_cloud_available():
		DebugManager.log_warn(name, "Steam Cloud not available. Cannot delete %s" % filename)
		return FAILED
	
	if Steam.fileDelete(filename):
		DebugManager.log_info(name, "Deleted Steam Cloud file: %s" % filename)
		return OK
	else:
		DebugManager.log_warn(name, "Failed to delete Steam Cloud file: %s" % filename)
		return FAILED


func cloud_list_files() -> Array[String]:
	var files: Array[String] = []
	if not is_cloud_available():
		DebugManager.log_warn(name, "Steam Cloud not available. Cannot list files.")
		return files

	var count: int = Steam.getFileCount()
	for i in range(count):
		var file_info = Steam.getFileNameAndSize(i)
		if file_info.has("name"):
			files.append(file_info["name"])

	DebugManager.log_debug(name, "Steam Cloud files: [%s]" % ", ".join(files))
	return files
