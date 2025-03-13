extends Node

# Dictionary to sync alphabetical google sheets and save them to json
var spreadsheet_configs = {
	"items": {
		# Google sheets link id
		"id": "1gLbKH8qPuMIA-s8Hr9qaiteuf-wpcvgvN3pkfZ--5nQ",
		"parent_path": "res://data/items.csv",
		"key_byte_path": "res://data/items_key_byte.json"
	},
	#"characters": {
		#"id": "your_other_spreadsheet_id",
		#"parent_path": "res://data/characters.csv",
		#"json_name": "character_positions"
	#}
}

func _load_first_column(file_path):
	var key_byte_pair = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	var byte_pos = 0
	
	#print("Reading CSV from: ", file_path)  # Debug print
	
	while !file.eof_reached():
		byte_pos = file.get_position()
		var line = file.get_csv_line()
		#print("Line read: ", line)  # Debug print
		if line.size() > 0:
			key_byte_pair.append([line[0], byte_pos])
	
	key_byte_pair.pop_front() # Remove the first term (it's a title)
	#print("Final key_byte_pair: ", key_byte_pair)  # Debug print
	file.close()
	return key_byte_pair

func save_to_json(parent_file_path: String, key_byte_path: String):
	var file_array = _load_first_column(parent_file_path)
	var json_string = JSON.stringify(file_array)
	var file = FileAccess.open(key_byte_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	print("Key-byte pairs saved to: %s" % key_byte_path)
	
func get_byte_from_key(key: String, key_byte_file_path: String) -> int:
	var file = FileAccess.open(key_byte_file_path, FileAccess.READ)
	var key_byte_pairs = JSON.parse_string(file.get_as_text())
	file.close()
	
	var left = 0
	var right = key_byte_pairs.size() - 1
	
	while left <= right:
		var mid = (left + right) / 2
		var key_name = key_byte_pairs[mid][0]
		
		# Compare the strings
		if key_name == key:
			return key_byte_pairs[mid][1] # Return the byte position
		elif key_name < key:
			left = mid + 1
		else:
			right = mid - 1
	
	print("Error: Binary Search ", key, " not found in ", key_byte_file_path)
	return -1 # Item not found
