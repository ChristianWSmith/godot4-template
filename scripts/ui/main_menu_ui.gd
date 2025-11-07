extends Control

@onready var play_button: Button =  %PlayButton
@onready var settings_button: Button =  %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	_deferred_ready.call_deferred()
	
func _deferred_ready() -> void:
	settings_button.pressed.connect(UIManager.open_ui.bind("settings_menu"))
	quit_button.pressed.connect(get_tree().quit)
