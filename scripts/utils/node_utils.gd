extends Node
class_name NodeUtils

static func safe_add_child(node: Node, child: Node) -> void:
	if child not in node.get_children():
		node.add_child(child)


static func safe_remove_child(node: Node, child: Node) -> void:
	if child in node.get_children():
		node.remove_child(child)
