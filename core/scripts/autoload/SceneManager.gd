## Handles scene transitions, including async loading, fade effects, and throbber display.
##
## Ensures only one scene change occurs at a time and emits events when scenes change.
extends BaseManager

var _loading_screen: LoadingScreen = SystemConstants.SCENE_LOADING_SCREEN.instantiate()
var _current_scene: Node = null
var _is_loading: bool = false
var _fade_rect: ColorRect = ColorRect.new()
var _loading_screen_timer: Timer = Timer.new()

## Initializes the SceneManager, setting up the current scene, the fade overlay, and a timer for minimum loading screen display.
## Emits a [code]scene_changed[/code] event for the current scene.
func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_current_scene = get_tree().current_scene
	EventBus.emit("scene_changed", _current_scene.scene_file_path)
	_setup_fader()
	_loading_screen_timer.one_shot = true
	add_child(_loading_screen_timer)
	return OK


## Changes the current scene to [code]scene_path[/code], showing a loading screen and applying a fade effect.
## If a scene change is already in progress, the request is ignored.
func change_scene(scene_path: String) -> void:
	if _is_loading:
		Log.warn(self, "Scene change already in progress; ignoring request.")
		return
	_loading_screen_timer.start(SystemConstants.SCENE_LOAD_SCREEN_MINIMUM_TIME)
	_swap_scene(_loading_screen)
	change_scene_async(scene_path)
	EventBus.once("scene_changed", func(_i: Variant) -> void:
		_loading_screen = SystemConstants.SCENE_LOADING_SCREEN.instantiate())


## Begins loading the scene at [code]scene_path[/code] asynchronously.
## The scene will be swapped in once loading is complete.
## Ignores requests if a load is already in progress.
func change_scene_async(scene_path: String) -> void:
	if _is_loading:
		Log.warn(self, "Scene change already in progress; ignoring request.")
		return
	_set_is_loading(true)
	_do_change_scene_async(scene_path)


## Reloads the currently active scene asynchronously.
## Logs a warning if no scene is loaded.
func reload_scene_async() -> void:
	if not _current_scene:
		Log.warn(self, "No scene to reload.")
		return
	change_scene_async(_current_scene.scene_file_path)


func _do_change_scene_async(scene_path: String) -> void:
	Log.info(self, "Starting async scene load for %s" % scene_path)
	ResourceLoader.load_threaded_request(scene_path)
	await _poll_async_load(scene_path)


func _poll_async_load(scene_path: String) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(scene_path)
	var progress: Array = [0]
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		_loading_screen.set_progress(min(
			progress[0],
			_get_loading_timer_progress()))
		await get_tree().process_frame
	
	while not _loading_screen_timer.is_stopped():
		_loading_screen.set_progress(_get_loading_timer_progress())
		await get_tree().process_frame

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		Log.fatal(self, "Async scene load failed for %s (status=%s)" % [scene_path, status])
		_set_is_loading(false)
		return

	var res: PackedScene = ResourceLoader.load_threaded_get(scene_path)
	if not res:
		Log.fatal(self, "Threaded load returned null: %s" % scene_path)
		_set_is_loading(false)
		return

	var new_scene: Node = res.instantiate()
	
	var fade_in_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(_fade_rect, "modulate:a", 1.0, SystemConstants.SCENE_FADE_TIME)
	fade_in_tween.tween_callback(func():
		_swap_scene(new_scene)
		var fade_out_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fade_out_tween.tween_property(_fade_rect, "modulate:a", 0.0, SystemConstants.SCENE_FADE_TIME)
		EventBus.emit("scene_changed", _current_scene.scene_file_path)
		)

	Log.info(self, "Async scene load complete: %s" % scene_path)
	_set_is_loading(false)


func _get_loading_timer_progress() -> float:
	return 1.0 - (_loading_screen_timer.time_left / SystemConstants.SCENE_LOAD_SCREEN_MINIMUM_TIME)


func _set_is_loading(value: float) -> void:
	_is_loading = value
	UIManager.show_throbber(_is_loading)


func _swap_scene(new_scene: Node) -> void:
	if _current_scene:
		_current_scene.queue_free()
	get_tree().root.add_child(new_scene)
	_current_scene = new_scene
	get_tree().current_scene = new_scene


func _setup_fader() -> void:
	_fade_rect.anchor_top = 0.0
	_fade_rect.anchor_left = 0.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.color = SystemConstants.SCENE_FADE_COLOR
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var transition_layer: CanvasLayer = CanvasLayer.new()
	transition_layer.layer = SystemConstants.SCENE_FADE_LAYER
	transition_layer.add_child(_fade_rect)
	add_child(transition_layer)
