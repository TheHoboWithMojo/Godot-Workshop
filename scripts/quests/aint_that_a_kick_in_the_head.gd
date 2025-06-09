extends QuestMaker

var doc_mitchell: NPC

var walk_to_vit: Objective
var use_the_vit: Objective
var sit_down: Objective
var exit: Objective
var doc_mitchells_house: Node
var vit_machine: Interactable

func _ready() -> void:
	name = Quests.get_quest_name(linked_quest)
	doc_mitchell = Global.npc_manager.get_npc(Characters.CHARACTERS.DOC_MITCHELL)

	await quest_created

	walk_to_vit = mainplot.new_objective("Walk to the Vit-o-Matic Vigor Tester.")
	walk_to_vit.pair_waypoints(["VitMachine"])
	use_the_vit = mainplot.new_objective("Use the Vit-o-Matic Vigor Tester.")
	use_the_vit.pair_waypoints(["VitMachine"])
	sit_down = mainplot.new_objective("Sit down on the couch in Doc Mitchell's living room.")
	sit_down.pair_waypoints(["Couch"])
	exit = mainplot.new_objective("Follow Doc Mitchell to the exit.")
	exit.pair_waypoints(["Exit"])

	related_level_loaded.connect(_on_related_level_loaded)
	related_timeline_played.connect(_on_related_timeline_played)

	declare_next_quest(Quests.QUESTS.BACK_IN_THE_SADDLE) # set what quest to trigger on completion

	_on_related_level_loaded(Levels.LEVELS.DOC_MITCHELLS_HOUSE)
	_on_related_timeline_played(Dialogue.TIMELINES.YOURE_AWAKE)

#func _on_new_npc_loaded(npc: NPC) -> void:
	#doc_mitchell = await Global.npc_manager.get_npc(npc.get_character_enum()) if npc.get_character_enum() == Characters.CHARACTERS.DOC_MITCHELL else doc_mitchell

func _on_related_level_loaded(level: Levels.LEVELS) -> void:
	match(level):
		Levels.LEVELS.DOC_MITCHELLS_HOUSE:
			doc_mitchells_house = await Levels.get_current_level_node() if not doc_mitchells_house else doc_mitchells_house


var in_tree: bool = false
# quest progression function, tracks when timelines and choreographs accordingly
func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
		match(timeline):
			Dialogue.TIMELINES.YOURE_AWAKE:
				if not walk_to_vit.is_complete() and not in_tree:
					in_tree = true
					await Dialogic.timeline_ended
					start()
					doc_mitchell.set_target(get_navpoint_position("VitMachine"))
					await Global.object_manager.object_method_complete(Global.object_manager.OBJECTS.VIT_MACHINE, "is_event_started")
					mainplot.advance()
					await Global.object_manager.object_method_complete(Global.object_manager.OBJECTS.VIT_MACHINE, "is_event_completed")
					mainplot.advance()
					await doc_mitchell.navigation_finished
					doc_mitchell.set_target(get_navpoint_position("Couch"))
					await doc_mitchell.navigation_finished
					doc_mitchell.set_timeline(Dialogue.TIMELINES.PICKTAGS)
					in_tree = false
			Dialogue.TIMELINES.PICKTAGS:
				if not use_the_vit.is_complete():
					await Dialogic.timeline_ended
					mainplot.advance()
					doc_mitchell.set_target(get_navpoint_position("Exit"))
					await doc_mitchell.navigation_finished
					doc_mitchell.set_timeline(Dialogue.TIMELINES.OFF_YOU_GO)
			Dialogue.TIMELINES.OFF_YOU_GO:
				if not is_complete():
					await Dialogic.timeline_ended
					mainplot.advance()
