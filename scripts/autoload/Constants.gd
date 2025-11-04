extends Node

# Debug
const LOG_FILE_PATH: String = "user://debug.log"

# Steam
const STEAM_APP_ID: int = 480
const STEAM_REQUIRED: bool = false

# Save
const SAVE_VERSION: int = 0
const LOCAL_SAVE_BASE_PATH: String = "user://"
const LOCAL_SAVE_SUBPATH: String = "save"
const LOCAL_SAVE_PATH: String = LOCAL_SAVE_BASE_PATH + LOCAL_SAVE_SUBPATH
const LOCAL_SAVE_MANIFEST_PATH: String = "user://save_manifest.json"
const DEFAULT_SAVE: Dictionary = {
	"meta": {
		"version": SAVE_VERSION,
		"timestamp": -1.0,
	},
	"data": {
		
	}
}

# Settings
const SETTINGS_VERSION: int = 0
const SETTINGS_CHANGED_EVENT_PREFIX: String = "settings_changed"
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
