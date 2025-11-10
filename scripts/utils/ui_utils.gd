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
		elif child is Slider:
			child.drag_started.connect(bound_click)
			child.drag_ended.connect(wrapped_click)
			child.mouse_entered.connect(bound_hover)
		elif child is TabContainer:
			child.tab_selected.connect(wrapped_click)
			child.tab_hovered.connect(wrapped_hover)
		elif child is OptionButton:
			child.toggled.connect(wrapped_click)
			child.mouse_entered.connect(bound_hover)
		elif child is Button:
			child.pressed.connect(bound_click)
			child.mouse_entered.connect(bound_hover)
