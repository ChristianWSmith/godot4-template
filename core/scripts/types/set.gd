## A custom set implementation for storing unique [code]Variant[/code] items.
## Provides standard set operations such as union, intersection, difference,
## and symmetric difference, as well as iteration support.
##
## Maintains uniqueness of items internally using a [code]Dictionary[/code].
## Supports batch addition and removal of elements, and conversion to an array.
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


## Creates a new set from the given array of items.
## The [code]array[/code] argument is an array of items to include in the set.
## Returns a new [code]Set[/code] instance containing the array's elements.
static func from_array(array: Array) -> Set:
	var s: Set = Set.new()
	s.add_many(array)
	return s


## Returns the number of items currently in the set.
func size() -> int:
	return _items.size()


## Adds a single [code]item[/code] to the set.
## Returns true if the item was added, false if it was already present.
func add(item: Variant) -> bool:
	return _items.set(item, true)


## Adds multiple [code]items[/code] to the set at once.
## Returns true if all items were added successfully.
func add_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return add(item))


## Removes a single [code]item[/code] from the set.
## Returns true if the item was removed, false if it was not present.
func erase(item: Variant) -> bool:
	return _items.erase(item)


## Removes multiple [code]items[/code] from the set at once.
## Returns true if all items were successfully removed.
func erase_many(items: Array[Variant]) -> bool:
	return items.all(func(item: Variant) -> bool:
		return erase(item))


## Checks whether the set contains the specified [code]item[/code].
## Returns true if present, false otherwise.
func has(item: Variant) -> bool:
	return _items.get(item, false)


## Returns true if the set contains no items.
func is_empty() -> bool:
	return self._items.is_empty()


## Returns a new set that is the union of this set and [code]other[/code].
func union(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		out.add(item)
	for item in other:
		out.add(item)
	return out


## Returns a new set that is the intersection of this set and [code]other[/code].
func intersect(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		if other.has(item):
			out.add(item)
	return out


## Checks whether this set intersects with [code]other[/code].
## Returns true if any common items exist.
func intersects(other: Set) -> bool:
	var other_dict = other._items
	for key in _items:
		if other_dict.has(key):
			return true
	return false


## Returns a new set containing items in this set but not in [code]other[/code].
func diff(other: Set) -> Set:
	var out: Set = Set.new()
	for item in self:
		if not other.has(item):
			out.add(item)
	return out


## Returns a new set containing items present in either set but not both.
func sym_diff(other: Set) -> Set:
	return self.union(other).diff(self.intersect(other))


## Returns the set's items as an array.
func as_list() -> Array:
	return _items.keys()
