extends BaseManager

var _pools: Dictionary[PackedScene, ObjectPool] = {}

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	return OK


func get_instance(scene: PackedScene) -> Node:
	if not _pools.has(scene):
		_pools[scene] = ObjectPool.new(scene)
		add_child(_pools[scene])
	return _pools[scene].get_instance()


func release(scene: PackedScene, obj: Node) -> void:
	if _pools.has(scene):
		_pools[scene].release(obj)


func clear() -> void:
	for scene in _pools:
		_pools[scene].clear()
		remove_child(_pools[scene])
		_pools[scene].queue_free()
	_pools = {}


func clear_pool(scene: PackedScene) -> void:
	if scene not in _pools:
		return
	_pools[scene].clear()
	remove_child(_pools[scene])
	_pools[scene].queue_free()
	_pools.erase(scene)
