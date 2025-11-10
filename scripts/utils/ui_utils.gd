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
	for child in node.get_children():
		if child is not Control:
			continue
		connect_ui_sounds(child)
		if child.has_signal("tab_selected"):
			child.tab_selected.connect(func(_idx: int):
				AudioManager.play_ui(preload("res://assets/bin/ui/click.wav")))
			if child.has_signal("tab_hovered"):
				child.tab_hovered.connect(func(_idx: int):
					AudioManager.play_ui(preload("res://assets/bin/ui/hover.wav")))
		if child.has_signal("pressed"):
			child.pressed.connect(
				AudioManager.play_ui.bind(preload("res://assets/bin/ui/click.wav")))
			if child.has_signal("mouse_entered"):
				child.mouse_entered.connect(
					AudioManager.play_ui.bind(preload("res://assets/bin/ui/hover.wav")))
