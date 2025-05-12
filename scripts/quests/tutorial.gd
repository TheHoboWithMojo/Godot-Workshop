extends Node

@export var characters: Array[DialogicCharacter]
@export var related_timelines: Array[DialogicTimeline]
@onready var active: bool = false
@onready var quest: Object = preload("res://scripts/classes/quest.gd").new(self)

enum CHOICES {ROB_THE_BANK, KILL_STEVE}

func _ready() -> void:
	await Global.active_and_ready(self)
	
	var main: Object = quest.mainplot
	
	main.new_objective("talk to bob", "I don't know where I am... maybe I should talk to that fellow over there")
	main.new_objective("talk to steve", "bob told me to go talk to some guy named steve")
	
	var sub1: Object = quest.new_subplot("find a weapon")
	sub1.new_objective("look for a gun", "Looks dangerous around here... should look for a gun.")
	sub1.new_objective("target practice", "I found a gun in an old barn, should test it out")
	
	quest.overview()
