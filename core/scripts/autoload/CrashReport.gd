extends Node

var crash_reason: String = ""

func crash(source: String, reason: String) -> void:
	crash_reason = "[%s] %s" % [source, reason]
	get_tree().current_scene.queue_free()
	get_tree().change_scene_to_file.call_deferred("res://core/scenes/crash.tscn")


func get_reason() -> String:
	return crash_reason
