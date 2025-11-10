extends Node
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


static func connect_ui_sounds(node: Node):
	var bound_click: Callable = AudioManager.play_ui.bind(preload("res://assets/bin/ui/click.wav"))
	var bound_hover: Callable = AudioManager.play_ui.bind(preload("res://assets/bin/ui/hover.wav"))
	var wrapped_click: Callable = func(_idx: int): AudioManager.play_ui(preload("res://assets/bin/ui/click.wav"))
	var wrapped_hover: Callable = func(_idx: int): AudioManager.play_ui(preload("res://assets/bin/ui/hover.wav"))
	for child in node.get_children():
		connect_ui_sounds(child)
		if child is SpinBox:
			child.value_changed.connect(wrapped_click)
			child.mouse_entered.connect(bound_hover)
			child.set_meta("ui_sound_connections", {
				"value_changed": wrapped_click,
				"mouse_entered": bound_hover
			})
		elif child is Slider:
			child.drag_started.connect(bound_click)
			child.drag_ended.connect(wrapped_click)
			child.mouse_entered.connect(bound_hover)
			child.set_meta("ui_sound_connections", {
				"drag_started": bound_click,
				"drag_ended": wrapped_click,
				"mouse_entered": bound_hover
			})
		elif child is TabContainer:
			child.tab_selected.connect(wrapped_click)
			child.tab_hovered.connect(wrapped_hover)
			child.set_meta("ui_sound_connections", {
				"tab_selected": wrapped_click,
				"tab_hovered": wrapped_hover
			})
		elif child is OptionButton:
			child.toggled.connect(wrapped_click)
			child.mouse_entered.connect(bound_hover)
			child.set_meta("ui_sound_connections", {
				"toggled": wrapped_click,
				"mouse_entered": bound_hover
			})
		elif child is Button:
			child.pressed.connect(bound_click)
			child.mouse_entered.connect(bound_hover)
			child.set_meta("ui_sound_connections", {
				"pressed": bound_click,
				"mouse_entered": bound_hover
			})


static func clear_ui_sounds(node: Node):
	for child in node.get_children():
		clear_ui_sounds(child)
	if node.has_meta("ui_sound_connections"):
		var data: Dictionary = node.get_meta("ui_sound_connections")
		for sig in data.keys():
			if node.is_connected(sig, data[sig]):
				node.disconnect(sig, data[sig])
		node.remove_meta("ui_sound_connections")
