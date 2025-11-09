extends Button
class_name BlipButton

func _ready() -> void:
	pressed.connect(AudioManager.play_ui.bind(preload("res://assets/bin/ui/blip.wav")))
