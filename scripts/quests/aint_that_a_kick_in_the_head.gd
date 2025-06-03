extends Node
@onready var quest: Quest = Quest.new(self, Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD)
func _ready() -> void:
	quest.add_timelines([Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS])
	quest.add_characters([Characters.CHARACTERS.DOC_MITCHELL])
	quest.add_levels([Levels.LEVELS.DOC_MITCHELLS_HOUSE])
	await quest.start()

	#Global.set_fast_travel_enabled(false) # can't leave tutorial
	#quest.waypoint_overview() # prints the names and coords of the placed waypoints
	#quest.navpoint_overview() # print the names and coods of placed navpoints
	walk_to_vit.pair_waypoints(["VitMachine"])
	use_the_vit.pair_waypoints(["VitMachine"])
	sit_down.pair_waypoints(["Couch"])
	exit.pair_waypoints(["Exit"])

# build the main quest
@onready var main: Quest.Plot = quest.mainplot
@onready var walk_to_vit: Quest.Objective = main.new_objective("Walk to the Vit-o-Matic Vigor Tester.")
@onready var use_the_vit: Quest.Objective = main.new_objective("Use the Vit-o-Matic Vigor Tester.")
@onready var sit_down: Quest.Objective = main.new_objective("Sit down on the couch in Doc Mitchell's living room.")
@onready var exit: Quest.Objective = main.new_objective("Follow Doc Mitchell to the exit.")

# init scene-specific variables that are assigned by the level loading function
var doc_mitchell: NPC
var doc_mitchells_house: Node
var vit_machine: Interactable

func _on_related_level_loaded(level: Level) -> void:
	if level.level == Levels.LEVELS.DOC_MITCHELLS_HOUSE:
		doc_mitchells_house = await Levels.get_current_level()
		doc_mitchell = await Global.npc_manager.get_npc(Characters.CHARACTERS.DOC_MITCHELL)
		vit_machine = doc_mitchells_house.find_child("VitMachine")

# quest progression function, tracks when timelines and choreographs accordingly
func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	var docs_nav: NavigationComponent = doc_mitchell.navigation_manager
	var docs_speech: DialogComponent = doc_mitchell.dialog_manager
	if timeline == Dialogue.TIMELINES.YOURE_AWAKE:
		await Dialogic.timeline_ended
		quest.start()
		docs_nav.set_target(quest.get_navpoint_position("VitMachine"))
		await vit_machine.event_started
		main.advance()
		await vit_machine.event_ended
		main.advance()
		await docs_nav.navigation_finished
		docs_nav.set_target(quest.get_navpoint_position("Couch"))
		await docs_nav.navigation_finished
		docs_speech.set_timeline(Dialogue.TIMELINES.PICKTAGS)
	elif timeline == Dialogue.TIMELINES.PICKTAGS:
		await Dialogic.timeline_ended
		main.advance()
		docs_nav.set_target(Vector2(0,0))
		await docs_nav.navigation_finished
		docs_nav.set_target(quest.get_navpoint_position("Exit"))
		await docs_nav.navigation_finished
		Global.set_fast_travel_enabled(true)
