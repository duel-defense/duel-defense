extends Control

@export var result = {}

@onready var congrats_text = $Container/VBoxContainer/CongratsText
@onready var continue_button = $Container/VBoxContainer/Continue

# Called when the node enters the scene tree for the first time.
func _ready():
	GodotLogger.info("CongratsMenu received result %s" % JSON.stringify(result))
	
	if "failed" in result and result.failed:
		continue_button.visible = false
		congrats_text.text = "Game Over!"
