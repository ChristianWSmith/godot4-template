extends Node

signal sfx_played(name: String)
signal sfx_stopped(name: String)

func initialize() -> void:
	pass


func play_sfx(name: String, position: Vector3 = Vector3.ZERO, volume_db: float = 0.0) -> void:
	pass


func stop_sfx(name: String) -> void:
	pass


func set_sfx_volume(volume_db: float) -> void:
	pass
