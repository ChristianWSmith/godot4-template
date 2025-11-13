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


func clear(ignore_list: Array[String] = SystemConstants.POOL_CLEAR_IGNORE_LIST) -> void:
	var scenes_to_remove: Array[PackedScene] = []
	for scene in _pools:
		if ResourceUID.path_to_uid(scene.resource_path) in ignore_list:
			continue
		_pools[scene].clear()
		remove_child(_pools[scene])
		_pools[scene].queue_free()
		scenes_to_remove.append(scene)
	for scene_to_remove in scenes_to_remove:
		_pools.erase(scene_to_remove)


func clear_pool(scene: PackedScene) -> void:
	if scene not in _pools:
		return
	_pools[scene].clear()
	remove_child(_pools[scene])
	_pools[scene].queue_free()
	_pools.erase(scene)
