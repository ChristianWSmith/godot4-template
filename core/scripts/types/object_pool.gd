extends Node
class_name ObjectPool

var _scene: PackedScene
var _available: Array[Node] = []
var _in_use: Array[Node] = []
var _has_visible: bool = false
var _lower_bound: int = 0
var _upper_bound: int = SystemConstants.INT_MAX
var _bound_enforcer_thread: Thread
var _run_bound_enforcer: bool = true
var _mutex: Mutex = Mutex.new()

func _init(
		scene: PackedScene, 
		lower_bound: int = 0, 
		upper_bound: int = SystemConstants.INT_MAX) -> void:
	_scene = scene
	var obj: Node = _scene.instantiate()
	_has_visible = obj is CanvasItem
	name = "ObjectPool[%s]" % obj.name
	_set_active(obj, false)
	_available.append(obj)
	add_child(obj)
	set_lower_bound(lower_bound)
	set_upper_bound(upper_bound)
	_enforce_bounds()


func _exit_tree() -> void:
	if _bound_enforcer_thread and _bound_enforcer_thread.is_alive():
		_run_bound_enforcer = false
		_bound_enforcer_thread.wait_to_finish()


func get_instance() -> Node:
	var obj: Node
	_mutex.lock()
	var available_empty: bool = _available.is_empty()
	_mutex.unlock()
	if available_empty:
		obj = _scene.instantiate()
		add_child(obj)
	else:
		_mutex.lock()
		obj = _available.pop_back()
		_mutex.unlock()
		_enforce_bounds()
	_in_use.append(obj)
	_set_active(obj, true)
	return obj


func release(obj: Node) -> void:
	if obj in _in_use:
		_in_use.erase(obj)
		_set_active(obj, false)
		_mutex.lock()
		_available.append(obj)
		_mutex.unlock()
		_enforce_bounds()


func clear() -> void:
	for obj in _in_use:
		_in_use.erase(obj)
		remove_child(obj)
		obj.queue_free()
	_mutex.lock()
	for obj in _available:
		_available.erase(obj)
		remove_child(obj)
		obj.queue_free()
	_mutex.unlock()


func set_lower_bound(lower_bound: int) -> void:
	if _upper_bound < lower_bound:
		Log.warn(self, "Refusing lower bound of %s, upper bound is %s, clamping" % [lower_bound, _upper_bound])
		lower_bound = _upper_bound
	_lower_bound = lower_bound
	_enforce_bounds()


func set_upper_bound(upper_bound: int) -> void:
	if upper_bound < _lower_bound:
		Log.warn(self, "Refusing upper bound of %s, lower bound is %s, clamping." % [upper_bound, _lower_bound])
		upper_bound = _lower_bound
	_upper_bound = upper_bound
	_enforce_bounds()


func _set_active(obj: Node, value: bool) -> void:
	if _has_visible:
		obj.visible = value
	obj.set_process(value)
	obj.set_physics_process(value)


func _get_total() -> int:
	_mutex.lock()
	var out: int = _available.size() + _in_use.size()
	_mutex.unlock()
	return out


func _enforce_bounds() -> void:
	if _bound_enforcer_thread:
		if _bound_enforcer_thread.is_alive():
			return
		elif _bound_enforcer_thread.is_started():
			_bound_enforcer_thread.wait_to_finish()
	if _lower_bound > _get_total():
		_bound_enforcer_thread = Thread.new()
		_bound_enforcer_thread.start(_expand)
	elif _upper_bound < _get_total():
		_bound_enforcer_thread = Thread.new()
		_bound_enforcer_thread.start(_shrink)


func _expand() -> void:
	while _lower_bound > _get_total() and _run_bound_enforcer:
		var obj: Node = _scene.instantiate()
		_set_active(obj, false)
		_mutex.lock()
		_available.append(obj)
		_mutex.unlock()
		add_child.call_deferred(obj)


func _shrink() -> void:
	while _upper_bound < _get_total() and _run_bound_enforcer:
		_mutex.lock()
		var available_empty: bool = _available.is_empty()
		_mutex.unlock()
		if available_empty:
			break
		_mutex.lock()
		var obj: Node = _available.pop_front()
		_mutex.unlock()
		remove_child.call_deferred(obj)
		obj.queue_free()
