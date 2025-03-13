extends Node2D

@export var sync_csvs = false

func _ready() -> void:
	Dialogic.start("boot") # Boot a blank timeline to load Dialogic
	
	# Connect dialogic signals
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	
	if sync_csvs:
		Data.sync_all_sheets()

func _on_http_request_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var is_metadata = Data.file_syncer.get_meta("is_metadata", false)
	print("Processing request for: ", Data.current_sync)
	
	match response_code:
		307:
			Data._handle_redirect(headers, is_metadata)
		200:
			Data._handle_successful_response(body, is_metadata)
		_:
			Data._handle_failed_response(response_code, headers)

# Run on dialogic start and end
func _on_dialogue_start() -> void:
	Global.player.speed = 0.0

func _on_dialogue_end() -> void:
	Global.player.speed = 300.0
