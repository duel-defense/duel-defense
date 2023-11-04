extends Abilties

var speed = 200
var velocity = Vector2(speed, 0)
var acceleration = Vector2.ZERO
var timer

var fired_missile = preload("res://Scenes/SupportScenes/FiredMissile.tscn")

@export var muzzle: Node2D
@export var tower_type = "MissileT1"

func _physics_process(delta):
	if icon_mode or not built:
		return
		
	if not built_detected and built:
		built_detected = true
		run_ability()
		custom_run_ability()
		
	velocity += acceleration * delta
	rotation = velocity.angle()
	position += velocity * delta

func _on_visible_on_screen_enabler_2d_screen_exited():
	if icon_mode or not built:
		return
	GodotLogger.debug("jet off screen, removing")
	queue_free()
	
func custom_run_ability():
	global_transform = transform
	velocity = transform.x * speed
	
	timer = Timer.new()
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	
	fire_missiles()
	
func fire_missiles():
	var pos = muzzle.position
	var missile_count = GameData.config.tower_data[type].damage
	for i in range(0, missile_count):
		randomize()
		var x_pos = pos.x + randi() % 20
		randomize()
		var y_pos = pos.y + randi() % 20
		var new_missile = fired_missile.instantiate()
		new_missile.position = Vector2(x_pos, y_pos)
		new_missile.connect("missile_impact", Callable(self, "missile_impacted"))
		muzzle.add_child(new_missile)
		timer.start(0.1); await timer.timeout
		
	timer.start(GameData.config.tower_data[type].rof); await timer.timeout
	fire_missiles()
	
func missile_impacted(impact_enemy):
	if not is_instance_valid(impact_enemy):
		impact_enemy = null
		return

	if impact_enemy:
		if sonar_mode:
			impact_enemy.seen()
		impact_enemy.on_hit(GameData.config.tower_data[tower_type]["damage"], GameData.config.tower_data[tower_type]["sound"], tower_type)
