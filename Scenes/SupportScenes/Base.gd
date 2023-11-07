extends Node2D

signal accept_click()
signal cancel_click()

@onready var hp_bar = $HealthBar
@onready var sprite = $Sprite
@onready var impact_area = $Impact
@onready var clickable_area = $ClickableArea

var explosion = preload("res://Scenes/Effects/Explosion.tscn")

@export var show_health_bar = true
@export var enemy_base = false
@export var current_health = 100

var type = "Base"

func _ready():
	if not show_health_bar:
		hp_bar.visible = false
	if enemy_base:
		var texture = load("res://Assets/Environment/Props/Cylindrical Tank A - Size 1 - Gray.png")
		sprite.texture = texture
		clickable_area.visible = false
		
func start_health_bar():
	hp_bar.visible = true
	show_health_bar = true

func update_health_bar(base_health):
	var tween = get_tree().create_tween()
	tween.tween_property(hp_bar, 'value', base_health, 0.1)
	explosion_animation(base_health)
	if base_health >= 60:
		hp_bar.set_tint_progress("4eff15")
	elif base_health <= 60 and base_health >= 25:
		hp_bar.set_tint_progress("e1be32")
	else:
		hp_bar.set_tint_progress("e11e1e")
		
	current_health = base_health
		
func explosion_animation(new_health):
	if new_health >= current_health:
		return
	
	randomize()
	var x_pos = randi() % 31
	randomize()
	var y_pos = randi() % 31
	var explosion_location = Vector2(x_pos, y_pos)
		
	var new_explosion = explosion.instantiate()
	new_explosion.position = explosion_location
	impact_area.add_child(new_explosion)
	
func accept_clicked():
	if not enemy_base:
		emit_signal('accept_click')
	
func cancel_clicked():
	if not enemy_base:
		emit_signal('cancel_click')
