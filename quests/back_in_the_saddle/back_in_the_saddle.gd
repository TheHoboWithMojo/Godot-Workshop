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
var sunny_smiles: NPC

signal bottle_shot
var num_bottles_shot: int = 0
signal first_well_gecko_killed
var num_first_well_geckos_killed: int = 0
signal second_well_gecko_killed
var num_second_well_geckos_killed: int = 0

func _ready() -> void:
	await quest_created

	Global.level_manager.new_level_loaded.connect(_on_level_loaded)
	Dialogue.timeline_started.connect(_on_timeline_started)
	Characters.character_died.connect(_on_character_died)
	bottle_shot.connect(_on_bottle_shot)
	first_well_gecko_killed.connect(_on_first_well_gecko_killed)
	second_well_gecko_killed.connect(_on_second_well_gecko_killed)

	sunny_smiles = Global.npc_manager.get_npc(Characters.CHARACTERS.SUNNY_SMILES)
	talk_to_sunny = mainplot.new_plot_objective("Talk to Sunny Smiles at the prospector Saloon.")
	talk_to_sunny.pair_waypoints_to_objective(["PortalToGoodsprings"])
	meet_sunny_in_the_back = mainplot.new_plot_objective("Meet Sunny at the back of the Prospector Saloon.")
	meet_sunny_in_the_back.pair_waypoints_to_objective(["ShootBottles"])
	shoot_the_bottles = mainplot.new_plot_objective("Shoot the Sarsparilla Bottles")
	meet_sunny_in_the_back.pair_waypoints_to_objective(["ShootBottles"])
	talk_to_sunny_post_bottles = mainplot.new_plot_objective("Talk to Sunny.")
	meet_sunny_in_the_back.pair_waypoints_to_objective(["ShootBottles"])
	follow_sunny = mainplot.new_plot_objective("Follow Sunny.")
	kill_geckos_at_first_well = mainplot.new_plot_objective("Kill the geckos at the well.")
	talk_to_sunny_post_geckos = mainplot.new_plot_objective("Talk to Sunny Smiles.")
	kill_geckos_at_second_well = mainplot.new_plot_objective("Kill the geckos at the other wells.")
	get_reward = mainplot.new_plot_objective("Talk to Sunny about your reward.")
	mainplot.declare_all_plot_objectives_assigned()


func _on_character_died(_character: Characters.CHARACTERS) -> void:
	pass


func _on_level_loaded(level: Level) -> void:
	match(level.get_level_enum()):
		Levels.LEVELS.GOODSPRINGS:
			if not mainplot.current_objective == meet_sunny_in_the_back:
				return
			sunny_smiles.set_target(get_quest_navpoint_position("Tutorial"))
			await sunny_smiles.wait_for_nav_finished()
			progress_quest()
			Player.give_weapon("res://scenes/projectiles/fireball/fireball.tscn")
			while num_bottles_shot < 3:
				await bottle_shot
			progress_quest()
			sunny_smiles.set_timeline_enum(Dialogue.TIMELINES.SHOT_BOTTLES)


func _on_timeline_started(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.SUNNY_GREETING:
			if not Quests.is_quest_finished(Quests.QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD):
				start_quest()
			await Dialogic.timeline_ended
			sunny_smiles.move_to_new_level(Levels.LEVELS.DOC_MITCHELLS_HOUSE)
			progress_quest()
		Dialogue.TIMELINES.SHOT_BOTTLES:
			await Dialogic.timeline_ended
			progress_quest()
			sunny_smiles.set_target(get_quest_navpoint_position("Well1"))
			await sunny_smiles.navigation_finished
			progress_quest()
			while num_first_well_geckos_killed < 3:
				await first_well_gecko_killed
			progress_quest()
			sunny_smiles.set_timeline_enum(Dialogue.TIMELINES.CLEARED_FIRST_WELL_GECKOS)
		Dialogue.TIMELINES.CLEARED_FIRST_WELL_GECKOS:
			await Dialogic.timeline_ended
			progress_quest()
			sunny_smiles.set_target(get_quest_navpoint_position("Well2"))
			while num_second_well_geckos_killed < 3:
				await second_well_gecko_killed
			progress_quest()
			Factions.set_faction_status(Factions.FACTIONS.GOODSPRINGS, Factions.STATUSES.LIKED)


# unfortunately these signals must be outside of the main methods because otherwise increments wouldn't track while another loop is running
func _on_bottle_shot() -> void:
	num_bottles_shot += 1


func _on_first_well_gecko_killed() -> void:
	num_first_well_geckos_killed += 1


func _on_second_well_gecko_killed() -> void:
	num_second_well_geckos_killed += 1
