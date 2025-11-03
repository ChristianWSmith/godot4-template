extends Node

signal music_started(track_name: String)
signal music_stopped(track_name: String)
signal music_faded(track_name: String)

var current_track: String = ""


func initialize() -> void:
	pass


func play_music(track_name: String, fade_time: float = 0.5) -> void:
	pass


func stop_music(fade_time: float = 0.5) -> void:
	pass


func set_music_volume(volume_db: float) -> void:
	pass
