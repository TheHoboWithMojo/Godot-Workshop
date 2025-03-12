extends Node2D

# --- Member Variables ---
# Store the player path
@onready var player = $"/root/Game/Player"

# Store frames
@onready var frames: int = 0

# Player Stats Dictionary with named keys for clarity
var player_stat_dict: Dictionary[String, float] = {
	"crit_chance": 0.01,
	"health": 100.0,
	"health_regen": 0.05,
	"speed_mult": 1.00
}

# Player Traits Dictionary with named keys for clarity
var _player_traits: Dictionary[String, Dictionary] = {
	"war hero": {"has": false, "description": "You've been through hell and back, unlocks gruff dialogue options.", "change1": "health * 1.05"},
	"scholar": {"has": false, "description": "The library is your true home, unlocks informed dialogue options."}
}

# Player Perks Dictionary with named keys for clarity
var _player_perks: Dictionary[String, Dictionary] = {
	"heavy handed": {"has": false, "description": "You punch twice as hard! +3 to Strength.", "change1": "crit_chance + 0.05", "change2": "health_regen / 2"}
}

# Timelines Dictionary for tracking progress in events
var Timelines: Dictionary[String, Dictionary] = {
	"npc": {"completed": false, "repeatable": false}
}


# --- Player Traits & Perks Methods ---
# Prints available player perks
func print_player_perks():
	print("Available Perks:\n")
	for perk in _player_perks:
		print(perk, ": ", _player_perks[perk]["description"], "\n")

# Prints available player traits
func print_player_traits():
	print("Available Traits:\n")
	for _trait in _player_traits:
		print(_trait, ": ", _player_traits[_trait]["description"], "\n")

# Method to add a trait to the player
func player_add_trait(trait_name: String):
	if trait_name in _player_traits:
		_player_traits[trait_name]["has"] = true
		print(trait_name, " trait added!")
		_parse_buffs(_player_traits) # Updates stat values
	else:
		print("Trait does not exist! Available traits:\n")
		print_player_traits()

# Method to add a perk to the player
func player_add_perk(perk_name: String):
	if perk_name in _player_perks:
		_player_perks[perk_name]["has"] = true
		print(perk_name, " perk added!")
		_parse_buffs(_player_perks) # Updates stat values
	else:
		print("Perk does not exist! Available perks:\n")
		print_player_perks()


# --- Timeline Methods ---
# Check if a timeline has been completed
func _is_timeline_completed(timeline: String) -> bool:
	return Timelines[timeline]["completed"] == true

# Check if a timeline is repeatable
func _is_timeline_repeatable(timeline: String) -> bool:
	return Timelines[timeline]["repeatable"] == true

# Start a dialogue based on timeline progress
func start_dialog(timeline: String) -> void:
	if timeline in Timelines: # Check if the timeline exists
		# If timeline is completed and non-repeatable, skip
		if _is_timeline_completed(timeline) and not _is_timeline_repeatable(timeline):
			return

		# Else, play the timeline
		Timelines[timeline]["completed"] = true  # Mark as completed
		Dialogic.start(timeline)
	else:
		print("The timeline ", timeline, " does not exist.")


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
	# Debugging for get_vector_to_player
	print("1. get_vector_to_player()")
	print("   debug options:")

	# Option 1: Show vectors
	print("   1. Show vector:")
	print("""func _draw() -> void:
	draw_line(Vector2.ZERO, vector_to_player, Color.GREEN, 2.0)

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	vector_to_player = get_vector_to_player(self)
	queue_redraw()
""")

	# Option 2: Print angle and length (simplified)
	print("   2. Print angle and length:")
	print("""var vector_to_player = get_vector_to_player(self)
print("Angle: ", vector_to_player.angle())
print("Length: ", vector_to_player.length())
""")


# --- Buff Parsing Method ---
# Function that parses buffs and updates player stats
# Parses all dicts[String, dict] in the form "name": {"Change 1": "stat operator change", "Change 2": "stat operator change"...}
# Ex "tough guy": {"has": true, "description": "tough as nails", "change1": health * 10....}
func _parse_buffs(buff_dict: Dictionary):
	# Iterate through each trait or perk
	for buff_name in buff_dict:
		var buff_data = buff_dict[buff_name]  # Access buff dictionary

		# Iterate through all key-value pairs in the buff sub-dictionary
		for change_key in buff_data:
			# Only process keys that start with "change"
			if change_key.begins_with("change"):
				var change_str: String = buff_data[change_key]  # Get the change string
				var word_list: Array = change_str.split(" ", false)

				# Remove any empty entries caused by multiple spaces
				var filtered_words: Array = word_list.filter(func(word): return word != "")

				# Ensure exactly 3 parts (stat, operator, change)
				if filtered_words.size() != 3:
					continue

				var stat = filtered_words[0]
				var operator = filtered_words[1]
				var change = filtered_words[2]

				# Ensure the stat exists in the player stats dictionary
				if stat not in player_stat_dict:
					continue

				# Ensure operator is one of the expected symbols
				if operator not in ["*", "-", "+", "/"]:
					continue

				# Ensure change is a valid float
				if not change.is_valid_float():
					continue

				# Convert change to a float before applying it
				var change_value = change.to_float()

				# Apply the operation to the stat
				match operator:
					"*":
						player_stat_dict[stat] *= change_value
					"-":
						player_stat_dict[stat] -= change_value
					"+":
						player_stat_dict[stat] += change_value
					"/":
						if change_value != 0:  # Prevent division by zero
							player_stat_dict[stat] /= change_value


# --- Frame Updates ---
func _ready() -> void:
	# Add traits and perks and print player stats
	player_add_trait("scholar")
	player_add_perk("heavy handed")
	print(player_stat_dict)

	# Update frames for periodic tasks
	frames += 1
	if frames >= 100:
		frames = 0
