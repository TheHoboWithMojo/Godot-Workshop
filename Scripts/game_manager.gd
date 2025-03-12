extends Node2D

func _ready() -> void:
	# Load A Timeline To Avoid Lag
	Dialogic.start("boot")
	
	# Declare dialogic timeline singals
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)

# Run when dialogue starts
func _on_dialogue_start() -> void:
	Global.player.speed = 0.0

# Run when dialogue ends
func _on_dialogue_end() -> void:
	Global.player.speed = 300.0
