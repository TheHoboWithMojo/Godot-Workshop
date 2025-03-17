# Who knows atp
extends Node

# Define the stat enumeration
enum Stat { STRENGTH, PERCEPTION, ENDURANCE, CHARISMA, INTELLIGENCE, AGILITY, LUCK }

# A structure to hold the range of values for each constant (min, max, and current)
class Value_Range:
	var min_value: float
	var max_value: float
	var current_value: float

	@warning_ignore("shadowed_variable")
	func _init(min_value: float, max_value: float, current_value: float):
		self.min_value = min_value
		self.max_value = max_value
		self.current_value = current_value

# A dictionary to store the constants with their ranges
var constants := {}

# Initialize ranges for the constants
func _ready():
	initialize_constants()

# Function to initialize the constants with their range values
func initialize_constants():
	constants = {
		Stat.STRENGTH: {
			Stat.PERCEPTION: Value_Range.new(0.1, 0.2, 0.15),
			Stat.ENDURANCE: Value_Range.new(0.15, 0.3, 0.2),
			Stat.CHARISMA: Value_Range.new(0.1, 0.2, 0.15),
			Stat.AGILITY: Value_Range.new(0.1, 0.3, 0.2)
		},
		Stat.PERCEPTION: {
			Stat.ENDURANCE: Value_Range.new(0.1, 0.2, 0.15),
			Stat.CHARISMA: Value_Range.new(0.1, 0.2, 0.15),
			Stat.INTELLIGENCE: Value_Range.new(0.1, 0.2, 0.15),
			Stat.AGILITY: Value_Range.new(0.05, 0.1, 0.075)
		},
		Stat.ENDURANCE: {
			Stat.STRENGTH: Value_Range.new(0.15, 0.25, 0.2),
			Stat.CHARISMA: Value_Range.new(0.1, 0.2, 0.15),
			Stat.AGILITY: Value_Range.new(0.05, 0.1, 0.075),
			Stat.LUCK: Value_Range.new(0.1, 0.15, 0.125)
		},
		Stat.CHARISMA: {
			Stat.PERCEPTION: Value_Range.new(0.1, 0.2, 0.15),
			Stat.ENDURANCE: Value_Range.new(0.1, 0.3, 0.2),
			Stat.INTELLIGENCE: Value_Range.new(0.1, 0.2, 0.15),
			Stat.AGILITY: Value_Range.new(0.05, 0.15, 0.1),
			Stat.LUCK: Value_Range.new(0.1, 0.2, 0.15)
		},
		Stat.INTELLIGENCE: {
			Stat.PERCEPTION: Value_Range.new(0.1, 0.2, 0.15),
			Stat.CHARISMA: Value_Range.new(0.1, 0.2, 0.15),
			Stat.LUCK: Value_Range.new(0.1, 0.2, 0.15)
		},
		Stat.AGILITY: {
			Stat.STRENGTH: Value_Range.new(0.1, 0.2, 0.15),
			Stat.CHARISMA: Value_Range.new(0.1, 0.15, 0.125),
			Stat.LUCK: Value_Range.new(0.1, 0.15, 0.125)
		},
		Stat.LUCK: {
			Stat.STRENGTH: Value_Range.new(0.05, 0.1, 0.075),
			Stat.PERCEPTION: Value_Range.new(0.05, 0.1, 0.075),
			Stat.ENDURANCE: Value_Range.new(0.05, 0.1, 0.075),
			Stat.CHARISMA: Value_Range.new(0.05, 0.1, 0.075),
			Stat.INTELLIGENCE: Value_Range.new(0.05, 0.1, 0.075),
			Stat.AGILITY: Value_Range.new(0.05, 0.1, 0.075)
		}
	}

# Function to set the current value of a constant within its range
func set_constant(stat: Stat, related_stat: Stat, new_value: float):
	if constants.has(stat) and constants[stat].has(related_stat):
		var constant_range = constants[stat][related_stat]
		if new_value >= constant_range.min_value and new_value <= constant_range.max_value:
			constant_range.current_value = new_value
			print("Set constant for", stat, "→", related_stat, "to", new_value)
		else:
			print("ERROR: New value is outside the defined range!")
	else:
		print("ERROR: Invalid stat or related stat!")

# Function to get the current value of a constant
func get_constant(stat: Stat, related_stat: Stat) -> float:
	if constants.has(stat) and constants[stat].has(related_stat):
		return constants[stat][related_stat].current_value
	else:
		print("ERROR: Invalid stat or related stat!")
		return 0

# Example of adjusting a constant and checking its value
func adjust_example():
	# Adjusting Strength to Perception constant
	set_constant(Stat.STRENGTH, Stat.PERCEPTION, 0.18)
	# Printing the current value after adjustment
	print("Current Strength → Perception constant:", get_constant(Stat.STRENGTH, Stat.PERCEPTION))
