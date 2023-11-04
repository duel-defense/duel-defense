extends Control

@export var achivement_is_locked = true
@export var achivement_label = ""

@onready var locked_icon = $HBoxContainer/Locked
@onready var unlocked_icon = $HBoxContainer/Unlocked
@onready var label_node = $HBoxContainer/Label

func _ready():
	if achivement_is_locked:
		locked_icon.visible = true
		unlocked_icon.visible = false
	else:
		locked_icon.visible = false
		unlocked_icon.visible = true
		
	label_node.text = achivement_label
