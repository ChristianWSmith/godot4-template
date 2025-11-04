extends Node

# Debug
const LOG_FILE_PATH: String = "user://debug.log"

# Steam
const STEAM_APP_ID: int = 480
const STEAM_REQUIRED: bool = false

# Settings
const SETTINGS_VERSION: int = 0
const LOCAL_SETTINGS_PATH: String = "user://settings.cfg"
const CLOUD_SETTINGS_FILE: String = "settings.cfg"
const DEFAULT_SETTINGS: Dictionary = {
	"meta": {
		"version": SETTINGS_VERSION,
		"timestamp": -1.0
	},
	"video": {
		"fullscreen": false,
		"borderless": false,
		"vsync": true,
		"resolution": Vector2i(1152, 648),
		"max_fps": 0,
	},
	"graphics": {},
	"audio": {},
	"controls": {},
	"gameplay": {}
}
