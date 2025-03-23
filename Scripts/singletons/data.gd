# Handles data saving and loading
extends Node
# ----- Variables -----
var game_data: Dictionary = {} # stores ALL GAME DATA

var is_data_loaded: bool = false

var is_data_cleared: bool = false

var spreadsheet_dict: Dictionary = { # dictionary for saving and syncing data
	"items": {
		"id": "1J16pLFRq0sskkJiUBQhY4QvSbcZ4VGSB00Zy3yi-1Vc",
		"sheet_path": "res://data/items.csv",
		"data_path": "res://data/items_data_ref.json",
		"static": true
	},
	"quests": {
		"id": "1YyJAqxexIt5-x0fV528fsZG9R7tNW6V0nZjoHDgejpY",
		"sheet_path": "res://data/quests.csv",
		"data_path": "res://data/quests_data_ref.json",
		"static": false
	},
	"perks": {
		"id": "1IQzht6HNObieTbztdmvUhZiIbRn8SqKPUCMjAEF9rXM",
		"sheet_path": "res://data/perks.csv",
		"data_path": "res://data/perks_data_ref.json",
		"static": false
	},
	"traits": {
		"id": "1KLbQ5k6whXAKWBNl_nwSfP1Rs2-0_y9-WZuwTxaigl8",
		"sheet_path": "res://data/traits.csv",
		"data_path": "res://data/traits_data_ref.json",
		"static": false
	},
	"beings": {
		"id": "1-ydtxqgvrp60mp_hDfPeCgo9gltg_JpEysfCA67aLuw",
		"sheet_path": "res://data/beings.csv",
		"data_path": "res://data/beings_data_ref.json",
		"static": true
	},
	"factions": {
		"id": "",
		"sheet_path": "",
		"data_path": "res://data/factions_data_ref.json",
		"static": false
	},
	"player stats": {
		"id": "",
		"sheet_path": "",
		"data_path": "res://data/player_stats_data_ref.json",
		"static": false
	},
}
# ----- Signals -----
signal data_cleared

signal data_loaded

signal data_saved
# ----- Initialization -----
func load_game_data() -> void:
	print("Loading game data...")
	var file_data: Dictionary
	for sheet_name: String in spreadsheet_dict:
		if _is_static(sheet_name):
			file_data = load_json_file(spreadsheet_dict[sheet_name]["data_path"])
		else:
			file_data = load_json_file(spreadsheet_dict[sheet_name]["data_path"].replace("_ref.json", "_current.json"))
		game_data[sheet_name] = file_data
	print("Game data loaded...")
	is_data_loaded = true
	data_loaded.emit()
# ----- Data Backup And Clearing -----	
func save_data_changes() -> void: # Safely updates and stores current and backup data
	for sheet_name in spreadsheet_dict:
		if not _is_static(sheet_name):
			# Get file paths
			var ref_data_path: String = spreadsheet_dict[sheet_name]["data_path"]
			var current_data_path: String = ref_data_path.replace("_ref.json", "_current.json")
			var backup_data_path: String = ref_data_path.replace("_ref.json", "_backup.json")
			var temp_data_path: String = ref_data_path.replace("_ref.json", "_temp.json")
			
			# Step 1: Copy current JSON to make copied JSON
			var current_data: Dictionary = load_json_file(current_data_path)
			var success_temp_save = save_json(current_data, temp_data_path)
			if not success_temp_save:
				print("Failed to create temporary copy for: ", sheet_name)
				continue
				
			# Step 2: Edit copied JSON to make new JSON (already done in memory)
			# The changes are already in Data.game_data[sheet_name]
			
			# Step 3: Copied JSON overwrites _backup
			var success_backup = save_json(current_data, backup_data_path)
			if not success_backup:
				print("Failed to create backup for: ", sheet_name)
				# Clean up temp file
				var temp_dir = DirAccess.open("res://data/")
				if temp_dir:
					temp_dir.remove(temp_data_path)
				continue
				
			# Step 4: Edited JSON overwrites current
			var success_current = save_json(game_data[sheet_name], current_data_path)
			if not success_current:
				print("Failed to save current data for: ", sheet_name)
				continue
				
			# Clean up temp file
			var cleanup_dir = DirAccess.open("res://data/")
			if cleanup_dir:
				cleanup_dir.remove(temp_data_path)
				
			#print("Successfully saved changes for: ", sheet_name)
	data_saved.emit()
	print("All non-static data has been saved with backups.")
		
func clear_data() -> void: # Resets all current and backup save data to ref
	for sheet_name: String in spreadsheet_dict:
		if not _is_static(sheet_name):
			var ref_data_path: String = spreadsheet_dict[sheet_name]["data_path"]
			var current_data_path: String = ref_data_path.replace("_ref.json", "_current.json")
			var backup_data_path: String = ref_data_path.replace("_ref.json", "_backup.json")
			
			var ref_data: Dictionary = load_json_file(ref_data_path)
			
			save_json(ref_data, current_data_path)
			save_json(ref_data, backup_data_path)
			
			#print("Reset data for: ", sheet_name)
	print("All non-static data has been reset to reference values.")
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
	
	for item_index in range(rows_data.size()):
		var item = rows_data[item_index]
		print("Item #" + str(item_index + 1) + ":")
		
		var item_dict = {}
		# Convert the array of field pairs into a dictionary for easier reading
		for field_pair in item:
			if field_pair.size() >= 2:
				item_dict[field_pair[0]] = field_pair[1]
		
		# Print each field with proper indentation
		for key in item_dict:
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
	#print(path)
	var json_as_dict: Dictionary = JSON.parse_string(json_as_text)
	if json_as_dict == null:
		Debug.throw_error(self, "load_json_file", "Could not parse input", path)
		return {}
	return json_as_dict
# ----- Helper Functions -----
func _sheet_exists(sheet_name: String) -> bool:
	if sheet_name in spreadsheet_dict.keys():
		return true
	Debug.throw_error(self, "_sheet_exists", "Sheet '%s' does not exist" % [sheet_name])
	return false

func _is_static(sheet_name: String) -> bool:
	if _sheet_exists(sheet_name):
		if spreadsheet_dict[sheet_name]["static"] == true:
			return true
		return false
	Debug.throw_error(self, "_is_static", "Input sheet name '%s' does not exist" % sheet_name)
	return false
