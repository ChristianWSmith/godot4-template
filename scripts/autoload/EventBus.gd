extends BaseManager

var _subscribers: Dictionary[String, Array] = {}
var _once_wrappers: Dictionary[Callable, Callable] = {}
var _waiters: Dictionary[String, Array] = {}

func initialize() -> Error:
	super()
	_subscribers.clear()
	_once_wrappers.clear()
	_waiters.clear()
	return OK


func subscribe(event_name: String, callable: Callable) -> void:
	if callable == null:
		return
	var obj = callable.get_object()
	if obj != null and not is_instance_valid(obj):
		return

	if not _subscribers.has(event_name):
		_subscribers[event_name] = []

	if callable in _subscribers[event_name]:
		return

	_subscribers[event_name].append(callable)


func unsubscribe(event_name: String, callable: Callable) -> void:
	if not _subscribers.has(event_name):
		return
	if callable in _subscribers[event_name]:
		_subscribers[event_name].erase(callable)

	if callable in _once_wrappers:
		_once_wrappers.erase(callable)

	_cleanup_signal_if_empty(event_name)


func once(event_name: String, callable: Callable) -> void:
	if callable == null:
		return

	var wrapper: Callable = Callable(self, "_once_wrapper").bind(event_name, callable)
	_once_wrappers[wrapper] = callable
	subscribe(event_name, wrapper)


func emit(event_name: String, data: Variant = null) -> void:
	if event_name != Constants.LOG_EVENT:
		Log.trace(self, "emit %s" % event_name)
	if _subscribers.has(event_name):
		var to_call: Array = _subscribers[event_name].duplicate()
		for callable in to_call:
			var obj = callable.get_object()
			if obj != null and is_instance_valid(obj):
				if data != null:
					callable.call(data)
				else:
					callable.call()
			else:
				_subscribers[event_name].erase(callable)

	if _waiters.has(event_name):
		var wait_list = _waiters[event_name].duplicate()
		for resume_func in wait_list:
			if resume_func is Callable:
				resume_func.call(data)
		_waiters[event_name].clear()

	_cleanup_signal_if_empty(event_name)


func wait_for(event_name: String) -> Variant:
	var state = {"done": false, "result": null}
	var resume_func := func(data):
		state.result = data
		state.done = true

	if not _waiters.has(event_name):
		_waiters[event_name] = []
	_waiters[event_name].append(resume_func)

	while not state.done:
		await get_tree().process_frame
	return state.result


func _once_wrapper(data: Variant, event_name: String, callable: Callable) -> void:
	if callable != null and (callable.get_object() == null or is_instance_valid(callable.get_object())):
		callable.call(data)

	unsubscribe(event_name, Callable(self, "_once_wrapper").bind(event_name, callable))


func _cleanup_signal_if_empty(event_name: String) -> void:
	if (not _subscribers.has(event_name) or _subscribers[event_name].is_empty()) and \
		(not _waiters.has(event_name) or _waiters[event_name].is_empty()):
		_subscribers.erase(event_name)
		_waiters.erase(event_name)
