extends Control

@export var mod_label = ""
@export var mod_author = ""
var mod_data
@export var mod_manager: Node
@export var fs: Node

@onready var label_node = $HBoxContainer/Label
@onready var author_node = $HBoxContainer/Author
var http_request

func _ready():
	label_node.text = mod_label
	author_node.text = mod_author
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

func _on_download_button_pressed():
	GodotLogger.info("download mod pressed: %s" % JSON.stringify(mod_data))
	# TODO: progress circle, hide download button
	var error = http_request.request(mod_data.modfile_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		# TODO: Show error in godot UI
	
func _http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		GodotLogger.info("download mod error: %s" % response_code)
		# TODO: show error in godot UI
		return
		
	var mod_zip_path = mod_manager.user_mods_path + mod_data.modfile_name
	GodotLogger.info("download mod saving zip to %s" % mod_zip_path)
	fs.write_file_buffer(mod_zip_path, body)
	fs.extract_zip(mod_zip_path, mod_manager.user_mods_path)
	mod_manager.mod_downloaded(mod_data)
	
