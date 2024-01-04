extends WindowPopup

var edit_icon = preload("res://Assets/UI/gear.png")

@onready var turrets_tree = $VBoxContainer/TabContainer/Turrets/VBoxContainer/Tree
@onready var enemies_tree = $VBoxContainer/TabContainer/Enemies/VBoxContainer/Tree
@onready var maps_label = $VBoxContainer/TabContainer/Maps/VBoxContainer/CodeEdit
@onready var tab_container = $VBoxContainer/TabContainer
@onready var save_button = $VBoxContainer/HBoxContainer/SaveButton

@export var configuration_manager: Node

func _ready():
	process_editor()
	
func process_editor():
	process_turrets()
	process_enemies()
	process_maps()
	
func process_turrets():
	create_tree(turrets_tree, GameData.config, 'tower_data')
	
func process_enemies():
	create_tree(enemies_tree, GameData.config, 'enemy_data')
	
func process_maps():
	var maps_json = JSON.stringify(GameData.config.maps, "\t", false)
	maps_label.text = maps_json
		
func create_tree(tree, data_wrapper, data_key):
	tree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	var data = data_wrapper[data_key]
	for key in data:
		var child = tree.create_item(root)
		child.set_text(0, key)
		child.add_button(0, edit_icon)
		
	tree.connect('button_clicked', Callable(self, "edit_requested").bind(data_key))

func edit_requested(item, _column, _id, _mouse_button_index, data_key):
	var item_key = item.get_text(0)
	get_parent().get_node("EditorItemPopup").process_data(GameData.config[data_key][item_key], item_key, data_key)

func _on_close_requested():
	visible = false

func _on_reset_button_pressed():
	var config_name = null
	if tab_container.current_tab == 0:
		config_name = "tower_data"
	elif tab_container.current_tab == 1:
		config_name = "enemy_data"
	elif tab_container.current_tab == 2:
		config_name = "maps"
		
	if config_name:
		configuration_manager.reset_config(config_name)
		configuration_manager.write_config(config_name)
		
		if config_name == "tower_data":
			process_turrets()
		elif config_name == "enemy_data":
			process_enemies()
		elif config_name == "maps":
			process_maps()

func _on_save_button_pressed():
	var maps_json_conv = JSON.new()
	var error = maps_json_conv.parse(maps_label.text)
	if error == OK:
		GameData.config.maps = maps_json_conv.get_data()
		configuration_manager.write_config("maps")
		GameData.show_toast_success("Saved maps data!")
	else:
		GameData.show_toast_error("An error occurred parsing the maps data. Error %s at line %s" % [maps_json_conv.get_error_message(), maps_json_conv.get_error_line()])

func _on_tab_container_tab_changed(tab):
	if tab == 2:
		save_button.visible = true
	else:
		save_button.visible = false
