extends Node

var user_mods_path = "user://mods/"

var mod_io_api_key = "14a081a80013ec1f004dc111ecc4f1cc"
var mod_io_game_id = 5960
var mod_io_interface = null

var fs = null
var configuration_manager = null

var mods_loaded = []
var available_mods = []

func init_mods():
	# mod loading fails in the editor, see https://github.com/godotengine/godot/issues/19815
	if not OS.has_feature("editor"):
		read_mod_dir(user_mods_path)
	else:
		GodotLogger.info("disabling init_mods, since running inside editor")
		
	get_mod_io_list()

func read_mod_dir(path):
	GodotLogger.debug("read_mod_dir: " + path)
	var mod_files = fs.list_files_in_directory(path)
	
	for filename in mod_files:
		var extension = filename.get_extension()
		if extension == "pck":
			load_mod(path, filename)

func load_mod(path, filename):
	GodotLogger.info("load_mod: " + filename)
	
	var result = ProjectSettings.load_resource_pack(path + filename)
	if not result:
		GodotLogger.error("load_mod error for %s" % filename)
		return
		
	var mod_name = filename.get_basename()
	var mod_metadata_str = fs.read_file("res://" + mod_name + "/Assets/Configs/metadata.json")
	if not mod_metadata_str:
		GodotLogger.error("load_mod error getting metadata for %s" % filename)
		return
	
	GodotLogger.info("load_mod metadata of: %s" % mod_metadata_str)
	var mod_metadata_conv = JSON.new()
	mod_metadata_conv.parse(mod_metadata_str)
	var mod_metadata = mod_metadata_conv.get_data()
	mods_loaded.append(mod_metadata)
	
	var mod_maps_str = fs.read_file("res://" + mod_name + "/Assets/Configs/maps.json")
	if not mod_maps_str:
		GodotLogger.warn("load_mod error loading maps for %s" % filename)
	else:
		GodotLogger.info("load_mod maps of: %s" % mod_maps_str)
		var mod_maps_conv = JSON.new()
		mod_maps_conv.parse(mod_maps_str)
		var mod_maps = mod_maps_conv.get_data()
		
		for map_key in mod_maps:
			var map = mod_maps[map_key]
			if "friendly_name" not in map:
				continue
				
			map["friendly_name"] = mod_metadata.name + " - " + map["friendly_name"]
			map["custom_scene_start_path"] = "res://" + mod_name
			map["from_mod"] = true
			
			configuration_manager.config_container.maps[mod_name + "_" + map_key] = map
			
	var mod_turrets_str = fs.read_file("res://" + mod_name + "/Assets/Configs/tower_data.json")
	if not mod_turrets_str:
		GodotLogger.warn("load_mod error loading turrets for %s" % filename)
	else:
		GodotLogger.info("load_mod turrets of: %s" % mod_turrets_str)
		var mod_turrets_conv = JSON.new()
		mod_turrets_conv.parse(mod_turrets_str)
		var mod_turrets = mod_turrets_conv.get_data()
		
		for turret_key in mod_turrets:
			var turret = mod_turrets[turret_key]
			turret["custom_scene_start_path"] = "res://" + mod_name
			turret["from_mod"] = true
			configuration_manager.config_container.tower_data[mod_name + "_" + turret_key] = turret
				
func get_mod_io_list():
	if mod_io_interface:
		available_mods = mod_io_interface.get_mod_io_list(mod_io_api_key, mod_io_game_id)
		GodotLogger.info("get_mod_io_list found mods: %s" % JSON.stringify(available_mods))
	else:
		GodotLogger.warn("get_mod_io_list, interface is not loaded")
	
func mod_downloaded(mod_data):
	GodotLogger.info("mod downloaded: %s" % JSON.stringify(mod_data))
	configuration_manager.read_configs()
	init_mods()
	
