extends Node

@onready var quest: Quests.QUESTS = Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD

@onready var characters: Array[Characters.CHARACTERS] = [Characters.CHARACTERS.DOC_MITCHELL]
@onready var related_timelines: Array[Dialogue.TIMELINES] = [Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS]
@onready var related_levels: Array[Levels.LEVELS] = [Levels.LEVELS.DOC_MITCHELLS_HOUSE]
@export var waypoints: Array[Area2D]

enum CHOICES {}

@onready var aint_that_a_kick_in_the_head: Quest = Quest.new(self, "Ain't That A Kick in the Head")
@onready var main: Quest.Plot = aint_that_a_kick_in_the_head.mainplot
@onready var walk_to_vit: Quest.Objective = main.new_objective("Walk to the Vit-o-Matic Vigor Tester.")
@onready var use_the_vit: Quest.Objective = main.new_objective("Use the Vit-o-Matic Vigor Tester.")
@onready var sit_down: Quest.Objective = main.new_objective("Sit down on the couch in Doc Mitchell's living room.")
@onready var exit: Quest.Objective = main.new_objective("Follow Doc Mitchell to the exit.")

@onready var doc_mitchells_house: Node
@onready var vit_machine: Node2D
@onready var couch: Node2D
@onready var door: Node2D
@onready var doc_mitchell: Being


func _ready() -> void:
	#walk_to_vit.pair_waypoint(Vector2(0, -100))
	aint_that_a_kick_in_the_head.set_active(true) # bc its the first quest in the game
	Global.set_fast_travel_enabled(false)


func _on_related_level_loaded(level: Level) -> void:
	if level.level == Levels.LEVELS.DOC_MITCHELLS_HOUSE:
		doc_mitchells_house = Levels.get_current_level()
		vit_machine = doc_mitchells_house.find_child("VitMachine")
		couch = doc_mitchells_house.find_child("DocMitchellsCouch")
		door = doc_mitchells_house.find_child("PortalToGoodsprings")
		doc_mitchell = doc_mitchells_house.find_child("DocMitchell").master


func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	if timeline == Dialogue.TIMELINES.YOURE_AWAKE:
		while Dialogic.current_timeline:
			if Dialogic.VAR.player_name:
				Player.change_name(Dialogic.VAR.player_name)
				break
			await get_tree().process_frame

		while Dialogic.current_timeline:
			await get_tree().process_frame

		aint_that_a_kick_in_the_head.start()
		doc_mitchell.seek(vit_machine, "right")
		await vit_machine.player_touched_me
		main.advance()

		await Player.player_stats_changed
		main.advance()

		doc_mitchell.seek(couch, "above")
		await doc_mitchell.seeking_complete()
		doc_mitchell.set_timeline(Dialogue.TIMELINES.PICKTAGS)

	elif timeline == Dialogue.TIMELINES.PICKTAGS:
		await Dialogic.timeline_ended
		main.advance()

		doc_mitchell.seek(door, "right")
		await doc_mitchell.seeking_complete()
		Global.set_fast_travel_enabled(true)
