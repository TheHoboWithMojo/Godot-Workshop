extends Node
@export var debugging: bool = false
enum STATS {
	UNASSIGNED,
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

enum CATEGORIES {UNASSIGNED, SPECIAL, SPEED, HEALTH, CRIT, EXP, DAMAGE, ACCOMPLISHMENTS}

# Stats and Constraints
var stats_dict: Dictionary[CATEGORIES, Dictionary] = {
	CATEGORIES.SPECIAL: {
		STATS.STRENGTH: 5,
		STATS.PERCEPTION: 5,
		STATS.ENDURANCE: 5,
		STATS.CHARISMA: 5,
		STATS.INTELLIGENCE: 5,
		STATS.AGILITY: 5,
		STATS.LUCK: 5
	},
	CATEGORIES.SPEED: {
		STATS.SPEED_MULT: 1.00,
		STATS.SPEED: 10000.0,
		STATS.ATTACK_SPEED_MULT: 3.00,
	},
	CATEGORIES.HEALTH: {
		STATS.MAX_HEALTH: 100.0,
		STATS.HEALTH: 100.0,
		STATS.HEALTH_REGEN: 0.05
	},
	CATEGORIES.CRIT: {
		STATS.CRIT_CHANCE: 0.01,
		STATS.CRIT_MULT: 2.0
	},
	CATEGORIES.EXP: {
		STATS.EXP: 0.0,
		STATS.EXP_MULT: 1.0
	},
	CATEGORIES.DAMAGE: {
		STATS.FIRE_DAMAGE_MULT: 1.0,
		STATS.MELEE_DAMAGE_MULT: 1.0,
		STATS.EXPLOSIVE_DAMAGE_MULT: 1.0,
		STATS.PERSUASION_DAMAGE: 0,
	},
	CATEGORIES.ACCOMPLISHMENTS: {
		STATS.ENEMIES_KILLED: 0,
	},
}

var stat_constraints: Dictionary = {
	CATEGORIES.SPEED: {
		STATS.SPEED_MULT: {"min": 1.0, "max": 5.0},
		STATS.SPEED: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	CATEGORIES.HEALTH: {
		STATS.HEALTH: {"min": 0.0, "max": Global.FLOAT_LIMIT},
		STATS.HEALTH_REGEN: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	CATEGORIES.CRIT: {
		STATS.CRIT_CHANCE: {"min": 0.0, "max": 1.0},
		STATS.CRIT_MULT: {"min": 0.0, "max": Global.FLOAT_LIMIT}
	}
}

func set_stat(stat: STATS, value: float, _stats_dict: Dictionary) -> bool:
	var stat_category: CATEGORIES = _get_stat_category(stat)
	var original_stat_value: float = float(Data.game_data[Data.PROPERTIES.PLAYER_STATS][stat_category][stat])
	var new_stat_value: float = _get_updated_stat(stat_category, stat, "=", value, _stats_dict)
	if new_stat_value == original_stat_value:
		return false
	Debug.debug("", Global.player, "set_stat")
	if debugging:
		_print_stat_change(stat, original_stat_value, new_stat_value)
	return true


func change_stat(stat: STATS, change: float, _stats_dict: Dictionary) -> bool:
	var stat_category: CATEGORIES = _get_stat_category(stat)
	var original_stat_value: float = get_stat(stat, _stats_dict)
	var new_stat_value: float = _get_updated_stat(stat_category, stat, "+", change, _stats_dict)
	if new_stat_value == original_stat_value:
		return false
	if debugging:
		_print_stat_change(stat, original_stat_value, new_stat_value)
	return true


func get_stat_name(stat: STATS) -> String:
	return Global.enum_to_title(stat, STATS)


func get_stat(stat: STATS, _stats_dict: Dictionary) -> float:
	var stat_category: CATEGORIES = _get_stat_category(stat)
	return _stats_dict[stat_category][stat]


func _print_stat_change(stat: STATS, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		STATS.keys()[stat], original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])


func _get_stat_category(stat: STATS) -> CATEGORIES:
	for category: CATEGORIES in Data.game_data[Data.PROPERTIES.PLAYER_STATS].keys():
		if not stat in Data.game_data[Data.PROPERTIES.PLAYER_STATS][category]:
			continue
		return category
	push_warning(Debug.define_error("Stat %s does not exist" % [stat], self))
	return CATEGORIES.UNASSIGNED


func _get_stat_constraints(stat_category: CATEGORIES, stat: STATS) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": Global.FLOAT_LIMIT })


func _get_updated_stat(stat_category: CATEGORIES, stat: STATS, operator: String, value: float, _stats_dict: Dictionary) -> float:
	var current_value: float = float(Data.game_data[Data.PROPERTIES.PLAYER_STATS][stat_category][stat])
	match operator:
		"*": current_value *= value
		"-": current_value -= value
		"+": current_value += value
		"=": current_value = value
		"/":
			if value == 0:
				push_warning(Debug.define_error("Cannot divide by 0.", self))
				return current_value
			current_value /= value

	var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
	var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
	_stats_dict[stat_category][stat] = constrained_value
	return constrained_value
