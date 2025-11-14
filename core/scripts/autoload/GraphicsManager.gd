extends BaseManager

@onready var _fps_label: Label = preload("res://core/scenes/ui/fps_label.tscn").instantiate()

func initialize() -> Error:
	super()
	Log.info(self, "Initializing...")
	_setup_fps_label()
	EventBus.subscribe(
		SettingsManager.get_event("graphics", "ui_scale"),
		_on_ui_scale_updated
	)
	EventBus.subscribe(
		SettingsManager.get_event("graphics", "show_fps"),
		_on_show_fps_updated
	)
	return OK


func _on_ui_scale_updated(ui_scale: float) -> void:
	UIManager.set_ui_scale(ui_scale)


func _on_show_fps_updated(show: bool) -> void:
	Log.info(self, "_on_show_fps_updated(%s)" % show)
	_fps_label.set_process(show)
	_fps_label.visible = show


func _setup_fps_label() -> void:
	_fps_label.set_process(false)
	_fps_label.visible = false
	_fps_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fps_label.position = Vector2(16.0, 16.0)
	var graphics_debug_layer: CanvasLayer = CanvasLayer.new()
	graphics_debug_layer.layer = SystemConstants.GRAPHICS_DEBUG_LAYER
	graphics_debug_layer.add_child(_fps_label)
	add_child(graphics_debug_layer)
	
