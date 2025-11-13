extends Node
class_name SignalUtils

static func safe_connect(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


static func safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


static func full_disconnect_node(node: Node) -> void:
	for sig in node.get_signal_list():
		for connection in node.get_signal_connection_list(sig["name"]):
			connection["signal"].disconnect(connection["callable"])


static func full_disconnect_signal(sig: Signal) -> void:
	for connection in sig.get_connections():
		sig.disconnect(connection["callable"])
