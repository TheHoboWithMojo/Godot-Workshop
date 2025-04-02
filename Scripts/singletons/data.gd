# Handles data saving and loading
extends Node

# ----- Variables -----
var game_data: Dictionary = {} # stores ALL GAME DATA
var is_data_loaded: bool = false
var is_data_cleared: bool = false

# ----- Signals -----
signal data_cleared
signal data_loaded
signal data_saved

# ----- Initialization -----
func load_game_data() -> void:
	print("Loading game data...")
	
	# Load pure references
	game_data["items"] = load_json_file(_get_current_path("items").replace("_current", ""))
	
	# Load All Currents
	for data_name: String in Dicts.reference_data.keys():
		game_data[data_name] = load_json_file(_get_current_path(data_name))
	game_data["quests"] = load_json_file(_get_current_path("quests"))
	
	Global.player.global_position = string_to_vector(game_data["reload_data"]["last_position"])
	
	print("Game data loaded...")
	
	is_data_loaded = true
	data_loaded.emit()
	
func string_to_vector(vector_string: String) -> Vector2:
	vector_string = vector_string.strip_edges(true).trim_prefix("(").trim_suffix(")")
	var x_y: Array = vector_string.split(",")
	return Vector2(float(x_y[0]), float(x_y[1]))

func _get_current_path(data_name: String) -> String:
	return "res://data/%s_current.json" % [data_name]
	
# ----- Data Backup And Clearing -----
	
func save_data_changes() -> void: # Safely updates and stores current and backup data
	# Save quests data with backup
	_save_data_with_backup("quests")
	
	# Save all reference data with backup
	for data_name: String in Dicts.reference_data.keys():
		_save_data_with_backup(data_name)
	
	data_saved.emit()
	print("All non-static data has been saved with backups.")
	
func _save_data_with_backup(data_name: String) -> void:
	# Get file paths
	var current_data_path: String = _get_current_path(data_name)
	var backup_data_path: String = current_data_path.replace("_current", "_backup")
	var temp_data_path: String = current_data_path.replace("_current", "_temp")
	
	# Step 1: Copy current JSON to make copied JSON
	var current_data: Dictionary = load_json_file(current_data_path)
	var success_temp_save: bool = save_json(current_data, temp_data_path)
	if not success_temp_save:
		print("Failed to create temporary copy for: ", data_name)
		return
	
	# Step 2: Edit copied JSON to make new JSON (already done in memory)
	# The changes are already in Data.game_data[data_name]
	
	# Step 3: Copied JSON overwrites _backup
	var success_backup: bool = save_json(current_data, backup_data_path)
	if not success_backup:
		print("Failed to create backup for: ", data_name)
		# Clean up temp file
		var temp_dir: DirAccess = DirAccess.open("res://data/")
		if temp_dir:
			temp_dir.remove(temp_data_path)
		return
	
	# Step 4: Edited JSON overwrites current
	var success_current: bool = save_json(game_data[data_name], current_data_path)
	if not success_current:
		print("Failed to save current data for: ", data_name)
		return
	
	# Clean up temp file
	var cleanup_dir: DirAccess = DirAccess.open("res://data/")
	if cleanup_dir:
		cleanup_dir.remove(temp_data_path)
	
	#print("Successfully saved changes for: ", data_name)

func clear_data() -> void: # Resets all current and backup files to default
	# Reset reference data (perks, player_stats, faction_stats)
	for data_name: String in Dicts.reference_data.keys():
		var current_path: String = _get_current_path(data_name)
		var backup_path: String = current_path.replace("_current", "_backup")
		
		save_json(Dicts.reference_data[data_name], current_path)
		save_json(Dicts.reference_data[data_name], backup_path)
		game_data[data_name] = Dicts.reference_data[data_name].duplicate(true)
	
	# Reset quests (using reference data)
	var quests_ref_path: String = _get_current_path("quests").replace("_current", "")
	var quests_ref_data: Dictionary = load_json_file(quests_ref_path)
	save_json(quests_ref_data, _get_current_path("quests"))
	save_json(quests_ref_data, _get_current_path("quests").replace("_current", "_backup"))
	game_data["quests"] = quests_ref_data.duplicate(true)
	
	print("All data have been reset to defaults.")
	
	is_data_cleared = true
	data_cleared.emit()

# ----- Data Querying -----
func print_info(sheet_name: String, key: String) -> void:
	var display_name: String = sheet_name.trim_suffix("s").capitalize()
	
	var items_dict: Dictionary = game_data[sheet_name]
	
	if items_dict.has(key):
		var row: Array = []
		var item: Dictionary = items_dict[key]
		for prop: String in item:
			row.append([prop, item[prop]])
		row.insert(0, ["id", key])
		
		print("\n=== %s Info ===" % display_name)
		Debug.print_array([row])
	else:
		print("\n=== %s with ID '%s' not found ===" % [display_name, key])

func get_filtered_rows_co(sheet_name: String, property: String, key: String) -> Array:
	if not is_data_loaded:
		await data_loaded
	if _sheet_exists(sheet_name):
		var display_name: String = sheet_name.capitalize()
		
		var items_dict: Dictionary = game_data[sheet_name]
		
		var filtered_rows: Array = []
		for item_name: String in items_dict:
			var item: Dictionary = items_dict[item_name]
			if item.has(property) and item[property] == key:
				var row: Array = []
				for prop: String in item:
					row.append([prop, item[prop]])
				row.insert(0, ["name", item_name])
				filtered_rows.append(row)
		
		_print_filtered_rows(filtered_rows, "Filtered " + display_name)
		
		return filtered_rows
	return []
	
# Special function for the specific data structure returned by get_filtered_rows_co
func _print_filtered_rows(rows_data: Array, title: String = "Filtered Items") -> void:
	print("\n=== " + title + " ===\n")
	
	for item_index: int in range(rows_data.size()):
		var item: Array = rows_data[item_index]
		print("Item #" + str(item_index + 1) + ":")
		
		var item_dict: Dictionary = {}
		# Convert the array of field pairs into a dictionary for easier reading
		for field_pair: Array in item:
			if field_pair.size() >= 2:
				item_dict[field_pair[0]] = field_pair[1]
		
		# Print each field with proper indentation
		for key: Variant in item_dict:
			print("\t" + key + ": " + Debug.format_value(item_dict[key]))
		
		print("")

# ----- Utility Functions -----
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

# ----- Helper Functions -----
func _sheet_exists(sheet_name: String) -> bool:
	if sheet_name in Dicts.spreadsheets.keys() or sheet_name in Dicts.reference_data.keys():
		return true
	Debug.throw_error(self, "_sheet_exists", "Sheet '%s' does not exist" % [sheet_name])
	return false
