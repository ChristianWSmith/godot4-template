extends Node
class_name Set

var _type_constraint: Variant.Type
var _items: Dictionary[Variant, bool] = {}

func _init(type_constraint: Variant.Type) -> void:
	_type_constraint = type_constraint
	name = "Set[%s]" % type_string(_type_constraint)


func _iter_init(iter: Array) -> bool:
	iter[0] = {
		"keys": _items.keys(),
		"index": 0
	}
	return iter[0]["index"] < iter[0]["keys"].size()


func _iter_next(iter: Array) -> bool:
	iter[0]["index"] += 1
	return iter[0]["index"] < iter[0]["keys"].size()


func _iter_get(iter: Variant) -> Variant:
	return iter["keys"][iter["index"]]


func add(item: Variant) -> bool:
	if typeof(item) == _type_constraint:
		_items.set(item, true)
		return true
	Log.error(self, "Failed to add item to set '%s'" % item)
	return false


func add_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return self.add(item))


func erase(item: Variant) -> bool:
	return _items.erase(item)


func erase_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return self.erase(item))


func has(item: Variant) -> bool:
	return _items.get(item, false)


func is_empty() -> bool:
	return self._items.is_empty()


func union(other: Set) -> Set:
	var out: Set = Set.new(_type_constraint)
	if _type_constraint != other._type_constraint:
		Log.error(self, "Failed to union with set '%s'" % other.name)
		return out
	for item in self:
		out.add(item)
	for item in other:
		out.add(item)
	return out


func intersect(other: Set) -> Set:
	var out: Set = Set.new(_type_constraint)
	if _type_constraint != other._type_constraint:
		Log.error(self, "Failed to intersect with set '%s'" % other.name)
		return out
	for item in self:
		if other.has(item):
			out.add(item)
	return out


func diff(other: Set) -> Set:
	var out: Set = Set.new(_type_constraint)
	if _type_constraint != other._type_constraint:
		Log.error(self, "Failed to diff with set '%s'" % other.name)
		return out
	for item in self:
		if not other.has(item):
			out.add(item)
	return out


func sym_diff(other: Set) -> Set:
	return self.union(other).diff(self.intersect(other))


func as_list() -> Array:
	var out: Array = []
	for item in self:
		out.append(item)
	return out
