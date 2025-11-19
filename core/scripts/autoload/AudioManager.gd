## Manager for playing and controlling audio across the game.
##
## Supports global music, sound effects, UI sounds, and voice lines.
## Can play audio in 2D or 3D space, handles fading, and responds
## to settings changes for master and individual bus volumes.
extends BaseManager

var _global_music_player: AudioStreamPlayer

## Initializes the audio manager, subscribing to changes in
## the master, music, sfx, UI, and voice volume settings.
## Automatically updates bus volumes when settings change.
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


## Plays a global music track.
## If the same track is already playing and [code]restart[/code] is false,
## nothing happens. Otherwise, fades out any current music and fades in the new track.
## [code]stream[/code] is the music to play.
## [code]fade_time[/code] is how long to fade in/out.
## [code]restart[/code] forces restarting the track even if it’s already playing.
func play_global_music(
		stream: AudioStream, 
		fade_time: float = SystemConstants.AUDIO_MUSIC_FADE_TIME,
		restart: bool = false) -> void:
	if _global_music_player and _global_music_player.stream == stream and not restart:
		return
	_fade_out_music(_global_music_player, fade_time)
	_global_music_player = _play_sound(stream, SystemConstants.AUDIO_BUS_MUSIC, SystemConstants.AUDIO_WRAPPED_PLAYER)
	_global_music_player.volume_db = SystemConstants.AUDIO_SILENCE_DB
	create_tween().tween_property(_global_music_player, "volume_db", 0.0, fade_time)
	Log.info(self, "Playing music: %s" % _global_music_player.stream.resource_path)


## Stops the currently playing global music with an optional fade out.
## [code]fade_time[/code] specifies how long the fade lasts.
func stop_global_music(fade_time: float = SystemConstants.AUDIO_MUSIC_FADE_TIME) -> void:
	_fade_out_music(_global_music_player, fade_time)
	_global_music_player = null


## Plays a global sound effect.
## [code]stream[/code] is the AudioStream to play on the SFX bus.
func play_global_sfx(stream: AudioStream) -> void:
	_play_sound(stream, SystemConstants.AUDIO_BUS_SFX, SystemConstants.AUDIO_WRAPPED_PLAYER)


## Plays a global voice line.
## [code]stream[/code] is the AudioStream to play on the Voice bus.
func play_global_voice(stream: AudioStream) -> void:
	_play_sound(stream, SystemConstants.AUDIO_BUS_VOICE, SystemConstants.AUDIO_WRAPPED_PLAYER)


## Plays a global UI sound.
## [code]stream[/code] is the AudioStream to play on the UI bus.
func play_global_ui(stream: AudioStream) -> void:
	_play_sound(stream, SystemConstants.AUDIO_BUS_UI, SystemConstants.AUDIO_WRAPPED_PLAYER)


## Plays a 2D music sound at a specific position.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the global 2D position to emit the sound from.
func play_music_2d(stream: AudioStream, position: Vector2) -> void:
	_play_sound_2d(stream, SystemConstants.AUDIO_BUS_MUSIC, position)


## Plays a 2D sound effect at a specific position.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the global 2D position.
func play_sfx_2d(stream: AudioStream, position: Vector2) -> void:
	_play_sound_2d(stream, SystemConstants.AUDIO_BUS_SFX, position)


## Plays a 2D UI sound at a specific position.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the global 2D position.
func play_ui_2d(stream: AudioStream, position: Vector2) -> void:
	_play_sound_2d(stream, SystemConstants.AUDIO_BUS_UI, position)


## Plays a 2D voice sound at a specific position.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the global 2D position.
func play_voice_2d(stream: AudioStream, position: Vector2) -> void:
	_play_sound_2d(stream, SystemConstants.AUDIO_BUS_MUSIC, position)


## Plays a 3D music sound at a specific position in the world.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the 3D world position to emit the sound from.
func play_music_3d(stream: AudioStream, position: Vector3) -> void:
	_play_sound_3d(stream, SystemConstants.AUDIO_BUS_MUSIC, position)


## Plays a 3D sound effect at a specific position in the world.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the 3D world position.
func play_sfx_3d(stream: AudioStream, position: Vector3) -> void:
	_play_sound_3d(stream, SystemConstants.AUDIO_BUS_SFX, position)


## Plays a 3D UI sound at a specific position in the world.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the 3D world position.
func play_ui_3d(stream: AudioStream, position: Vector3) -> void:
	_play_sound_3d(stream, SystemConstants.AUDIO_BUS_UI, position)


## Plays a 3D voice sound at a specific position in the world.
## [code]stream[/code] is the AudioStream to play.
## [code]position[/code] is the 3D world position.
func play_voice_3d(stream: AudioStream, position: Vector3) -> void:
	_play_sound_3d(stream, SystemConstants.AUDIO_BUS_MUSIC, position)


func _play_sound_2d(stream: AudioStream, bus: String, position: Vector2):
	var player: AudioStreamPlayer2D = _play_sound(stream, bus, SystemConstants.AUDIO_WRAPPED_PLAYER_2D)
	player.global_position = position


func _play_sound_3d(stream: AudioStream, bus: String, position: Vector3):
	var player: AudioStreamPlayer3D = _play_sound(stream, bus, SystemConstants.AUDIO_WRAPPED_PLAYER_3D)
	player.global_position = position
	

func _play_sound(stream: AudioStream, bus: String, scene: PackedScene) -> Variant:
	var player: Variant = scene.instantiate()
	add_child(player)
	player.stream = stream
	player.bus = bus
	player.finished.connect(func() -> void:
		remove_child(player)
		player.queue_free())
	player.play.call_deferred()
	Log.trace(self, "Playing sound on bus: %s %s" % [bus, stream.resource_path])
	return player


func _fade_out_music(player: AudioStreamPlayer, fade_time: float) -> void:
	if not player:
		Log.debug(self, "No music to fade out.")
		return
	var fade_out: Tween = create_tween()
	fade_out.tween_property(player, "volume_db", SystemConstants.AUDIO_SILENCE_DB, fade_time)
	fade_out.tween_callback(func() -> void:
		remove_child(player)
		player.queue_free())
	Log.trace(self, "Fading out music: %s" % player.stream.resource_path)


func _on_master_updated(value: float) -> void:
	_set_bus_volume(SystemConstants.AUDIO_BUS_MASTER, value)


func _on_music_updated(value: float) -> void:
	_set_bus_volume(SystemConstants.AUDIO_BUS_MUSIC, value)


func _on_sfx_updated(value: float) -> void:
	_set_bus_volume(SystemConstants.AUDIO_BUS_SFX, value)


func _on_ui_updated(value: float) -> void:
	_set_bus_volume(SystemConstants.AUDIO_BUS_UI, value)


func _on_voice_updated(value: float) -> void:
	_set_bus_volume(SystemConstants.AUDIO_BUS_VOICE, value)


func _set_bus_volume(bus_name: String, value: float):
	var target: float = lerpf(
			SystemConstants.AUDIO_SILENCE_DB, 
			0.0, 
			_percent_to_perceptual(value))
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if target <= SystemConstants.AUDIO_SILENCE_DB:
		AudioServer.set_bus_mute(bus_idx, true)
		Log.trace(self, "Muted bus %s" % bus_name)
	else:
		if AudioServer.is_bus_mute(bus_idx):
			AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bus_name), 
			target)
		Log.trace(self, "Set bus volume %s %s" % [bus_name, value])


static func _percent_to_perceptual(percent: float) -> float:
	return pow(percent, 0.25)
