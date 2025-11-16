extends Control

func _ready() -> void:
	AudioManager.play_global_music(preload("res://assets/bin/music/music.ogg"), 0.0)
	GameState.unload()
	UIManager.open_ui("main_menu")
