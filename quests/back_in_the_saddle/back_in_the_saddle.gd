class_name BackInTheSaddle extends Quest

var talk_to_sunny: Objective
var meet_sunny_in_the_back: Objective
var shoot_the_bottles: Objective
var follow_sunny: Objective
var kill_geckos_at_first_well: Objective
var talk_to_sunny_post_geckos: Objective
var talk_to_sunny_post_bottles: Objective
var kill_geckos_at_second_well: Objective
var get_reward: Objective
var saloon: Level
var goodsprings: Level
var sunny_smiles: NPC

signal bottle_shot
var num_bottles_shot: int = 0
signal first_well_gecko_killed
var num_first_well_geckos_killed: int = 0
signal second_well_gecko_killed
var num_second_well_geckos_killed: int = 0

func _ready() -> void:
	related_level_loaded.connect(_on_related_level_loaded)
	related_timeline_played.connect(_on_related_timeline_played)
	related_character_died.connect(_on_related_character_died)
	await quest_created
	sunny_smiles = Global.npc_manager.get_npc(Characters.CHARACTERS.SUNNY_SMILES)
	talk_to_sunny = mainplot.new_objective("Talk to Sunny Smiles at the prospector Saloon.")
	talk_to_sunny.pair_waypoints(["PortalToGoodsprings"])
	meet_sunny_in_the_back = mainplot.new_objective("Meet Sunny at the back of the Prospector Saloon.")
	shoot_the_bottles = mainplot.new_objective("Shoot the Sarsparilla Bottles")
	talk_to_sunny_post_bottles = mainplot.new_objective("Talk to Sunny.")
	follow_sunny = mainplot.new_objective("Follow Sunny.")
	kill_geckos_at_first_well = mainplot.new_objective("Kill the geckos at the well.")
	talk_to_sunny_post_geckos = mainplot.new_objective("Talk to Sunny Smiles.")
	kill_geckos_at_second_well = mainplot.new_objective("Kill the geckos at the other wells.")
	get_reward = mainplot.new_objective("Talk to Sunny about your reward.")
	mainplot.declare_all_objectives_assigned()

	bottle_shot.connect(_on_bottle_shot)
	first_well_gecko_killed.connect(_on_first_well_gecko_killed)
	second_well_gecko_killed.connect(_on_second_well_gecko_killed)


func _on_related_character_died(_character: Characters.CHARACTERS) -> void:
	pass


func _on_related_level_loaded(level: Levels.LEVELS) -> void:
	match(level):
		Levels.LEVELS.PROSPECTORS_SALOON:
			saloon = await Levels.get_current_level_node()
		Levels.LEVELS.GOODSPRINGS:
			goodsprings = await Levels.get_current_level_node()
			if not mainplot.current_objective == meet_sunny_in_the_back:
				return
			sunny_smiles.set_target(get_navpoint_position("Tutorial"))
			await sunny_smiles.wait_for_nav_finished()
			advance()
			Player.give_weapon("res://scenes/projectiles/fireball/fireball.tscn")
			while num_bottles_shot < 3:
				await bottle_shot
			advance()
			sunny_smiles.set_timeline_enum(Dialogue.TIMELINES.SHOT_BOTTLES)


func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.SUNNY_GREETING:
			if not Quests.is_quest_finished(Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD):
				start()
			await Dialogic.timeline_ended
			sunny_smiles.move_to_new_level(Levels.LEVELS.GOODSPRINGS)
			advance()
		Dialogue.TIMELINES.SHOT_BOTTLES:
			await Dialogic.timeline_ended
			advance()
			sunny_smiles.set_target(get_navpoint_position("Well1"))
			await sunny_smiles.navigation_finished
			advance()
			while num_first_well_geckos_killed < 3:
				await first_well_gecko_killed
			advance()
			sunny_smiles.set_timeline_enum(Dialogue.TIMELINES.CLEARED_FIRST_WELL_GECKOS)
		Dialogue.TIMELINES.CLEARED_FIRST_WELL_GECKOS:
			await Dialogic.timeline_ended
			advance()
			sunny_smiles.set_target(get_navpoint_position("Well2"))
			while num_second_well_geckos_killed < 3:
				await second_well_gecko_killed
			advance()
			Factions.set_faction_status(Factions.FACTIONS.GOODSPRINGS, Factions.STATUSES.LIKED)


# unfortunately these signals must be outside of the main methods because otherwise increments wouldn't track while another loop is running
func _on_bottle_shot() -> void:
	num_bottles_shot += 1


func _on_first_well_gecko_killed() -> void:
	num_first_well_geckos_killed += 1


func _on_second_well_gecko_killed() -> void:
	num_second_well_geckos_killed += 1
