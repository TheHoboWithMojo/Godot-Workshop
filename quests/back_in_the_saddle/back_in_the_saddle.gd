class_name BackInTheSaddle extends Quest

var talk_to_sunny: Objective
var meet_sunny_in_the_back: Objective
var shoot_the_bottles: Objective
var shoot_bottles: Objective
var follow_sunny: Objective
var kill_geckos: Objective
var talk_to_sunny_post_geckos: Objective
var talk_to_sunny_post_bottles: Objective
var kill_other_geckos: Objective
var get_reward: Objective
var saloon: Level
var goodsprings: Level
var sunny_smiles: NPC
var bottles_shot: int = 0

signal bottle_shot

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
	kill_geckos = mainplot.new_objective("Kill the geckos at the well.")
	talk_to_sunny_post_geckos = mainplot.new_objective("Talk to Sunny Smiles.")
	kill_other_geckos = mainplot.new_objective("Kill the geckos at the other wells.")
	get_reward = mainplot.new_objective("Talk to Sunny about your reward.")


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
			mainplot.advance()
			Player.give_weapon("res://scenes/projectiles/fireball/fireball.tscn")
			while bottles_shot < 3:
				await bottle_shot
				bottles_shot += 1
			mainplot.advance()


func _on_related_timeline_played(timeline: Dialogue.TIMELINES) -> void:
	match(timeline):
		Dialogue.TIMELINES.SUNNY_GREETING:
			if not Global.quest_manager.aint_that_a_kick_in_the_head.is_complete():
				start()
			await Dialogic.timeline_ended
			sunny_smiles.move_to_new_level(Levels.LEVELS.GOODSPRINGS)
			mainplot.advance()
