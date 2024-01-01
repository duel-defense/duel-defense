extends Control

@export var mod_label = ""
@export var mod_author = ""
@export var mod_loaded = false
@export var mod_divider_label = false
@export var mod_link = ""
var mod_data
@export var mod_manager: Node
@export var fs: Node

@onready var label_node = $HBoxContainer/Label
@onready var author_node = $HBoxContainer/Author
@onready var download_button_node = $HBoxContainer/DownloadButton
@onready var link_button_node = $HBoxContainer/LinkButton
var http_request

func _ready():
	label_node.text = mod_label
	author_node.text = mod_author
	if mod_loaded or mod_divider_label:
		download_button_node.visible = false
		
	if mod_divider_label:
		label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if mod_link != "":
		link_button_node.visible = true
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

func _on_download_button_pressed():
	GodotLogger.info("download mod pressed: %s" % JSON.stringify(mod_data))
	download_button_node.disabled = true
	var error = http_request.request(mod_data.modfile_url)
	if error != OK:
		download_button_node.disabled = false
		GodotLogger.error("An error occurred in the HTTP request. %s" % error)
		GameData.show_toast_error("An error occurred in the HTTP request")
	
func _http_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		GodotLogger.error("download mod error: %d" % response_code)
		download_button_node.disabled = false
		GameData.show_toast_error("An error occurred in downloading the mod")
		return
		
	var mod_zip_path = mod_manager.user_mods_path + mod_data.modfile_name
	GodotLogger.info("download mod saving zip to %s" % mod_zip_path)
	fs.write_file_buffer(mod_zip_path, body)
	var extract_result = fs.extract_zip(mod_zip_path, mod_manager.user_mods_path)
	if not extract_result:
		GodotLogger.error("extract mod error")
		download_button_node.disabled = false
		GameData.show_toast_error("An error occurred in extracting the mod")
		return
	mod_manager.mod_downloaded(mod_data)
	
	download_button_node.visible = false
	GameData.show_toast_success("Mod successfully installed!")
	

func _on_link_button_pressed():
	OS.shell_open(mod_link)
