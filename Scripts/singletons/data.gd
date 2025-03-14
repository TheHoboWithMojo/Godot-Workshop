extends Node

# ----- Variables -----
var game_data = {}

# ----- Configuration Data -----
var spreadsheet_configs = {
	"items": {
		"id": "1J16pLFRq0sskkJiUBQhY4QvSbcZ4VGSB00Zy3yi-1Vc",
		"csv_path": "res://data/items.csv",
		"data_path": "res://data/items_data.json"
	},
	"quests": {
		"id": "1YyJAqxexIt5-x0fV528fsZG9R7tNW6V0nZjoHDgejpY",
		"csv_path": "res://data/quests.csv",
		"data_path": "res://data/quests_data.json"
	},
	"perks": {
		"id": "1IQzht6HNObieTbztdmvUhZiIbRn8SqKPUCMjAEF9rXM",
		"csv_path": "res://data/perks.csv",
		"data_path": "res://data/perks_data.json"
	},
	"traits": {
		"id": "1KLbQ5k6whXAKWBNl_nwSfP1Rs2-0_y9-WZuwTxaigl8",
		"csv_path": "res://data/traits.csv",
		"data_path": "res://data/traits_data.json"
	}
}

signal data_loaded
var is_data_loaded = false

# ----- Initialization -----
func _ready():
	_load_game_data()

func _load_game_data():
	print("Loading game data...")
	for csv_name in spreadsheet_configs:
		var file = FileAccess.open(spreadsheet_configs[csv_name].data_path, FileAccess.READ)
		var json_content = file.get_as_text()
		game_data[csv_name] = JSON.parse_string(json_content)
		file.close()
	print("Game data loaded...")
	is_data_loaded = true
	data_loaded.emit()

func load_json_file(path: String) -> Variant:
	var json_as_text = FileAccess.get_file_as_string(path)
	var json_as_dict = JSON.parse_string(json_as_text)
	if json_as_dict == null:
		print("Failed to parse ", path)
		return {"properties": [], "perks": [], "traits": []}
	return json_as_dict
	
func save_to_json(csv_path: String, data_path: String):
	var data = _load_all_columns(csv_path)
	var json_string = JSON.stringify(data, "", false)
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("Data saved to: %s" % data_path)
	
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

func get_json_properties(instanced_json: Dictionary) -> Array:
	var headers = []
	for i in instanced_json.properties:
		headers.append(i)
	return headers

# ----- Data Querying -----
func print_info(csv_name: String, key: String) -> void:
	var display_name = csv_name.trim_suffix("s").capitalize()
	var data = game_data[csv_name][csv_name].filter(
		func(row): return row[0][1] == key
	)
	if data.size() > 0:
		print("\n=== %s Info ===" % display_name)
		pretty_print_rows([data[0]], csv_name)

func get_filtered_rows_co(csv_name: String, property: String, key: String) -> Array:
	if not is_data_loaded:
		await data_loaded
	
	var display_name = csv_name.capitalize()
	
	var filtered_rows = game_data[csv_name][csv_name].filter(
		func(row): return row.any(func(field): return field[0] == property and field[1] == key)
	)
	
	print("\n=== Filtered %s ===" % display_name)
	pretty_print_rows(filtered_rows, csv_name)
	return filtered_rows

func pretty_print_rows(rows: Array, csv_name: String) -> void:
	var display_name = csv_name.trim_suffix("s").capitalize()
	
	for row in rows:
		print("\n%s:" % display_name.capitalize())
		for field in row:
			print("  %s: %s" % [field[0], field[1]])
		print("\n---------------")
