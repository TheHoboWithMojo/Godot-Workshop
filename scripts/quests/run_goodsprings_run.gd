extends Node
@onready var characters: Array[Dicts.CHARACTERS] = [
	Dicts.CHARACTERS.DOC_MITCHELL,
	Dicts.CHARACTERS.SUNNY_SMILES,
	Dicts.CHARACTERS.CHET,
	Dicts.CHARACTERS.RINGO,
	Dicts.CHARACTERS.TAMMY,
	Dicts.CHARACTERS.OLD_MAN_PETE
]

@onready var related_timelines: Array[Dicts.TIMELINES] = [
]

@onready var related_levels: Array[Dicts.LEVELS] = [
	
]

enum CHOICES {}

func _ready() -> void:
	var run_goodsprings_run: Quest = Quest.new(self)
	
	var main: Quest.Plot = run_goodsprings_run.mainplot
	var kill_ringo: Quest.Objective = main.new_objective("Kill Ringo.")
	var tell_cobb: Quest.Objective = main.new_objective("Inform Joe Cobb that Ringo is dead.")
	var ready_up: Quest.Objective = main.new_objective("Let Joe Cobb know when you're ready to take over Goodsprings.")
	var defeat_goodsprings: Quest.Objective = main.new_objective("Defeat the Goodsprings militia.")
	
	#run_goodsprings_run.overview()
