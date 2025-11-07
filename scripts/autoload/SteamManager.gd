extends BaseManager

var _reconciliation_timer: Timer = Timer.new()
var _reconciliation_mutex: Mutex = Mutex.new()
var _files_to_write: Dictionary[String, PackedByteArray] = {}
var _files_to_delete: Dictionary[String, bool] = {}

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
	
	_reconciliation_timer.timeout.connect(_attempt_reconciliation)
	add_child(_reconciliation_timer)
	_reconciliation_timer.start(Constants.STEAM_RECONCILIATION_INTERVAL)
	
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
	return Steam.isSteamRunning() and Steam.loggedOn() and Steam.isCloudEnabledForAccount() and Steam.isCloudEnabledForApp()


func cloud_write(filename: String, data: PackedByteArray) -> Error:
	if not is_cloud_available():
		DebugManager.log_warn(name, "Steam cloud not available, won't write file: %s" % filename)
		return FAILED
	if Steam.fileWrite(filename, data):
		DebugManager.log_info(name, "Wrote Steam Cloud file: %s" % filename)
		_dequeue_reconciliation(filename)
		return OK
	else:
		DebugManager.log_warn(name, "Failed to write Steam Cloud file: %s" % filename)
		_queue_write(filename, data)
		return FAILED


func cloud_read(filename: String) -> PackedByteArray:
	if not is_cloud_available() or not Steam.fileExists(filename):
		DebugManager.log_warn(name, "Steam cloud not available, won't read file: %s" % filename)
		return PackedByteArray()
	return Steam.fileRead(filename, Steam.getFileSize(filename)).get("buf", PackedByteArray())


func cloud_delete(filename: String) -> Error:
	if not is_cloud_available():
		DebugManager.log_warn(name, "Steam Cloud not available. Cannot delete %s" % filename)
		return FAILED
	if Steam.fileDelete(filename) or filename not in cloud_list_files():
		DebugManager.log_info(name, "Deleted Steam Cloud file: %s" % filename)
		_dequeue_reconciliation(filename)
		return OK
	else:
		DebugManager.log_warn(name, "Failed to delete Steam Cloud file: %s" % filename)
		_queue_delete(filename)
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


func _queue_write(filename: String, data: PackedByteArray) -> void:
	_reconciliation_mutex.lock()
	_files_to_delete.erase(filename)
	_files_to_write[filename] = data
	_reconciliation_mutex.unlock()


func _queue_delete(filename: String) -> void:
	_reconciliation_mutex.lock()
	_files_to_write.erase(filename)
	_files_to_delete[filename] = true
	_reconciliation_mutex.unlock()


func _dequeue_reconciliation(filename: String) -> void:
	_reconciliation_mutex.lock()
	_files_to_delete.erase(filename)
	_files_to_write.erase(filename)
	_reconciliation_mutex.unlock()


func _attempt_reconciliation() -> void:
	if not is_cloud_available():
		return
	_reconciliation_mutex.lock()
	if not _files_to_delete.is_empty():
		var successfully_deleted: Array[String] = []
		for filename in _files_to_delete:
			if cloud_delete(filename) == OK:
				successfully_deleted.append(filename)
		for filename in successfully_deleted:
			_files_to_delete.erase(filename)
	if not _files_to_write.is_empty():
		var successfully_written: Array[String] = []
		for filename in _files_to_write:
			if cloud_write(filename, _files_to_write[filename]) == OK:
				successfully_written.append(filename)
		for filename in successfully_written:
			_files_to_write.erase(filename)
	_reconciliation_mutex.unlock()
	_reconciliation_timer.start(Constants.STEAM_RECONCILIATION_INTERVAL)
