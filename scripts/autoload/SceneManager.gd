extends BaseManager

var _current_scene: Node = null
var _next_scene_path: String = ""
var _is_loading: bool = false
var _fade_rect: ColorRect = ColorRect.new()

func initialize() -> Error:
	super()
	DebugManager.log_info(name, "Initializing...")
	
	_fade_rect.anchor_top = 0.0
	_fade_rect.anchor_left = 0.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	
	var transition_layer: CanvasLayer = CanvasLayer.new()
	transition_layer.layer = RenderingServer.CANVAS_LAYER_MAX
	transition_layer.add_child(_fade_rect)
	add_child(transition_layer)
	
	return OK


func change_scene(scene_path: String) -> void:
	if _is_loading:
		DebugManager.log_warn(name, "Scene change already in progress; ignoring request.")
		return

	_is_loading = true
	_next_scene_path = scene_path
	
	_do_change_scene()


func reload_scene() -> void:
	if not _current_scene:
		DebugManager.log_warn(name, "No scene to reload.")
		return
	change_scene(_current_scene.scene_file_path)


func _do_change_scene() -> void:
	DebugManager.log_info(name, "Starting async scene load for %s" % _next_scene_path)
	ResourceLoader.load_threaded_request(_next_scene_path)
	await _poll_async_load()


func _poll_async_load() -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_next_scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(_next_scene_path)

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		DebugManager.log_fatal(name, "Async scene load failed for %s (status=%s)" % [_next_scene_path, status])
		_is_loading = false
		return

	var res: PackedScene = ResourceLoader.load_threaded_get(_next_scene_path)
	if not res:
		DebugManager.log_fatal(name, "Threaded load returned null: %s" % _next_scene_path)
		_is_loading = false
		return

	var new_scene: Node = res.instantiate()
	
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, Constants.SCENE_FADE_TIME)
	tween.tween_callback(func():
		if _current_scene:
			_current_scene.queue_free()
		get_tree().root.add_child(new_scene)
		_current_scene = new_scene
		get_tree().current_scene = new_scene
		create_tween().tween_property(_fade_rect, "modulate:a", 0.0, Constants.SCENE_FADE_TIME)
		)

	DebugManager.log_info(name, "Async scene load complete: %s" % _next_scene_path)
	_is_loading = false
