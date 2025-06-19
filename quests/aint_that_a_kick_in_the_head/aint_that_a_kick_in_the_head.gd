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

	Dialogue.timeline_started.connect(_on_timeline_started)
	Characters.character_died.connect(_on_character_died)

	doc_mitchell = Global.npc_manager.get_npc(Characters.CHARACTERS.DOC_MITCHELL)
	walk_to_vit = mainplot.new_plot_objective("Walk to the Vit-o-Matic Vigor Tester.")
	walk_to_vit.pair_waypoints_to_objective(["VitMachine"])
	use_the_vit = mainplot.new_plot_objective("Use the Vit-o-Matic Vigor Tester.")
	use_the_vit.pair_waypoints_to_objective(["VitMachine"])
	sit_down = mainplot.new_plot_objective("Sit down on the couch in Doc Mitchell's living room.")
	sit_down.pair_waypoints_to_objective(["Couch"])
	exit = mainplot.new_plot_objective("Follow Doc Mitchell to the exit.")
	exit.pair_waypoints_to_objective(["Exit"])

	mainplot.declare_all_plot_objectives_assigned()

	while await Levels.get_current_level_enum() != Levels.LEVELS.DOC_MITCHELLS_HOUSE:
		await Global.level_manager.new_level_loaded

	var timeline_to_set: Dialogue.TIMELINES
	var position_to_set: Vector2

	match(mainplot.get_plot_latest_unfinished_objective()):
		walk_to_vit:
			Dialogue.start(Dialogue.TIMELINES.YOURE_AWAKE)
		use_the_vit:
			position_to_set = get_quest_navpoint_position("VitMachine")
		sit_down:
			position_to_set = get_quest_navpoint_position("Couch")
			timeline_to_set = Dialogue.TIMELINES.PICKTAGS
		exit:
			position_to_set = get_quest_navpoint_position("Exit")
			timeline_to_set = Dialogue.TIMELINES.OFF_YOU_GO
	if position_to_set:
		doc_mitchell.place_at(position_to_set)
	if timeline_to_set:
		doc_mitchell.set_timeline_enum(timeline_to_set)

	# set what quest to trigger on completion
	set_subsequent_quest(Quests.QUESTS.BACK_IN_THE_SADDLE)


func _on_character_died(_character: Characters.CHARACTERS) -> void:
	pass


func _on_timeline_started(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.YOURE_AWAKE:
			start_quest()
			await Dialogic.timeline_ended
			doc_mitchell.set_target(get_quest_navpoint_position("VitMachine"))
			await vit_started
			progress_quest()
			await vit_ended
			progress_quest()
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_target(get_quest_navpoint_position("Couch"))
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_timeline_enum(Dialogue.TIMELINES.PICKTAGS)
		Dialogue.TIMELINES.PICKTAGS:
			await Dialogic.timeline_ended
			progress_quest()
			doc_mitchell.set_target(get_quest_navpoint_position("Exit"))
			await doc_mitchell.wait_for_nav_finished()
			doc_mitchell.set_timeline_enum(Dialogue.TIMELINES.OFF_YOU_GO)
		Dialogue.TIMELINES.OFF_YOU_GO:
			await Dialogic.timeline_ended
			progress_quest()
