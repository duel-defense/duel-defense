extends Button

@export var level_name: String
@export var num_stars: int
@export var completion_time: float

@onready var name_node = $VBoxContainer/Name
@onready var stars_container_node = $VBoxContainer/StarsContainer
@onready var completion_time_node = $VBoxContainer/CompletionTime

# Called when the node enters the scene tree for the first time.
func _ready():
	name_node.text = level_name
