## Handles global crash behavior for the game.
## 
## This autoload is responsible for:
## - Recording crash source and reason
## - Freeing all registered systems
## - Unloading the current scene
## - Switching to the crash screen
##
## The crash information can be retrieved via [code]get_reason()[/code].
extends Node

var _crash_reason: String = ""

## Triggers a full engine-level crash sequence.
## 
## The [code]source[/code] argument identifies which system or subsystem
## reported the crash. The [code]reason[/code] argument contains the error
## message or failure context.
##
## This function stores the crash message, frees all registered systems and
## the current scene, and then loads the global crash screen.
func crash(source: String, reason: String) -> void:
	_crash_reason = "[%s] %s" % [source, reason]
	for system in InitManager.systems():
		get_tree().root.get_node("/root/" + system.name).queue_free()
	get_tree().current_scene.queue_free()
	get_tree().change_scene_to_file.call_deferred("res://core/scenes/crash.tscn")


## Returns the most recent crash reason recorded by [code]crash()[/code].
## The returned string contains the formatted crash source and error message.
func get_reason() -> String:
	return _crash_reason
