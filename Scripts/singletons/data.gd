extends Node

var game_data: Dictionary = {}

func save_json(data: Dictionary, file_path: String) -> bool: # Quick function that stores a dict as a json at a specific file path
	var json_string: String = JSON.stringify(data, "", false)

	# Check if JSON conversion was successful
	if json_string.is_empty() and not data.is_empty():
		Debug.throw_error(self, "save_json", "Failed to convert data to JSON string", file_path)
		return false

	# Try to open the file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

	# Check if file was opened successfully
	if file == null:
		var error: int = FileAccess.get_open_error()
		Debug.throw_error(self, "save_json", "Failed to open file for writing. Error code: " + str(error), file_path)
		return false

	# Write to file and close it
	file.store_string(json_string)
	file.close()

	# Verify file was written by checking if it exists and has content
	if not FileAccess.file_exists(file_path):
		Debug.throw_error(self, "save_json", "File was not created successfully", file_path)
		return false

	return true

func load_json_file(path: String) -> Dictionary: # Quick function for loading a json as a dict
	var json_as_text: String = FileAccess.get_file_as_string(path)
	var json_as_dict: Dictionary = JSON.parse_string(json_as_text)
	if json_as_dict == null:
		Debug.throw_error(self, "load_json_file", "Could not parse input", path)
		return {}
	return json_as_dict


func get_current_path(data_name: String) -> String:
	return "res://data/%s_current.json" % [data_name]


func get_backup_path(data_name: String) -> String:
	return "res://data/%s_backup.json" % [data_name]
