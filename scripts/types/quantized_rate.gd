extends Node
class_name QuantizedRate

@export var rate: float = 0.0
var _remainder: float = 0.0

func _init(new_rate: float = 0.0) -> void:
	rate = new_rate


func set_rate(new_rate: float) -> void:
	rate = new_rate


func get_discrete(delta: float) -> int:
	var total: float = delta * rate + _remainder
	var discrete: int = int(total)
	_remainder = total - float(discrete)
	return discrete
