extends QuestMaker

enum CHOICES {}

#func _ready() -> void:
	#var shoot_bottles: Objective = main.new_objective("Shoot 3 sarsaparilla bottles outside the Prospector Saloon.")
	#var follow_sunny: Objective = main.new_objective("Follow Sunny.")
	#var kill_geckos: Objective = main.new_objective("Kill the geckos at the well.")
	#var talk_to_sunny: Objective = main.new_objective("Talk to Sunny Smiles.")
	#var kill_other_geckos: Objective = main.new_objective("Kill the geckos at the other wells.")
	#var get_reward: Objective = main.new_objective("Talk to Sunny about your reward.")
#
	#back_in_the_saddle.overview()

# declare the script-wide variables
var talk_to_sunny: Objective
var meet_sunny_in_the_back: Objective
var shoot_the_bottles: Objective
var saloon: Level
var goodsprings: Level
var sunny_smiles: NPC

func _ready() -> void:
	related_level_loaded.connect(_on_related_level_loaded)
	related_timeline_played.connect(_on_related_timeline_played)
	await quest_created
	sunny_smiles = Global.npc_manager.get_npc(Characters.CHARACTERS.SUNNY_SMILES)
	talk_to_sunny = mainplot.new_objective("Talk to Sunny Smiles at the prospector Saloon.")
	talk_to_sunny.pair_waypoints(["PortalToGoodsprings"])
	meet_sunny_in_the_back = mainplot.new_objective("Meet Sunny at the back of the Prospector Saloon.")
	shoot_the_bottles = mainplot.new_objective("Shoot the Sarsparilla Bottles")


func _on_related_level_loaded(level: Levels.LEVELS) -> void:
	match(level):
		Levels.LEVELS.PROSPECTORS_SALOON:
			saloon = await Levels.get_current_level_node()
		Levels.LEVELS.GOODSPRINGS:
			goodsprings = await Levels.get_current_level_node()
			if mainplot.current_objective == meet_sunny_in_the_back:
				sunny_smiles.set_target(get_navpoint_position("Tutorial"))
				await sunny_smiles.navigation_finished
				Player.give_weapon("res://scenes/projectiles/fireball.tscn")



func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.SUNNY_GREETING:
			if not talk_to_sunny.is_complete():
				await Dialogic.timeline_ended
				sunny_smiles.move_to_new_level(Levels.LEVELS.GOODSPRINGS)
				mainplot.advance()
