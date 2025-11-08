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

@onready var graphics_placeholder_check_button: CheckButton = %GrapicsPlaceholderCheckButton

@onready var gameplay_placeholder_check_button: CheckButton = %GameplayPlaceholderCheckButton

func _ready() -> void:
	_make_connections()
	visibility_changed.connect(_load_values)


func _make_connections() -> void:
	close_button.pressed.connect(UIManager.close_ui)
	apply_button.pressed.connect(_on_apply_pressed)
	UIUtils.tether_values(audio_master_slider, audio_master_spinbox)
	UIUtils.tether_values(audio_music_slider, audio_music_spinbox)
	UIUtils.tether_values(audio_sfx_slider, audio_sfx_spinbox)
	UIUtils.tether_values(audio_ui_slider, audio_ui_spinbox)
	UIUtils.tether_values(audio_voice_slider, audio_voice_spinbox)
	video_window_mode_option_button.item_selected.connect(func(idx: int):
		match idx:
			0: 
				video_resolution_option_button.disabled = false
				_load_video_resolution()
			1: 
				video_resolution_option_button.disabled = true
				video_resolution_option_button.select(-1)
			2: 
				video_resolution_option_button.disabled = true
				video_resolution_option_button.select(-1)
			_: 
				video_resolution_option_button.disabled = true
				video_resolution_option_button.select(-1)
		)


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
	
	_load_video_resolution()
	
	if SettingsManager.get_value("video", "fullscreen"):
		video_window_mode_option_button.select(2) # Fullscreen
		video_window_mode_option_button.item_selected.emit(2)
	elif SettingsManager.get_value("video", "borderless"):
		video_window_mode_option_button.select(1) # Borderless
		video_window_mode_option_button.item_selected.emit(1)
	else:
		video_window_mode_option_button.select(0) # Windowed
		video_window_mode_option_button.item_selected.emit(0)
	
	match SettingsManager.get_value("video", "max_fps"):
		30: video_max_fps_option_button.select(0)
		60: video_max_fps_option_button.select(1)
		120: video_max_fps_option_button.select(2)
		240: video_max_fps_option_button.select(3)
		0: video_max_fps_option_button.select(4)
		_: video_max_fps_option_button.select(4)
	
	video_vsync_check_button.button_pressed = SettingsManager.get_value("video", "vsync")

	graphics_placeholder_check_button.button_pressed = SettingsManager.get_value("graphics", "placeholder")
	
	gameplay_placeholder_check_button.button_pressed = SettingsManager.get_value("gameplay", "placeholder")


func _load_video_resolution() -> void:
	match SettingsManager.get_value("video", "resolution"):
		Vector2i(1280, 720): video_resolution_option_button.select(0)
		Vector2i(1280, 800): video_resolution_option_button.select(1)
		Vector2i(1280, 1024): video_resolution_option_button.select(2)
		Vector2i(1360, 768): video_resolution_option_button.select(3)
		Vector2i(1366, 768): video_resolution_option_button.select(4)
		Vector2i(1440, 900): video_resolution_option_button.select(5)
		Vector2i(1600, 900): video_resolution_option_button.select(6)
		Vector2i(1600, 1200): video_resolution_option_button.select(7)
		Vector2i(1680, 1050): video_resolution_option_button.select(8)
		Vector2i(1920, 1080): video_resolution_option_button.select(9)
		Vector2i(1920, 1200): video_resolution_option_button.select(10)
		Vector2i(2560, 1080): video_resolution_option_button.select(11)
		Vector2i(2560, 1440): video_resolution_option_button.select(12)
		Vector2i(2560, 1600): video_resolution_option_button.select(13)
		Vector2i(3440, 1440): video_resolution_option_button.select(14)
		Vector2i(3840, 2180): video_resolution_option_button.select(15)
		_: video_resolution_option_button.select(0)


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
	
	var video_keys: Array[String] = []
	var video_values: Array = []
	
	video_keys.append("vsync")
	video_values.append(video_vsync_check_button.button_pressed)
	
	video_keys.append("borderless")
	video_keys.append("fullscreen")
	match video_window_mode_option_button.selected:
		0: # Windowed
			video_values.append(false)
			video_values.append(false)
		1: # Borderless
			video_values.append(true)
			video_values.append(true)
		2: # Fullscreen
			video_values.append(false)
			video_values.append(true)
		_: # Default
			video_values.append(false)
			video_values.append(false)
	
	video_keys.append("max_fps")
	match video_max_fps_option_button.selected:
		0: video_values.append(30)
		1: video_values.append(60)
		2: video_values.append(120)
		3: video_values.append(240)
		4: video_values.append(0)
		_: video_values.append(0)
	
	if not video_resolution_option_button.disabled:
		video_keys.append("resolution")
		match video_resolution_option_button.selected:
			0: video_values.append(Vector2i(1280, 720))
			1: video_values.append(Vector2i(1280, 800))
			2: video_values.append(Vector2i(1280, 1024))
			3: video_values.append(Vector2i(1360, 768))
			4: video_values.append(Vector2i(1366, 768))
			5: video_values.append(Vector2i(1440, 900))
			6: video_values.append(Vector2i(1600, 900))
			7: video_values.append(Vector2i(1600, 1200))
			8: video_values.append(Vector2i(1680, 1050))
			9: video_values.append(Vector2i(1920, 1080))
			10: video_values.append(Vector2i(1920, 1200))
			11: video_values.append(Vector2i(2560, 1080))
			12: video_values.append(Vector2i(2560, 1440))
			13: video_values.append(Vector2i(2560, 1600))
			14: video_values.append(Vector2i(3440, 1440))
			15: video_values.append(Vector2i(3840, 2180))
			_: video_values.append(Vector2i(1280, 720))
	
	SettingsManager.set_values("video", video_keys, video_values, false)

	SettingsManager.set_value("graphics", "placeholder", 
		graphics_placeholder_check_button.button_pressed, false)
	SettingsManager.set_value("gameplay", "placeholder", 
		gameplay_placeholder_check_button.button_pressed, false)
	
	SettingsManager.save()
