## Utility class for converting continuous rates into discrete steps while
## accumulating fractional remainders. Useful for systems that need
## integer outputs at variable update rates.
##
## Tracks the remainder between updates to ensure accurate quantization over time.
extends RefCounted
class_name QuantizedRate

var _rate: float = 0.0
var _remainder: float = 0.0

func _init(rate: float = 0.0) -> void:
	_rate = rate


## Sets the continuous rate used for quantization.
## The [code]rate[/code] argument specifies how many discrete steps accumulate per unit time.
func set_rate(rate: float) -> void:
	_rate = rate


## Computes the discrete number of steps for a given delta time.
## The [code]delta[/code] argument is the time elapsed since the last update.
## Returns the number of discrete steps that occurred during this interval.
func get_discrete(delta: float) -> int:
	var total: float = delta * _rate + _remainder
	var discrete: int = int(total)
	_remainder = total - float(discrete)
	return discrete
