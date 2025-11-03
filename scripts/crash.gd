extends Control

@onready var reason_label: Label = $ScrollContainer/VBoxContainer/Reason

func _ready() -> void:
	var reason_text: String = CrashReport.get_reason()
	if reason_text != "":
		reason_label.text = reason_text
