extends Node2D

@export var sync_sheets: bool = false

@onready var http_request: HTTPRequest = $"/root/FileSyncer/HTTPRequest"

signal sheet_completed(csv_name: String)

var current_sync = null
var spreadsheet_name = ""

func _ready():
	if sync_sheets:
		sync_all_sheets()

func sync_all_sheets():
	print("Starting sync of all sheets...")
	for csv_name in Data.spreadsheet_configs.keys():
		print("Processing sheet: ", csv_name)
		await _sync_csv(csv_name)
		await sheet_completed
	print("All sheets processed!")

func _sync_csv(csv_name: String):
	if Data.spreadsheet_configs.has(csv_name):
		current_sync = csv_name
		var metadata_url = "https://docs.google.com/spreadsheets/d/%s/edit" % Data.spreadsheet_configs[csv_name].id
		await _make_initial_request(metadata_url, true)

func _make_initial_request(url: String, is_metadata: bool = false) -> void:
	http_request.cancel_request()
	http_request.use_threads = true
	http_request.accept_gzip = true
	http_request.max_redirects = 0
	
	var properties = [
		"User-Agent: Mozilla/5.0",
		"Accept: text/csv,application/json",
		"Accept-Encoding: gzip, deflate",
		"Connection: keep-alive"
	]
	
	http_request.set_meta("is_metadata", is_metadata)
	var error = http_request.request(url, properties)
	if error == OK:
		await http_request.request_completed

func _on_http_request_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var is_metadata = http_request.get_meta("is_metadata", false)
	print("Processing request for: ", current_sync)
	
	match response_code:
		307:
			_handle_redirect(headers, is_metadata)
		200:
			_handle_successful_response(body, is_metadata)
		_:
			_handle_failed_response(response_code, headers)

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

func _process_metadata(body: PackedByteArray) -> void:
	var html_content = body.get_string_from_utf8()
	var title_start = html_content.find("<title>") + 7
	var title_end = html_content.find(" - Google Sheets")
	spreadsheet_name = html_content.substr(title_start, title_end - title_start)
	
	var csv_url = "https://docs.google.com/spreadsheets/d/%s/export?format=csv" % Data.spreadsheet_configs[current_sync].id
	await _make_initial_request(csv_url, false)

func _save_csv_and_json(body: PackedByteArray) -> void:
	var config = Data.spreadsheet_configs[current_sync]
	var file = FileAccess.open(config.csv_path, FileAccess.WRITE)
	file.store_string(body.get_string_from_utf8())
	file.close()
	print("CSV file synced and saved as: %s" % config.csv_path)
	
	await get_tree().create_timer(0.1).timeout
	Data.save_to_json(config.csv_path, config.data_path)
	sheet_completed.emit(current_sync)
