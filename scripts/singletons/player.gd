extends Node2D
signal player_stats_changed
signal player_name_changed

var choices: Array[String]

# Enums
enum STATS {
	ERROR,
	SPEED_MULT,
	SPEED,
	ATTACK_SPEED_MULT,
	STRENGTH,
	PERCEPTION,
	ENDURANCE,
	CHARISMA,
	INTELLIGENCE,
	AGILITY,
	LUCK,
	MAX_HEALTH,
	HEALTH,
	HEALTH_REGEN,
	CRIT_CHANCE,
	CRIT_MULT,
	EXP,
	EXP_MULT,
	FIRE_DAMAGE_MULT,
	MELEE_DAMAGE_MULT,
	EXPLOSIVE_DAMAGE_MULT,
	PERSUASION_DAMAGE,
	ENEMIES_KILLED
}

enum STAT_CATEGORIES {ERROR, SPECIAL, SPEED, HEALTH, CRIT, EXP, DAMAGE, ACCOMPLISHMENTS}

enum PERKS {
	HEAVY_HANDED,
	EXPERIENCED,
	ASSHOLE,
	POLITICIAN
}

# Stats and Constraints
var stats: Dictionary = {
	STAT_CATEGORIES.SPECIAL: {
		STATS.STRENGTH: 5,
		STATS.PERCEPTION: 5,
		STATS.ENDURANCE: 5,
		STATS.CHARISMA: 5,
		STATS.INTELLIGENCE: 5,
		STATS.AGILITY: 5,
		STATS.LUCK: 5
	},
	STAT_CATEGORIES.SPEED: {
		STATS.SPEED_MULT: 1.00,
		STATS.SPEED: 10000.0,
		STATS.ATTACK_SPEED_MULT: 3.00,
	},
	STAT_CATEGORIES.HEALTH: {
		STATS.MAX_HEALTH: 100.0,
		STATS.HEALTH: 100.0,
		STATS.HEALTH_REGEN: 0.05
	},
	STAT_CATEGORIES.CRIT: {
		STATS.CRIT_CHANCE: 0.01,
		STATS.CRIT_MULT: 2.0
	},
	STAT_CATEGORIES.EXP: {
		STATS.EXP: 0.0,
		STATS.EXP_MULT: 1.0
	},
	STAT_CATEGORIES.DAMAGE: {
		STATS.FIRE_DAMAGE_MULT: 1.0,
		STATS.MELEE_DAMAGE_MULT: 1.0,
		STATS.EXPLOSIVE_DAMAGE_MULT: 1.0,
		STATS.PERSUASION_DAMAGE: 0,
	},
	STAT_CATEGORIES.ACCOMPLISHMENTS: {
		STATS.ENEMIES_KILLED: 0,
	},
}

var stat_constraints: Dictionary = {
	STAT_CATEGORIES.SPEED: {
		STATS.SPEED_MULT: {"min": 1.0, "max": 5.0},
		STATS.SPEED: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	STAT_CATEGORIES.HEALTH: {
		STATS.HEALTH: {"min": 0.0, "max": Global.FLOAT_LIMIT},
		STATS.HEALTH_REGEN: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	STAT_CATEGORIES.CRIT: {
		STATS.CRIT_CHANCE: {"min": 0.0, "max": 1.0},
		STATS.CRIT_MULT: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	}
}

# Perks
var perks: Dictionary = {
	PERKS.HEAVY_HANDED: {
		"reqs": {"level": 5, "bravery": 10},
		"buffs": {STATS.MELEE_DAMAGE_MULT: 0.05},
		"reversible": false
	},
	PERKS.EXPERIENCED: {
		"reqs": {"level": 2, "intelligence": 5},
		"buffs": {STATS.EXP_MULT: 0.05},
		"reversible": false
	},
	PERKS.ASSHOLE: {
		"reqs": {"level": 5, "cruelty": 10},
		"buffs": {},
		"reversible": false
	},
	PERKS.POLITICIAN: {
		"reqs": {"level": 1, "charisma": 10},
		"buffs": {STATS.PERSUASION_DAMAGE: 0.05},
		"abilities": {},
		"reversible": false
	},
}

@onready var _damagable: bool = true


func _process(_delta: float) -> void:
	if Global.frames % 120 == 0:
		check_for_achievements()


func set_stat(stat: STATS, value: float, debugging: bool = false) -> bool:
	var stat_category: STAT_CATEGORIES = _get_stat_category(stat)
	var original_stat_value: float = float(Data.game_data["stats"][str(stat_category)][str(stat)])
	var new_stat_value: float = _get_updated_stat(stat_category, stat, "=", value)
	if new_stat_value == original_stat_value:
		return false
	if debugging:
		_print_stat_change(stat, original_stat_value, new_stat_value)
	player_stats_changed.emit()
	return true


func get_stat_name(stat: STATS) -> String:
	return Global.enum_to_title(stat, STATS)


func get_stat(stat: STATS) -> float:
	var stat_category: STAT_CATEGORIES = _get_stat_category(stat)
	return Data.game_data["stats"][str(stat_category)][str(stat)]


func change_stat(stat: STATS, change: float) -> bool:
	var stat_category: STAT_CATEGORIES = _get_stat_category(stat)
	var original_stat_value: float = get_stat(stat)
	var new_stat_value: float = _get_updated_stat(stat_category, stat, "+", change)
	if new_stat_value == original_stat_value:
		return false
	player_stats_changed.emit()
	_print_stat_change(stat, original_stat_value, new_stat_value)
	return true


func set_perk_active(perk: PERKS, value: bool) -> bool:
	if is_perk_active(perk) and not is_perk_reversible(perk):
		return false
	Data.game_data["perks"][str(perk)]["has"] = value
	return true


func is_perk_reversible(perk: PERKS) -> bool:
	return Data.game_data["perks"][str(perk)]["reversible"] == "true"


func is_perk_active(perk: PERKS) -> bool:
	return Data.game_data["perks"][str(perk)]["has"] == "true"


func get_perk_name(perk: PERKS) -> String:
	return Global.enum_to_title(perk, PERKS)


func check_for_achievements() -> void:
	if Player.get_stat(Player.STATS.ENEMIES_KILLED) > 5:
		Player.set_perk_active(Player.PERKS.ASSHOLE, true)


func damage(amount: float) -> bool:
	if not _damagable:
		return false
	_damagable = false
	Global.player.health -= amount
	change_stat(STATS.HEALTH, -amount)
	await Global.delay(self, 1.0)
	_damagable = true
	return true


func heal(amount: float) -> void:
	change_stat(STATS.HEALTH, amount)


func add_exp(exp_gain: int) -> void:
	var exp_mult: float = get_stat(STATS.EXP_MULT)
	change_stat(STATS.EXP, exp_gain * exp_mult)


func log_kill(exp_gain: int) -> void:
	add_exp(exp_gain)
	change_stat(STATS.ENEMIES_KILLED, 1)


func change_name(nomen: String) -> void:
	Global.player.nametag.set_text(nomen)
	player_name_changed.emit()


func is_occupied() -> bool:
	return Global.is_in_menu() or Dialogue.is_dialogue_playing()


func set_objective(objective: Quest.Objective) -> void:
	var objective_box: RichTextLabel = Global.quest_box.get_node("Box/Objective")
	objective_box.set_text(objective.nomen)


func set_quest(quest: Quest) -> void:
	var quest_box: RichTextLabel = Global.quest_box.get_node("Box/Quest")
	quest_box.set_text(quest.nomen + ":")


func _print_stat_change(stat: STATS, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		STATS.keys()[stat], original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])


func _get_stat_category(stat: STATS) -> STAT_CATEGORIES:
	for category: String in Data.game_data["stats"].keys():
		if not str(stat) in Data.game_data["stats"][category]: # go through all categories until you find the stat
			continue
		@warning_ignore("int_as_enum_without_cast")
		return int(category) # return the category that had the stat
	Debug.throw_error(self, "_get_stat_category", "Stat %s does not exist" % [stat])
	return STAT_CATEGORIES.ERROR


func _get_stat_constraints(stat_category: STAT_CATEGORIES, stat: STATS) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": Global.FLOAT_LIMIT })


func _get_updated_stat(stat_category: STAT_CATEGORIES, stat: STATS, operator: String, value: float) -> float:
	var current_value: float = float(Data.game_data["stats"][str(stat_category)][str(stat)])
	match operator:
		"*": current_value *= value
		"-": current_value -= value
		"+": current_value += value
		"=": current_value = value
		"/":
			if value == 0:
				Debug.throw_error(self, "_get_updated_stat", "Cannot divide by 0")
				return current_value
			current_value /= value

	var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
	var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
	Data.game_data["stats"][str(stat_category)][str(stat)] = constrained_value

	return constrained_value
