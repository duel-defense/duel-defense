extends Node

func get_mod_io_list(mod_io_api_key, mod_io_game_id):
	var modio = ModIO.new()
	modio.connect(mod_io_api_key, mod_io_game_id)
	return modio.get_mods("")
	
