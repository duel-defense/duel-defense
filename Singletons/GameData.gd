extends Node

signal setting_updated(setting_key, setting_value)
signal config_updated(key)

var config = {}

func _ready():
	GodotLogger.log_requested.connect(on_log_requested)
	
	Console.add_command("get_setting", on_get_setting, 1)
	Console.add_command("set_setting", on_set_setting, 2)
	Console.add_command("list_settings", on_list_settings)

func update_setting(setting_key, value):
	config.settings[setting_key] = value
	emit_signal('setting_updated', setting_key, value)
	
func update_config(key):
	emit_signal('config_updated', key)

# Console commands related to GameData

func on_log_requested(msg):
	Console.print_line(msg)

func on_get_setting(key):
	if not key:
		Console.print_line("get_setting <key>")
		return
		
	if key not in GameData.config.settings:
		Console.print_line("get_setting <key>, key is invalid")
		return
	
	Console.print_line("%s" % GameData.config.settings[key])
	
func on_set_setting(key, value):
	if not key or not value:
		Console.print_line("set_setting <key> <value>")
		return
		
	if key not in GameData.config.settings_map or key not in GameData.config.settings:
		Console.print_line("set_setting <key>, key is invalid")
		return
	
	var final_value = value
	
	var setting_map = GameData.config.settings_map[key]
	if setting_map.type == "slider":
		final_value = float(value)
	elif setting_map.type == "checkbox":
		if value == "true":
			final_value = true
		else:
			final_value = false
	
	update_setting(key, final_value)

func on_list_settings():
	Console.print_line(JSON.stringify(GameData.config.settings, "\t"))
