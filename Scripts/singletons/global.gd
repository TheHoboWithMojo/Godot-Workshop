extends Node2D

# --- Member Variables ---
@onready var player = $"/root/Game/Player"
@onready var frames: int = 0

@onready var traits = Data.load_json_file("res://data/traits_data.json")
@onready var perks = Data.load_json_file("res://data/perks_data.json")

# Private variables for stats
var _stats: Dictionary = {
	"crit_chance": 0.01,
	"health": 100.0,
	"health_regen": 0.05,
	"speed_mult": 1.00,
	"speed": 50,
}

# Stat Constraints
var _max_stat_values: Dictionary = {
	"crit_chance": 1.0,  # 100% max crit chance
	"speed_mult": 5.0    # 500% max movement speed
}

var _min_stat_values: Dictionary = {
	"speed_mult": 1.0    # Minimum speed multiplier 100% (regular speed can enforce 0)
}

# Timelines Dictionary
var Timelines: Dictionary = {
	"npc": {"completed": false, "repeatable": false}
}

# --- BuffString Class ---
class BuffString: # This class creates the data type for buffs [stat, operator, value]
	var stat: String
	var operator: String
	var value: float

	func _init(buff_str: String):
		var words = buff_str.strip_edges().split(" ", false)

		if words.size() != 3:
			print("Error: BuffString(): Invalid format. Expected 'stat operator value' but got:", buff_str)
			return
		
		self.stat = words[0]
		self.operator = words[1]
		
		if not words[2].is_valid_float():
			print("Error: BuffString(): Invalid value. Expected a number but got:", words[2])
			return
		
		self.value = words[2].to_float()

		if self.operator not in ["*", "-", "+", "/"]:
			print("Error: BuffString(): Invalid operator. Expected one of ['*', '-', '+', '/'] but got:", self.operator)
			return

		if self.stat == "":
			print("Error: BuffString(): Stat cannot be empty.")
			return


# --- Getter for Player Stats ---
func player_get_stat(stat: String) -> float:
	return _stats.get(stat, 0.0)

# --- Setter for Player Stats with Constraints ---
func player_change_stat(buff_str: String):
	var buff = BuffString.new(buff_str)
	
	# If BuffString failed initialization due to errors, stop execution
	if buff.stat == "" or buff.operator == "" or buff.value == 0.0:
		return
	
	# Ensure the stat exists before modifying
	if not _stats.has(buff.stat):
		print("Error: player_change_stat(): Stat '", buff.stat, "' does not exist.")
		return
	
	# Apply the operator
	match buff.operator:
		"*": _stats[buff.stat] *= buff.value
		"-": _stats[buff.stat] -= buff.value
		"+": _stats[buff.stat] += buff.value
		"/": 
			if buff.value != 0:
				_stats[buff.stat] /= buff.value
	
	# Apply stat set constraints (clamp min/max)
	_stats[buff.stat] = clamp(
		_stats[buff.stat], 
		_min_stat_values.get(buff.stat, 0.0),   # Default min to 0 if not found in _min_stat_values
		_max_stat_values.get(buff.stat, 2147483647.0)  # Default max to int limit if not found in _max_stat_values
	)

# --- Player Traits & Perks Methods ---
func print_player_perks():
	print("Available Perks:\n")
	for perk in perks.perks:
		var _name = perk[0][1]  # Get name from first field
		var description = perk[2][1]  # Get description from third field
		print(_name, ": ", description, "\n")

func print_player_traits():
	print("Available Traits:\n")
	for _trait in traits.traits:
		var _name = _trait[0][1]
		var description = _trait[2][1]
		print(_name, ": ", description, "\n")

func player_add_trait(trait_name: String):
	for _trait in traits.traits:
		if _trait[0][1] == trait_name and _trait[1][1] == "FALSE":
			_trait[1][1] = "TRUE"  # Set Has to TRUE
			print(trait_name, " trait added!")
			_parse_buffs_from_json(_trait[3][1])  # Parse Buffs field
			return
	print("Trait does not exist or already added!")

func player_add_perk(perk_name: String):
	for perk in perks.perks:
		if perk[0][1] == perk_name and perk[1][1] == "FALSE":
			perk[1][1] = "TRUE"  # Set Has to TRUE
			print(perk_name, " perk added!")
			_parse_buffs_from_json(perk[3][1])  # Parse Buffs field
			return
	print("Perk does not exist or already added!")

# New method to parse buff strings from JSON format
func _parse_buffs_from_json(buff_string: String):
	# Remove brackets and split buffs
	var buffs = buff_string.trim_prefix("[").trim_suffix("]").split(";")
	for buff in buffs:
		if buff != "":
			player_change_stat(buff)

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
	player_add_perk("heavy handed")
	player_add_perk("heavy handed")
	print(_stats)
