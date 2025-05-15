extends Node

@onready var characters: Array[Dialogue.CHARACTERS] = [
	Dialogue.CHARACTERS.SUNNY_SMILES,
]

@onready var related_timelines: Array[Dialogue.TIMELINES] = [
]

@onready var related_levels: Array[Levels.LEVELS] = [
	
]

enum CHOICES {}

func _ready() -> void:
	var back_in_the_saddle: Quest = Quest.new(self)
	
	var main: Quest.Plot = back_in_the_saddle.mainplot
	var find_sunny: Quest.Objective = main.new_objective("Talk to Sunny Smiles in the Prospector Saloon.")
	var go_outside: Quest.Objective = main.new_objective("Meet Sunny Smiles behind the Prospector Saloon.")
	var shoot_bottles: Quest.Objective = main.new_objective("Shoot 3 sarsaparilla bottles outside the Prospector Saloon.")
	var follow_sunny: Quest.Objective = main.new_objective("Follow Sunny.")
	var kill_geckos: Quest.Objective = main.new_objective("Kill the geckos at the well.")
	var talk_to_sunny: Quest.Objective = main.new_objective("Talk to Sunny Smiles.")
	var kill_other_geckos: Quest.Objective = main.new_objective("Kill the geckos at the other wells.")
	var get_reward: Quest.Objective = main.new_objective("Talk to Sunny about your reward.")
	
	#back_in_the_saddle.overview()
	
