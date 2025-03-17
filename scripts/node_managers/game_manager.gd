extends Node2D

func _ready() -> void:
	Data.load_game_data()
	Dialogic.start("boot") # Boot a blank timeline to load Dialogic
	
	# Connect dialogic signals
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)

# Run on dialogic start and end
func _on_dialogue_start() -> void:
	Global.player.speed = 0.0

func _on_dialogue_end() -> void:
	Global.player.speed = 300.0
