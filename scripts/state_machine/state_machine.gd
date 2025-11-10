extends Node
class_name StateMachine

enum ProcessType { RENDER, PHYSICS }

@export var default_state: StateMachineState
@export var process_type: ProcessType = ProcessType.RENDER

var _states: Dictionary[StateMachineState, bool] = {}
var _current_state: StateMachineState = null

func _ready() -> void:
	for child in get_children():
		_register_node(child)
	match process_type:
		ProcessType.RENDER:
			set_process(true)
			set_physics_process(false)
		ProcessType.PHYSICS:
			set_process(false)
			set_physics_process(true)
		_:
			set_process(false)
			set_physics_process(false)
			Log.error(self, "Unknown process type '%s'" % process_type)
	child_entered_tree.connect(_register_node)
	child_exiting_tree.connect(_deregister_node)
	_transition_state(default_state)


func _process(delta: float) -> void:
	var result: StateMachineState = _current_state.process(delta)
	if result != _current_state:
		_transition_state(result)


func _physics_process(delta: float) -> void:
	var result: StateMachineState = _current_state.process(delta)
	if result != _current_state:
		_transition_state(result)


func _register_node(node: Node) -> void:
	if node is StateMachineState:
		_register_state(node)


func _deregister_node(node: Node) -> void:
	if node is StateMachineState:
		_deregister_state(node)


func _register_state(child: StateMachineState) -> void:
	_states[child] = true


func _deregister_state(child: StateMachineState) -> void:
	if child == _current_state:
		_transition_state(default_state)
	_states.erase(child)


func _transition_state(
		requested_state: StateMachineState,
		state_chain: Array[StateMachineState] = []) -> void:
	if requested_state == null:
		set_process(false)
		set_physics_process(false)
		Log.error(self, "Requested null state, will not process")
		return
	if requested_state in state_chain or \
		requested_state not in _states or \
		 requested_state == _current_state:
		return
	if _current_state:
		_current_state.exit()
	Log.trace(self, "transition '%s' -> '%s'" % [_current_state.name, requested_state.name])
	_current_state = requested_state
	_current_state.enter()
	var result: StateMachineState = _current_state.process(0.0)
	if result != requested_state:
		state_chain.append(result)
		_transition_state(result, state_chain)
