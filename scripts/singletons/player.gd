extends Node2D

# Stat Constraints
var stat_constraints: Dictionary = {
	"speed": {
		"speed_mult": {"min": 1.0, "max": 5.0},
		"speed_base": {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	"health": {
		"health": {"min": 0.0, "max": Global.FLOAT_LIMIT},
		"health_regen": {"min": 0.0, "max": Global.FLOAT_LIMIT}
	},
	"crit": {
		"crit_chance": {"min": 0.0, "max": 1.0},
		"crit_mult": {"min": 0.0, "max": Global.FLOAT_LIMIT}
	}
}

var stats: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed": 10000.0,
		"attack_speed_mult": 3.00,
	},
	"special": {
		"strength": 5,
		"perception": 5,
		"endurance": 5,
		"charisma": 5,
		"intelligence": 5,
		"agility": 5,
		"luck": 5
	},
	"health": {
		"max_health": 100.0,
		"health": 100.0,
		"health_regen": 0.05
	},
	"crit": {
		"crit_chance": 0.01,
		"crit_mult": 2.0
	},
	"exp": {
		"exp": 0.0,
		"exp_mult": 1.0
	},
	"personality": {
		"bravery": 5,
		"intelligence": 5,
		"snarkiness": 5,
		"charisma": 5,
		"cruelty": 5,
		"selflessness": 5,
		"selfishness": 5,
	},
	"accomplishments": {
		"enemies_killed": 0,
	},
	"damage":{
		"fire_damage_mult": 1.0,
		"melee_damage_mult": 1.0,
		"explosive_damage_mult": 1.0,
		"persuasion_damage": 0,
	}
}

var perks: Dictionary = {
	"heavy_handed":
		{
		"reqs": {"level": 5, "bravery": 10},
		"buffs": "melee_damage_mult + 0.05",
		},
	"experienced":
		{
		"reqs": {"level": 2, "intelligence": 5},
		"buffs": "exp_mult + 0.05",
		},
	"asshole":
		{
		"reqs": {"level": 5, "cruelty": 10},
		"buffs": "none",
		"abilities": "none" # write the function name that adds the functionality so you can call it here
		},
	"politician":
		{
		"reqs": {"level": 1, "charisma": 10},
		"buffs": "persuasion_damage + 0.05",
		"abilities": "none"
		},
}

var choices: Array[String]

# Functions Related to Player Stats and Behavior
func aggro_conversers() -> void:
	for node: Node2D in Global.player.current_conversers:
		if "master" in node:
			node.master.set_hostile(true)

func get_stat(stat: String) -> float:
	var stat_category: String = _get_stat_category(stat)
	return Data.game_data["stats"][stat_category][stat] if stat_category else 0.0

@onready var _damagable: bool = true
func damage(amount: float) -> void:
	if _damagable:
		_damagable = false
		Global.player.health -= amount
		change_stat("health = %s" % [Global.player.health])
		await Global.delay(self, 1.0) # IFRAMES
		_damagable = true

func heal(amount: float) -> void:
	Global.player.health -= amount
	change_stat("health + %s" % [Global.player.health])

func add_exp(exp_gain: int) -> void:
	change_stat("exp + %s" % [exp_gain*get_stat("exp_mult")])
	
func log_kill(exp_gain: int) -> void:
	add_exp(exp_gain)
	change_stat("enemies_killed + 1")

func add_perk(perk_name: String) -> void:
	if not Data.game_data["perks"].has(perk_name):
		print("Could not find '", perk_name, "' in perks data")
		Debug.print_player_perks()
		return
		
	if _update_toggle_buff(perk_name, Data.game_data["perks"]):
		print(perk_name, " boolean buff was added!")
		
func change_name(nomen: String) -> void:
	Global.player.nametag.set_text(nomen)

func change_stat(buff_string: String, debug: bool = false) -> void:
	var buffs: Array = _parse_buff_string(buff_string)
	for buff: Array in buffs:
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: float = buff[2]
		var stat_category: String = _get_stat_category(stat)
		
		if stat_category.is_empty():
			continue
			
		var original_stat_value: float = Data.game_data["stats"][stat_category][stat]
		var new_stat_value: float = _get_updated_stat(stat_category, stat, operator, value)
		
		if debug:
			_print_stat_change(stat, original_stat_value, new_stat_value)
			
# =============================================
# PRIVATE HELPER FUNCTIONS
# =============================================
# Parses a buff string, i.e. "stat", "operator", value pair and directly modifies the game data dict
# Can be generalized to all beings NOT JUST PLAYER
# Buff string Ex: "health + 5"
func _is_valid_buff_string(string: String) -> bool:
	var buffs: Array = _split_buff_string(string)
	for buff: Array in buffs:
		if buff.size() != 3:
			Debug.throw_error(self, "_is_valid_buff_string", "Buff does not contain the required word amount (3)", buff)
			return false
		
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: String = buff[2]
		if not _is_valid_stat(stat) or not _is_valid_operator(operator) or not value.is_valid_float():
			Debug.throw_error(self, "_is_valid_buff_string", "Invalid buff format", buff)
			return false
	
	return true

func _is_valid_stat(stat: String) -> bool:
	for stat_category: Dictionary in Data.game_data["stats"].values():
		if stat in stat_category:
			return true
	return false

func _is_valid_operator(_char: String) -> bool:
	return _char in ["*", "-", "+", "/", "="]

func _split_buff_string(buff_string: String) -> Array:
	var buffs: Array = []
	for buff: String in buff_string.split(";", false):
		var split_buff: Array = buff.strip_edges().split(" ", false)
		if split_buff.size() == 3:
			buffs.append(Array(split_buff))
	return buffs

func _parse_buff_string(buff_string: String) -> Array:
	if _is_valid_buff_string(buff_string):
		var buffs: Array = _split_buff_string(buff_string)
		for buff: Array in buffs:
			buff[2] = buff[2].to_float()
		return buffs
	return []

func _print_stat_change(stat: String, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		stat, original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])

func _get_stat_category(stat: String) -> String:
	if Global.game_manager.active:
		for stat_category: String in Data.game_data["stats"].keys():
			if stat in Data.game_data["stats"][stat_category]:
				return stat_category
		return ""
	return ""

func _get_stat_constraints(stat_category: String, stat: String) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": Global.FLOAT_LIMIT })

func _get_updated_stat(stat_category: String, stat: String, operator: String, value: float) -> float:
	if Global.player:
		var current_value: float = Data.game_data["stats"][stat_category][stat]
		match operator:
			"*": current_value *= value
			"-": current_value -= value
			"+": current_value += value
			"=": current_value = value
			"/": 
				if value != 0:
					current_value /= value
				else:
					Debug.throw_error(self, "_get_updated_stat", "Cannot divide by 0")
		var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
		var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
		Data.game_data["stats"][stat_category][stat] = constrained_value
		
		return constrained_value
	return 0.0

func _is_toggle_buff_active(buff_dict: Dictionary) -> bool:
	return buff_dict.get("has") == "true"

func _update_toggle_buff(buff_name: String, buff_data: Dictionary) -> bool:
	if not buff_data.has(buff_name):
		return false
		
	var buff: Dictionary = buff_data[buff_name]
	
	if _is_toggle_buff_active(buff):
		return false
	
	buff["has"] = "true"
	Player.change_stat(buff.get("buffs", ""))
	return true
