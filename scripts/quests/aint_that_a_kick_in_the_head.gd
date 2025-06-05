extends Quest

var walk_to_vit: Objective
var use_the_vit: Objective
var sit_down: Objective
var exit: Objective
var doc_mitchell: NPC
var doc_nav: NavigationComponent
var doc_speech: DialogComponent
var doc_mitchells_house: Node
var vit_machine: Interactable

func _ready() -> void:
	await quest_created
	await waypoints_assigned
	walk_to_vit = mainplot.new_objective("Walk to the Vit-o-Matic Vigor Tester.")
	walk_to_vit.pair_waypoints(["VitMachine"])
	use_the_vit = mainplot.new_objective("Use the Vit-o-Matic Vigor Tester.")
	use_the_vit.pair_waypoints(["VitMachine"])
	sit_down = mainplot.new_objective("Sit down on the couch in Doc Mitchell's living room.")
	sit_down.pair_waypoints(["Couch"])
	exit = mainplot.new_objective("Follow Doc Mitchell to the exit.")
	exit.pair_waypoints(["Exit"])
	related_character_loaded.connect(_on_related_character_loaded)
	related_level_loaded.connect(_on_related_level_loaded)
	related_timeline_played.connect(_on_related_timeline_played)
	# force the signals - default level so it's tricky
	_on_related_level_loaded(Levels.LEVELS.DOC_MITCHELLS_HOUSE)
	_on_related_character_loaded(Characters.CHARACTERS.DOC_MITCHELL)
	_on_related_timeline_played(Dialogue.TIMELINES.YOURE_AWAKE)

signal doc_assigned
signal vit_assigned

#func _on_new_npc_loaded(npc: NPC) -> void:
	#doc_mitchell = await Global.npc_manager.get_npc(npc.get_character_enum()) if npc.get_character_enum() == Characters.CHARACTERS.DOC_MITCHELL else doc_mitchell

func _on_related_level_loaded(level: Levels.LEVELS) -> void:
	match(level):
		Levels.LEVELS.DOC_MITCHELLS_HOUSE:
			doc_mitchells_house = await Levels.get_current_level_node() if not doc_mitchells_house else doc_mitchells_house
			vit_machine = doc_mitchells_house.find_child("VitMachine") if not vit_machine else vit_machine
			vit_assigned.emit()


func _on_related_character_loaded(character: Characters.CHARACTERS) -> void:
	match(character):
		Characters.CHARACTERS.DOC_MITCHELL:
			doc_mitchell = await Global.npc_manager.get_npc(Characters.CHARACTERS.DOC_MITCHELL)
			doc_nav = doc_mitchell.get_navigator()
			doc_speech = doc_mitchell.get_dialog_component()
			doc_assigned.emit()


# quest progression function, tracks when timelines and choreographs accordingly
func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.YOURE_AWAKE:
			if not walk_to_vit.is_complete():
				await Dialogic.timeline_ended
				start()
				doc_nav.set_target(get_navpoint_position("VitMachine"))
				await vit_machine.event_started
				mainplot.advance()
				await vit_machine.event_ended
				mainplot.advance()
				await doc_nav.navigation_finished
				doc_nav.set_target(get_navpoint_position("Couch"))
				await doc_nav.navigation_finished
				doc_speech.set_timeline(Dialogue.TIMELINES.PICKTAGS)
		Dialogue.TIMELINES.PICKTAGS:
			if not use_the_vit.is_complete():
				await Dialogic.timeline_ended
				mainplot.advance()
				doc_nav.set_target(Vector2(0,0))
				await doc_nav.navigation_finished
				doc_nav.set_target(get_navpoint_position("Exit"))
				await doc_nav.navigation_finished
				Global.set_fast_travel_enabled(true)
