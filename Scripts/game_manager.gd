extends Node2D

@onready var file_syncer: HTTPRequest = $"File Syncer"
@export var sync_csvs = false

var current_sync = null
var spreadsheet_name = ""

func _ready() -> void:
	Dialogic.start("boot")
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	
	if sync_csvs:
		sync_all_sheets()
		
# ------Data Saving Handler------
func sync_all_sheets():
	for sheet_name in Data.spreadsheet_configs.keys():
		sync_sheet(sheet_name)

func sync_sheet(sheet_name: String):
	if Data.spreadsheet_configs.has(sheet_name):
		current_sync = sheet_name
		var metadata_url = "https://docs.google.com/spreadsheets/d/%s/edit" % Data.spreadsheet_configs[sheet_name].id
		_make_initial_request(metadata_url, true)

func _make_initial_request(url: String, is_metadata: bool = false) -> void:
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
	file_syncer.request(url, headers)

func _on_http_request_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var is_metadata = file_syncer.get_meta("is_metadata", false)
	
	if response_code == 307:
		var redirect_url = ""
		for header in headers:
			if header.begins_with("Location:"):
				redirect_url = header.substr(10).strip_edges()
				break
		
		if redirect_url != "":
			_make_initial_request(redirect_url, is_metadata)
	elif response_code == 200:
		if is_metadata:
			var html_content = body.get_string_from_utf8()
			var title_start = html_content.find("<title>") + 7
			var title_end = html_content.find(" - Google Sheets")
			spreadsheet_name = html_content.substr(title_start, title_end - title_start)
			
			var csv_url = "https://docs.google.com/spreadsheets/d/%s/export?format=csv" % Data.spreadsheet_configs[current_sync].id
			_make_initial_request(csv_url, false)
		else:
			var config = Data.spreadsheet_configs[current_sync]
			var file = FileAccess.open(config.parent_path, FileAccess.WRITE)
			file.store_string(body.get_string_from_utf8())
			file.close()  # Make sure to close the file
			print("CSV file synced and saved as: %s" % config.parent_path)

			# Add a timer before generating JSON
			await get_tree().create_timer(0.1).timeout
			Data.save_to_json(config.parent_path, config.key_byte_path)
	else:
		print("Request failed with response code: ", response_code)
		print("Headers: ", headers)
#---------------------------------------------------------
# Procks during dialogue
func _on_dialogue_start() -> void:
	Global.player.speed = 0.0

func _on_dialogue_end() -> void:
	Global.player.speed = 300.0
