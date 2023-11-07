extends Node2D

signal game_finished(result)
signal complete_achivement(key)

var map_name = "Map1"
var map_node
var game_ended

var build_mode = false
var build_valid = false
var build_location
var build_type
var build_tile

var upgrade_mode = false
var upgrade_node

var current_wave = 0
var enemies_in_wave = 0
var boss_wave = false

var debug_tile_coords = false
var debug_resolution = false

var base_health = GameData.config.settings.starting_base_health
var enemy_base_health = 100
var current_money

@onready var debug_message = $UI/DebugMessage
@onready var hud = $UI/HUD
@onready var ui = $UI

var normal_upbeat_music_track = true

var main_menu_mode = false
var skip_auto_turrets = false
var use_auto_turrets_not_in_menu = false
var ambience_player

var timer
var wave_timer
var auto_turrets_timer

var fired_missile = preload("res://Scenes/SupportScenes/FiredMissile.tscn")

var controller_mouse_movement
var controller_upgrade_pos

func handle_main_menu():
	hud.hide()
	start_next_wave()
	
func _exit_tree():
	SoundManager.stop_music(1)
	stop_ambience()

func _ready():
	var map_data = GameData.config.maps[map_name]
	var scene_name = map_data.scene_name
	var map_path = "res://Scenes/Maps/" + scene_name + ".tscn"
	if not FileAccess.file_exists(map_path):
		GodotLogger.error("GameScene error loading map at %s" % map_path)
		queue_free()
		return
	else:
		GodotLogger.info("GameScene loading map at %s, main_menu_mode = %s" % [map_path, main_menu_mode])
	
	setup_timers()
	var map_instance = load(map_path).instantiate()
	add_child(map_instance)
	map_node = get_node(NodePath(map_instance.name))
	
	var base = map_node.get_node_or_null("Base")
	if base:
		base.connect("accept_click", Callable(self, "initiate_upgrade_mode").bind(base))
		base.connect("cancel_click", Callable(self, "cancel_upgrade_mode").bind(base))
	
	if "weather_effect" in map_data and map_data.weather_effect:
		var weather_effect_node = map_node.get_node_or_null("WeatherEffect")
		if weather_effect_node:
			GodotLogger.info("GameScene turning on weather effect")
			weather_effect_node.visible = true
			
	if "modulate" in map_data:
		map_node.modulate = map_data.modulate
		
	if "spawn_tank_mode" in map_data and map_data.spawn_tank_mode:
		var enemy_base = map_node.get_node_or_null("EnemyBase")
		if enemy_base:
			enemy_base.start_health_bar()
	
	current_money = GameData.config.maps[map_name].starting_money + GameData.config.settings.money_change
	
	if main_menu_mode:
		handle_main_menu()
	else:
		SoundManager.play_music(load("res://Assets/Audio/Music/2 Part Invention in B Minor.mp3"), 1, "BackgroundMusic")
		map_node.get_node("Base").update_health_bar(base_health)
		ui.setup_build_buttons(GameData.config.tower_data, get_node("UI/HUD/InfoBar/M/H/BuildBar"))
		setup_ambience()
	
	ui.update_money(current_money, true)
	
	Console.add_command("set_use_auto_turrets", on_set_use_auto_turrets, 1)
	Console.add_command("set_debug_tile_coords", on_set_debug_tile_coords, 1)
	Console.add_command("set_game_speed", on_set_game_speed, 1)
	Console.add_command("place_tower", on_place_tower, 3)
	Console.add_command("set_base_damage", on_set_base_damage, 1)
	Console.add_command("spawn_missiles", on_spawn_missiles, 1)
	Console.add_command("set_debug_resolution", on_set_debug_resolution, 1)
	
	get_tree().get_root().size_changed.connect(on_window_resized)
	
	if ControllerIcons._last_input_type != ControllerIcons.InputType.KEYBOARD_MOUSE:
		ui.get_node("HUD/Cursor").visible = true
		
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)
	
func setup_ambience():
	var map_data = GameData.config.maps[map_name]
	if "ambience" in map_data:
		var ambience = map_data.ambience
		GodotLogger.info("setting up ambience %s" % ambience)
		ambience_player = SoundManager.play_sound(load(ambience), "Ambience")
	
func stop_ambience():
	if ambience_player:
		ambience_player.stop()

func _on_input_type_changed(input_type):
	match input_type:
		ControllerIcons.InputType.KEYBOARD_MOUSE:
			ui.get_node("HUD/Cursor").visible = false
		ControllerIcons.InputType.CONTROLLER:
			if not build_mode and not upgrade_mode:
				ui.get_node("HUD/Cursor").visible = true

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_accept") and not DisplayServer.is_touchscreen_available():
		if build_mode:
			verify_and_build()
		if controller_upgrade_pos:
			controller_upgrade(controller_upgrade_pos)
	
	if not wave_timer.is_stopped():
		var time_between_waves = GameData.config.settings.time_between_waves
		var timer_percentage = (wave_timer.time_left / time_between_waves) * 100
		ui.update_next_wave_progress(timer_percentage)
	
func _unhandled_input(event):
	if event.is_action_released("ui_cancel"):
		if build_mode:
			cancel_build_mode()
		if upgrade_mode:
			cancel_upgrade_mode()
	elif event.is_action_released("ui_select"):
		if build_mode:
			cancel_build_mode()
		if upgrade_mode:
			cancel_upgrade_mode()
		ui.ui_bar_focus_toggle()
	elif build_mode and event is InputEventMouseMotion:
		update_tower_preview(event.global_position)
	elif debug_tile_coords and event is InputEventMouseMotion:
		update_debug_tile_coords(event.global_position)
	elif build_mode and event is InputEventJoypadMotion:
		var direction : Vector2
		var movement : Vector2
		
		direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		if abs(direction.x) == 1 and abs(direction.y) == 1:
			direction = direction.normalized()
		
		movement = 10 * direction
		
		if not controller_mouse_movement:
			controller_mouse_movement = get_viewport().get_mouse_position()
		
		if (movement):
			controller_mouse_movement += movement
			update_tower_preview(controller_mouse_movement)
	elif not build_mode and not upgrade_mode and event is InputEventJoypadMotion:
		var direction : Vector2
		var movement : Vector2
		
		direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		if abs(direction.x) == 1 and abs(direction.y) == 1:
			direction = direction.normalized()
		
		movement = 10 * direction
		
		if not controller_mouse_movement:
			controller_mouse_movement = get_viewport().get_mouse_position()
		if (movement):
			controller_mouse_movement += movement
			update_cursor(controller_mouse_movement)
	elif build_mode and event is InputEventScreenDrag:
		update_tower_preview(event.position)
	elif build_mode and event is InputEventScreenTouch and not event.pressed:
		if build_mode:
			verify_and_build()
		if upgrade_mode:
			cancel_upgrade_mode()
		
### build functions

func controller_upgrade(pos):
	controller_upgrade_pos = null
	for turret in map_node.get_node("Turrets").get_children():
		if turret.tile_pos == pos:
			initiate_upgrade_mode(turret)
			return
			
	var base_node = map_node.get_node_or_null("Base")
	if base_node:
		initiate_upgrade_mode(base_node)

func initiate_build_mode(tower_type):
	if upgrade_mode:
		cancel_upgrade_mode()
	if build_mode:
		cancel_build_mode()
	
	ui.get_node("HUD/Cursor").visible = false
	ui.ui_bar_focus_toggle(true)

	var cost = GameData.config.tower_data[tower_type].cost
	if (current_money - cost) < 0:
		GodotLogger.info("initiate_build_mode, not enough money")
		Helpers.play_error_sound()
		return

	Helpers.play_button_sound()
		
	build_type = tower_type
	build_mode = true
	var mouse_pos = get_global_mouse_position()
	set_tower_preview(build_type, mouse_pos)
	update_tower_preview(mouse_pos)
	ui.info_bar.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func update_cursor(cursor_position):
	var current_tile = map_node.get_node("TowerExclusion").local_to_map(cursor_position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_local(current_tile)
	ui.get_node("HUD/Cursor").position = Vector2(tile_position.x - 64, tile_position.y - 96)
	
	var tower_at_loc = map_node.get_node("TowerExclusion").get_cell_source_id(0, current_tile) == 6
	if tower_at_loc:
		ui.get_node("HUD/Cursor").set("theme_override_colors/font_color", Color.GREEN)
		controller_upgrade_pos = current_tile
	else:
		ui.get_node("HUD/Cursor").set("theme_override_colors/font_color", Color.WHITE)
		controller_upgrade_pos = null
	
func update_tower_preview(mouse_position = get_global_mouse_position()):
	var current_tile = map_node.get_node("TowerExclusion").local_to_map(mouse_position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_local(current_tile)
	
	var tower_valid = map_node.get_node("TowerExclusion").get_cell_source_id(0, current_tile) == -1
	var road_valid = map_node.get_node("Ground").get_cell_source_id(1, current_tile) == -1
	
	if (tower_valid and road_valid) or GameData.config.tower_data[build_type].build_anywhere:
		update_tower_preview_scene(tile_position, "a3a3e4")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		build_valid = false
		update_tower_preview_scene(tile_position, "f44336")

func update_debug_tile_coords(mouse_position):
	var current_tile = map_node.get_node("TowerExclusion").local_to_map(mouse_position)
	debug_message.text = str(current_tile)
	
func set_tower_preview(tower_type, mouse_position):
	var drag_tower = load("res://Scenes/Turrets/" + GameData.config.tower_data[tower_type].scene_name + ".tscn").instantiate()
	drag_tower.set_name("DragTower")
	drag_tower.modulate = Color("a3a3e4", 0.4)
	drag_tower.type = tower_type
	
	var range_texture = Sprite2D.new()
	range_texture.set_name("RangeTexture")
	range_texture.position = Vector2(0,0)
	var scaling = GameData.config.tower_data[tower_type].range / 100
	range_texture.scale = Vector2(scaling, scaling)
	var texture = load("res://Assets/UI/circle.svg")
	range_texture.texture = texture
	range_texture.modulate = Color("a3a3e4", 0.4)
	
	var control	= Node2D.new()
	control.add_child(drag_tower, true)
	control.add_child(range_texture, true)
	control.position = mouse_position
	control.set_name("TowerPreview")
	add_child(control, true)

func update_tower_preview_scene(new_position, color):
	get_node("TowerPreview").position = new_position
	if get_node("TowerPreview/DragTower").modulate != Color(color, 0.4):
		get_node("TowerPreview/DragTower").modulate = Color(color, 0.4)
		get_node("TowerPreview/RangeTexture").modulate = Color(color, 0.4)

func cancel_build_mode():
	ui.get_node("HUD/Cursor").set("theme_override_colors/font_color", Color.WHITE)
	build_mode = false
	build_valid = false
	var tower_preview = get_node_or_null("TowerPreview")
	if tower_preview:
		tower_preview.free()
	ui.info_bar.visible = true
	controller_mouse_movement = null
	if ControllerIcons._last_input_type == ControllerIcons.InputType.KEYBOARD_MOUSE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		ui.get_node("HUD/Cursor").visible = true
	
	controller_upgrade_pos = null
	
func verify_and_build():
	if build_valid:
		var new_tower = load("res://Scenes/Turrets/" + GameData.config.tower_data[build_type].scene_name + ".tscn").instantiate()
		new_tower.position = build_location
		new_tower.built = true
		new_tower.type = build_type
		new_tower.tile_pos = build_tile
		
		var map_data = GameData.config.maps[map_name]
		if "sonar_mode" in map_data and map_data.sonar_mode:
			new_tower.sonar_mode = true
		if "enemy_fire" in map_data and map_data.enemy_fire:
			new_tower.enemy_fire = true
		if upgrade_mode:
			new_tower.from_upgrade = true
		new_tower.category = GameData.config.tower_data[build_type]["category"]
		map_node.get_node("Turrets").add_child(new_tower, true)
		if new_tower.category != "Ability":
			map_node.get_node("TowerExclusion").set_cell(0, build_tile, 6, Vector2i(0,0), 1)
			new_tower.connect("accept_click", Callable(self, "initiate_upgrade_mode").bind(new_tower))
			new_tower.connect("cancel_click", Callable(self, "cancel_upgrade_mode").bind(new_tower))
		else:
			new_tower.connect("ability_complete", Callable(self, 'on_ability_complete'))
			
		if "cooldown" in GameData.config.tower_data[build_type]:
			ui.start_button_cooldown(build_type)
			
		GodotLogger.info("Building %s tower at %s, upgrade_mode = %s" % [build_type, build_location, upgrade_mode])
		
		if upgrade_mode:
			change_money(-(GameData.config.tower_data[build_type].upgrade_cost))
			if not main_menu_mode:
				Helpers.play_upgrade_sound()
				emit_signal("complete_achivement", "upgrade_tower")
		else:
			change_money(-(GameData.config.tower_data[build_type].cost))
			if GameData.config.tower_data[build_type].category != "Ability" and not main_menu_mode:
				Helpers.play_confirm_sound()
			
		cancel_build_mode()
		cancel_upgrade_mode()
		
func initiate_upgrade_mode(tower):
	if build_mode:
		return
		
	if upgrade_mode:
		cancel_upgrade_mode()
		
	ui.get_node("HUD/Cursor").visible = false
	Helpers.play_button_sound()
		
	upgrade_node = tower
	
	if tower.type != "Base" and not tower.get_node_or_null("RangeTexture"):
		var range_texture = Sprite2D.new()
		range_texture.set_name("RangeTexture")
		range_texture.position = Vector2(0,0)
		var scaling = GameData.config.tower_data[tower.type].range / 100
		range_texture.scale = Vector2(scaling, scaling)
		var texture = load("res://Assets/UI/circle.svg")
		range_texture.texture = texture
		range_texture.modulate = Color("a3a3e4", 0.5)
		tower.add_child(range_texture, true)
	
	var upgrades = GameData.config.tower_data[tower.type].upgrades
	if upgrades and upgrades.size():
		GodotLogger.info("Showing upgrades for tower type %s, upgrades = %s" % [tower.type, upgrades])
		upgrade_mode = true
		var map_data = GameData.config.maps[map_name]
		ui.show_upgrade_bar(upgrades, map_data)
	else:
		ui.hide_upgrade_bar()
	
func cancel_upgrade_mode(_tower = null):
	ui.get_node("HUD/Cursor").set("theme_override_colors/font_color", Color.WHITE)
	if upgrade_node and is_instance_valid(upgrade_node) and upgrade_node.get_node_or_null("RangeTexture"):
		upgrade_node.get_node_or_null("RangeTexture").queue_free()
	
	upgrade_mode = false
	upgrade_node = null
	ui.hide_upgrade_bar()
	ui.info_bar.visible = true
	controller_mouse_movement = null
	if ControllerIcons._last_input_type != ControllerIcons.InputType.KEYBOARD_MOUSE:
		ui.get_node("HUD/Cursor").visible = true
	
func upgrade_requested(upgrade_name):
	var tower_data = GameData.config.tower_data[upgrade_name]
	if tower_data.category == "Action":
		return action_requested(tower_data)
	var cost = tower_data.upgrade_cost
	if (current_money - cost) < 0:
		GodotLogger.info("upgrade_requested, not enough money")
		Helpers.play_error_sound()
		return
	
	build_type = upgrade_name
	build_valid = true
	
	var current_tile = map_node.get_node("TowerExclusion").local_to_map(upgrade_node.position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_local(current_tile)
	
	build_location = tile_position
	build_tile = current_tile
	
	upgrade_node.free()
	verify_and_build()
	
func action_requested(tower_data):
	if not upgrade_node:
		return cancel_upgrade_mode()
	
	var current_tower_type = upgrade_node.type
	var current_tower_cost = GameData.config.tower_data[current_tower_type].cost
	
	if tower_data.action == "sell":
		change_money(current_tower_cost)
		
		var current_tile = map_node.get_node("TowerExclusion").local_to_map(upgrade_node.position)
		map_node.get_node("TowerExclusion").erase_cell(0, current_tile)
		upgrade_node.free()
	elif tower_data.action == "repair":
		if current_tower_type == "Base":
			if base_health < 100:
				var base_health_percentage = base_health / 100
				var repair_cost = current_tower_cost * base_health_percentage
				
				if current_money >= repair_cost:
					change_money(-repair_cost)
					base_health = GameData.config.settings.starting_base_health
					map_node.get_node("Base").update_health_bar(base_health)
				else:
					GodotLogger.info("repair, not enough money")
					Helpers.play_error_sound()
		else:
			var current_health = upgrade_node.hp
			var full_tower_hp = GameData.config.tower_data[current_tower_type].hp
			if current_health < full_tower_hp:
				var health_percentage = current_health / full_tower_hp
				var repair_cost = current_tower_cost * health_percentage
				if current_money >= repair_cost:
					change_money(-repair_cost)
					upgrade_node.set_health(full_tower_hp)
				else:
					GodotLogger.info("repair, not enough money")
					Helpers.play_error_sound()
	elif tower_data.action == "spawn_tank":
		var map_data = GameData.config.maps[map_name]
		var spawn_tanks = map_data.spawn_tank
		var cost = map_data.spawn_tanks_cost
		if current_money >= cost:
			spawn_enemies(spawn_tanks, "BaseTankPath")
			change_money(-cost)
		else:
			GodotLogger.info("spawn tank, not enough money")
			Helpers.play_error_sound()
		
	cancel_upgrade_mode()

### wave functions

func start_next_wave():
	var wave_data = retrieve_wave_data()
	if wave_data:
		var should_auto_turrets = 'turrets' in wave_data and wave_data.turrets and not skip_auto_turrets
		if should_auto_turrets and not use_auto_turrets_not_in_menu and not main_menu_mode:
			should_auto_turrets = false
			
		GodotLogger.info("start_next_wave. %s, should_auto_turrets = %s" % [JSON.stringify(wave_data, "\t"), should_auto_turrets])
	
		if should_auto_turrets:
			GodotLogger.info("start_next_wave, auto creating turrets")
			timer.start(0.2); await timer.timeout
			process_auto_turrets(wave_data.turrets)

		timer.start(0.2); await timer.timeout
		boss_wave = "boss_wave" in wave_data and wave_data.boss_wave
		play_music('upbeat')
		update_wave_data(false)
		
		var custom_path = "Path3D"
		if 'custom_path' in wave_data and wave_data.custom_path:
			custom_path = wave_data.custom_path
		spawn_enemies(wave_data.enemies, custom_path)
	else:
		game_passed()
		
func game_passed():
	var health_percentage = base_health / 100
	var num_stars = (health_percentage * 100) / 20
	if num_stars < 1:
		num_stars = 1
			
	var map_data = GameData.config.maps[map_name]
	var radar_mode = "sonar_mode" in map_data and map_data.sonar_mode
	var result = {"ended": true, "num_stars": num_stars, "base_health": base_health, "current_money": current_money, "radar_mode": radar_mode}
	on_game_finished(result)
		
func on_game_finished(result):
	game_ended = true
	emit_signal("game_finished", result, map_name)
	play_music("upbeat")
	hud.visible = false
	map_node.get_node("Base").get_node("HealthBar").visible = false
	Engine.set_time_scale(1.0)
		
func process_auto_turrets(turrets):
	for turret in turrets:
		var current_tile = Vector2(turret.coords.x, turret.coords.y)
		var tile_position = map_node.get_node("TowerExclusion").map_to_local(current_tile)
		build_type = turret.type
		
		if 'upgrade' in turret and turret.upgrade:
			upgrade_mode = true
			upgrade_node = null
			for active_turret in map_node.get_node("Turrets").get_children():
				if active_turret.position.x == tile_position.x and active_turret.position.y == tile_position.y:
					upgrade_node = active_turret
					upgrade_requested(turret.type)
					break
		elif map_node.get_node("TowerExclusion").get_cell_source_id(0, current_tile) == -1 or GameData.config.tower_data[build_type].build_anywhere:
			build_valid = true
			build_location = tile_position
			build_tile = current_tile
			verify_and_build()
		
		auto_turrets_timer.start(turret.delay); await auto_turrets_timer.timeout

func retrieve_wave_data():
	if GameData.config.maps[map_name].waves.size() <= current_wave and main_menu_mode:
		skip_auto_turrets = true
		current_wave = 0

	if GameData.config.maps[map_name].waves.size() > current_wave:
		var wave_data = GameData.config.maps[map_name].waves[current_wave]
		current_wave += 1
		enemies_in_wave = wave_data.enemies.size()
		return wave_data
	
func spawn_enemies(wave_data, path_name):
	GodotLogger.info("spawn_enemies, path_name = %s" % path_name)
	var map_data = GameData.config.maps[map_name]
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i.base + ".tscn").instantiate()
		new_enemy.category = i.category
		new_enemy.hide_hp_bar = main_menu_mode
		if "base_tank" in i and i.base_tank:
			new_enemy.base_tank = true
		if "sonar_mode" in map_data and map_data.sonar_mode:
			new_enemy.visible = false
		if "enemy_fire" in map_data and map_data.enemy_fire:
			new_enemy.fire_mode = true
		new_enemy.connect("on_base_damage", Callable(self, 'on_base_damage'))
		new_enemy.connect("on_destroyed", Callable(self, 'on_enemy_destroyed'))
		
		map_node.get_node(path_name).add_child(new_enemy, true)
		timer.start(i.delay); await timer.timeout

func wave_completed():
	if GameData.config.maps[map_name].waves.size() <= current_wave:
		GodotLogger.info("wave_completed, game completed")
	elif game_ended:
		return GodotLogger.info("wave completed, not running next wave because game ended")
	else:
		GodotLogger.info("wave_completed, starting wait for next wave")
		play_music('idle')
		change_money(GameData.config.maps[map_name].waves[current_wave - 1].cost)
		
		var time_between_waves = GameData.config.settings.time_between_waves
		wave_timer.start(time_between_waves); await wave_timer.timeout

	start_next_wave()

## enemy functions

func on_base_damage(damage, is_from_base_tank, category):
	GodotLogger.debug("on_base_damage = %s base_tank = %s" % [damage, is_from_base_tank])
	if not is_from_base_tank:
		base_health -= damage
		update_wave_data()
	else:
		enemy_base_health -= damage
		map_node.get_node("EnemyBase").update_health_bar(enemy_base_health)
		var cost = GameData.config.enemy_data[category].cost
		change_money(cost)
	
	if game_ended:
		return
		
	if is_from_base_tank and enemy_base_health <= 0 and not main_menu_mode:
		game_passed()
	
	if base_health <= 0 and not main_menu_mode:
		var result = {"failed": true}
		on_game_finished(result)
	else:
		map_node.get_node("Base").update_health_bar(base_health)
		
func on_enemy_destroyed(category, tower_type):
	GodotLogger.debug("on_enemy_destroyed = %s, tower type = %s" % [category, tower_type])
	var cost = GameData.config.enemy_data[category].cost
	change_money(cost)
	update_wave_data()
	
	# updating achivements
	var tower_data = GameData.config.tower_data[tower_type]
	if tower_data.category == "Missile":
		emit_signal("complete_achivement", "destroy_missile")
	elif tower_data.category == "Ability":
		emit_signal("complete_achivement", "destroy_ability")
	elif tower_data.category == "Projectile":
		emit_signal("complete_achivement", "destroy_gun")
	elif "Laser" in tower_type:
		emit_signal("complete_achivement", "destroy_laser")
	
## ability functions

func on_ability_complete(enemies, type):
	GodotLogger.info("on_ability_complete type = %s, enemies = %s" % [type, enemies])
	if not enemies.size():
		change_money(GameData.config.tower_data[type].cost / 2)
	else:
		for enemy in enemies:
			enemy.on_hit(GameData.config.tower_data[type]["damage"], GameData.config.tower_data[type]["sound"], type)
	
## hud functions
	
func update_wave_data(subtract = true):
	if subtract:
		enemies_in_wave -= 1
	
	ui.update_wave_data(enemies_in_wave, current_wave)
	
	if subtract and enemies_in_wave <= 0:
		wave_completed()
		ui.wave_completed()
		
func change_money(moneyDelta):
	GodotLogger.debug("change_money = %s" % moneyDelta)
	current_money = current_money + moneyDelta
	ui.update_money(current_money, false)
	
func play_music(music_name):
	if main_menu_mode:
		return
	GodotLogger.debug("play_music = %s" % music_name)
	if music_name == 'upbeat':
		if game_ended:
			normal_upbeat_music_track = false
			SoundManager.play_music(load("res://Assets/Audio/Music/Zander Noriega - School of Quirks.mp3"), 2)
		elif boss_wave:
			normal_upbeat_music_track = false
			SoundManager.play_music(load("res://Assets/Audio/Music/Orbital Colossus.mp3"), 1)
		elif base_health <= 50 and normal_upbeat_music_track:
			normal_upbeat_music_track = false
			SoundManager.play_music(load("res://Assets/Audio/Music/n-Dimensions (Main Theme).mp3"), 1)
		elif base_health > 50 and not normal_upbeat_music_track:
			normal_upbeat_music_track = true
			SoundManager.play_music(load("res://Assets/Audio/Music/Tactical Pursuit.mp3"), 1)
		else:
			SoundManager.play_music(load("res://Assets/Audio/Music/Tactical Pursuit.mp3"), 1)
	elif music_name == 'idle':
		SoundManager.play_music(load("res://Assets/Audio/Music/2 Part Invention in B Minor.mp3"), 1)

func setup_timers():
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	
	wave_timer = Timer.new()
	wave_timer.one_shot = true
	wave_timer.autostart = false
	add_child(wave_timer)
	
	auto_turrets_timer = Timer.new()
	auto_turrets_timer.one_shot = true
	auto_turrets_timer.autostart = false
	add_child(auto_turrets_timer)

# console commands related to game logic

func on_set_use_auto_turrets(new_value):
	if not new_value:
		Console.print_line("set_use_auto_turrets <boolean>")
		return
		
	if new_value == "true":
		use_auto_turrets_not_in_menu = true
	else:
		use_auto_turrets_not_in_menu = false
		
	GodotLogger.info("Setting use_auto_turrets_not_in_menu to %s" % use_auto_turrets_not_in_menu)

func on_set_debug_tile_coords(new_value):
	if not new_value:
		Console.print_line("set_debug_tile_coords <boolean>")
		return
		
	if new_value == "true":
		debug_tile_coords = true
	else:
		debug_tile_coords = false
		
	debug_message.visible = debug_tile_coords
		
	GodotLogger.info("Setting debug_tile_coords to %s" % debug_tile_coords)
	
func on_set_debug_resolution(new_value):
	if not new_value:
		Console.print_line("set_debug_resolution <boolean>")
		return
		
	if new_value == "true":
		debug_resolution = true
	else:
		debug_resolution = false
		
	debug_message.visible = debug_resolution
		
	GodotLogger.info("Setting debug_resolution to %s" % debug_resolution)
	
func on_window_resized():
	if not debug_resolution:
		return
	var window_size = DisplayServer.window_get_size()
	debug_message.text = "%s" % window_size

func on_set_game_speed(speed_str):
	if not speed_str:
		Console.print_line("set_game_speed <speed>, speed should be number from 0-x; ex = 1.5")
		return
	GodotLogger.info("Setting speed to %s" % speed_str)
	Engine.set_time_scale(float(speed_str))

func on_place_tower(tower_type, x, y):
	if not tower_type or not x or not y:
		Console.print_line("place_tower <tower_type> <x> <y>")
		return
		
	if not tower_type in GameData.config.tower_data:
		Console.print_line("place_tower <tower_type> <x> <y>, tower_type is invalid")
		return
		
	var current_tile = Vector2(float(x), float(y))
	if map_node.get_node("TowerExclusion").get_cell_source_id(0, current_tile) == -1 or GameData.config.tower_data[build_type].build_anywhere:
		var tile_position = map_node.get_node("TowerExclusion").map_to_local(current_tile)
		cancel_build_mode()
		build_type = tower_type
		build_valid = true
		build_tile = current_tile
		build_location = tile_position
		verify_and_build()
	else:
		Console.print_line("place_tower <tower_type> <x> <y>, position was invalid")
		
func on_set_base_damage(base_damage):
	if not base_damage:
		Console.print_line("set_base_damage <float>")
		return
	
	on_base_damage(float(base_damage), false, null)	
	
func on_spawn_missiles(missile_count_str):
	if not missile_count_str:
		Console.print_line("spawn_missiles <int>")
		return
	
	var mouse_pos = get_global_mouse_position()
	var missile_count = int(missile_count_str)
	for i in range(0, missile_count):
		randomize()
		var x_pos = mouse_pos.x + randi() % 100
		randomize()
		var y_pos = mouse_pos.y + randi() % 100
		var new_missile = fired_missile.instantiate()
		new_missile.position = Vector2(x_pos, y_pos)
		new_missile.connect("missile_impact", Callable(self, "missile_impacted"))
		add_child(new_missile)
		timer.start(0.1); await timer.timeout

func missile_impacted(impact_enemy):
	if not is_instance_valid(impact_enemy):
		impact_enemy = null
		return

	if impact_enemy:
		var type = "MissileT1"
		impact_enemy.on_hit(GameData.config.tower_data[type]["damage"], GameData.config.tower_data[type]["sound"], type)
