extends BaseManager

var _pools: Dictionary[PackedScene, ObjectPool] = {}

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	return OK


func get_instance(scene: PackedScene) -> Node:
	if not _pools.has(scene):
		_pools[scene] = ObjectPool.new(scene)
	return _pools[scene].get_instance()


func release(scene: PackedScene, obj: Node) -> void:
	if not _pools.has(scene):
		return
	_pools[scene].release(obj)
