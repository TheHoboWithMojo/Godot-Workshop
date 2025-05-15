extends Node
@onready var characters: Array[Dialogue.CHARACTERS] = [
	Dialogue.CHARACTERS.DOC_MITCHELL
]
@onready var related_timelines: Array[Dialogue.TIMELINES] = [
	Dialogue.TIMELINES.YOUREAWAKE
]

@onready var related_levels: Array[Levels.LEVELS] = [
	Levels.LEVELS.DOC_MITCHELLS_HOUSE
]

@export var waypoints: Array[Area2D]

enum CHOICES {}

@onready var aint_that_a_kick_in_the_head: Quest = Quest.new(self)
@onready var main: Quest.Plot = aint_that_a_kick_in_the_head.mainplot
@onready var walk_to_vit: Quest.Objective = main.new_objective("Walk to the Vit-o-Matic Vigor Tester.")
@onready var use_the_vit: Quest.Objective = main.new_objective("Use the Vit-o-Matic Vigor Tester.")
@onready var sit_down: Quest.Objective = main.new_objective("Sit down on the couch in Doc Mitchell's living room.")
@onready var exit: Quest.Objective = main.new_objective("Follow Doc Mitchell to the exit.")

func _ready() -> void:
	walk_to_vit.pair_waypoint(Vector2(0, -100))
	
func _on_related_level_loaded(_level: Node) -> void:
	pass

func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	if timeline == Dialogue.TIMELINES.YOUREAWAKE:
		var doc_mitchells_house: Node = Levels.get_current_level()
		var vit_machine: Node2D = doc_mitchells_house.find_child("VitMachine")
		var doc_mitchell: Object = doc_mitchells_house.find_child("DocMitchell").master
		while Dialogic.current_timeline:
			if Dialogic.VAR.player_name:
				Player.change_name(Dialogic.VAR.player_name)
				break
			await get_tree().process_frame
		while Dialogic.current_timeline:
			await get_tree().process_frame
		aint_that_a_kick_in_the_head.start()
		doc_mitchell.seek(vit_machine, "right") # go to the right side of the vit-machine
