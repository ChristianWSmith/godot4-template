## Base class for individual states used with [code]StateMachine[/code].
## Defines the interface for state behavior, including entry, exit, and
## per-frame or per-physics processing.
##
## Each state should be a child node of a [code]StateMachine[/code] and can
## override [code]enter()[/code], [code]exit()[/code], and [code]process()[/code]
## to implement custom behavior.
extends Node
class_name StateMachineState

## Called when the state becomes active. Override to implement setup behavior.
func enter() -> void:
	pass


## Called when the state is being exited. Override to implement cleanup behavior.
func exit() -> void:
	pass


## Called each frame (or physics frame depending on the parent [code]StateMachine[/code]'s
## process type) while the state is active.
##
## The [code]delta[/code] argument is the frame delta time.
##
## Returns the next state to transition to, or [code]self[/code] to remain in the current state.
@warning_ignore("unused_parameter")
func process(delta: float) -> StateMachineState:
	return self
