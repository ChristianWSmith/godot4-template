extends Node2D

@export var flasher_spawn_rate: float = 1000.0

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var color_rect: ColorRect = %ColorRect
@onready var camera2d: Camera2D = %Camera2D
@onready var flasher_scene: PackedScene = preload("res://scenes/game/flasher.tscn")

var spawn_flashers: bool = false
var remainder: float = 0.0
var flasher_quantized_rate: QuantizedRate = QuantizedRate.new(flasher_spawn_rate)

func _ready() -> void:
	EventBus.subscribe(InputManager._get_pressed_event("back"), _exit)
	sprite_2d.modulate = GameState.get_scene_data("sprite_modulate", Color.WHITE)
	color_rect.modulate = GameState.get_scene_data("color_rect_modulate", Color.BLACK)
	InputManager.subscribe_pressed("some_action", _randomize_colors)
	InputManager.subscribe_pressed("some_action", set.bind("spawn_flashers", true))
	InputManager.subscribe_released("some_action", set.bind("spawn_flashers", false))


func _process(delta: float) -> void:
	if not spawn_flashers:
		return
	for i in range(flasher_quantized_rate.get_discrete(delta)):
		var flasher: Node2D = flasher_scene.instantiate()
		flasher.global_position = _get_random_visible_position()
		add_child(flasher)
		flasher.done.connect(func() -> void:
			remove_child(flasher)
			flasher.queue_free())


func _randomize_colors() -> void:
	AudioManager.play_global_sfx(preload("res://assets/bin/sfx/sound.wav"))
	sprite_2d.modulate = Color.from_hsv(randf(), 0.5, 0.9)
	color_rect.modulate = sprite_2d.modulate
	color_rect.modulate.h += 0.5
	color_rect.modulate.v = 0.1
	GameState.set_scene_data("sprite_modulate", sprite_2d.modulate)
	GameState.set_scene_data("color_rect_modulate", color_rect.modulate)


func _exit() -> void:
	GameState.save_to_current_slot()
	SceneManager.change_scene("res://scenes/main_menu.tscn")


func _get_random_visible_position() -> Vector2:
	var visible_rect: Rect2 = camera2d.get_viewport_rect()
	return Vector2(
		randf_range(visible_rect.position.x - visible_rect.size.x / 2.0, visible_rect.position.x + visible_rect.size.x / 2.0),
		randf_range(visible_rect.position.y - visible_rect.size.y / 2.0, visible_rect.position.y + visible_rect.size.y / 2.0)
		)
