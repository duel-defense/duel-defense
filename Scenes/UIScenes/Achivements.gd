extends WindowPopup

var achivement_scene = preload("res://Scenes/UIScenes/AchivementItem.tscn")
@onready var achivement_container = $MarginContainer/ScrollContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	populate_achivements()

func open():
	populate_achivements()
	visible = true
	
func populate_achivements():
	for item in achivement_container.get_children():
		item.queue_free()
		
	var achivements = GameData.config.achivements
	var completed_achivements = GameData.config.user_achivements
	for achivement in achivements:
		var completed = achivement.key in completed_achivements and completed_achivements[achivement.key]
		var new_achivement_scene = achivement_scene.instantiate()
		new_achivement_scene.achivement_is_locked = !completed
		new_achivement_scene.achivement_label = achivement.label
		achivement_container.add_child(new_achivement_scene)

func _on_close_requested():
	visible = false
