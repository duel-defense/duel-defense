extends Node2D

class_name Abilties

signal ability_complete(enemies, type)

var type
var category
var built
var built_detected
var enemy_array = []
var icon_mode

@onready var collision_2d = get_node("Range/CollisionShape2D")
@export var sprite: Node2D
@export var animated_sprite: Node2D

func _ready():
	if type:
		collision_2d.get_shape().radius = 0.5 * GameData.config.tower_data[type]["range"]
		
func _physics_process(_delta):
	if not built_detected and built:
		built_detected = true
		run_ability()
		
func run_ability():
	if sprite:
		sprite.visible = false
	animated_sprite.visible = true
	animated_sprite.play()
	get_node("Range/CollisionShape2D/AudioStreamPlayer2D").play()
	
func _on_AudioStreamPlayer2D_finished():
	queue_free()

func _on_AnimatedSprite_animation_finished():
	get_node("Range/AnimatedSprite2D").visible = false
	emit_signal('ability_complete', enemy_array, type)

func _on_Range_body_entered(body):
	if built:
		enemy_array.append(body.get_parent())

func _on_Range_body_exited(body):
	if built:
		enemy_array.erase(body.get_parent())

