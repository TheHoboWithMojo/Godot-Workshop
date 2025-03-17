extends Node2D

# Constants
const FLOAT_LIMIT: float = 2147483647.0

# --- Member Variables ---
@onready var player: CharacterBody2D = $"/root/Game/Player"
@onready var frames: int = 0

# Stats dictionary
var _stats_dict: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed": 50
	},
	"health": {
		"health": 100.0,
		"health_regen": 0.05
	},
	"crit": {
		"crit_chance": 0.01,
		"crit_mult": 2.0
	},
	"personality": {
			"recklessness": 5,
			"bravery": 5,
			"intelligence": 5,
			"snarkiness": 5,
			"charisma": 5,
		}
}

# Stat Constraints
var stat_constraints: Dictionary = {
	"speed": {
		"speed_mult": {"min": 1.0, "max": 5.0},
		"speed_base": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"health": {
		"health": {"min": 0.0, "max": FLOAT_LIMIT},
		"health_regen": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"crit": {
		"crit_chance": {"min": 0.0, "max": 1.0},
		"crit_mult": {"min": 0.0, "max": FLOAT_LIMIT}
	}
}

# Timelines Dictionary
var Timelines: Dictionary = {
	"npc": {
		"completed": false,
		"repeatable": false
	}
}

func _is_valid_buff_string(string: String) -> bool:
	var buffs: Array = _split_buff_string(string)
	
	for buff in buffs:
		if buff.size() != 3:
			Debug.throw_error(self, "Buff does not contain the required word amount (3).", buff)
			return false
		
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: String = buff[2]
		if not _is_valid_stat(stat) or not _is_valid_operator(operator) or not value.is_valid_float():
			Debug.throw_error(self, "Invalid buff format", buff)
			return false
	
	return true

func _is_valid_stat(stat: String) -> bool:
	for stat_category in _stats_dict.values():
		if stat in stat_category:
			return true
	return false

func _is_valid_operator(_char: String) -> bool:
	return _char in ["*", "-", "+", "/"]

func _split_buff_string(buff_string: String) -> Array:
	var buffs: Array = []
	for buff in buff_string.split(";", false):
		var split_buff = buff.strip_edges().split(" ", false)
		if split_buff.size() == 3:
			buffs.append(Array(split_buff))
	return buffs

func _parse_buff_string(buff_string: String) -> Array:
	if _is_valid_buff_string(buff_string):
		var buffs: Array = _split_buff_string(buff_string)
		for buff in buffs:
			buff[2] = buff[2].to_float()
		return buffs
	return []

func player_get_stat(stat: String) -> float:
	var stat_category: String = _get_stat_category(stat)
	return _stats_dict[stat_category][stat] if stat_category else 0.0

func player_change_stat(buff_string: String) -> void:
	var buffs: Array = _parse_buff_string(buff_string)
	for buff in buffs:
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: float = buff[2]
		var stat_category: String = _get_stat_category(stat)
		
		if stat_category.is_empty():
			continue
			
		var original_stat_value: float = _stats_dict[stat_category][stat]
		var new_stat_value: float = _get_updated_stat(stat_category, stat, operator, value)
		_print_stat_change(stat, original_stat_value, new_stat_value)
		
func _print_stat_change(stat: String, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		stat, original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])

func _get_stat_category(stat: String) -> String:
	for stat_category in _stats_dict.keys():
		if stat in _stats_dict[stat_category]:
			return stat_category
	return ""

func _get_stat_constraints(stat_category: String, stat: String) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": FLOAT_LIMIT })

func _get_updated_stat(stat_category: String, stat: String, operator: String, value: float) -> float:
	var current_value: float = _stats_dict[stat_category][stat]
	match operator:
		"*": current_value *= value
		"-": current_value -= value
		"+": current_value += value
		"/": 
			if value != 0:
				current_value /= value
			else:
				Debug.throw_error(self, "Cannot divide by 0", str(value))
	var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
	var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
	_stats_dict[stat_category][stat] = constrained_value
	return constrained_value

func print_player_perks():
	print("=== All Perks ===")
	for perk_name in Data.game_data["perks"]:
		var perk = Data.game_data["perks"][perk_name]
		print("\nPerk: ", perk_name)
		for property in perk:
			print("  %s: %s" % [property, perk[property]])

func print_player_traits():
	print("=== All Traits ===")
	for trait_name in Data.game_data["traits"]:
		var _trait = Data.game_data["traits"][trait_name]
		print("\nTrait: ", trait_name)
		for property in _trait:
			print("  %s: %s" % [property, _trait[property]])

func player_add_perk(perk_name: String) -> void:
	if not Data.game_data["perks"].has(perk_name):
		print("Could not find '", perk_name, "' in perks data")
		print_player_perks()
		return
		
	if _update_toggle_buff(perk_name, Data.game_data["perks"]):
		print(perk_name, " boolean buff was added!")
	else:
		print(perk_name, " boolean buff is already active.")

func player_add_trait(trait_name: String) -> void:
	if not Data.game_data["traits"].has(trait_name):
		Debug.throw_error(self, trait_name + " not found in traits.")
		print_player_traits()
		return
		
	if _update_toggle_buff(trait_name, Data.game_data["traits"]):
		print(trait_name, " boolean buff was added!")
	else:
		print(trait_name, " boolean buff is already active.")

func _is_toggle_buff_active(buff_dict: Dictionary) -> bool:
	return buff_dict.get("has") == "true"

func _update_toggle_buff(buff_name: String, buff_data: Dictionary) -> bool:
	if not buff_data.has(buff_name):
		return false
		
	var buff = buff_data[buff_name]
	
	if _is_toggle_buff_active(buff):
		return false
	
	buff["has"] = "true"
	player_change_stat(buff.get("buffs", ""))
	return true

# --- Timeline Methods ---
func _is_timeline_completed(timeline: String) -> bool:
	return Timelines[timeline]["completed"] == true

func _is_timeline_repeatable(timeline: String) -> bool:
	return Timelines[timeline]["repeatable"] == true

func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null

func start_dialog(timeline: String) -> void:
	if _is_timeline_running():
		Debug.throw_error(self, "A timeline is already running! Cannot start a new one.")
		return
	if timeline in Timelines:
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			Debug.throw_error(self, "The timeline " + timeline + " has been played and is not repeatable")
			return
		
		Timelines[timeline]["completed"] = true
		Dialogic.start(timeline)
	else:
		Debug.throw_error(self, "The timeline " + timeline + " does not exist.")

# --- Vector and Debug Methods ---
func get_vector_to_player(self_node: Node2D) -> Vector2:
	if player:
		return player.global_position - self_node.global_position
	else:
		print(self, "get_vector_to_player()", "Player Path Has Changed")
		return Vector2.ZERO

func debug() -> void:
	print("""
Show Vectors:
func _draw() -> void:
	draw_line(Vector2.ZERO, vector_to_player, Color.GREEN, 2.0)
func _ready() -> void:
	queue_redraw()
func _process(_delta: float) -> void:
	vector_to_player = get_vector_to_player(self)
	queue_redraw()
""")

func _ready() -> void:
	frames += 1
	if frames >= 100:
		frames = 0
