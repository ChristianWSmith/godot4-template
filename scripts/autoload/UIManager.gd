extends BaseManager

var menu_stack: Array[String] = []
var ui_nodes: Dictionary[String, Control] = {}

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	var ui_layer: CanvasLayer = CanvasLayer.new()
	ui_layer.layer = Constants.UI_LAYER_INDEX
	for ui_name in Constants.UI_PRELOADS.keys():
		var ui_instance: Control = Constants.UI_PRELOADS[ui_name].instantiate()
		ui_layer.add_child(ui_instance)
		ui_instance.visible = false
		_deactivate_ui(ui_instance)
		ui_nodes[ui_name] = ui_instance
	add_child(ui_layer)
	return OK


func open_ui(ui_name: String) -> void:
	if not ui_nodes.has(ui_name):
		Log.error(self, "No UI registered with name '%s'" % ui_name)
		return

	Log.debug(self, "Opening UI '%s'" % ui_name)
	
	if menu_stack.size() > 0:
		_deactivate_ui(ui_nodes[menu_stack[-1]])
	
	var ui_node = ui_nodes[ui_name]
	ui_node.visible = true
	_activate_ui(ui_node)
	menu_stack.append(ui_name)
	EventBus.emit(get_ui_open_event(ui_name))


func close_ui() -> void:
	if menu_stack.size() == 0:
		return
	var closing_name = menu_stack.pop_back()
	Log.debug(self, "Closing UI '%s'" % closing_name)
	var closing_node = ui_nodes[closing_name]
	_deactivate_ui(closing_node)
	closing_node.visible = false

	if menu_stack.size() > 0:
		_activate_ui(ui_nodes[menu_stack[-1]])
	EventBus.emit(get_ui_close_event(closing_name))


func close_specific(ui_name: String) -> void:
	if ui_name in menu_stack:
		Log.debug(self, "Closing UI '%s'" % ui_name)
		menu_stack.erase(ui_name)
		var node = ui_nodes[ui_name]
		_deactivate_ui(node)
		node.visible = false
		if menu_stack.size() > 0:
			_activate_ui(ui_nodes[menu_stack[-1]])
		EventBus.emit(get_ui_close_event(ui_name))


func get_ui(ui_name: String) -> Control:
	return ui_nodes.get(ui_name, null)


func get_top_ui() -> Control:
	if menu_stack.size() == 0:
		return null
	return ui_nodes[menu_stack[-1]]


func get_ui_open_event(ui_name: String) -> String:
	if ui_name not in ui_nodes:
		Log.warn(self, "No open event for UI '%s'" % ui_name)
		return ""
	return "ui_open/" + ui_name


func get_ui_close_event(ui_name: String) -> String:
	if ui_name not in ui_nodes:
		Log.warn(self, "No close event for UI '%s'" % ui_name)
		return ""
	return "ui_close/" + ui_name


func _activate_ui(ui_node: Control) -> void:
	ui_node.set_process(true)
	ui_node.set_process_input(true)
	ui_node.set_process_unhandled_input(true)
	ui_node.visibility_layer = menu_stack.size()


func _deactivate_ui(ui_node: Control) -> void:
	ui_node.set_process(false)
	ui_node.set_process_input(false)
	ui_node.set_process_unhandled_input(false)
