extends Node
class_name DictUtils

static func flatten(dict: Dictionary, prefix: String = "", separator: String = "/") -> Dictionary:
	var flat: Dictionary = {}
	for key in dict.keys():
		var path = prefix + key if prefix == "" else prefix + separator + key
		var value = dict[key]
		if typeof(value) == TYPE_DICTIONARY and value.size() != 0:
			flat.merge(flatten(value, path, separator))
		else:
			flat[path] = value
	return flat


static func unflatten(flat: Dictionary, separator: String = "/") -> Dictionary:
	var nested: Dictionary = {}
	for path in flat.keys():
		var keys = path.split(separator)
		var node = nested
		for i in range(keys.size() - 1):
			var key = keys[i]
			if not node.has(key):
				node[key] = {}
			node = node[key]
		node[keys[-1]] = flat[path]
	return nested
