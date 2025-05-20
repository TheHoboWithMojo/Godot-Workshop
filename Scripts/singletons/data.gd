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

@onready var reference_data: Dictionary[String, Dictionary] = {
	"reload_data": reload_data,
	"stats": Player.stats,
	"factions_data": Factions.factions_data,
	"perks": Player.perks,
	"characters": Characters.characters,
	"timelines": Dialogue.timelines,
}
var reload_data: Dictionary = {
	"last_level": "res://scenes/levels/doc_mitchell's_house/doc_mitchell's_house.tscn", # these are set to level one values by default
	"last_position": Vector2(0, 0),
	"acquired_weapons": [],
}
var spreadsheets: Dictionary[String, Dictionary] = { # dictionary for syncing csvs
	"items": {
		"id": "1J16pLFRq0sskkJiUBQhY4QvSbcZ4VGSB00Zy3yi-1Vc",
	},
	"quests": {
		"id": "1YyJAqxexIt5-x0fV528fsZG9R7tNW6V0nZjoHDgejpY",
	},
}

# ----- Initialization -----
func load_game_data() -> void:
	print("Loading game data...")
	_load_static_data()
	_load_dynamic_data()
	_process_reload_data()
	_convert_faction_keys()
	_ensure_player_health()

	print("Game data loaded...")
	is_data_loaded = true
	data_loaded.emit()


func _load_static_data() -> void: # quests is outdated
	game_data["items"] = load_json_file(_get_current_path("items").replace("_current", ""))
	game_data["quests"] = load_json_file(_get_current_path("quests"))


func _load_dynamic_data() -> void:
	for data_name: String in reference_data.keys():
		var current_data_path: String = _get_current_path(data_name)
		var backup_data_path: String = _get_backup_path(data_name)

		var current_data_str: String = FileAccess.get_file_as_string(current_data_path)
		var backup_data_str: String = FileAccess.get_file_as_string(backup_data_path)

		var current_data: Dictionary = {} if current_data_str.is_empty() else JSON.parse_string(current_data_str)
		var backup_data: Dictionary = {} if backup_data_str.is_empty() else JSON.parse_string(backup_data_str)


		if current_data == null or current_data.is_empty():
			print("Warning: Current data for %s is invalid or empty" % data_name)

			if backup_data != null and not backup_data.is_empty():
				print("Restoring from backup for %s" % data_name)
				game_data[data_name] = backup_data
				save_json(backup_data, current_data_path)
				continue

			print("Using default data for %s" % data_name)
			game_data[data_name] = reference_data[data_name].duplicate(true)
			save_json(game_data[data_name], current_data_path)
			save_json(game_data[data_name], backup_data_path)
			continue

		game_data[data_name] = current_data
		if current_data_str != backup_data_str:
			print("Updating backup for %s" % data_name)
			save_json(current_data, backup_data_path)


func _process_reload_data() -> void:
	if not game_data.has("reload_data"):
		return

	var _reload_data: Dictionary = game_data["reload_data"]

	if _reload_data.has("last_position"):
		Global.player.global_position = _string_to_vector2(_reload_data["last_position"])

	if _reload_data.has("acquired_weapons"):
		for weapon_scene_path: String in _reload_data["acquired_weapons"]:
			Global.player.projectiles.append(load(weapon_scene_path))
		if Global.player.projectiles:
			Global.player.current_projectile = Global.player.projectiles[0]

	if _reload_data.has("last_level"):
		Global.level_manager.current_level = load(_reload_data["last_level"]).instantiate()


func _convert_faction_keys() -> void:
	if not game_data.has("factions_data"):
		return

	var factions_copy: Dictionary = game_data["factions_data"].duplicate()
	game_data["factions_data"].clear()
	for faction_number: String in factions_copy.keys():
		game_data["factions_data"][int(faction_number)] = factions_copy[faction_number]


func _ensure_player_health() -> void:
	if Player.get_stat(Player.STATS.HEALTH) == 0:
		Player.set_stat(Player.STATS.HEALTH, 100.0)

func _string_to_vector2(input: String) -> Vector2:
	var trimmed: String = input.strip_edges(true, true).trim_prefix("(").trim_suffix(")")
	var parts: PackedStringArray = trimmed.split(",")
	if parts.size() == 2:
		var x: float = parts[0].to_float()
		var y: float = parts[1].to_float()
		return Vector2(x, y)
	return Vector2.ZERO  # fallback if string is malformed

func _get_current_path(data_name: String) -> String:
	return "res://data/%s_current.json" % [data_name]

func _get_backup_path(data_name: String) -> String:
	return "res://data/%s_backup.json" % [data_name]
# ----- Data Backup And Clearing -----
func verify_data_integrity() -> bool:
	var all_valid: bool = true

	# Check all data files
	for data_name: String in reference_data.keys():
		var current_path: String = _get_current_path(data_name)
		var backup_path: String = _get_backup_path(data_name)

		if not FileAccess.file_exists(current_path) or not FileAccess.file_exists(backup_path):
			print("Missing data file for: ", data_name)
			all_valid = false
			continue

		var current_data: Dictionary = load_json_file(current_path)
		var backup_data: Dictionary = load_json_file(backup_path)

		if current_data.is_empty() and not game_data[data_name].is_empty():
			print("Current data file is empty for: ", data_name)
			all_valid = false

		if backup_data.is_empty() and not game_data[data_name].is_empty():
			print("Backup data file is empty for: ", data_name)
			all_valid = false

	return all_valid

func save_data_changes() -> void:
	# Save quests data with backup
	_save_data_with_backup("quests")

	# Save all reference data with backup
	for data_name: String in reference_data.keys():
		_save_data_with_backup(data_name)

	# Verify data integrity
	var is_valid: bool = verify_data_integrity()
	if is_valid:
		print("All data saved successfully and verified.")
	else:
		print("WARNING: Some data may not have been saved correctly!")

	data_saved.emit()

func _save_data_with_backup(data_name: String) -> void:
	# Get file paths
	var current_data_path: String = _get_current_path(data_name)
	var backup_data_path: String = _get_backup_path(data_name)
	var temp_data_path: String = current_data_path.replace("_current", "_temp")

	# Step 1: Save the NEW data to temp file first
	var new_data: Dictionary = game_data[data_name]
	var success_temp_save: bool = save_json(new_data, temp_data_path)
	if not success_temp_save:
		print("Failed to create temporary file for: ", data_name)
		return

	# Step 2: Verify temp file was written correctly
	var temp_data: Dictionary = load_json_file(temp_data_path)
	if temp_data.is_empty() and not new_data.is_empty():
		print("Temp file verification failed for: ", data_name)
		return

	# Step 3: Move current to backup (only if current exists and is valid)
	if FileAccess.file_exists(current_data_path):
		var current_data: Dictionary = load_json_file(current_data_path)
		if not current_data.is_empty():
			var success_backup: bool = save_json(current_data, backup_data_path)
			if not success_backup:
				print("Failed to create backup for: ", data_name)
				return

	# Step 4: Move temp to current
	var success_current: bool = save_json(new_data, current_data_path)
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
	for data_name: String in reference_data.keys():
		var current_path: String = _get_current_path(data_name)
		var backup_path: String = current_path.replace("_current", "_backup")

		save_json(reference_data[data_name], current_path)
		save_json(reference_data[data_name], backup_path)
		game_data[data_name] = reference_data[data_name].duplicate(true)

	# Reset quests (using reference data)
	var quests_ref_path: String = _get_current_path("quests").replace("_current", "")
	var quests_ref_data: Dictionary = load_json_file(quests_ref_path)
	save_json(quests_ref_data, _get_current_path("quests"))
	save_json(quests_ref_data, _get_backup_path("quests"))
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
	if sheet_name in spreadsheets.keys() or sheet_name in reference_data.keys():
		return true
	Debug.throw_error(self, "_sheet_exists", "Sheet '%s' does not exist" % [sheet_name])
	return false
