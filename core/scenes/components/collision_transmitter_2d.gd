extends Area2D
class_name CollisionTransmitter2D

@export var _type_payloads: Dictionary[Enums.CollisionPayloadType, ValueStore]

signal transmitted(type: Enums.CollisionPayloadType, payload: ValueStore)

func _ready() -> void:
	_type_payloads.make_read_only()


func get_type_payloads() -> Dictionary[Enums.CollisionPayloadType, ValueStore]:
	return _type_payloads


func inform_transmitted(type: Enums.CollisionPayloadType, payload: ValueStore):
	transmitted.emit(type, payload)
