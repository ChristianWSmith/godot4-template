extends Control

@onready var reason: Label = $ScrollContainer/VBoxContainer/Reason

func _ready() -> void:
	var reason_text: String = CrashReport.get_reason()
	if reason_text != "":
		reason.text = reason_text
