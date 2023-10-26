extends PathFollow2D

signal on_base_damage(damage)
signal on_destroyed()

var category
var speed
var hp
var base_damage
var destroyed
var hide_hp_bar = false
var timer

@onready var health_bar = $Sprite2D/HealthBar
@onready var impact_area = $Impact
@onready var sprite = $Sprite2D
@onready var sprite_turret = $Sprite2D/Turret
var projectile_impact = preload("res://Scenes/Effects/ProjectileImpact.tscn")
var explosion = preload("res://Scenes/Effects/Explosion.tscn")
var impact_sound = preload("res://Assets/Audio/Sounds/impactMining_000.ogg")
var sound_manager

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	
	var tmp_enemy_data = GameData.config.enemy_data[category]
	speed = tmp_enemy_data.speed
	hp = tmp_enemy_data.hp
	base_damage = tmp_enemy_data.damage
	
	if "sprite_path" in tmp_enemy_data:
		var sprite_path = tmp_enemy_data.sprite_path
		var texture = load(sprite_path)
		sprite.texture = texture
	
	if "turret_sprite_path" in tmp_enemy_data:
		var turret_texture = load(tmp_enemy_data.turret_sprite_path)
		sprite_turret.texture = turret_texture
		
	if "engine_trail_x" in tmp_enemy_data:
		set_trail_property("position_x", tmp_enemy_data.engine_trail_x)
		
	if "engine_trail_max_points" in tmp_enemy_data:
		set_trail_property("max_points", tmp_enemy_data.engine_trail_max_points)
		
	if "engine_trail_width" in tmp_enemy_data:
		set_trail_property("width", tmp_enemy_data.engine_trail_width)
	
	health_bar.max_value = hp
	health_bar.value = hp
	health_bar.set_as_top_level(true)
	
	if hide_hp_bar:
		health_bar.visible = false
	
	sound_manager = SoundManager.play_sound(load("res://Assets/Audio/Sounds/engine_heavy_" + tmp_enemy_data.move_sound + "_loop.ogg"))
	sound_manager.set_volume_db(linear_to_db(0.2))

func set_trail_property(property_name, value):
	for child in get_children():
		if child.is_in_group("trail"):
			if property_name == "position_x":
				child.position.x = value
			else:
				child[property_name] = value

func _physics_process(delta):
	if progress_ratio == 1.0:
		emit_signal("on_base_damage", base_damage)
		queue_free()
	move(delta)
	
func move(delta):
	set_progress(get_progress() + speed * delta)
	health_bar.set_position(position - Vector2(30, 30))

func on_hit(damage, has_sound):
	impact(has_sound)
	hp -= damage
	health_bar.value = hp
	if hp <= 0:
		on_destroy()
		
func impact(has_sound):
	randomize()
	var x_pos = randi() % 31
	randomize()
	var y_pos = randi() % 31
	var impact_location = Vector2(x_pos, y_pos)
	var new_impact = projectile_impact.instantiate()
	new_impact.position = impact_location
	impact_area.add_child(new_impact)
	
	if has_sound:
		var k_body = get_node_or_null("CharacterBody2D//ImpactEffects")
		if k_body:
			SoundManager.play_sound(impact_sound)
		
func on_destroy():
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
		for child in get_children():
			if child.is_in_group("trail"):
				child.visible = false
		new_explosion.connect('animation_finished', Callable(self, 'destroy_complete'))
		new_explosion.connect('hide_sprite', Callable(self, 'hide_sprite'))
		impact_area.add_child(new_explosion)
		
		sound_manager.stop()
	
func destroy_complete():
	if not destroyed:
		destroyed = true
		emit_signal("on_destroyed", category)
		self.queue_free()
		
func hide_sprite():
	sprite.visible = false
	
func _exit_tree():
	if sound_manager:
		sound_manager.stop()
