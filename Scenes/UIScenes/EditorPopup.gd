extends WindowPopup

var edit_icon = preload("res://Assets/UI/gear.png")

@onready var turrets_tree = $VBoxContainer/TabContainer/Turrets/VBoxContainer/Tree

func _ready():
	process_editor()
	
func process_editor():
	process_turrets()
	process_enemies()
	
func process_turrets():
	create_tree(turrets_tree, GameData.config, 'tower_data')
	
func process_enemies():
	create_tree(turrets_tree, GameData.config, 'enemy_data')
		
func create_tree(tree, data_wrapper, data_key):
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	var data = data_wrapper[data_key]
	for key in data:
		var child = tree.create_item(root)
		child.set_text(0, key)
		child.add_button(0, edit_icon)
		
	tree.connect('button_clicked', Callable(self, "edit_requested").bind(data, data_key))

func edit_requested(item, _column, _id, _mouse_button_index, data, data_key):
	var item_key = item.get_text(0)
	get_parent().get_node("EditorItemPopup").process_data(data[item_key], item_key, data_key)

func _on_close_requested():
	visible = false
