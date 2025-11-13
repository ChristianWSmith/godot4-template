extends RefCounted
class_name QuantizedRate

var _rate: float = 0.0
var _remainder: float = 0.0

func _init(rate: float = 0.0) -> void:
	_rate = rate


func set_rate(rate: float) -> void:
	_rate = rate


func get_discrete(delta: float) -> int:
	var total: float = delta * _rate + _remainder
	var discrete: int = int(total)
	_remainder = total - float(discrete)
	return discrete
