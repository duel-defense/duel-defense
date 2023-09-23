extends Area2D

signal missile_impact(enemy, missle)

var speed = 350
var velocity = Vector2(speed, 0)
var acceleration = Vector2.ZERO

func start(_transform):
	global_transform = _transform
	velocity = transform.y * speed

func _physics_process(delta):
	velocity += acceleration * delta
	rotation = velocity.angle()
	position += velocity * delta

func _on_Area2D_body_entered(body):
	var parent = body.get_parent()
	if parent.is_in_group("enemy"):
		emit_signal("missile_impact", parent)
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited():
	GodotLogger.debug("missile off screen, removing")
	queue_free()
