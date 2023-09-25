extends "res://Scenes/UIScenes/WindowPopup.gd"

const UIBuilder = preload("res://CommonScripts/UIBuilder.gd")
@onready var ui_builder = UIBuilder.new(self)

var current_data
var data_key

func process_data(data, item_key, given_data_key):
	if not data:
		return
		
	current_data = data
	data_key = given_data_key
	
	clear_scroll_container()
	title = item_key
	ui_builder.build_ui(data, GameData.config.editor_data_map)
		
	open_popup()

func value_changed(value, item_key, label_node = null):
	if label_node:
		label_node.text = str(value)
		
	current_data[item_key] = value
	signal_config_updated(data_key)


func _on_close_requested():
	visible = false
