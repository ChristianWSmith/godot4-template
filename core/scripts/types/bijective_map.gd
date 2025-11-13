extends RefCounted
class_name BijectiveMap

var _k2v: Dictionary = {}
var _v2k: Dictionary = {}

func _iter_init(iter: Array) -> bool:
	iter[0] = {
		"keys": _k2v.keys(),
		"index": 0
	}
	return iter[0]["index"] < iter[0]["keys"].size()


func _iter_next(iter: Array) -> bool:
	iter[0]["index"] += 1
	return iter[0]["index"] < iter[0]["keys"].size()


func _iter_get(iter: Variant) -> Variant:
	return iter["keys"][iter["index"]]


static func from_dict(dict: Dictionary) -> BijectiveMap:
	var out: BijectiveMap = BijectiveMap.new()
	for key in dict.keys():
		out.put(key, dict[key])
	return out


func put(key: Variant, value: Variant) -> void:
	if _k2v.has(key) and _k2v[key] == value:
		return

	if _k2v.has(key):
		var old_val = _k2v[key]
		_v2k.erase(old_val)

	if _v2k.has(value):
		var old_key = _v2k[value]
		_k2v.erase(old_key)

	_k2v[key] = value
	_v2k[value] = key


func get_by_key(key: Variant, default: Variant = null) -> Variant:
	return _k2v.get(key, default)


func get_by_value(value: Variant, default: Variant = null) -> Variant:
	return _v2k.get(value, default)


func remove_by_key(key: Variant) -> Variant:
	if not _k2v.has(key):
		return null
	var val = _k2v[key]
	_k2v.erase(key)
	_v2k.erase(val)
	return val


func remove_by_value(value: Variant) -> Variant:
	if not _v2k.has(value):
		return null
	var key = _v2k[value]
	_v2k.erase(value)
	_k2v.erase(key)
	return key


func has_key(key: Variant) -> bool:
	return _k2v.has(key)


func has_value(value: Variant) -> bool:
	return _v2k.has(value)


func size() -> int:
	return _k2v.size()


func is_empty() -> bool:
	return _k2v.size() == 0


func keys() -> Array:
	return _k2v.keys()


func values() -> Array:
	return _v2k.keys()


func clear() -> void:
	_k2v.clear()
	_v2k.clear()


func to_dict() -> Dictionary:
	return _k2v.duplicate(true)
