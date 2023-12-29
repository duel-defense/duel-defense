extends Node

func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		DirAccess.make_dir_absolute(path)
		dir = DirAccess.open(path)
	
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	
	files.sort()

	return files
	
func read_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var content = file.get_as_text()
	file.close()
	return content

func write_file(path, contents):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
