extends WindowPopup

const UIBuilder = preload("res://CommonScripts/UIBuilder.gd")
@onready var ui_builder = UIBuilder.new(self)

@export var configuration_manager: Node

func _ready():
	process_settings()
	
func open_popup():
	var current_fps_monitor_status = DebugMenu.style
	if (current_fps_monitor_status == DebugMenu.Style.HIDDEN and GameData.config.settings.show_fps_monitor) or (current_fps_monitor_status != DebugMenu.Style.HIDDEN and !GameData.config.settings.show_fps_monitor):
		value_changed(!GameData.config.settings.show_fps_monitor, "show_fps_monitor")
		process_settings()
		
	super()
	
func process_settings():
	clear_scroll_container()
	ui_builder.build_ui(GameData.config.settings, GameData.config.settings_map)

func value_changed(value, setting_key, label_node = null):
	if label_node:
		label_node.text = str(value)
	GameData.update_setting(setting_key, value)

func _on_close_requested():
	visible = false


func _on_reset_button_pressed():
	configuration_manager.reset_config("settings")
	process_settings()
