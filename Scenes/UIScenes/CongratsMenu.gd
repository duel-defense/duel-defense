extends Control

@export var result = {}

@onready var congrats_text = $Container/VBoxContainer/CongratsText
@onready var continue_button = $Container/VBoxContainer/Continue
@onready var stars_container_node = $Container/VBoxContainer/StarsContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	GodotLogger.info("CongratsMenu received result %s" % JSON.stringify(result))
	
	if "failed" in result and result.failed:
		continue_button.visible = false
		congrats_text.text = "Game Over!"
		
	if "num_stars" in result:
		for node in stars_container_node.get_children():
			stars_container_node.remove_child(node)
			node.queue_free()
		
		var num_stars = result.num_stars
		for star in num_stars:
			var icon_script = load("res://addons/material-design-icons/nodes/MaterialIcon.gd")
			var icon = Label.new()
			icon.set_script(icon_script)
			icon.icon_name = "star"
			stars_container_node.add_child(icon)
		
		stars_container_node.visible = true
