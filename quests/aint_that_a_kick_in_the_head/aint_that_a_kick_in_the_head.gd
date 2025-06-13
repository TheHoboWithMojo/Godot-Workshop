class_name AintThatAKickInTheHead extends Quest

var doc_mitchell: NPC
var walk_to_vit: Objective
var use_the_vit: Objective
var sit_down: Objective
var exit: Objective
var doc_mitchells_house: Node
var vit_machine: Node
signal vit_started
signal vit_ended


func _ready() -> void:
	await quest_created

	doc_mitchell = Global.npc_manager.get_npc(Characters.CHARACTERS.DOC_MITCHELL)
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
	related_character_died.connect(_on_related_character_died)

	set_subsequent_quest(Quests.QUESTS.BACK_IN_THE_SADDLE) # set what quest to trigger on completion

	_on_related_level_loaded(Levels.LEVELS.DOC_MITCHELLS_HOUSE)
	_on_related_timeline_played(Dialogue.TIMELINES.YOURE_AWAKE)


func _on_related_level_loaded(level: Levels.LEVELS) -> void:
	match(level):
		Levels.LEVELS.DOC_MITCHELLS_HOUSE:
			doc_mitchells_house = await Levels.get_current_level_node() if not doc_mitchells_house else doc_mitchells_house


func _on_related_character_died(_character: Characters.CHARACTERS) -> void:
	pass


func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.YOURE_AWAKE:
			if is_started():
				return
			start()
			await Dialogic.timeline_ended
			doc_mitchell.set_target(get_navpoint_position("VitMachine"))
			await vit_started
			mainplot.advance()
			await vit_ended
			mainplot.advance()
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_target(get_navpoint_position("Couch"))
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_timeline_enum(Dialogue.TIMELINES.PICKTAGS)
		Dialogue.TIMELINES.PICKTAGS:
			await Dialogic.timeline_ended
			mainplot.advance()
			doc_mitchell.set_target(get_navpoint_position("Exit"))
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_timeline_enum(Dialogue.TIMELINES.OFF_YOU_GO)
		Dialogue.TIMELINES.OFF_YOU_GO:
			await Dialogic.timeline_ended
			mainplot.advance()
