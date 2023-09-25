extends "res://Scenes/UIScenes/WindowPopup.gd"

const FS = preload("res://CommonScripts/FS.gd")
@onready var fs = FS.new()
var licenses_path = "res://Assets/AssetLicenses/"

func _ready():
	process_license_files()
	
func process_license_files():
	var license_files = fs.list_files_in_directory(licenses_path)
	for license_file_name in license_files:
		var license_path = licenses_path + '/' + license_file_name
		var license_content = fs.read_file(license_path)
		add_text(license_content)
		
	var godot_license = "Godot License\n" + Engine.get_license_text()
	add_text(godot_license)

func add_text(text):
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	
	add_to_scroll_container(label)
	add_to_scroll_container(HSeparator.new())

func _on_close_requested():
	visible = false
