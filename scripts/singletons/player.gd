extends Node
signal player_stats_changed
signal player_name_changed

var choices: Array[String]
var player: CharacterBody2D = null

var _damagable: bool = true
var debugging: bool = false


func _ready() -> void:
	set_process(false)
	await Global.ready_to_start()
	player = Global.player
	set_process(true)


func _process(_delta: float) -> void:
	if Global.frames % 120 == 0:
		check_for_achievements()


func is_player_moving() -> bool:
	return player.velocity.length() > 0


func give_weapon(scene_path: String) -> void:
	var weapon: PackedScene = load(scene_path)
	if not weapon in player.projectiles: # Check if the player already has the projectile
		player.projectiles.append(weapon)
		Data.game_data[Data.PROPERTIES.RELOAD_DATA]["acquired_weapons"].append(weapon.get_path())

		if player.projectiles.size() == 1: # if its the first they pick up, set it as their active
			player.current_projectile = weapon


func check_for_achievements() -> void:
	Global.if_do(Player.get_stat(Stats.STATS.ENEMIES_KILLED) > 5, [{Player.set_perk_active: [Perks.PERKS.ASSHOLE, true]}])


func set_perk_active(perk: Perks.PERKS, value: bool) -> bool:
	if Perks.is_perk_active(perk, Data.game_data[Data.PROPERTIES.PLAYER_PERKS]) and not Perks.is_perk_reversible(perk):
		return false
	Data.game_data[Data.PROPERTIES.PLAYER_PERKS][perk][Perks.PROPERTIES.ACTIVE] = value
	return true


func is_perk_active(perk: Perks.PERKS) -> bool:
	return Data.game_data[Data.PROPERTIES.PLAYER_PERKS][perk][Perks.PROPERTIES.ACTIVE] == true


func damage(amount: float) -> bool:
	if not _damagable:
		return false
	_damagable = false
	player.health -= amount
	Stats.change_stat(Stats.STATS.HEALTH, -amount, Data.game_data[Data.PROPERTIES.PLAYER_STATS])
	await Global.delay(self, 1.0)
	_damagable = true
	return true


func set_stat(stat: Stats.STATS, value: float) -> bool:
	if Stats.set_stat(stat, value, Data.game_data[Data.PROPERTIES.PLAYER_STATS]):
		player_stats_changed.emit()
		return true
	return false


func change_stat(stat: Stats.STATS, change: float) -> bool:
	if Stats.change_stat(stat, change, Data.game_data[Data.PROPERTIES.PLAYER_STATS]):
		player_stats_changed.emit()
		return true
	return false


func get_stat(stat: Stats.STATS) -> float:
	return Stats.get_stat(stat, Data.game_data[Data.PROPERTIES.PLAYER_STATS])


func heal(amount: float) -> void:
	change_stat(Stats.STATS.HEALTH, amount)


func add_exp(exp_gain: int) -> void:
	var exp_mult: float = get_stat(Stats.STATS.EXP_MULT)
	change_stat(Stats.STATS.EXP, exp_gain * exp_mult)


func log_kill(exp_gain: int) -> void:
	add_exp(exp_gain)
	change_stat(Stats.STATS.ENEMIES_KILLED, 1)


func set_movement_enabled(value: bool) -> void:
	player.movement_enabled(value)


func change_name(nomen: String) -> void:
	player.nametag.set_text(nomen)
	player_name_changed.emit()


func is_occupied() -> bool:
	return Global.is_in_menu() or Dialogue.is_dialogue_playing()


func set_objective(objective: Quest.Objective) -> void:
	Global.quest_displayer.get_node("Objective").set_text(objective.nomen)


func set_quest(quest: Quest) -> void:
	Global.quest_displayer.get_node("Quest").set_text(quest.name + ":")
