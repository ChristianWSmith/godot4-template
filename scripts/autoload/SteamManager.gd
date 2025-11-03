extends Node


func initialize() -> void:
	var response: Dictionary = Steam.steamInitEx( Constants.STEAM_APP_ID, false )
	var status: int = response.get("status", -1)
	match status:
		-1:
			push_error("[%s] Unkonwn error" % name)
		0:
			push_error("[%s] Steamworks active" % name)
		1:
			push_error("[%s] Failed (generic)" % name)
		2:
			push_error("[%s] Cannot connect to Steam, client probably isn't running" % name)
		3:
			push_error("[%s] Steam client appears to be out of date" % name)
		_: 
			pass

func _process(_delta: float) -> void:
	Steam.run_callbacks()
