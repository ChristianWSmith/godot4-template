extends Control

@onready var play_button: Button =  %PlayButton
@onready var settings_button: Button =  %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	play_button.pressed.connect(_play)
	settings_button.pressed.connect(UIManager.open_ui.bind("settings_menu"))
	quit_button.pressed.connect(get_tree().quit)


func _play() -> void:
	if "test" not in SaveManager.list_slots():
		SaveManager.new_slot("test")
	GameState.load_from_slot("test")
	UIManager.close_ui()
