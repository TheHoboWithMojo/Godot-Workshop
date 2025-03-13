extends Node

# ----- Node References -----
@onready var file_syncer: HTTPRequest = $"/root/Game/FileSyncer"

# ----- Signals -----
signal sheet_completed(csv_name: String)

# ----- Variables -----
var current_sync = null
var spreadsheet_name = ""
var game_data = {}

# ----- Configuration Data -----
var spreadsheet_configs = {
	"items": {
		"id": "1gLbKH8qPuMIA-s8Hr9qaiteuf-wpcvgvN3pkfZ--5nQ",
		"csv_path": "res://data/items.csv",
		"data_path": "res://data/items_data.json"
	},
	"quests": {
		"id": "1n3to2dllKgTFvkpmE4Zw98Y_5wce10mDet8FhWPGWZc",
		"csv_path": "res://data/quests.csv",
		"data_path": "res://data/quests_data.json"
	},
	"perks": {
		"id": "1nKLvKB9mliP27oI7FWDbOTOya2tg2QWDEOLosJCX5vA",
		"csv_path": "res://data/perks.csv",
		"data_path": "res://data/perks_data.json"
	},
	"traits": {
		"id": "1L2NEgYkvv6ST-dnvBm7BA6ZIkahCxwODje687aHw0sU",
		"csv_path": "res://data/traits.csv",
		"data_path": "res://data/traits_data.json"
	}
}

# ----- Initialization -----
func _ready():
	var needs_sync = false
	for csv_name in spreadsheet_configs:
		var file = FileAccess.open(spreadsheet_configs[csv_name].data_path, FileAccess.READ)
		if !file:
			needs_sync = true
			break
		file.close()
	
	if needs_sync:
		print("Data files missing, syncing sheets...")
		await sync_all_sheets()
		_load_game_data()
	else:
		_load_game_data()

func _load_game_data():
	for csv_name in spreadsheet_configs:
		var file = FileAccess.open(spreadsheet_configs[csv_name].data_path, FileAccess.READ)
		game_data[csv_name] = JSON.parse_string(file.get_as_text())
		file.close()

# ----- Sheet Syncing -----
func sync_all_sheets():
	print("Starting sync of all sheets...")
	for csv_name in spreadsheet_configs.keys():
		print("Processing sheet: ", csv_name)
		await _sync_csv(csv_name)
		await sheet_completed
	print("All sheets processed!")

func _sync_csv(csv_name: String):
	if spreadsheet_configs.has(csv_name):
		current_sync = csv_name
		var metadata_url = "https://docs.google.com/spreadsheets/d/%s/edit" % spreadsheet_configs[csv_name].id
		await _make_initial_request(metadata_url, true)

# ----- HTTP Request Handling -----
func _make_initial_request(url: String, is_metadata: bool = false) -> void:
	file_syncer.cancel_request()
	file_syncer.use_threads = true
	file_syncer.accept_gzip = true
	file_syncer.max_redirects = 0
	
	var properties = [
		"User-Agent: Mozilla/5.0",
		"Accept: text/csv,application/json",
		"Accept-Encoding: gzip, deflate",
		"Connection: keep-alive"
	]
	
	file_syncer.set_meta("is_metadata", is_metadata)
	var error = file_syncer.request(url, properties)
	if error == OK:
		await file_syncer.request_completed

func _handle_redirect(properties: PackedStringArray, is_metadata: bool) -> void:
	var redirect_url = ""
	for header in properties:
		if header.begins_with("Location:"):
			redirect_url = header.substr(10).strip_edges()
			break
	
	if redirect_url != "":
		await _make_initial_request(redirect_url, is_metadata)

func _handle_successful_response(body: PackedByteArray, is_metadata: bool) -> void:
	if is_metadata:
		_process_metadata(body)
	else:
		_save_csv_and_json(body)

func _handle_failed_response(response_code: int, properties: PackedStringArray) -> void:
	print("Request failed with response code: ", response_code)
	print("properties: ", properties)

# ----- Data Processing -----
func _process_metadata(body: PackedByteArray) -> void:
	var html_content = body.get_string_from_utf8()
	var title_start = html_content.find("<title>") + 7
	var title_end = html_content.find(" - Google Sheets")
	spreadsheet_name = html_content.substr(title_start, title_end - title_start)
	
	var csv_url = "https://docs.google.com/spreadsheets/d/%s/export?format=csv" % spreadsheet_configs[current_sync].id
	await _make_initial_request(csv_url, false)

func _save_csv_and_json(body: PackedByteArray) -> void:
	var config = spreadsheet_configs[current_sync]
	var file = FileAccess.open(config.csv_path, FileAccess.WRITE)
	file.store_string(body.get_string_from_utf8())
	file.close()
	print("CSV file synced and saved as: %s" % config.csv_path)
	await get_tree().create_timer(0.1).timeout
	save_to_json(config.csv_path, config.data_path)
	sheet_completed.emit(current_sync)

func _load_all_columns(csv_path: String) -> Dictionary:
	var data = {}
	var file = FileAccess.open(csv_path, FileAccess.READ)
	var master_name = csv_path.get_file().trim_suffix(".csv")
	
	var properties = file.get_csv_line()
	data["properties"] = properties
	data[master_name] = []
	
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() > 0:
			var row_data = []
			for i in range(line.size()):
				row_data.append([properties[i], line[i]])
			data[master_name].append(row_data)
	
	file.close()
	return data

func save_to_json(csv_path: String, data_path: String):
	var data = _load_all_columns(csv_path)
	var json_string = JSON.stringify(data, "", false)
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("Data saved to: %s" % data_path)
	
func load_json_file(path: String) -> Variant:
	var json_as_text = FileAccess.get_file_as_string(path)
	var json_as_dict = JSON.parse_string(json_as_text)
	if json_as_dict == null:
		print("Failed to parse ", path)
		return {"properties": [], "perks": [], "traits": []}
	return json_as_dict

# ----- Data Querying -----
func print_info(csv_name: String, key: String) -> void:
	var display_name = csv_name.trim_suffix("s").capitalize()
	var data = game_data[csv_name][csv_name].filter(
		func(row): return row[0][1] == key
	)
	if data.size() > 0:
		print("\n=== %s Info ===" % display_name)
		pretty_print_rows([data[0]], csv_name)

func get_filtered_rows(csv_name: String, property: String, key: String) -> Array:
	var display_name = csv_name.trim_suffix("s").capitalize()
	var filtered_rows = game_data[csv_name][csv_name].filter(
		func(row): return row.any(func(field): return field[0] == property and field[1] == key)
	)
	print("\n=== Filtered %s ===" % display_name)
	pretty_print_rows(filtered_rows, csv_name)
	return filtered_rows

func pretty_print_rows(rows: Array, sheet_name: String) -> void:
	var display_name = sheet_name.trim_suffix("s")
	
	for row in rows:
		print("\n%s:" % display_name.capitalize())
		for field in row:
			print("  %s: %s" % [field[0], field[1]])
		print("\n---------------")
