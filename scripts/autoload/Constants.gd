extends Node

const STEAM_APP_ID: int = 480
const STEAM_REQUIRED: bool = false
const LOG_FILE_PATH: String = "user://debug.log"
const SETTINGS_PATH: String = "user://settings.cfg"
const CLOUD_SETTINGS_FILE: String = "settings.cfg"

const DEFAULT_SETTINGS: Dictionary = {
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
