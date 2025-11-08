extends Control

@onready var close_button: Button = %CloseButton
@onready var apply_button: Button = %ApplyButton

@onready var audio_master_slider: Slider = %AudioMasterSlider
@onready var audio_master_spinbox: SpinBox = %AudioMasterSpinbox
@onready var audio_music_slider: Slider = %AudioMusicSlider
@onready var audio_music_spinbox: SpinBox = %AudioMusicSpinbox
@onready var audio_sfx_slider: Slider = %AudioSFXSlider
@onready var audio_sfx_spinbox: SpinBox = %AudioSFXSpinbox
@onready var audio_voice_slider: Slider = %AudioVoiceSlider
@onready var audio_voice_spinbox: SpinBox = %AudioVoiceSpinbox
@onready var audio_ui_slider: Slider = %AudioUISlider
@onready var audio_ui_spinbox: SpinBox = %AudioUISpinbox

@onready var video_window_mode_option_button: OptionButton = %VideoWindowModeOptionButton
@onready var video_resolution_option_button: OptionButton = %VideoResolutionOptionButton
@onready var video_vsync_check_button: CheckButton = %VideoVsyncCheckButton
@onready var video_max_fps_option_button: OptionButton = %VideoMaxFPSOptionButton

func _ready() -> void:
	_make_connections()
	visibility_changed.connect(_load_values)


func _load_values() -> void:
	audio_master_slider.value = SettingsManager.get_value("audio", "master") * \
		audio_master_slider.max_value
	audio_music_slider.value = SettingsManager.get_value("audio", "music") * \
		audio_music_slider.max_value
	audio_sfx_slider.value = SettingsManager.get_value("audio", "sfx") * \
		audio_sfx_slider.max_value
	audio_voice_slider.value = SettingsManager.get_value("audio", "voice") * \
		audio_voice_slider.max_value
	audio_ui_slider.value = SettingsManager.get_value("audio", "ui") * \
		audio_ui_slider.max_value


func _make_connections() -> void:
	close_button.pressed.connect(UIManager.close_ui)
	apply_button.pressed.connect(_on_apply_pressed)
	UIUtils.tether_values(audio_master_slider, audio_master_spinbox)
	UIUtils.tether_values(audio_music_slider, audio_music_spinbox)
	UIUtils.tether_values(audio_sfx_slider, audio_sfx_spinbox)
	UIUtils.tether_values(audio_ui_slider, audio_ui_spinbox)
	UIUtils.tether_values(audio_voice_slider, audio_voice_spinbox)


func _on_apply_pressed() -> void:
	var audio_keys: Array[String] = ["master", "music", "sfx", "voice", "ui"]
	var audio_values: Array = [
		audio_master_slider.value / audio_master_slider.max_value,
		audio_music_slider.value / audio_music_slider.max_value,
		audio_sfx_slider.value / audio_sfx_slider.max_value,
		audio_voice_slider.value / audio_voice_slider.max_value,
		audio_ui_slider.value / audio_ui_slider.max_value,
	]
	SettingsManager.set_values("audio", audio_keys, audio_values, false)
	SettingsManager.save()
