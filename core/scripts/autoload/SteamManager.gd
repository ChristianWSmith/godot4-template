## Manager for handling Steamworks integration, including cloud storage,
## file reconciliation, and Steam initialization. Handles automatic retry
## of failed writes/deletes via an internal timer and mutex-protected queues.
extends BaseManager

var _reconciliation_timer: Timer = Timer.new()
var _reconciliation_mutex: Mutex = Mutex.new()
var _files_to_write: Dictionary[String, PackedByteArray] = {}
var _files_to_delete: Set = Set.new()

## Initializes the Steam API and sets up the reconciliation timer.
## Returns [code]OK[/code] if Steam is active or optional, [code]FAILED[/code] if Steam is required but unavailable.
func initialize() -> Error:
	super()
	Log.info(self, "Initializing Steam...")
	var response: Dictionary = Steam.steamInitEx( SystemConstants.STEAM_APP_ID, false )
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
	_reconciliation_timer.start(SystemConstants.STEAM_RECONCILIATION_INTERVAL)
	
	if active:
		Log.info(self, message)
		return OK
	elif SystemConstants.STEAM_REQUIRED:
		Log.fatal(self, message)
		return FAILED
	else:
		Log.warn(self, message)
		return OK


func _process(_delta: float) -> void:
	Steam.run_callbacks()


## Returns [code]true[/code] if Steam is running, the user is logged in, and cloud storage is enabled for both the account and the app.
func is_cloud_available() -> bool:
	return Steam.isSteamRunning() and Steam.loggedOn() and Steam.isCloudEnabledForAccount() and Steam.isCloudEnabledForApp()

## Writes [code]data[/code] to a file named [code]filename[/code] in Steam Cloud.
## Returns [code]OK[/code] if successful, [code]FAILED[/code] if the write fails (file will be queued for retry).
func cloud_write(filename: String, data: PackedByteArray) -> Error:
	if not is_cloud_available():
		Log.warn(self, "Steam cloud not available, won't write file: %s" % filename)
		return FAILED
	if Steam.fileWrite(filename, data):
		Log.debug(self, "Wrote Steam Cloud file: %s" % filename)
		_dequeue_reconciliation(filename)
		return OK
	else:
		Log.warn(self, "Failed to write Steam Cloud file, will retry: %s" % filename)
		_queue_write(filename, data)
		return FAILED


## Reads the contents of a Steam Cloud file named [code]filename[/code].
## Returns a [code]PackedByteArray[/code] containing the file data.
## Returns an empty [code]PackedByteArray[/code] if the cloud is unavailable or the file does not exist.
func cloud_read(filename: String) -> PackedByteArray:
	if not is_cloud_available() or not Steam.fileExists(filename):
		Log.warn(self, "Steam cloud not available, cannot read file: %s" % filename)
		return PackedByteArray()
	return Steam.fileRead(filename, Steam.getFileSize(filename)).get("buf", PackedByteArray())


## Deletes a file named [code]filename[/code] from Steam Cloud.
## Returns [code]OK[/code] if deletion succeeds or the file does not exist.
## Returns [code]FAILED[/code] if deletion fails (file will be queued for retry).
func cloud_delete(filename: String) -> Error:
	if not is_cloud_available():
		Log.warn(self, "Steam Cloud not available. Cannot delete %s" % filename)
		return FAILED
	if Steam.fileDelete(filename) or filename not in cloud_list_files():
		Log.debug(self, "Deleted Steam Cloud file: %s" % filename)
		_dequeue_reconciliation(filename)
		return OK
	else:
		Log.warn(self, "Failed to delete Steam Cloud file, will retry: %s" % filename)
		_queue_delete(filename)
		return FAILED


## Returns an array of [code]String[/code] containing all file names currently stored in Steam Cloud.
## Returns an empty array if Steam Cloud is unavailable.
func cloud_list_files() -> Array[String]:
	var files: Array[String] = []
	if not is_cloud_available():
		Log.warn(self, "Steam Cloud not available. Cannot list files.")
		return files

	var count: int = Steam.getFileCount()
	for i in range(count):
		var file_info = Steam.getFileNameAndSize(i)
		if file_info.has("name"):
			files.append(file_info["name"])

	Log.debug(self, "Steam Cloud files: [%s]" % ", ".join(files))
	return files


func _queue_write(filename: String, data: PackedByteArray) -> void:
	_reconciliation_mutex.lock()
	_files_to_delete.erase(filename)
	_files_to_write[filename] = data
	_reconciliation_mutex.unlock()


func _queue_delete(filename: String) -> void:
	_reconciliation_mutex.lock()
	_files_to_write.erase(filename)
	_files_to_delete.add(filename)
	_reconciliation_mutex.unlock()


func _dequeue_reconciliation(filename: String) -> void:
	_reconciliation_mutex.lock()
	_files_to_delete.erase(filename)
	_files_to_write.erase(filename)
	_reconciliation_mutex.unlock()


func _attempt_reconciliation() -> void:
	if not is_cloud_available():
		_reconciliation_timer.start(SystemConstants.STEAM_RECONCILIATION_INTERVAL)
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
	_reconciliation_timer.start(SystemConstants.STEAM_RECONCILIATION_INTERVAL)
