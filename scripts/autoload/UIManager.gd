extends BaseManager

var _menu_stack: Array[String] = []
var _ui_nodes: Dictionary[String, Control] = {}
var _ui_root: Control = Control.new()

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
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


func _activate_ui(ui_node: Control) -> void:
	ui_node.set_process(true)
	ui_node.set_process_input(true)
	ui_node.set_process_unhandled_input(true)
	ui_node.visibility_layer = _menu_stack.size() + 1


func _deactivate_ui(ui_node: Control) -> void:
	ui_node.set_process(false)
	ui_node.set_process_input(false)
	ui_node.set_process_unhandled_input(false)
