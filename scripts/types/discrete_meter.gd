extends Node
class_name DiscreteMeter

@export var rate: float = 0.0

var _remainder: float = 0.0

func _init(new_rate: float) -> void:
	rate = new_rate

func set_rate(new_rate: float) -> void:
	rate = new_rate


func get_discrete(delta: float) -> int:
	var target: float = delta * rate
	var target_int: int = int(target)
	_remainder += target - float(target_int)
	var out: int = target_int + int(_remainder)
	if _remainder >= 1.0:
		_remainder -= float(int(_remainder))
	return out
