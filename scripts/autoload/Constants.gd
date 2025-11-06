extends Node

# General
const INT_MAX: int = int(INF) - 1
const INT_MIN: int = int(INF)

# Scene
const SCENE_FADE_TIME: float = 0.5

# Debug
const LOG_FILE_PATH: String = "user://debug.log"

# Steam
const STEAM_APP_ID: int = 480
const STEAM_REQUIRED: bool = false
const STEAM_RECONCILIATION_INTERVAL: float = 5.0

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

# Input
const INPUT_BUILT_IN_ACTIONS: Array[String] = [
	"ui_accept", "ui_select", "ui_cancel", "ui_focus_next", "ui_focus_prev", "ui_left", "ui_right",
	"ui_up", "ui_down", "ui_page_up", "ui_page_down", "ui_home", "ui_end",
	"ui_accessibility_drag_and_drop", "ui_cut", "ui_copy", "ui_focus_mode", "ui_paste", "ui_undo",
	"ui_redo", "ui_text_completion_query", "ui_text_completion_accept",
	"ui_text_completion_replace", "ui_text_newline", "ui_text_newline_blank",
	"ui_text_newline_above", "ui_text_indent", "ui_text_dedent", "ui_text_backspace",
	"ui_text_backspace_word", "ui_text_backspace_word.macos", "ui_text_backspace_all_to_left",
	"ui_text_backspace_all_to_left.macos", "ui_text_delete", "ui_text_delete_word",
	"ui_text_delete_word.macos", "ui_text_delete_all_to_right", "ui_text_delete_all_to_right.macos",
	"ui_text_caret_left", "ui_text_caret_word_left", "ui_text_caret_word_left.macos",
	"ui_text_caret_right", "ui_text_caret_word_right", "ui_text_caret_word_right.macos",
	"ui_text_caret_up", "ui_text_caret_down", "ui_text_caret_line_start",
	"ui_text_caret_line_start.macos", "ui_text_caret_line_end", "ui_text_caret_line_end.macos",
	"ui_text_caret_page_up", "ui_text_caret_page_down", "ui_text_caret_document_start",
	"ui_text_caret_document_start.macos", "ui_text_caret_document_end",
	"ui_text_caret_document_end.macos", "ui_text_caret_add_below", "ui_text_caret_add_below.macos",
	"ui_text_caret_add_above", "ui_text_caret_add_above.macos", "ui_text_scroll_up",
	"ui_text_scroll_up.macos", "ui_text_scroll_down", "ui_text_scroll_down.macos",
	"ui_text_select_all", "ui_text_select_word_under_caret",
	"ui_text_select_word_under_caret.macos", "ui_text_add_selection_for_next_occurrence",
	"ui_text_skip_selection_for_next_occurrence", "ui_text_clear_carets_and_selection",
	"ui_text_toggle_insert_mode", "ui_menu", "ui_text_submit", "ui_unicode_start",
	"ui_graph_duplicate", "ui_graph_delete", "ui_graph_follow_left", "ui_graph_follow_left.macos",
	"ui_graph_follow_right", "ui_graph_follow_right.macos", "ui_filedialog_up_one_level",
	"ui_filedialog_refresh", "ui_filedialog_show_hidden", "ui_swap_input_direction",
	"ui_colorpicker_delete_preset",
]

# Audio
const MUSIC_FADE_TIME: float = 1.0
@onready var SILENCE_DB: float = ProjectSettings.get_setting("audio/buses/channel_disable_threshold_db")

# Settings
const SETTINGS_VERSION: int = 0
const SETTINGS_CHANGED_EVENT_PREFIX: String = "settings_changed"
const LOCAL_SETTINGS_PATH: String = "user://settings.cfg"
const CLOUD_SETTINGS_FILE: String = "settings.cfg"
const DEFAULT_INPUT_BINDINGS_SETTINGS: Dictionary = {} # overrides project input map
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
	"graphics": {
		"placeholder": true
	},
	"audio": {
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0,
		"ui": 1.0,
		"voice": 1.0,
	},
	"input": {
		"bindings": DEFAULT_INPUT_BINDINGS_SETTINGS
	},
	"gameplay": {
		"placeholder": true
	}
}
