extends WindowPopup

@onready var mods_container = $MarginContainer/ScrollContainer/VBoxContainer
var mod_scene = preload("res://Scenes/UIScenes/ModItem.tscn")
var configuration_manager

func open():
	populate_mods()
	visible = true
	
func populate_mods():
	for item in mods_container.get_children():
		item.free()
		
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
	
	var mods_available = configuration_manager.mod_manager.available_mods_for_ui()
	
	if len(mods_available) > 0:
		var mod_scene_label = mod_scene.instantiate()
		mod_scene_label.mod_label = "Available mod.io Mods"
		mod_scene_label.mod_divider_label = true
		mods_container.add_child(mod_scene_label)
	
	for mod in mods_available:
		var new_mod_scene = mod_scene.instantiate()
		new_mod_scene.mod_label = "%s (%s)" % [mod.name, mod.modfile_version]
		new_mod_scene.mod_link = mod.profile_url
		new_mod_scene.mod_author = "by %s" % mod.author
		new_mod_scene.mod_manager = configuration_manager.mod_manager
		new_mod_scene.fs = configuration_manager.fs
		new_mod_scene.mod_data = mod
		mods_container.add_child(new_mod_scene)
		
	if len(mods_container.get_children()) == 0 and OS.has_feature("editor"):
		var mod_scene_label = mod_scene.instantiate()
		mod_scene_label.mod_label = "Mods do not load in editor"
		mod_scene_label.mod_divider_label = true
		mods_container.add_child(mod_scene_label)

func _on_close_requested():
	visible = false
