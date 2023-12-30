extends WindowPopup

@onready var mods_container = $MarginContainer/ScrollContainer/VBoxContainer
var mod_scene = preload("res://Scenes/UIScenes/ModItem.tscn")
var configuration_manager

func open():
	populate_mods()
	visible = true
	
func populate_mods():
	for item in mods_container.get_children():
		item.queue_free()
		
	var mods = configuration_manager.mod_manager.available_mods
	for mod in mods:
		var new_mod_scene = mod_scene.instantiate()
		new_mod_scene.mod_label = mod.name
		new_mod_scene.mod_author = "by %s" % mod.submitted_by_username
		new_mod_scene.mod_manager = configuration_manager.mod_manager
		new_mod_scene.fs = configuration_manager.fs
		new_mod_scene.mod_data = mod
		mods_container.add_child(new_mod_scene)

func _on_close_requested():
	visible = false
