extends BaseManager

enum LogLevel { TRACE, DEBUG, INFO, WARN, ERROR, FATAL, NONE }

var _current_level: LogLevel = LogLevel.NONE
var _log_to_file: bool = false
var _file_path: String = SystemConstants.LOG_FILE_PATH
var _file: FileAccess = null
var _initialized: bool = false

func initialize() -> Error:
	super()
	_handle_cli_args()
	_clear_log_file()
	_open_log_file()
	_log_internal(LogLevel.INFO, name, "Initialized and ready.")
	_initialized = true
	return OK


func set_log_level(level: LogLevel) -> void:
	if not _initialized:
		return
	_current_level = level
	_log_internal(LogLevel.INFO, name, "Log level set to %s" % [_get_level_name(level)])


func set_log_to_file(enabled: bool, path: String = SystemConstants.LOG_FILE_PATH) -> void:
	if not _initialized:
		return
	_log_to_file = enabled
	_file_path = path
	if enabled:
		_open_log_file()
	else:
		_close_log_file()
	_log_internal(LogLevel.INFO, name, "File logging %s (%s)" % ["enabled" if enabled else "disabled", _file_path])


func trace(source: Node, message: String) -> void:
	if not _initialized:
		return
	_log_internal(LogLevel.TRACE, source.name, message)


func debug(source: Node, message: String) -> void:
	if not _initialized:
		return
	_log_internal(LogLevel.DEBUG, source.name, message)


func info(source: Node, message: String) -> void:
	if not _initialized:
		return
	_log_internal(LogLevel.INFO, source.name, message)


func warn(source: Node, message: String) -> void:
	if not _initialized:
		return
	_log_internal(LogLevel.WARN, source.name, message)


func error(source: Node, message: String) -> void:
	if not _initialized:
		return
	_log_internal(LogLevel.ERROR, source.name, message)


func fatal(source: Node, message: String) -> void:
	_log_internal(LogLevel.FATAL, source.name, message)


func _clear_log_file() -> void:
	if FileAccess.file_exists(_file_path):
		var f = FileAccess.open(_file_path, FileAccess.WRITE)
		f.store_string("")
		f.close()
		_log_internal(LogLevel.INFO, name, "Cleared log file: %s" % _file_path)


func _log_internal(level: LogLevel, source: String, message: String) -> void:
	if level < _current_level:
		return

	var timestamp: float = Time.get_unix_time_from_system()
	var timestr: String = Time.get_datetime_string_from_unix_time(int(timestamp), true)
	var level_str: String = _get_level_name(level)

	var formatted: String = "[%s] [%s] (%s) %s" % [timestr, level_str, source, message]

	match level:
		LogLevel.TRACE:
			print_rich("[color=gray]%s[/color]" % formatted)
		LogLevel.DEBUG:
			print_rich("[color=cyan]%s[/color]" % formatted)
		LogLevel.INFO:
			print_rich("[color=green]%s[/color]" % formatted)
		LogLevel.WARN:
			print_rich("[color=yellow]%s[/color]" % formatted)
		LogLevel.ERROR:
			print_rich("[color=orange]%s[/color]" % formatted)
		LogLevel.FATAL:
			print_rich("[color=red]%s[/color]" % formatted)

	if _log_to_file and _file:
		_file.store_line(formatted)
		_file.flush()

	if source != EventBus.name:
		var payload = {
			"timestamp": timestamp,
			"level": level_str,
			"source": source,
			"message": message,
		}
		EventBus.emit(SystemConstants.LOG_EVENT, payload)
	
	if level == LogLevel.FATAL:
		CrashReport.crash(source, message)


func _open_log_file() -> void:
	if not _log_to_file:
		return
	_close_log_file()
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	if _file:
		_file.store_line("----- Debug Log Started: %s -----" % Time.get_datetime_string_from_system())
	else:
		_file_path = SystemConstants.LOG_FILE_PATH
		_open_log_file()


func _close_log_file() -> void:
	if _file:
		_file.close()
		_file = null


func _get_level_name(level: LogLevel) -> String:
	match level:
		LogLevel.TRACE: return "TRACE"
		LogLevel.DEBUG: return "DEBUG"
		LogLevel.INFO: return "INFO"
		LogLevel.WARN: return "WARN"
		LogLevel.ERROR: return "ERROR"
		LogLevel.FATAL: return "FATAL"
		_: return "UNKNOWN"


func _exit_tree() -> void:
	_close_log_file()


func _handle_cli_args() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg in args:
		if arg.to_lower().begins_with("--log-level="):
			var level: String = arg.split("=")[1]
			match level.to_lower():
				"trace": _current_level = LogLevel.TRACE
				"debug": _current_level = LogLevel.DEBUG
				"info": _current_level = LogLevel.INFO
				"warn": _current_level = LogLevel.WARN
				"error": _current_level = LogLevel.ERROR
				"fatal": _current_level = LogLevel.FATAL
				_: _current_level = LogLevel.NONE
		elif arg.to_lower().begins_with("--log-file="):
			_file_path = arg.split("=")[1]
			_log_to_file = true
	
