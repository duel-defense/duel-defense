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
		
	var mods_loaded = configuration_manager.mod_manager.mods_loaded
	for mod in mods_loaded:
		var new_mod_scene = mod_scene.instantiate()
		new_mod_scene.mod_label = mod.name
		new_mod_scene.mod_author = "by %s" % mod.author
		new_mod_scene.mod_manager = configuration_manager.mod_manager
		new_mod_scene.fs = configuration_manager.fs
		new_mod_scene.mod_data = mod
		new_mod_scene.mod_loaded = true
		mods_container.add_child(new_mod_scene)
		
	var mod_scene_label = mod_scene.instantiate()
	mod_scene_label.mod_label = "Available mod.io Mods"
	mod_scene_label.mod_divider_label = true
	mods_container.add_child(mod_scene_label)
	
	var mods_available = configuration_manager.mod_manager.available_mods
	for mod in mods_available:
		var mod_file_loaded = configuration_manager.fs.file_exists(configuration_manager.mod_manager.user_mods_path + mod.modfile_name)
		if mod_file_loaded:
			continue
		var new_mod_scene = mod_scene.instantiate()
		new_mod_scene.mod_label = mod.name
		new_mod_scene.mod_author = "by %s" % mod.submitted_by_username
		new_mod_scene.mod_manager = configuration_manager.mod_manager
		new_mod_scene.fs = configuration_manager.fs
		new_mod_scene.mod_data = mod
		mods_container.add_child(new_mod_scene)

func _on_close_requested():
	visible = false
