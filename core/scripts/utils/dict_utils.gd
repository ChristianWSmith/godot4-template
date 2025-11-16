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


static func diff(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	var result := {}
	for key in dict1.keys():
		if not dict2.has(key):
			result[key] = true
		else:
			var val1 = dict1[key]
			var val2 = dict2[key]
			if typeof(val1) == TYPE_DICTIONARY and typeof(val2) == TYPE_DICTIONARY:
				var sub_diff = diff(val1, val2)
				if sub_diff.size() > 0:
					result[key] = sub_diff
			elif val1 != val2:
				result[key] = true
	for key in dict2.keys():
		if not dict1.has(key):
			result[key] = true
	return result
