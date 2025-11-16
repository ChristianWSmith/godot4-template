extends Area2D
class_name CollisionReceiver2D

@export var _types: Array[Enums.CollisionPayloadType] = []

signal received(type: Enums.CollisionPayloadType, payload: ValueStore)

func _ready() -> void:
	_types.make_read_only()
	area_entered.connect(_on_area_entered)


func _on_area_entered(other: Area2D) -> void:
	if other is CollisionTransmitter2D:
		var type_payloads: Dictionary[Enums.CollisionPayloadType, ValueStore] = \
			other.get_type_payloads()
		for type in _types:
			if type in type_payloads:
				var payload: ValueStore = type_payloads[type]
				received.emit(type, payload)
				other.inform_transmitted(type, payload)
