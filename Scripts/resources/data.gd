extends Node

# ----- Node References -----
@onready var file_syncer = $"/root/Game/FileSyncer"

# ----- Signals -----
signal sheet_completed(sheet_name: String)

# ----- Variables -----
var current_sync = null
var spreadsheet_name = ""

# ----- Configuration Data -----
var spreadsheet_configs = {
	"items": {
		"id": "1gLbKH8qPuMIA-s8Hr9qaiteuf-wpcvgvN3pkfZ--5nQ",
		"csv_path": "res://data/items.csv",
		"sbr_path": "res://data/item_sbr.json"
	},
	"quests": {
		"id": "1n3to2dllKgTFvkpmE4Zw98Y_5wce10mDet8FhWPGWZc",
		"csv_path": "res://data/quests.csv",
		"sbr_path": "res://data/quests_sbr.json"
	}
}

# ----- Sheet Syncing Functions -----
func sync_all_sheets():
	print("Starting sync of all sheets...")
	for sheet_name in spreadsheet_configs.keys():
		print("Processing sheet: ", sheet_name)
		await sync_sheet(sheet_name)
		await sheet_completed
	print("All sheets processed!")

func sync_sheet(sheet_name: String):
	if spreadsheet_configs.has(sheet_name):
		current_sync = sheet_name
		var metadata_url = "https://docs.google.com/spreadsheets/d/%s/edit" % spreadsheet_configs[sheet_name].id
		await _make_initial_request(metadata_url, true)

func _make_initial_request(url: String, is_metadata: bool = false) -> void:
	file_syncer.cancel_request()
	
	file_syncer.use_threads = true
	file_syncer.accept_gzip = true
	file_syncer.max_redirects = 0
	
	var headers = [
		"User-Agent: Mozilla/5.0",
		"Accept: text/csv,application/json",
		"Accept-Encoding: gzip, deflate",
		"Connection: keep-alive"
	]
	
	file_syncer.set_meta("is_metadata", is_metadata)
	var error = file_syncer.request(url, headers)
	if error == OK:
		await file_syncer.request_completed

# ----- Data Processing Functions -----
func _load_all_columns(csv_path: String) -> Dictionary:
	var column_data = {}
	var file = FileAccess.open(csv_path, FileAccess.READ)
	var master_name = csv_path.get_file().trim_suffix(".csv")
	
	# Get headers first
	var headers = file.get_csv_line()
	for header in headers:
		column_data[header] = []
	
	# Add our new master reference array
	column_data[master_name] = []
	
	# Now collect byte positions and row numbers for each column
	var row_number = 0
	while !file.eof_reached():
		var row_start_pos = file.get_position()
		var line = file.get_csv_line()
		if line.size() > 0:
			row_number += 1
			# Add complete row data to our master reference
			var row_data = []
			var current_byte_pos = row_start_pos
			
			for i in range(line.size()):
				# Calculate exact byte position for each column
				if i > 0:
					current_byte_pos += len(line[i-1]) + 1  # +1 for the comma
				row_data.append([headers[i], line[i], current_byte_pos, row_number])
				column_data[headers[i]].append([line[i], current_byte_pos, row_number])
				
			column_data[master_name].append(row_data)
	
	file.close()
	return column_data

func save_to_json(csv_path: String, sbr_path: String):
	var column_data = _load_all_columns(csv_path)
	# Custom formatting for more compact JSON
	var formatted_data = {}
	for column in column_data:
		formatted_data[column] = column_data[column]
	var json_string = JSON.stringify(formatted_data, "  ", true)

	# This will produce SBR format:
	# {
	#   "Has": [["FALSE", 28, 1], ["FALSE", 51, 2], ["FALSE", 74, 3], ["FALSE", 101, 4]],
	#   "Item": [["Gun", 28, 1], ["Melon", 51, 2], ["Sword", 74, 3], ["Tin Can", 101, 4]],
	#   ...
	# }

	var file = FileAccess.open(sbr_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("CBR saved to: %s" % sbr_path)

func get_byte_from_string(string: String, sbr_path: String, column: String = "Name") -> int:
	var file = FileAccess.open(sbr_path, FileAccess.READ)
	var column_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if !column_data.has(column):
		print("Error: Column '%s' not found" % column)
		return -1
		
	var sbr_data = column_data[column]
	
	# Use binary search for Name column
	if column == "Name":
		return _binary_search(sbr_data, string)
	
	# Use linear search for other columns
	return _linear_search(sbr_data, string)

func _binary_search(sbr_data: Array, value: String) -> int:
	var left = 0
	var right = sbr_data.size() - 1
	
	while left <= right:
		@warning_ignore("integer_division")
		var mid = (left + right) / 2
		var value_name = sbr_data[mid][0]
		
		if value_name == value:
			return sbr_data[mid][1]
		elif value_name < value:
			left = mid + 1
		else:
			right = mid - 1
	
	print("Error: Binary Search '%s' not found" % value)
	return -1

func _linear_search(sbr_data: Array, value: String) -> int:
	for data in sbr_data:
		if data[0] == value:
			return data[1]
	
	print("Error: Linear Search '%s' not found" % value)
	return -1

func print_quest_info(string: String) -> void:
	var csv_path = spreadsheet_configs["quests"].csv_path
	var sbr_path = spreadsheet_configs["quests"].sbr_path
	
	var byte_position = get_byte_from_string(string, sbr_path)
	if byte_position != -1:
		var file = FileAccess.open(csv_path, FileAccess.READ)
		file.seek(byte_position)
		var row = file.get_csv_line()
		print("Info for Quest '%s': %s" % [string, row])
		file.close()

func print_item_info(string: String) -> void:
	var csv_path = spreadsheet_configs["items"].csv_path
	var sbr_path = spreadsheet_configs["items"].sbr_path
	
	var byte_position = get_byte_from_string(string, sbr_path)
	if byte_position != -1:
		var file = FileAccess.open(csv_path, FileAccess.READ)
		file.seek(byte_position)
		var row = file.get_csv_line()
		print("Info for Item '%s': %s" % [string, row])
		file.close()

func _ready():
	pass
