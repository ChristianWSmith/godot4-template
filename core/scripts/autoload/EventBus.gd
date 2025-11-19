## A centralized event management system for subscribing, emitting, and
## waiting for named events. Supports persistent and one-time listeners,
## as well as asynchronous waiting for events using [code]wait_for()[/code].
##
## Ensures safe handling of invalid or freed objects when calling listeners.
extends BaseManager

var _subscribers: Dictionary[String, Array] = {}
var _once_wrappers: Dictionary[Callable, Callable] = {}
var _waiters: Dictionary[String, Array] = {}

## Initializes the EventBus, clearing all subscribers, one-time wrappers,
## and waiting coroutines. Called automatically during setup.
func initialize() -> Error:
	super()
	_subscribers.clear()
	_once_wrappers.clear()
	_waiters.clear()
	return OK


## Subscribes a callable to a named [code]event_name[/code].
## The [code]callable[/code] will be invoked whenever the event is emitted.
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


## Unsubscribes a callable from a named [code]event_name[/code].
## If the callable was added via [code]once()[/code], it is also removed from internal wrappers.
func unsubscribe(event_name: String, callable: Callable) -> void:
	if not _subscribers.has(event_name):
		return
	if callable in _subscribers[event_name]:
		_subscribers[event_name].erase(callable)

	if callable in _once_wrappers:
		_once_wrappers.erase(callable)

	_cleanup_signal_if_empty(event_name)


## Subscribes a callable to a named [code]event_name[/code] that will be called only once.
## After the first emission, the listener is automatically removed.
func once(event_name: String, callable: Callable) -> void:
	if callable == null:
		return

	var wrapper: Callable = Callable(self, "_once_wrapper").bind(event_name, callable)
	_once_wrappers[wrapper] = callable
	subscribe(event_name, wrapper)


## Emits an event with the given [code]event_name[/code] and optional [code]data[/code].
## All subscribed callables and any waiting coroutines will be invoked with the data.
func emit(event_name: String, data: Variant = null) -> void:
	if event_name != SystemConstants.LOG_EVENT:
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


## Waits asynchronously until the named [code]event_name[/code] is emitted.
## Returns the data passed to [code]emit()[/code] once the event occurs.
func wait_for(event_name: String) -> Variant:
	var state = {"done": false, "result": null}
	var resume_func: Callable = func(data):
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
		if data != null:
			callable.call(data)
		else:
			callable.call()

	unsubscribe(event_name, Callable(self, "_once_wrapper").bind(event_name, callable))


func _cleanup_signal_if_empty(event_name: String) -> void:
	if (not _subscribers.has(event_name) or _subscribers[event_name].is_empty()) and \
		(not _waiters.has(event_name) or _waiters[event_name].is_empty()):
		_subscribers.erase(event_name)
		_waiters.erase(event_name)
