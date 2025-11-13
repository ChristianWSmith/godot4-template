extends Node
class_name ObjectPool

var _scene: PackedScene
var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _init(scene: PackedScene) -> void:
	_scene = scene


func get_instance() -> Node:
	var obj: Node
	if _available.is_empty():
		obj = _scene.instantiate()
		add_child(obj)
	else:
		obj = _available.pop_back()
	_in_use.append(obj)
	_set_active(obj, true)
	return obj


func release(obj: Node) -> void:
	if obj in _in_use:
		_in_use.erase(obj)
		_set_active(obj, false)
		_available.append(obj)


func clear() -> void:
	for obj in _in_use:
		_in_use.erase(obj)
		remove_child(obj)
		obj.queue_free()
	for obj in _available:
		_available.erase(obj)
		remove_child(obj)
		obj.queue_free()


static func _set_active(obj: Node, value: bool) -> void:
	obj.visible = value
	obj.set_process(value)
	obj.set_physics_process(value)
