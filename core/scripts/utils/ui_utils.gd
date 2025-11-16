class_name UIUtils

static func tether_values(node_a: Control, node_b: Control):
	if node_a.has_signal("value_changed") and \
		node_a.has_method("set_value_no_signal") and \
		node_b.has_signal("value_changed") and \
		node_b.has_method("set_value_no_signal"):
		node_a.value_changed.connect(node_b.set_value_no_signal)
		node_b.value_changed.connect(node_a.set_value_no_signal)
		Log.trace(node_a, "Tethered to '%s'" % node_b.name)
	else:
		Log.warn(node_a, "Failed to tether to '%s'" % node_b.name)


static func connect_ui_sounds(
		node: Node, 
		deep: bool = true,
		hover_stream: AudioStream = SystemConstants.UI_HOVER_STREAM,
		click_stream: AudioStream = SystemConstants.UI_CLICK_STREAM):
	var bound_click: Callable = AudioManager.play_global_ui.bind(click_stream)
	var bound_hover: Callable = AudioManager.play_global_ui.bind(hover_stream)
	var wrapped_click: Callable = func(_idx: int): AudioManager.play_global_ui(click_stream)
	var wrapped_hover: Callable = func(_idx: int): AudioManager.play_global_ui(hover_stream)
	if deep:
		for child in node.get_children():
			connect_ui_sounds(child, deep, hover_stream, click_stream)
	if node is SpinBox:
		node.value_changed.connect(wrapped_click)
		node.mouse_entered.connect(bound_hover)
		node.set_meta("ui_sound_connections", {
			"value_changed": wrapped_click,
			"mouse_entered": bound_hover
		})
	elif node is Slider:
		node.drag_started.connect(bound_click)
		node.drag_ended.connect(wrapped_click)
		node.mouse_entered.connect(bound_hover)
		node.set_meta("ui_sound_connections", {
			"drag_started": bound_click,
			"drag_ended": wrapped_click,
			"mouse_entered": bound_hover
		})
	elif node is ScrollBar:
		node.mouse_entered.connect(bound_hover)
		node.set_meta("ui_sound_connections", {
			"mouse_entered": bound_hover
		})
	elif node is TextEdit:
		node.mouse_entered.connect(bound_hover)
		node.set_meta("ui_sound_connections", {
			"mouse_entered": bound_hover
		})
	elif node is LineEdit:
		node.mouse_entered.connect(bound_hover)
		node.set_meta("ui_sound_connections", {
			"mouse_entered": bound_hover
		})
	elif node is TabContainer:
		node.tab_selected.connect(wrapped_click)
		node.tab_hovered.connect(wrapped_hover)
		node.set_meta("ui_sound_connections", {
			"tab_selected": wrapped_click,
			"tab_hovered": wrapped_hover
		})
	elif node is BaseButton:
		if node is OptionButton:
			node.toggled.connect(wrapped_click)
			node.mouse_entered.connect(bound_hover)
			node.set_meta("ui_sound_connections", {
				"toggled": wrapped_click,
				"mouse_entered": bound_hover
			})
		else: # other Button type
			node.pressed.connect(bound_click)
			node.mouse_entered.connect(bound_hover)
			node.set_meta("ui_sound_connections", {
				"pressed": bound_click,
				"mouse_entered": bound_hover
			})


static func clear_ui_sounds(node: Node, deep: bool = true):
	if deep:
		for child in node.get_children():
			clear_ui_sounds(child, true)
	if not node.has_meta("ui_sound_connections"):
		return
	var data: Dictionary = node.get_meta("ui_sound_connections")
	for sig in data.keys():
		if node.is_connected(sig, data[sig]):
			node.disconnect(sig, data[sig])
	node.remove_meta("ui_sound_connections")
