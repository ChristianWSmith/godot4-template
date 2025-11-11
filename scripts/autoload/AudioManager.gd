extends BaseManager

var music_player: AudioStreamPlayer

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	EventBus.subscribe(
		SettingsManager.get_event("audio", "master"),
		_on_master_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("audio", "music"),
		_on_music_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("audio", "sfx"),
		_on_sfx_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("audio", "ui"),
		_on_ui_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("audio", "voice"),
		_on_voice_updated
	)
	return OK


func play_music(
		stream: AudioStream, 
		fade_time: float = SystemConstants.AUDIO_MUSIC_FADE_TIME,
		restart: bool = false) -> void:
	if music_player and music_player.stream == stream and not restart:
		return
	var old_player: AudioStreamPlayer = music_player
	
	music_player = AudioStreamPlayer.new()
	music_player.stream = stream
	music_player.bus = "Music"
	music_player.volume_db = SystemConstants.AUDIO_SILENCE_DB
	add_child(music_player)
	create_tween().tween_property(music_player, "volume_db", 0.0, fade_time)
	music_player.play()
	Log.info(self, "Playing music: %s" % music_player.stream.resource_path)
	
	_fade_out_music(old_player, fade_time)


func stop_music(fade_time: float = SystemConstants.AUDIO_MUSIC_FADE_TIME) -> void:
	var old_player: AudioStreamPlayer = music_player
	music_player = null
	_fade_out_music(old_player, fade_time)


func play_sfx(stream: AudioStream) -> void:
	_play_sound(stream, "SFX")


func play_voice(stream: AudioStream) -> void:
	_play_sound(stream, "Voice")


func play_ui(stream: AudioStream) -> void:
	_play_sound(stream, "UI")


func _play_sound(stream: AudioStream, bus: String) -> void:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
	Log.trace(self, "Playing sound on bus: %s %s" % [bus, stream.resource_path])


func _fade_out_music(player: AudioStreamPlayer, fade_time: float) -> void:
	if player == null or not is_instance_valid(player):
		Log.debug(self, "No music to fade out")
		return
	var fade_out: Tween = create_tween()
	fade_out.tween_property(player, "volume_db", SystemConstants.AUDIO_SILENCE_DB, fade_time)
	fade_out.tween_callback(func():
		if is_instance_valid(player):
			remove_child(player)
			player.queue_free()
	)
	Log.trace(self, "Fading out music: %s" % player.stream.resource_path)


func _on_master_updated(value: float) -> void:
	_set_bus_volume("Master", value)


func _on_music_updated(value: float) -> void:
	_set_bus_volume("Music", value)


func _on_sfx_updated(value: float) -> void:
	_set_bus_volume("SFX", value)


func _on_ui_updated(value: float) -> void:
	_set_bus_volume("UI", value)


func _on_voice_updated(value: float) -> void:
	_set_bus_volume("Voice", value)


func _set_bus_volume(bus_name: String, value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(bus_name), 
		lerpf(SystemConstants.AUDIO_SILENCE_DB, 0.0, 
			AudioUtils.percent_to_perceptual(value)))
	Log.trace(self, "Set bus volume %s %s" % [bus_name, value])
