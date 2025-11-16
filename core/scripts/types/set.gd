extends RefCounted
class_name Set

var _items: Dictionary[Variant, bool] = {}

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


static func from_array(array: Array) -> Set:
	var s: Set = Set.new()
	s.add_many(array)
	return s


func add(item: Variant) -> bool:
	return _items.set(item, true)


func add_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return add(item))


func erase(item: Variant) -> bool:
	return _items.erase(item)


func erase_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return erase(item))


func has(item: Variant) -> bool:
	return _items.get(item, false)


func is_empty() -> bool:
	return self._items.is_empty()


func union(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		out.add(item)
	for item in other:
		out.add(item)
	return out


func intersect(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		if other.has(item):
			out.add(item)
	return out


func intersects(other: Set) -> bool:
	var other_dict = other._items
	for key in _items:
		if other_dict.has(key):
			return true
	return false


func diff(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		if not other.has(item):
			out.add(item)
	return out


func sym_diff(other: Set) -> Set:
	return self.union(other).diff(self.intersect(other))


func as_list() -> Array:
	return _items.keys()
