extends Button

@export var level_name: String
@export var num_stars: int

@onready var name_node = $VBoxContainer/Name
@onready var stars_container_node = $VBoxContainer/StarsContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	name_node.text = level_name
	if num_stars:
		for node in stars_container_node.get_children():
			stars_container_node.remove_child(node)
			node.queue_free()
			
		for star in num_stars:
			var icon_script = load("res://addons/material-design-icons/nodes/MaterialIcon.gd")
			var star_icon = Label.new()
			star_icon.set_script(icon_script)
			star_icon.icon_name = "star"
			stars_container_node.add_child(star_icon)
		
		stars_container_node.visible = true
