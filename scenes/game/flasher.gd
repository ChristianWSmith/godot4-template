extends CharacterBody2D
class_name Flasher

signal done

@export var duration: float = 1.0

func _ready() -> void:
	%StateC.request_change.connect(func() -> void:
		$Sprite2D.modulate = Color.CYAN)
	%StateM.request_change.connect(func() -> void:
		$Sprite2D.modulate = Color.MAGENTA)
	%StateY.request_change.connect(func() -> void:
		$Sprite2D.modulate = Color.YELLOW)
	%Timer.timeout.connect(done.emit)
	%Timer.start(duration)


func _physics_process(delta: float) -> void:
	velocity.y += delta * ProjectSettings.get("physics/2d/default_gravity")
	move_and_slide()
