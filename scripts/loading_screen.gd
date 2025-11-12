extends Control
class_name LoadingScreen

@onready var _progress_bar: ProgressBar = %ProgressBar

func set_progress(value: float) -> void:
	if _progress_bar:
		_progress_bar.value = value
