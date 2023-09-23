# Casts a laser along a raycast, emitting particles on the impact point.
# Use `is_casting` to make the laser fire and stop.
# You can attach it to a weapon or a ship; the laser will rotate with its parent.
extends RayCast2D

signal collided()

# Speed at which the laser extends when first fired, in pixels per seconds.
@export var cast_speed := 7000.0
# Maximum length of the laser in pixels.
@export var max_length := 1400.0
# Base duration of the tween animation in seconds.
@export var growth_time := 0.1

# If `true`, the laser is firing.
# It plays appearing and disappearing animations when it's not animating.
# See `appear()` and `disappear()` for more information.
var is_casting := false: set = set_is_casting

@onready var fill := $FillLine2D
var tween
@onready var casting_particles := $CastingParticles2D
@onready var collision_particles := $CollisionParticles2D
@onready var beam_particles := $BeamParticles2D

@onready var line_width: float = fill.width

@onready var sound_effects = get_node("SoundEffects")

func fire():
	set_is_casting(true)
	
func cease_fire():
	set_is_casting(false)

func _ready() -> void:
	set_physics_process(false)
	fill.points[1] = Vector2.ZERO


func _physics_process(delta: float) -> void:
	target_position = (target_position + Vector2.RIGHT * cast_speed * delta).limit_length(max_length)
	cast_beam()


func set_is_casting(cast: bool) -> void:
	if cast and not is_casting:
		sound_effects.volume_db = 1
		sound_effects.play()
		get_parent().get_parent().play()
	elif not cast and is_casting:
		var sound_tween = get_tree().create_tween()
		sound_tween.tween_property(sound_effects, 'volume_db', -100, 1.5)
		get_parent().get_parent().stop()
	
	is_casting = cast

	if is_casting:
		target_position = Vector2.ZERO
		fill.points[1] = target_position
		appear()
	else:
		collision_particles.emitting = false
		disappear()

	set_physics_process(is_casting)
	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting


# Controls the emission of particles and extends the Line2D to `cast_to` or the ray's 
# collision point, whichever is closest.
func cast_beam() -> void:
	var cast_point := target_position

	force_raycast_update()
	collision_particles.emitting = is_colliding()

	if is_colliding():
		cast_point = to_local(get_collision_point())
		collision_particles.global_rotation = get_collision_normal().angle()
		collision_particles.position = cast_point
		
		var collider_parent = get_collider().get_parent()
		emit_signal("collided", collider_parent)
		

	fill.points[1] = cast_point
	beam_particles.position = cast_point * 0.5
	beam_particles.process_material.emission_box_extents.x = cast_point.length() * 0.5


func appear() -> void:
	if tween and tween.is_running():
		tween.kill()
		tween = null
	
	tween = get_tree().create_tween()
	tween.tween_property(fill, 'width', line_width, growth_time * 2)


func disappear() -> void:
	if tween and tween.is_running():
		tween.kill()
		tween = null
	
	tween = get_tree().create_tween()
	tween.tween_property(fill, 'width', 0, growth_time)


func _on_soundeffect_tween_completed(_object, _key):
	get_node("SoundEffects").stop()
