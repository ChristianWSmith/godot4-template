extends Node
class_name UIUtils

static func tether_values(node_a: Control, node_b: Control):
	if node_a.has_signal("value_changed") and \
		node_a.has_method("set_value_no_signal") and \
		node_b.has_signal("value_changed") and \
		node_b.has_method("set_value_no_signal"):
		node_a.value_changed.connect(node_b.set_value_no_signal)
		node_b.value_changed.connect(node_a.set_value_no_signal)
		Log.debug(node_a, "Tethered to '%s'" % node_b.name)
	else:
		Log.warn(node_a, "Failed to tether to '%s'" % node_b.name)
