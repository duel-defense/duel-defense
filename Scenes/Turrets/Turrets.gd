extends Node2D

class_name Turrets

signal accept_click()
signal cancel_click()

var type
var category
var enemy_array = []
var built = false
var enemy
var turret_ready = true
var from_upgrade
var icon_mode
var tile_pos
var sonar_mode = false
var hp
var destroyed
var destroy_called
var enemy_fire

var timer
var waiting_for_anim = false
var missile_timer
var missile_reloading_timer

var fired_missile = preload("res://Scenes/SupportScenes/FiredMissile.tscn")
var projectile_impact = preload("res://Scenes/Effects/ProjectileImpact.tscn")
var explosion = preload("res://Scenes/Effects/Explosion.tscn")
var impact_sound = preload("res://Assets/Audio/Sounds/impactMining_000.ogg")

@onready var turret = $Turret
@onready var collision_2d = $Range/CollisionShape2D
@onready var sonar = $Sonar
@onready var impact_area = $Impact
@onready var health_bar = $Base/HealthBar

func _ready():
	if type:
		var turret_data = GameData.config.tower_data[type]
		hp = turret_data.hp
		health_bar.max_value = hp
		health_bar.value = hp
		
		if "spritesheet_path" in turret_data:
			var spritesheet_path = turret_data.spritesheet_path
			var sprite_size = Vector2(turret_data.sprite_size_width, turret_data.sprite_size_height)
			var fps = turret_data.fps
			var sprite_frames = SpriteManager.convert_sprite_sheet_to_sprite_frames(spritesheet_path, sprite_size, fps)
			turret.sprite_frames = sprite_frames
	
	if icon_mode:
		return
	setup_timers()
	
	if built and sonar_mode:
		sonar.visible = true
		var tower_range = GameData.config.tower_data[type].range
		sonar.size = Vector2(tower_range, tower_range)
		sonar.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_CENTER, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE)
	
	if type and built and enemy_fire:
		var shield = get_node_or_null("Shield")
		if shield:
			shield.visible = true
	
	if type:
		collision_2d.get_shape().radius = 0.5 * GameData.config.tower_data[type]["range"]

func set_health(new_health):
	hp = new_health
	health_bar.value = hp

func _physics_process(_delta):
	if icon_mode:
		return
	if enemy_array.size() != 0 and built:
		select_enemy()
		
		var shouldTurn = true
		if get_node_or_null("AnimationPlayer") and get_node_or_null("AnimationPlayer").is_playing():
			shouldTurn = false

		if shouldTurn:
			turn()
		if turret_ready:
			fire()
	else:
		cease_fire_custom()
		enemy = null

func turn():
	if not is_instance_valid(enemy):
		enemy = null
		return
	
	turret.look_at(enemy.position)

func select_enemy():
	var enemy_progress_array = []
	for i in enemy_array:
		if not is_instance_valid(i):
			enemy_array.erase(i)
			continue
		enemy_progress_array.append(i.h_offset)
		var max_offset = enemy_progress_array.max() #close to path
		var enemy_index = enemy_progress_array.find(max_offset)
		enemy = enemy_array[enemy_index]
		if sonar_mode:
			enemy.seen()
		
func fire():
	if not timer.is_stopped():
		return
		
	if waiting_for_anim:
		return
	
	turret_ready = false
	if category == "Custom":
		timer.start(GameData.config.tower_data[type]["rof"]); await timer.timeout
		fire_custom()
	elif category == "Projectile":
		timer.start(GameData.config.tower_data[type]["rof"]); await timer.timeout
		fire_gun()
	elif category == "Missile":
		timer.start(GameData.config.tower_data[type]["rof"] / 2); await timer.timeout
		fire_missile()
	turret_ready = true
	
func fire_gun():
	if "play" in turret:
		waiting_for_anim = true
		turret.frame = 0
		turret.play()
	else:
		get_node("AnimationPlayer").play("Fire")
	if enemy:
		enemy.on_hit(GameData.config.tower_data[type]["damage"], GameData.config.tower_data[type]["sound"], type)
	
func on_hit(damage, has_sound, tower_type):
	impact(has_sound)
	hp -= damage
	health_bar.value = hp
	health_bar.visible = true
	if hp <= 0 and not destroy_called:
		on_destroy(tower_type)
		
func on_destroy(tower_type):
	destroy_called = true
	var k_body = get_node_or_null("CharacterBody2D")
	if k_body:
		k_body.queue_free()
		timer.start(0.2); await timer.timeout
		
		randomize()
		var x_pos = randi() % 31
		randomize()
		var y_pos = randi() % 31
		var explosion_location = Vector2(x_pos, y_pos)
		
		var new_explosion = explosion.instantiate()
		new_explosion.position = explosion_location
		health_bar.visible = false
		new_explosion.connect('animation_finished', Callable(self, 'destroy_complete').bind(tower_type))
		new_explosion.connect('hide_sprite', Callable(self, 'hide_sprite'))
		impact_area.add_child(new_explosion)
		
func destroy_complete(tower_type):
	if not destroyed:
		destroyed = true
		emit_signal("on_destroyed", category, tower_type)
		self.queue_free()
		
func hide_sprite():
	$Base.visible = false
	$Turret.visible = false
	sonar.visible = false
		
func impact(has_sound):
	if impact_area.get_child_count() > 3:
		return
	randomize()
	var x_pos = randi() % 31
	randomize()
	var y_pos = randi() % 31
	var impact_location = Vector2(x_pos, y_pos)
	var new_impact = projectile_impact.instantiate()
	new_impact.position = impact_location
	impact_area.add_child(new_impact)
	if has_sound:
		SoundManager.play_sound(impact_sound)

func fire_gun_finished():
	waiting_for_anim = false
	
func fire_custom():
	for i in turret.get_children():
		if i.get_node_or_null("Fire"):
			i.get_node_or_null("Fire").fire()
			
func cease_fire_custom():
	if not turret:
		return
	for i in turret.get_children():
		if i.get_node_or_null("Fire"):
			i.get_node_or_null("Fire").cease_fire()

func fire_missile():
	var picked_missile
	var missiles = []
	for i in turret.get_children():
		if i.is_in_group("missile"):
			missiles.append(i)

	var reloading = false
	if not missiles[missiles.size() - 1].visible:
		reloading = true
	
	if reloading:
		missile_reloading_timer.start(GameData.config.tower_data[type]["rof"]); await missile_reloading_timer.timeout
		return
		
	for i in missiles:
		if i.visible:
			picked_missile = i
			i.visible = false
			var new_missile = fired_missile.instantiate()
			new_missile.position = i.position
			new_missile.connect("missile_impact", Callable(self, "missile_impacted"))
			turret.add_child(new_missile)
			break
		
	missile_timer.start(GameData.config.tower_data[type]["rof"]); await missile_timer.timeout
	if picked_missile and is_instance_valid(picked_missile):
		picked_missile.visible = true
	
func missile_impacted(impact_enemy):
	if not is_instance_valid(impact_enemy):
		impact_enemy = null
		return

	if impact_enemy:
		impact_enemy.on_hit(GameData.config.tower_data[type]["damage"], GameData.config.tower_data[type]["sound"], type)

func _on_Range_body_entered(body):
	if built:
		var found_enemy = body.get_parent()
		enemy_array.append(found_enemy)
		if sonar_mode:
			found_enemy.seen()

func _on_Range_body_exited(body):
	if built:
		var found_enemy = body.get_parent()
		enemy_array.erase(found_enemy)
		if sonar_mode:
			found_enemy.not_seen()
		
func _on_Fire_collided(fire_enemy):
	if not is_instance_valid(fire_enemy):
		return
	fire_enemy.on_hit(GameData.config.tower_data[type]["damage"], GameData.config.tower_data[type]["sound"], type)

func accept_clicked():
	if built:
		emit_signal('accept_click')
	
func cancel_clicked():
	if built:
		emit_signal('cancel_click')
		
func setup_timers():
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	
	missile_timer = Timer.new()
	missile_timer.one_shot = true
	missile_timer.autostart = false
	add_child(missile_timer)
	
	missile_reloading_timer = Timer.new()
	missile_reloading_timer.one_shot = true
	missile_reloading_timer.autostart = false
	add_child(missile_reloading_timer)
