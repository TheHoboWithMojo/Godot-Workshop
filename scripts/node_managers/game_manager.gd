# Handles essential game operations (loading, saving, essential signals, tracking frames)
extends Node2D
@export var track_frames: bool
@export var save_data: bool = false
const BOOT = preload("res://dialogic/timelines/boot.dtl")

func _ready() -> void:
	Global.game_reloaded.emit() # Tells global to reset its player and camera assignments
	
	if not save_data:
		Data.clear_data() # Reset all current and backup files 
	
	Data.load_game_data()
	
	# Connect dialogic signals
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	
	Dialogic.start("boot") # Start a blank timeline to load dialogic assets
	preload("res://dialogic/styles/default.tres") # Load generic dialogic style
	
	if not Data.is_data_loaded: # ESSENTIAL - DATA MUST ABSOLUTELY BE LOADED BEFORE ANYTHING ELSE
		await Data.data_loaded # Waits for completion signal
		
func _process(_delta: float) -> void:
	if track_frames:
		Global.frames += 1
		if Global.frames >= 100:
			Global.frames = 0
		
# Run on dialogue start and end
func _on_dialogue_start() -> void:
	Global.speed_mult = 0.0
	
func _on_dialogue_end() -> void:
	Global.speed_mult = 1.0
	
