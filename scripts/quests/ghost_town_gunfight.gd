extends Node
@onready var characters: Array[Characters.CHARACTERS] = [
	Characters.CHARACTERS.DOC_MITCHELL,
	Characters.CHARACTERS.SUNNY_SMILES,
	Characters.CHARACTERS.CHET,
	Characters.CHARACTERS.RINGO,
	Characters.CHARACTERS.TAMMY,
	Characters.CHARACTERS.OLD_MAN_PETE
]

@onready var related_timelines: Array[Dialogue.TIMELINES] = [
]

@onready var related_levels: Array[Levels.LEVELS] = [

]

enum CHOICES {}

#func _ready() -> void:
	#var ghost_town_gunfight: QuestMaker = QuestMaker.new(self)
	#
	#var main: QuestMaker.Plot = ghost_town_gunfight.mainplot
	#var offer_help: QuestMaker.Objective = main.new_objective("Offer to help Ringo deal with the Powder Gangers.")
	#var talk_to_sunny: QuestMaker.Objective = main.new_objective("Talk to Sunny Smiles about fighting the Powder Gangers.")
#
	#var trudy_plot: QuestMaker.Plot = ghost_town_gunfight.new_sideplot("Recruit Trudy")
	#var enlist_trudy: QuestMaker.Objective = trudy_plot.new_objective("Enlist the help of Trudy.")
#
	#var chet_plot: QuestMaker.Plot = ghost_town_gunfight.new_sideplot("Convince Chet")
	#var enlist_chet: QuestMaker.Objective = chet_plot.new_objective("Convince Chet to open his store's stock to the town.")
#
	#var doc_plot: QuestMaker.Plot = ghost_town_gunfight.new_sideplot("Get Medical Supplies")
	#var enlist_doc: QuestMaker.Objective = doc_plot.new_objective("Acquire additional medical supplies from Doc Mitchell.")
#
	#var pete_plot: QuestMaker.Plot = ghost_town_gunfight.new_sideplot("Get Dynamite")
	#var enlist_pete: QuestMaker.Objective = pete_plot.new_objective("Get some dynamite from Easy Pete.")
#
	#var return_to_ringo: QuestMaker.Objective = main.new_objective("Return to Ringo when you're ready for the gunfight with the Powder Gangers.")
	#var ready_for_battle: QuestMaker.Objective = main.new_objective("Join up with Sunny.")
	#
	#if chet_plot.is_complete() and trudy_plot.is_complete():
		#pass
		##logic to move them to battle and aggro them
		#
	## logic to catch things and advance plots
	#
	##ghost_town_gunfight.overview()
