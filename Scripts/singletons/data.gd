extends Node

	#"reload_data": reload_data,
	#"characters": Characters.characters_dict,
	#"stats": Player.stats,
	#"factions": Factions.factions_data,
	#"perks": Player.perks,
	#"timelines": Dialogue.timelines,
	#"quests": Quests.quests_dict


enum PROPERTIES {RELOAD_DATA, CHARACTERS, PLAYER_STATS, FACTIONS, PLAYER_PERKS, TIMELINES, QUESTS, ITEMS, NAVPOINTS_DATA, WAYPOINTS_DATA}

var game_data: Dictionary = {}

func save_json(data: Dictionary, file_path: String) -> bool: # Quick function that stores a dict as a json at a specific file path
	var json_string: String = JSON.stringify(data, "", false)

	if json_string.is_empty() and not data.is_empty():
		push_error(Debug.define_error("Failed to convert data to JSON string", self))
		return false

	# Try to open the file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

	# Check if file was opened successfully
	if file == null:
		push_error(Debug.define_error("Failed to open file for writing. Error code: " + str(FileAccess.get_open_error()), self))
		return false

	# Write to file and close it
	file.store_string(json_string)
	file.close()

	# Verify file was written by checking if it exists and has content
	if not FileAccess.file_exists(file_path):
		push_error(Debug.define_error("File was not created successfully", self))
		return false
	return true


func load_json_file(path: String) -> Dictionary: # Quick function for loading a json as a dict
	var json_as_text: String = FileAccess.get_file_as_string(path)
	var json_as_dict: Dictionary = JSON.parse_string(json_as_text)
	if json_as_dict == null:
		push_error(Debug.define_error("Could not parse input", self))
		return {}
	return json_as_dict


func get_current_path(data_enum: PROPERTIES) -> String:
	return "res://data/%s/%s_current.json" % [Global.enum_to_snakecase(data_enum, PROPERTIES), Global.enum_to_snakecase(data_enum, PROPERTIES)]


func get_backup_path(data_enum: PROPERTIES) -> String:
	return "res://data/%s/%s_backup.json" % [Global.enum_to_snakecase(data_enum, PROPERTIES), Global.enum_to_snakecase(data_enum, PROPERTIES)]
