## Handles the game's startup sequence. This autoload is responsible for
## triggering system initialization, enforcing the minimum load screen time,
## and handing off control to the main launch scene once initialization
## completes successfully.
##
## If initialization fails, the failure is logged and the scene transition
## does not proceed.
extends Node
class_name EntryPoint

@onready var timer: Timer = %Timer

func _ready() -> void:
	print("[%s] Starting initialization..." % name)
	
	timer.start(SystemConstants.SCENE_LOAD_SCREEN_MINIMUM_TIME)

	if InitManager.initialize() == OK:
		Log.info(self, "Systems initialized successfully.")
		if not timer.is_stopped():
			await timer.timeout
		SceneManager.change_scene_async(
			ResourceUID.uid_to_path(SystemConstants.LAUNCH_SCENE_UID)
		)
	else:
		print("[%s] Initialization failed." % name)
