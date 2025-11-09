extends BaseManager

var _current_scene: Node = null
var _next_scene_path: String = ""
var _is_loading: bool = false
var _fade_rect: ColorRect = ColorRect.new()

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_current_scene = get_tree().current_scene
	_setup_fader()
	return OK


func change_scene(scene_path: String) -> void:
	if _is_loading:
		Log.warn(self, "Scene change already in progress; ignoring request.")
		return
	
	_set_is_loading(true)
	_next_scene_path = scene_path
	
	_do_change_scene()


func reload_scene() -> void:
	if not _current_scene:
		Log.warn(self, "No scene to reload.")
		return
	change_scene(_current_scene.scene_file_path)


func _do_change_scene() -> void:
	Log.info(self, "Starting async scene load for %s" % _next_scene_path)
	ResourceLoader.load_threaded_request(_next_scene_path)
	await _poll_async_load()


func _poll_async_load() -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_next_scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(_next_scene_path)

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		Log.fatal(self, "Async scene load failed for %s (status=%s)" % [_next_scene_path, status])
		_set_is_loading(false)
		return

	var res: PackedScene = ResourceLoader.load_threaded_get(_next_scene_path)
	if not res:
		Log.fatal(self, "Threaded load returned null: %s" % _next_scene_path)
		_set_is_loading(false)
		return

	var new_scene: Node = res.instantiate()
	
	var fade_in_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(_fade_rect, "modulate:a", 1.0, Constants.SCENE_FADE_TIME)
	fade_in_tween.tween_callback(func():
		if _current_scene:
			_current_scene.queue_free()
		get_tree().root.add_child(new_scene)
		_current_scene = new_scene
		get_tree().current_scene = new_scene
		var fade_out_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fade_out_tween.tween_property(_fade_rect, "modulate:a", 0.0, Constants.SCENE_FADE_TIME)
		EventBus.emit("scene_changed", _next_scene_path)
		)

	Log.info(self, "Async scene load complete: %s" % _next_scene_path)
	_set_is_loading(false)


func _set_is_loading(value: float) -> void:
	_is_loading = value
	UIManager.show_throbber(_is_loading)


func _setup_fader() -> void:
	_fade_rect.anchor_top = 0.0
	_fade_rect.anchor_left = 0.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.color = Constants.SCENE_FADE_COLOR
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var transition_layer: CanvasLayer = CanvasLayer.new()
	transition_layer.layer = Constants.SCENE_FADE_LAYER
	transition_layer.add_child(_fade_rect)
	add_child(transition_layer)
