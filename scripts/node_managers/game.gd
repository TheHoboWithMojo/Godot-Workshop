# Handles essential game operations (loading, saving, essential signals, tracking frames)
extends Node2D
@export var track_frames: bool
@export var use_save_data: bool = false
@onready var start_ready: bool = false

signal ready_to_start

const BOOT = preload("res://dialogic/timelines/boot.dtl")

func _ready() -> void:
	_update_global_player_reference()
	
	_load_data()
	
	_boot_dialogic()
	
	start_ready = true
	
	ready_to_start.emit()
		
func _process(_delta: float) -> void:
	if track_frames:
		_track_frames()
	
func _update_global_player_reference():
	Global.game_reloaded.emit()
	
func _load_data():
	if not use_save_data:
		Data.clear_data()
		if Data.is_data_cleared != true:
			await Data.data_cleared
	
	Data.load_game_data() # Load _current data into the game
	if Data.is_data_loaded != true:
		await Data.data_loaded

func _boot_dialogic():
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	Dialogic.start(BOOT) # Start a blank timeline to load dialogic assets
	preload("res://dialogic/styles/default.tres") # Load generic dialogic style
	
func _on_dialogue_start() -> void:
	Global.speed_mult = 0.0
	
func _on_dialogue_end() -> void:
	Global.speed_mult = 1.0
	
func _track_frames():
	Global.frames += 1
	if Global.frames >= 100:
		Global.frames = 0
	
