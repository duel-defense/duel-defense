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

@onready var health_bar = get_node("HealthBar")
@onready var impact_area = get_node("Impact")
@onready var sound_effects = get_node("CharacterBody2D/SoundEffects")
@onready var sprite = get_node("Sprite2D")
var projectile_impact = preload("res://Scenes/Effects/ProjectileImpact.tscn")
var explosion = preload("res://Scenes/Effects/Explosion.tscn")
var impact_sound = preload("res://Assets/Audio/Sounds/impactMining_000.ogg")

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
		sprite.get_node("Turret").texture = turret_texture
	
	health_bar.max_value = hp
	health_bar.value = hp
	health_bar.set_as_top_level(true)
	
	if hide_hp_bar:
		health_bar.visible = false
	
	sound_effects.stream = load("res://Assets/Audio/Sounds/engine_heavy_" + tmp_enemy_data.move_sound + "_loop.ogg")

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
			var children_count = k_body.get_children().size()
			if children_count <= 3:
				var tmp_stream = AudioStreamPlayer2D.new()
				tmp_stream.stream = impact_sound
				tmp_stream.stream.loop = false
				tmp_stream.volume_db = 4
				tmp_stream.bus = "SoundEffects"
				tmp_stream.connect('finished', Callable(self, 'impact_stream_finished').bind(tmp_stream))
				k_body.add_child(tmp_stream)
				tmp_stream.play()
		
func impact_stream_finished(node):
	node.queue_free()
		
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
		new_explosion.connect('animation_finished', Callable(self, 'destroy_complete'))
		new_explosion.connect('hide_sprite', Callable(self, 'hide_sprite'))
		impact_area.add_child(new_explosion)
	
func destroy_complete():
	if not destroyed:
		destroyed = true
		emit_signal("on_destroyed", category)
		self.queue_free()
		
func hide_sprite():
	sprite.visible = false
