extends WindowPopup

const FS = preload("res://CommonScripts/FS.gd")
@onready var fs = FS.new()
var licenses_path = "res://Assets/AssetLicenses/"

@onready var scroll_container = get_node("ScrollContainer")

func _ready():
	process_license_files()
	
func _input(event: InputEvent):
	if visible:
		if event.is_action_pressed("ui_down"):
			await get_tree().process_frame
			scroll_container.set_v_scroll(scroll_container.get_v_scroll() + 100)
		elif event.is_action_pressed("ui_up"):
			await get_tree().process_frame
			scroll_container.set_v_scroll(scroll_container.get_v_scroll() - 100)
	
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
