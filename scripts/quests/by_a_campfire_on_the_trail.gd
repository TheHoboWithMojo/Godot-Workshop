extends Node

@onready var characters: Array[Characters.CHARACTERS] = [
	Characters.CHARACTERS.SUNNY_SMILES,
]

@onready var related_timelines: Array[Dialogue.TIMELINES] = [
]

@onready var related_levels: Array[Levels.LEVELS] = [

]

enum CHOICES {}

#func _ready() -> void:
	#var by_a_campfire_on_the_trail: QuestMaker = QuestMaker.new(self)
	#
	#var main: QuestMaker.Plot = by_a_campfire_on_the_trail.mainplot
	#var find_herbs: QuestMaker.Objective = main.new_objective("Find a broc flower and a xander root.")
	#var make_powder: QuestMaker.Objective = main.new_objective("Use the campfire to make Healing Powder.")
	#var meet_trudy: QuestMaker.Objective = main.new_objective("Go and meet Trudy at the Prospector Saloon.")
	#
	##by_a_campfire_on_the_trail.overview()
