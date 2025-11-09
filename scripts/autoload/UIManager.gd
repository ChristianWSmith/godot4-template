extends BaseManager

var _menu_stack: Array[String] = []
var _ui_nodes: Dictionary[String, Control] = {}
var _ui_root: Control = Control.new()
var _throbber: AnimatedSprite2D = AnimatedSprite2D.new()
var _throbber_tween: Tween = create_tween()
var _throbber_counter: int = 0
var _throbber_showing: bool = false

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_setup_throbber()
	_setup_ui()
	return OK


func open_ui(ui_name: String) -> void:
	if not _ui_nodes.has(ui_name):
		Log.error(self, "No UI registered with name '%s'" % ui_name)
		return

	Log.debug(self, "Opening UI '%s'" % ui_name)
	
	if _menu_stack.size() > 0:
		_deactivate_ui(_ui_nodes[_menu_stack[-1]])
	
	var ui_node = _ui_nodes[ui_name]
	ui_node.visible = true
	_activate_ui(ui_node)
	_menu_stack.append(ui_name)
	EventBus.emit(get_ui_open_event(ui_name))


func close_ui() -> void:
	if _menu_stack.size() == 0:
		return
	var closing_name = _menu_stack.pop_back()
	Log.debug(self, "Closing UI '%s'" % closing_name)
	var closing_node = _ui_nodes[closing_name]
	_deactivate_ui(closing_node)
	closing_node.visible = false

	if _menu_stack.size() > 0:
		_activate_ui(_ui_nodes[_menu_stack[-1]])
	EventBus.emit(get_ui_close_event(closing_name))


func close_specific(ui_name: String) -> void:
	if ui_name in _menu_stack:
		Log.debug(self, "Closing UI '%s'" % ui_name)
		_menu_stack.erase(ui_name)
		var node = _ui_nodes[ui_name]
		_deactivate_ui(node)
		node.visible = false
		if _menu_stack.size() > 0:
			_activate_ui(_ui_nodes[_menu_stack[-1]])
		EventBus.emit(get_ui_close_event(ui_name))


func get_ui(ui_name: String) -> Control:
	return _ui_nodes.get(ui_name, null)


func get_top_ui() -> Control:
	if _menu_stack.size() == 0:
		return null
	return _ui_nodes[_menu_stack[-1]]


func get_ui_open_event(ui_name: String) -> String:
	if ui_name not in _ui_nodes:
		Log.warn(self, "No open event for UI '%s'" % ui_name)
		return ""
	return "ui_open/" + ui_name


func get_ui_close_event(ui_name: String) -> String:
	if ui_name not in _ui_nodes:
		Log.warn(self, "No close event for UI '%s'" % ui_name)
		return ""
	return "ui_close/" + ui_name


func set_ui_scale(value: float) -> void:
	_ui_root.scale = Vector2(value, value)


func show_throbber(show: bool) -> void:
	_throbber_counter = max(0, _throbber_counter + (1 if show else -1))
	if _throbber_counter > 0 and not _throbber_showing:
		_throbber_showing = true
		_throbber.play()
		_throbber_tween.kill()
		_throbber_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_throbber_tween.tween_interval(Constants.SCENE_THROBBER_DELAY)
		_throbber_tween.tween_property(
			_throbber, 
			"modulate:a", 
			1.0, 
			Constants.SCENE_THROBBER_FADE_TIME)
	elif _throbber_counter == 0 and _throbber_showing:
		_throbber_showing = false
		_throbber_tween.kill()
		_throbber_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_throbber_tween.tween_property(
			_throbber, 
			"modulate:a", 
			0.0, 
			min(Constants.SCENE_THROBBER_FADE_TIME, Constants.SCENE_FADE_TIME))
		_throbber_tween.tween_callback(_throbber.stop)


func _activate_ui(ui_node: Control) -> void:
	ui_node.set_process(true)
	ui_node.set_process_input(true)
	ui_node.set_process_unhandled_input(true)
	ui_node.visibility_layer = _menu_stack.size() + 1


func _deactivate_ui(ui_node: Control) -> void:
	ui_node.set_process(false)
	ui_node.set_process_input(false)
	ui_node.set_process_unhandled_input(false)


func _setup_ui() -> void:
	
	var ui_layer: CanvasLayer = CanvasLayer.new()
	ui_layer.layer = Constants.UI_LAYER_INDEX
	
	var ui_scaler: Control = Control.new()
	ui_scaler.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_scaler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_scaler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_ui_root.anchor_left = 0.5
	_ui_root.anchor_top = 0.5
	_ui_root.anchor_right = 0.5
	_ui_root.anchor_bottom = 0.5
	_ui_root.offset_left = -_ui_root.size.x / 2
	_ui_root.offset_top = -_ui_root.size.y / 2
	
	ui_layer.add_child(ui_scaler)
	ui_scaler.add_child(_ui_root)
	
	for ui_name in Constants.UI_PRELOADS.keys():
		var ui_instance: Control = Constants.UI_PRELOADS[ui_name].instantiate()
		_ui_root.add_child(ui_instance)
		ui_instance.visible = false
		_deactivate_ui(ui_instance)
		_ui_nodes[ui_name] = ui_instance
	add_child(ui_layer)


func _setup_throbber() -> void:
	_throbber.sprite_frames = preload("res://assets/src/ui/throbber.tres")
	var throbber_size: Vector2 = _throbber.sprite_frames.get_frame_texture(
		_throbber.animation, _throbber.frame).get_size()
	_throbber.scale = Vector2(
		Constants.SCENE_THROBBER_SIZE_PX.x / throbber_size.x, 
		Constants.SCENE_THROBBER_SIZE_PX.y / throbber_size.y)
		
	match Constants.SCENE_THROBBER_ANCHOR:
		Control.PRESET_BOTTOM_LEFT: 
			_throbber.position = Vector2(
				Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 + Constants.SCENE_THROBBER_OFFSET.x,
				- Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 - Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_BOTTOM_RIGHT: 
			_throbber.position = Vector2(
				- Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 - Constants.SCENE_THROBBER_OFFSET.x,
				- Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 - Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_TOP_LEFT: 
			_throbber.position = Vector2(
				Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 + Constants.SCENE_THROBBER_OFFSET.x,
				Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 + Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_TOP_RIGHT: 
			_throbber.position = Vector2(
				- Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 - Constants.SCENE_THROBBER_OFFSET.x,
				Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 + Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_CENTER_TOP: 
			_throbber.position = Vector2(
				0.0,
				Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 + Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_CENTER_LEFT: 
			_throbber.position = Vector2(
				Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 + Constants.SCENE_THROBBER_OFFSET.x,
				0.0)
		Control.PRESET_CENTER_RIGHT: 
			_throbber.position = Vector2(
				- Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 - Constants.SCENE_THROBBER_OFFSET.x,
				0.0)
		Control.PRESET_CENTER_BOTTOM: 
			_throbber.position = Vector2(
				0.0,
				- Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 - Constants.SCENE_THROBBER_OFFSET.y)
		Control.PRESET_CENTER: 
			_throbber.position = Vector2(
				Constants.SCENE_THROBBER_SIZE_PX.x / 2.0 + Constants.SCENE_THROBBER_OFFSET.x,
				Constants.SCENE_THROBBER_SIZE_PX.y / 2.0 + Constants.SCENE_THROBBER_OFFSET.y)
		_: _throbber.position = Vector2.ZERO
	
	_throbber.modulate.a = 0.0
	var throbber_container := Control.new()
	throbber_container.set_anchors_preset(Constants.SCENE_THROBBER_ANCHOR)
	throbber_container.add_child(_throbber)
	
	var throbber_layer: CanvasLayer = CanvasLayer.new()
	throbber_layer.layer = RenderingServer.CANVAS_LAYER_MAX - 1
	throbber_layer.add_child(throbber_container)
	add_child(throbber_layer)
