extends Node

@onready var characters: Array[Characters.CHARACTERS] = [
	Characters.CHARACTERS.SUNNY_SMILES,
]

@onready var related_timelines: Array[Dialogue.TIMELINES] = [
	Dialogue.TIMELINES.SUNNY_GREETING,
]

@onready var related_levels: Array[Levels.LEVELS] = [
	Levels.LEVELS.PROSPECTORS_SALOON,
	Levels.LEVELS.GOODSPRINGS
]

enum CHOICES {}

#func _ready() -> void:
	#var main: Quest.Plot = back_in_the_saddle.mainplot
	#var find_sunny: Quest.Objective = main.new_objective("Talk to Sunny Smiles in the Prospector Saloon.")
	#var go_outside: Quest.Objective = main.new_objective("Meet Sunny Smiles behind the Prospector Saloon.")
	#var shoot_bottles: Quest.Objective = main.new_objective("Shoot 3 sarsaparilla bottles outside the Prospector Saloon.")
	#var follow_sunny: Quest.Objective = main.new_objective("Follow Sunny.")
	#var kill_geckos: Quest.Objective = main.new_objective("Kill the geckos at the well.")
	#var talk_to_sunny: Quest.Objective = main.new_objective("Talk to Sunny Smiles.")
	#var kill_other_geckos: Quest.Objective = main.new_objective("Kill the geckos at the other wells.")
	#var get_reward: Quest.Objective = main.new_objective("Talk to Sunny about your reward.")
#
	#back_in_the_saddle.overview()


@onready var quest: Quest = Quest.new(self, Quests.QUESTS.BACK_IN_THE_SADDLE)
func _ready() -> void:
	name = Quests.get_quest_name(Quests.QUESTS.BACK_IN_THE_SADDLE)
	quest.add_timelines(related_timelines)
	quest.add_characters(characters)
	quest.add_levels(related_levels)
	await quest.waypoints_assigned
	talk_to_sunny.pair_waypoints(["PortalToGoodsprings"])
	await quest.start()

# build the main quest
@onready var main: Quest.Plot = quest.mainplot
@onready var talk_to_sunny: Quest.Objective = main.new_objective("Talk to Sunny Smiles at the prospector Saloon.")
@onready var meet_sunny_in_the_back: Quest.Objective = main.new_objective("Meet Sunny at the back of the Prospector Saloon.")
@onready var shoot_the_bottles: Quest.Objective = main.new_objective("Shoot the Sarsparilla Bottles")
var saloon: Level = null
var sunny_smiles: NPC = null

func _on_related_level_loaded(level: Level) -> void:
	if level.level == Levels.LEVELS.PROSPECTORS_SALOON:
		sunny_smiles = await Global.npc_manager.get_npc(Characters.CHARACTERS.SUNNY_SMILES)
		saloon = await Levels.get_current_level()

# quest progression function, tracks when timelines and choreographs accordingly
func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	if timeline == Dialogue.TIMELINES.SUNNY_GREETING:
		await Dialogic.timeline_ended
		await sunny_smiles.move_to_new_level(Levels.LEVELS.GOODSPRINGS)
		main.advance()
