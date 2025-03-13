extends Node2D

# ----- Exports -----
@export var sync_csvs = false

# ----- Ready Function -----
func _ready() -> void:
	Dialogic.start("boot") # Boot an empty timeline to avoid lag
	
	# Intialize Dialogic Signals
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	
	if sync_csvs: # Update all data sheets if sync is on
		Data.sync_all_sheets()

# ----- HTTP Request Handler -----
func _on_http_request_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var is_metadata = Data.file_syncer.get_meta("is_metadata", false)
	print("Processing request for: ", Data.current_sync)
	
	match response_code:
		307:
			_handle_redirect(headers, is_metadata)
		200:
			_handle_successful_response(body, is_metadata)
		_:
			_handle_failed_response(response_code, headers)

# ----- Response Handlers -----
func _handle_redirect(headers: PackedStringArray, is_metadata: bool) -> void:
	var redirect_url = ""
	for header in headers:
		if header.begins_with("Location:"):
			redirect_url = header.substr(10).strip_edges()
			break
	
	if redirect_url != "":
		await Data._make_initial_request(redirect_url, is_metadata)

func _handle_successful_response(body: PackedByteArray, is_metadata: bool) -> void:
	if is_metadata:
		_process_metadata(body)
	else:
		_save_csv_and_json(body)

func _handle_failed_response(response_code: int, headers: PackedStringArray) -> void:
	print("Request failed with response code: ", response_code)
	print("Headers: ", headers)

# ----- Helper Functions -----
func _process_metadata(body: PackedByteArray) -> void:
	var html_content = body.get_string_from_utf8()
	var title_start = html_content.find("<title>") + 7
	var title_end = html_content.find(" - Google Sheets")
	Data.spreadsheet_name = html_content.substr(title_start, title_end - title_start)
	
	var csv_url = "https://docs.google.com/spreadsheets/d/%s/export?format=csv" % Data.spreadsheet_configs[Data.current_sync].id
	await Data._make_initial_request(csv_url, false)

func _save_csv_and_json(body: PackedByteArray) -> void:
	var config = Data.spreadsheet_configs[Data.current_sync]
	var file = FileAccess.open(config.csv_path, FileAccess.WRITE)
	file.store_string(body.get_string_from_utf8())
	file.close()
	print("CSV file synced and saved as: %s" % config.csv_path)
	await get_tree().create_timer(0.1).timeout
	Data.save_to_json(config.csv_path, config.sbr_path)
	Data.sheet_completed.emit(Data.current_sync)

# ----- Dialogue Handlers -----
func _on_dialogue_start() -> void:
	Global.player.speed = 0.0

func _on_dialogue_end() -> void:
	Global.player.speed = 300.0
