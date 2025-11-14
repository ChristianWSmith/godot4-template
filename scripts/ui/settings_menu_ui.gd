extends Control

@onready var close_button: Button = %CloseButton
@onready var default_button: Button = %DefaultButton
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
@onready var video_resolution_label: Label = %VideoResolutionLabel
@onready var video_resolution_option_button: OptionButton = %VideoResolutionOptionButton
@onready var video_vsync_check_button: CheckButton = %VideoVsyncCheckButton
@onready var video_max_fps_option_button: OptionButton = %VideoMaxFPSOptionButton

@onready var input_some_action_key_button: InputCaptorButton = %InputSomeActionKeyboardButton
@onready var input_some_action_joypad_button: InputCaptorButton = %InputSomeActionJoypadButton
@onready var input_back_key_button: InputCaptorButton = %InputBackKeyboardButton
@onready var input_back_joypad_button: InputCaptorButton = %InputBackJoypadButton

@onready var graphics_ui_scale_slider: Slider = %GraphicsUIScaleSlider
@onready var graphics_ui_scale_spinbox: SpinBox = %GraphicsUIScaleSpinbox

@onready var gameplay_autosave_check_button: CheckButton = %GameplayAutosaveCheckButton

var resolution_bimap: BijectiveMap = BijectiveMap.from_array(
	SystemConstants.VIDEO_SUPPORTED_RESOLUTIONS)

func _ready() -> void:
	_make_connections()
	_setup_resolutions()


func _on_visibility_changed() -> void:
	if not visible:
		InputManager.unsubscribe_pressed("back", _on_close_pressed)
		return
	InputManager.subscribe_pressed("back", _on_close_pressed)
	SettingsManager.checkpoint()
	_load_values()


func _on_close_pressed() -> void:
	SettingsManager.reinstate_checkpoint()
	UIManager.close_ui()


func _on_default_pressed() -> void:
	SettingsManager.reset_to_default()
	_load_values()


func _on_apply_pressed() -> void:
	SettingsManager.save()
	UIManager.close_ui()


func _make_connections() -> void:
	_make_ui_connections()
	_make_settings_connections()


func _make_ui_connections() -> void:
	visibility_changed.connect(_on_visibility_changed)
	close_button.pressed.connect(_on_close_pressed)
	default_button.pressed.connect(_on_default_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	UIUtils.tether_values(audio_master_slider, audio_master_spinbox)
	UIUtils.tether_values(audio_music_slider, audio_music_spinbox)
	UIUtils.tether_values(audio_sfx_slider, audio_sfx_spinbox)
	UIUtils.tether_values(audio_ui_slider, audio_ui_spinbox)
	UIUtils.tether_values(audio_voice_slider, audio_voice_spinbox)
	UIUtils.tether_values(graphics_ui_scale_slider, graphics_ui_scale_spinbox)
	video_window_mode_option_button.item_selected.connect(func(idx: int):
		match idx:
			0: # Windowed
				video_resolution_option_button.disabled = false
				video_resolution_label.visible = true
				video_resolution_option_button.visible = true
			1: # Borderless
				video_resolution_option_button.disabled = true
				video_resolution_label.visible = false
				video_resolution_option_button.visible = false
			2: # Fullscreen
				video_resolution_option_button.disabled = true
				video_resolution_label.visible = false
				video_resolution_option_button.visible = false
			_: # Default to windowed
				video_resolution_option_button.disabled = true
				video_resolution_label.visible = false
				video_resolution_option_button.visible = false
		)


func _make_settings_connections() -> void:
	# Audio
	audio_master_slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value("audio", "master", 
			value / audio_master_slider.max_value))
	audio_music_slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value("audio", "music", 
			value / audio_music_slider.max_value))
	audio_sfx_slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value("audio", "sfx", 
			value / audio_sfx_slider.max_value))
	audio_ui_slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value("audio", "ui", 
			value / audio_ui_slider.max_value))
	audio_voice_slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value("audio", "voice", 
			value / audio_voice_slider.max_value))
	
	# Video
	video_vsync_check_button.pressed.connect(func() -> void:
		SettingsManager.set_value("video", "vsync", 
			video_vsync_check_button.button_pressed))
	video_window_mode_option_button.item_selected.connect(func(idx: int) -> void:
		match idx:
			1: # Borderless
				SettingsManager.set_value("video", "window_mode", SystemConstants.WindowMode.BORDERLESS)
			2: # Fullscreen
				SettingsManager.set_value("video", "window_mode", SystemConstants.WindowMode.FULLSCREEN)
			_: # Windowed
				SettingsManager.set_value("video", "window_mode", SystemConstants.WindowMode.WINDOWED)
		)
	video_max_fps_option_button.item_selected.connect(func(idx: int) -> void:
		match idx:
			0: SettingsManager.set_value("video", "max_fps", 30)
			1: SettingsManager.set_value("video", "max_fps", 60)
			2: SettingsManager.set_value("video", "max_fps", 120)
			3: SettingsManager.set_value("video", "max_fps", 240)
			_: SettingsManager.set_value("video", "max_fps", 0)
		)
	video_resolution_option_button.item_selected.connect(func(idx: int) -> void:		
		SettingsManager.set_value(
			"video", 
			"resolution", 
			resolution_bimap.get_by_key(idx, Vector2i(1280, 720)))
		)
	
	# Graphics
	graphics_ui_scale_slider.drag_ended.connect(func(value_changed: bool) -> void:
		if value_changed:
			SettingsManager.set_value("graphics", "ui_scale",
				graphics_ui_scale_slider.value)
		)
	
	# Gameplay
	gameplay_autosave_check_button.pressed.connect(func() -> void:
		SettingsManager.set_value("gameplay", "autosave",
			gameplay_autosave_check_button.button_pressed)
		)
	
	# Input
	input_back_joypad_button.binding_updated.connect(_set_bindings)
	input_back_key_button.binding_updated.connect(_set_bindings)
	input_some_action_joypad_button.binding_updated.connect(_set_bindings)
	input_some_action_key_button.binding_updated.connect(_set_bindings)


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
	
	video_resolution_option_button.select(
		resolution_bimap.get_by_value(
			SettingsManager.get_value("video", "resolution"), 0
		)
	)
	
	match SettingsManager.get_value("video", "window_mode"):
		SystemConstants.WindowMode.BORDERLESS:
			video_window_mode_option_button.select(1) # Borderless
			video_window_mode_option_button.item_selected.emit(1)
		SystemConstants.WindowMode.FULLSCREEN:
			video_window_mode_option_button.select(2) # Fullscreen
			video_window_mode_option_button.item_selected.emit(2)
		_:
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

	var bindings: Dictionary = SettingsManager.get_value("input", "bindings")
	_load_binding(bindings.get("some_action", []), input_some_action_key_button, input_some_action_joypad_button)
	_load_binding(bindings.get("back", []), input_back_key_button, input_back_joypad_button)
	
	graphics_ui_scale_slider.value = SettingsManager.get_value("graphics", "ui_scale")

	gameplay_autosave_check_button.button_pressed = SettingsManager.get_value("gameplay", "autosave")


func _load_binding(
		bindings: Array, 
		key_button: InputCaptorButton, 
		joypad_button: InputCaptorButton) -> void:
	for binding: Dictionary in bindings:
		match binding.get("type", ""):
			"Key": key_button.set_binding(binding)
			"JoypadButton": joypad_button.set_binding(binding)
			_: Log.warn(self, "Bind type not used in this demo: '%s'" % binding.get("type", ""))


func _set_bindings() -> void:
	var bindings: Dictionary = {}
	bindings["some_action"] = [
		input_some_action_key_button.get_binding(),
		input_some_action_joypad_button.get_binding(),
	]
	bindings["back"] = [
		input_back_key_button.get_binding(),
		input_back_joypad_button.get_binding(),
	]
	SettingsManager.set_value("input", "bindings", bindings)


func _setup_resolutions() -> void:
	for res_idx in resolution_bimap:
		video_resolution_option_button.add_item(
			"%sx%s" % [
				resolution_bimap.get_by_key(res_idx).x, 
				resolution_bimap.get_by_key(res_idx).y],
			res_idx)
