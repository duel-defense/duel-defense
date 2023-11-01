extends WindowPopup

@onready var level_container = $MarginContainer/ScrollContainer/FlowContainer
var level_scene = preload("res://Scenes/UIScenes/LevelSelectLevel.tscn")

signal level_requested(map_key)

# Called when the node enters the scene tree for the first time.
func _ready():
	populate_levels()

func open():
	populate_levels()
	visible = true
	
func populate_levels():
	for level in level_container.get_children():
		level.queue_free()
	
	var maps = GameData.config.maps
	for map_key in maps:
		var map = maps[map_key]
		
		var maps_user_data = {}
		if map_key in GameData.config.maps_user_data:
			maps_user_data = GameData.config.maps_user_data[map_key]
			
		var new_level_scene = level_scene.instantiate()
		new_level_scene.level_name = map_key
		if "num_stars" in maps_user_data:
			new_level_scene.num_stars = maps_user_data.num_stars
		level_container.add_child(new_level_scene)
		new_level_scene.connect("pressed", Callable(self, "level_pressed").bind(map_key, map))
		
func level_pressed(map_key, _map):
	GodotLogger.info("level_pressed %s" % map_key)
	level_requested.emit(map_key)

func _on_close_requested():
	visible = false
