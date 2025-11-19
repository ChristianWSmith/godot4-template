## Implements a one-to-one mapping between keys and values, allowing
## lookups in both directions. Ensures that each key maps to a unique value
## and each value maps to a unique key.
##
## Supports insertion, removal, and query operations, as well as
## conversion to/from arrays and dictionaries.
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


## Creates a new bijective map from the given dictionary.
## Each key-value pair in [code]dict[/code] is added to the map.
static func from_dict(dict: Dictionary) -> BijectiveMap:
	var out: BijectiveMap = BijectiveMap.new()
	for key in dict.keys():
		out.put(key, dict[key])
	return out


## Creates a new bijective map from the given array.
## Array indices are used as keys, and array elements as values.
static func from_array(arr: Array) -> BijectiveMap:
	var out: BijectiveMap = BijectiveMap.new()
	for idx in range(arr.size()):
		out.put(idx, arr[idx])
	return out


## Adds or updates the mapping from [code]key[/code] to [code]value[/code].
## Maintains uniqueness of keys and values.
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


## Retrieves the value corresponding to [code]key[/code].
## Returns [code]default[/code] if the key does not exist.
func get_by_key(key: Variant, default: Variant = null) -> Variant:
	return _k2v.get(key, default)


## Retrieves the key corresponding to [code]value[/code].
## Returns [code]default[/code] if the value does not exist.
func get_by_value(value: Variant, default: Variant = null) -> Variant:
	return _v2k.get(value, default)


## Removes the mapping associated with [code]key[/code].
## Returns the value that was mapped, or null if the key was not present.
func remove_by_key(key: Variant) -> Variant:
	if not _k2v.has(key):
		return null
	var val = _k2v[key]
	_k2v.erase(key)
	_v2k.erase(val)
	return val


## Removes the mapping associated with [code]value[/code].
## Returns the key that was mapped, or null if the value was not present.
func remove_by_value(value: Variant) -> Variant:
	if not _v2k.has(value):
		return null
	var key = _v2k[value]
	_v2k.erase(value)
	_k2v.erase(key)
	return key


## Returns true if the map contains [code]key[/code].
func has_key(key: Variant) -> bool:
	return _k2v.has(key)


## Returns true if the map contains [code]value[/code].
func has_value(value: Variant) -> bool:
	return _v2k.has(value)


## Returns the number of key-value pairs in the map.
func size() -> int:
	return _k2v.size()


## Returns true if the map is empty.
func is_empty() -> bool:
	return _k2v.size() == 0


## Returns an array of all keys in the map.
func keys() -> Array:
	return _k2v.keys()


## Returns an array of all values in the map.
func values() -> Array:
	return _v2k.keys()


## Removes all key-value mappings from the map.
func clear() -> void:
	_k2v.clear()
	_v2k.clear()


## Returns a duplicate of the map as a standard [code]Dictionary[/code].
func to_dict() -> Dictionary:
	return _k2v.duplicate(true)
