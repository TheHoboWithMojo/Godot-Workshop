extends Node2D

# --- Member Variables ---
@onready var player = $"/root/Game/Player"

@onready var frames: int = 0

@onready var traits = Data.load_json_file("res://data/traits_data.json")
@onready var traits_properties = traits["properties"]

@onready var perks = Data.load_json_file("res://data/perks_data.json")
@onready var perks_properties = perks["properties"]

# Private variables for stats
var _stats: Dictionary = {
	"speed": {
		"speed_mult": 1.00,
		"speed_base": 50
	},
	"health": {
		"health": 100.0,
		"health_regen": 0.05
	},
	"crit": {
		"crit_chance": 0.01,
		"crit_mult": 2.0
	}
}

# Stat Constraints
var _max_stat_values: Dictionary = {
	"crit": {
		"crit_chance": 1.0
	},
	"speed": {
		"speed_mult": 5.0
	}
}

var _min_stat_values: Dictionary = {
	"speed": {
		"speed_mult": 1.0
	}
}

# Timelines Dictionary
var Timelines: Dictionary = {
	"npc": {"completed": false, "repeatable": false},
}

func _is_valid_buff_string(string: String) -> bool:
	# Split the buff string into its components
	var words_in_string_array = _unwrap_buff_string(string)
	# Assign the first three terms to their theoretical values
	var stat = words_in_string_array[0]
	var operator = words_in_string_array[1]
	var value = words_in_string_array[2]

	if _is_correct_buff_string_size(words_in_string_array) and _is_valid_stat(stat) and _is_valid_operator(operator):
		# is_valid_float doesnt have a built in error print function, so we separate it
		if value.is_valid_float():
			return true
		print("Error: global.gd, is_valid_buff_string ", value, " is not a float.")
		return false
	return false
	
func _is_correct_buff_string_size(words_in_string_array: Array) -> bool:
	var required_word_amount = 3
	if words_in_string_array.size() != required_word_amount:
		print("Error: global.gd, _is_valid_buff_string_size(): String does not contain required word amount (3). Input: ", words_in_string_array)
		return false
	return true

func _is_valid_stat(stat: String) -> bool:
	for category in _stats.values():
		if stat in category:
			return true
	print("Error: global.gd, is_valid_stat(): Stat, ", stat, " does not exist.")
	return false

func _is_valid_operator(_char: String) -> bool:
	var operators = ["*", "-", "+", "/"]
	if _char in operators:
		return true
	print("Error: global.gd, _is_valid_operator(): ", _char, " is not a valid operator")
	return false

func _convert_string_to_buff(string: String) -> Array:
	if not _is_valid_buff_string(string):
		return []
	
	var buff = _unwrap_buff_string(string)
	
	# Convert the value to a float before returning
	buff = [buff[0], buff[1], buff[2].to_float()]
	return buff

# Helper function that unwraps buff string, i.e. removes [] and returns the string array [stat, operator, value]
func _unwrap_buff_string(string: String) -> Array:
	return string.strip_edges().replace("[", "").replace("]","").split(" ", false)

# --- Getter for Player Stats ---
func player_get_stat(stat: String) -> float:
	for category in _stats.keys():
		if stat in _stats[category]:
			return _stats[category][stat]
	print("Error, global.gd, player_get_stat(), input stat: ", stat, " does not exist")
	return 0.0

# --- Setter for Player Stats with Constraints ---
func player_change_stat(buff_str: String):
	var buff: Array = _convert_string_to_buff(buff_str)

	var stat = buff[0]
	
	var operator = buff[1]
	
	var value = buff[2]
	
	# Find the correct category containing the stat
	var category = _get_stat_category(stat)
	
	# Store the original value for change calculation
	var original_stat_value = _stats[category][stat]

	_set_preconstrained_stat_value(category, stat, operator, value)

	var constraints = _get_stat_constraints(category, stat)
	
	var min_val = constraints[0]
	
	var max_val = constraints[1]
	
	_stats[category][stat] = _get_constrained_stat_value(category, stat, min_val, max_val)
	
	_print_stat_change(category, stat, original_stat_value)

func _print_stat_change(category: String, stat: String, original_stat_value: float) -> void:
	var new_stat_value = _stats[category][stat]
	
	var change = new_stat_value - original_stat_value
	
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		stat,
		original_stat_value,
		_stats[category][stat],
		"+" if change >= 0 else "",
		change
	])
	
func _get_stat_category(stat: String) -> String:
	for category in _stats.keys():
		if stat in _stats[category]:
			return category
	print("Error: global.gd, _get_stat_category(): the stat '", stat , "' does not exist")
	return ""
	
func _set_preconstrained_stat_value(category: String, stat: String, operator: String, value: float) -> void:
	match operator:
		"*": _stats[category][stat] *= value
		"-": _stats[category][stat] -= value
		"+": _stats[category][stat] += value
		"/": 
			if value != 0.0:
				_stats[category][stat] /= value

# Returns the min, max vals of a given stat. assumes 0.0,  2147483647.0 if none are set
func _get_stat_constraints(category: String, stat: String) -> Array:
	return [_min_stat_values.get(category, {}).get(stat, 0.0), _max_stat_values.get(category, {}).get(stat, 2147483647.0)]
	
func _get_constrained_stat_value(category: String, stat: String, min_val: float, max_val: float) -> float:
	return clamp(_stats[category][stat], min_val, max_val)

# --- Player Traits & Perks Methods ---
func print_player_perks():
	print("=== All Perks ===")
	Data.pretty_print_rows(perks.perks, "perks")

func print_player_traits():
	print("=== All Traits ===")
	Data.pretty_print_rows(traits.traits, "traits")

# NEEDS CLEANED
func player_add_trait(trait_name: String):
	for _trait in traits.traits:
		var name_index = traits_properties.find("name")
		var has_index = traits_properties.find("has") 
		var buffs_index = traits_properties.find("buffs")
		
		if _trait[name_index][1] == trait_name:
			if _trait[has_index][1] == "true":
				print("Trait '" + trait_name + "' is already active on this character")
				return
			
			_trait[has_index][1] = "true"
			print(trait_name + " trait added!")
			_parse_buff_from_json(_trait[buffs_index][1])
			return
	
	print("Could not find trait named '" + trait_name + "' in available traits list")

# NEEDS CLEANED
func player_add_perk(perk_name: String):
	for perk in perks.perks:
		var name_index = perks_properties.find("name")
		var has_index = perks_properties.find("has")
		var buffs_index = perks_properties.find("buffs")
		
		if perk[name_index][1] == perk_name:
			if perk[has_index][1] == "true":
				print("Perk '" + perk_name + "' is already active on this character")
				return
			
			perk[has_index][1] = "true"
			print(perk_name, " perk added!")
			_parse_buff_from_json(perk[buffs_index][1])
			return
	
	print("Could not find perk named '" + perk_name + "' in available perks list")

# New method to parse buff strings from JSON format - NEEDS CLEANED
func _parse_buff_from_json(buff: String):
	# Ensure the string isn't empty before indexing
	if buff.is_empty():
		print("error: global.gd, _parse_buff_from_json, input is empty.")
		return
	
	# Check for proper array formatting before processing
	if buff[0] == '[' and buff[buff.length() - 1] == ']':
		var buffs = buff.trim_prefix("[").trim_suffix("]").split(";")
		for _buff in buffs:
			if not buff.is_empty():
				player_change_stat(buff)
	else:
		print("error: global.gd, _parse_buff_from_json, input '", buff, "' is improperly formatted.")

# --- Timeline Methods ---
func _is_timeline_completed(timeline: String) -> bool:
	return Timelines[timeline]["completed"] == true

func _is_timeline_repeatable(timeline: String) -> bool:
	return Timelines[timeline]["repeatable"] == true
	
func _is_timeline_running() -> bool:
	return Dialogic.current_timeline != null

func start_dialog(timeline: String) -> void:
	if _is_timeline_running():
		print("Error: A timeline is already running! Cannot start a new one.")
		return

	if timeline in Timelines:
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			print("Timeline ", timeline, " is already completed and not repeatable.")
			return
		
		Timelines[timeline]["completed"] = true
		Dialogic.start(timeline)
	else:
		print("Error: The timeline '", timeline, "' does not exist.")
		
# --- Vector and Debug Methods ---

# Provides the vector between any node and the player
func get_vector_to_player(self_node: Node2D) -> Vector2:
	if player:
		return player.global_position - self_node.global_position
	else:
		print(self, "get_vector_to_player()", "Player Path Has Changed")
		return Vector2.ZERO

# Debug method for visualizing the vector, angle, and length
func debug() -> void:
	print("1. get_vector_to_player()")
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

# --- Frame Updates ---
func _ready() -> void:
	frames += 1
	if frames >= 100:
		frames = 0
	# Test every function
	var _array = await Data.get_filtered_rows_co("items", "type", "weapon")
	player_add_perk("heavy handed")
	player_add_perk("heavy handed")
	print_player_perks()
	print_player_traits()
	player_change_stat("health - 50")
