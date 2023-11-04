extends Node

const FS = preload("res://CommonScripts/FS.gd")
var fs = FS.new()

var default_config_path = "res://Assets/Configs/"
var user_config_path = "user://configs/"

var config_container
var write_requests = []
var write_requests_timer = null

func _init():
	config_container = GameData.config
	read_configs()
	
func _ready():
	write_requests_timer = Timer.new()
	add_child(write_requests_timer)

	write_requests_timer.connect("timeout", Callable(self, "process_write_requests"))
	write_requests_timer.set_wait_time(2.0)
	write_requests_timer.set_one_shot(false)
	write_requests_timer.start()
	
func process_write_requests():
	var tmp_requests = write_requests.duplicate(true)
	write_requests.clear()
	for request in tmp_requests:
		write_config_process(request)

func read_configs():
	read_config_dir(user_config_path)
	read_config_dir(default_config_path)

func read_config_dir(path):
	GodotLogger.debug("read_config_dir: " + path)
	var config_files = fs.list_files_in_directory(path)
	
	for filename in config_files:
		if '.json' in filename:
			parse_json(path, filename)
		elif '.cfg' in filename:
			parse_cfg(path, filename)

func parse_json(path, filename):
	var config_key = filename.split(".json")[0]
	if !config_container.has(config_key):
		GodotLogger.info("Found config: " + config_key + " from " + path)
					
		var file_str = fs.read_file(path + filename)
		var test_json_conv = JSON.new()
		test_json_conv.parse(file_str)
		var config_data = test_json_conv.get_data()
		config_container[config_key] = config_data
		
func parse_cfg(path, filename):
	var config_key = filename.split(".cfg")[0]
	if !config_container.has(config_key):
		GodotLogger.info("Found config: " + config_key + " from " + path)
		var file_str = fs.read_file(path + filename)
		config_container[config_key] = file_str.split("\n")

func write_config(config_key):
	if !write_requests.has(config_key):
		GodotLogger.debug("Requesting write for " + config_key)
		write_requests.append(config_key)
	
func write_config_process(config_key):
	var filename = config_key + ".json"
	var path = user_config_path + filename
	fs.write_file(path, JSON.stringify(config_container[config_key]))
	GodotLogger.debug("Written for " + config_key)

func reset_config(key):
	var filename = "%s.json" % key
	config_container.erase(key)
	parse_json(default_config_path, filename)
