extends Node

var last_map_name
var current_map
var in_game_for_menu = false

@onready var main_menu = $MainMenu
@onready var main_menu_music = $MainMenu/BackgroundMusic
@onready var configuration_manager = $ConfigurationManager
@onready var level_select = $LevelSelect
@onready var achivements = $Achivements
@onready var mods = $Mods

func _ready():
	SoundManager.set_default_music_bus("BackgroundMusic")
	SoundManager.set_default_ui_sound_bus("InterfaceEffects")
	SoundManager.set_default_sound_bus("SoundEffects")
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)
	
	link_main_menu()
	link_setting_change()
	check_fps_monitor()
	check_full_screen()
	process_audio_settings()
	
	Console.add_command("open_editor", on_open_editor)
	Console.add_command("map", on_load_map, 1)
	
	mods.configuration_manager = $ConfigurationManager
	
	check_autoexec()
	
func check_autoexec():
	if "autoexec" in GameData.config:
		var autoexecArray = GameData.config.autoexec
		for line in autoexecArray:
			if line:
				Console.on_text_entered(line)
				
func _on_input_type_changed(input_type):
	match input_type:
		ControllerIcons.InputType.KEYBOARD_MOUSE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		ControllerIcons.InputType.CONTROLLER:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _input(event):
	if event.is_action_pressed("ui_menu"):
		var game_scene = get_node_or_null("GameScene")
		if !game_scene.main_menu_mode:
			if main_menu.visible:
				on_resume_game_pressed()			
			else:
				load_main_menu(true)
				get_tree().paused = true
	
func link_setting_change():
	# warning-ignore:return_value_discarded
	GameData.connect("setting_updated", Callable(self, "setting_change"))
	# warning-ignore:return_value_discarded
	GameData.connect("config_updated", Callable(self, "config_element_update"))

func check_fps_monitor():
	if GameData.config.settings.show_fps_monitor:
		DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
	else:
		DebugMenu.style = DebugMenu.Style.HIDDEN
		
func check_full_screen():
	if GameData.config.settings.full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		
func setting_change(setting_key, _value):
	configuration_manager.write_config('settings')
		
	if setting_key == "show_fps_monitor":
		check_fps_monitor()
	elif setting_key == "full_screen":
		check_full_screen()
	elif setting_key in GameData.config.settings_map and 'audio_bus' in GameData.config.settings_map[setting_key]:
		process_audio_bus_change(setting_key)
		
func process_audio_settings():
	for key in GameData.config.settings_map:
		var settings_map_data = GameData.config.settings_map[key]
		if 'audio_bus' in settings_map_data:
			process_audio_bus_change(key)
		
func process_audio_bus_change(setting_key):
	var settings_map_data = GameData.config.settings_map[setting_key]
	var percent_value = GameData.config.settings[setting_key]
	var value = percent_value / 100
	
	var bus_index = AudioServer.get_bus_index(settings_map_data.audio_bus)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
		
func config_element_update(key):
	configuration_manager.write_config(key)
	
func complete_achivement(key):
	var game_scene = get_node_or_null("GameScene")
	if game_scene.main_menu_mode:
		GodotLogger.info("ignoring achivement completed because of main menu mode = %s" % key)
		return
	GodotLogger.info("achivement completed = %s" % key)
	if key in GameData.config.user_achivements and GameData.config.user_achivements[key]:
		return
	GameData.config.user_achivements[key] = true
	configuration_manager.write_config("user_achivements")
	
func load_main_menu(in_game = false):
	var congrats_menu = get_node_or_null("CongratsMenu")
	if congrats_menu and is_instance_valid(congrats_menu):
		congrats_menu.queue_free()
	in_game_for_menu = in_game
	main_menu.visible = true
	update_menu_items()
	if not in_game:
		main_menu_music.play()
	
func load_congrats_menu(result):
	if result and "ended" in result and result.ended:
		GameData.config.maps_user_data[result.map_name] = result
		configuration_manager.write_config("maps_user_data")
		
		# checking for achivements
		complete_achivement("map_complete")
		if "base_health" in result and result.base_health >= 100:
			complete_achivement("finish_all_health")
		if "current_money" in result and result.current_money <= 300:
			complete_achivement("finish_money_little")
		if "current_money" in result and result.current_money >= 2000:
			complete_achivement("finish_money_lots")
		if "radar_mode" in result and result.radar_mode:
			complete_achivement("map_complete_radar")
	
	var congrats_menu = load("res://Scenes/UIScenes/CongratsMenu.tscn").instantiate()
	congrats_menu.result = result
	add_child(congrats_menu)
	# warning-ignore:return_value_discarded
	get_node("CongratsMenu/Container/VBoxContainer/MainMenu").connect("pressed", Callable(self, "on_congrats_main_menu"))
	# warning-ignore:return_value_discarded
	get_node("CongratsMenu/Container/VBoxContainer/Quit").connect("pressed", Callable(self, "on_quit_pressed"))
	
	last_map_name = current_map
	
	var last_map_data = GameData.config.maps[last_map_name]
	if "next_map" not in last_map_data:
		get_node("CongratsMenu/Container/VBoxContainer/Continue").visible = false
	else:
		# warning-ignore:return_value_discarded
		get_node("CongratsMenu/Container/VBoxContainer/Continue").connect("pressed", Callable(self, "on_continue_pressed"))

func link_main_menu():
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/NewGame").connect("pressed", Callable(self, "on_new_game_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/ResumeGame").connect("pressed", Callable(self, "on_resume_game_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/Settings").connect("pressed", Callable(self, "on_settings_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/Editor").connect("pressed", Callable(self, "on_editor_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/About").connect("pressed", Callable(self, "on_about_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/Quit").connect("pressed", Callable(self, "on_quit_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/MainMenu").connect("pressed", Callable(self, "on_main_menu_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/Achivements").connect("pressed", Callable(self, "on_achivements_pressed"))
	# warning-ignore:return_value_discarded
	get_node("MainMenu/Container/VBoxContainer/Mods").connect("pressed", Callable(self, "on_mods_pressed"))
	
	update_menu_items()
	
func update_menu_items():
	if in_game_for_menu:
		get_node("MainMenu/Container/TitleContainer").visible = false
		get_node("MainMenu/Container/VBoxContainer/ResumeGame").visible = true
		get_node("MainMenu/Container/VBoxContainer/MainMenu").visible = true
		get_node("MainMenu/Container/VBoxContainer/NewGame").visible = false
		get_node("MainMenu/Container/VBoxContainer/Mods").visible = false
		get_node("MainMenu/Container/VBoxContainer/About").visible = false
		get_node("MainMenu/Container/VBoxContainer/ResumeGame").grab_focus()
	else:
		var map_name = GameData.config.settings.main_menu_map
		var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instantiate()
		game_scene.map_name = map_name
		game_scene.main_menu_mode = true
		game_scene.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(game_scene)
		move_child(game_scene, 0)
		
		get_node("MainMenu/Container/TitleContainer").visible = true
		get_node("MainMenu/Container/VBoxContainer/ResumeGame").visible = false
		get_node("MainMenu/Container/VBoxContainer/MainMenu").visible = false
		get_node("MainMenu/Container/VBoxContainer/NewGame").visible = true
		get_node("MainMenu/Container/VBoxContainer/Mods").visible = true
		get_node("MainMenu/Container/VBoxContainer/About").visible = true
		get_node("MainMenu/Container/VBoxContainer/NewGame").grab_focus()
	
	if OS.has_feature("mobile") or OS.has_feature("web"):
		get_node("MainMenu/Container/VBoxContainer/Quit").visible = false
	
	if OS.has_feature("web"):
		get_node("MainMenu/Container/VBoxContainer/Mods").visible = false
		
func on_main_menu_pressed():
	on_congrats_main_menu()
	get_tree().paused = false
	
func on_achivements_pressed():
	achivements.open()
	
func on_mods_pressed():
	mods.open()

func on_new_game_pressed():
	Helpers.play_button_sound()
	level_select.open()
	
func on_resume_game_pressed():
	Helpers.play_button_sound()
	main_menu.visible = false
	in_game_for_menu = false
	get_tree().paused = false
	
func on_settings_pressed():
	Helpers.play_button_sound()
	get_node("SettingsPopup").open_popup()
	
func on_editor_pressed(disable_sound = false):
	if not disable_sound:
		Helpers.play_button_sound()
	get_node("EditorPopup").open_popup()
	
func on_about_pressed():
	Helpers.play_button_sound()
	get_node("AboutPopup").open_popup()
	
func on_continue_pressed():
	Helpers.play_button_sound()
	var last_map_data = GameData.config.maps[last_map_name]
	if "next_map" in last_map_data:
		get_node("CongratsMenu").queue_free()
		var new_map = last_map_data.next_map
		load_game_scene(new_map)
		
func on_congrats_main_menu():
	unload_game(null, current_map, true)
	load_main_menu()
	
func load_game_scene(map_name = null):
	if current_map:
		unload_game(null, current_map, true)
	
	if not map_name:
		map_name = GameData.config.settings.starting_map
		
	var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instantiate()
	game_scene.map_name = map_name
	game_scene.connect("game_finished", Callable(self, 'unload_game'))
	game_scene.connect("complete_achivement", Callable(self, 'complete_achivement'))
	game_scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	game_scene.set_name("GameScene")
	add_child(game_scene)
	current_map = map_name
	main_menu_music.stop()
	
func on_quit_pressed():
	Helpers.play_button_sound()
	get_tree().quit()

func unload_game(result, map_name, skip_load = false):
	if result:
		result.map_name = map_name
		return load_congrats_menu(result)
	
	last_map_name = map_name
	current_map = null
	
	var game_scene = get_node_or_null("GameScene")
	if game_scene and is_instance_valid(game_scene):
		game_scene.free()
	
	if not skip_load:
		if not result:
			load_main_menu()

# console commands related to the menu/game behavior

func on_open_editor():
	Console.toggle_console()
	on_editor_pressed(true)

func on_load_map(map_name):
	if not map_name:
		Console.print_line("map <map_name>")
		return
		
	var game_scene = get_node_or_null("GameScene")
	if game_scene:
		game_scene.free()
		
	main_menu.visible = false
	
	if current_map:
		unload_game(null, current_map, true)
	
	load_game_scene(map_name)

func _on_level_select_level_requested(map_key):
	GodotLogger.info("_on_level_select_level_requested %s" % map_key)
	level_select.visible = false
	main_menu.visible = false
	var game_scene = get_node_or_null("GameScene")
	if game_scene:
		game_scene.free()
	in_game_for_menu = false
	last_map_name = null
	load_game_scene(map_key)
