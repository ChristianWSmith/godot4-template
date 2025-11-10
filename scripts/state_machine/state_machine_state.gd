extends Node
class_name StateMachineState

func enter() -> void:
	pass

func exit() -> void:
	pass

@warning_ignore("unused_parameter")
func process(delta: float) -> StateMachineState:
	return self
