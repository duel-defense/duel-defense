extends AnimatedSprite2D

signal hide_sprite()

var hide_sprite_called = false

@export var hide_at_frame = 5

func _ready():
	play()

func _on_ProjectileImpact_animation_finished():
	self.visible = false

func _on_AudioStreamPlayer_finished():
	queue_free()

func _on_frame_changed():
	if not hide_sprite_called and frame >= hide_at_frame:
		emit_signal('hide_sprite')
		hide_sprite_called = true
