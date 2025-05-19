extends Node

enum FACTIONS {
	ERROR,
	NEW_CALIFORNIA_REPUBLIC,
	CAESERS_LEGION,
	BROTHERHOOD_OF_STEEL,
	FOLLOWERS_OF_THE_APOCALYPSE,
	GREAT_KHANS,
	GUN_RUNNERS,
	BOOMERS,
	ENCLAVE_REMNANTS,
	WHITE_GLOVE_SOCIETY,
	OMERTAS,
	CHAIRMEN,
	KINGS,
	POWDER_GANGERS,
	FIENDS,
	VAN_GRAFFS,
	CRIMSON_CARAVAN,
	JACOBSTOWN,
	WESTSIDE_COOPERATIVE,
	BROTHERHOOD_OUTCASTS,
	GOODSPRINGS,
}

var factions_data: Dictionary = {
	FACTIONS.NEW_CALIFORNIA_REPUBLIC: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.GOODSPRINGS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.CAESERS_LEGION: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.BROTHERHOOD_OF_STEEL: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.FOLLOWERS_OF_THE_APOCALYPSE: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.GREAT_KHANS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.GUN_RUNNERS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.BOOMERS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.ENCLAVE_REMNANTS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.WHITE_GLOVE_SOCIETY: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.OMERTAS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.CHAIRMEN: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.KINGS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.POWDER_GANGERS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.FIENDS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.VAN_GRAFFS: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.CRIMSON_CARAVAN: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.JACOBSTOWN: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.WESTSIDE_COOPERATIVE: {
		"rep": 50,
		"decisions": []
	},
	FACTIONS.BROTHERHOOD_OUTCASTS: {
		"rep": 50,
		"decisions": []
	}
}


func _ready() -> void:
	if Global.level_manager:
		Global.level_manager.level_loaded.connect(_on_level_loaded)


func _on_level_loaded() -> void: # check for hostility when entering level
	for being: Node2D in get_tree().get_nodes_in_group("beings"):
		if Factions.faction_exists(being.master._faction):
			if Factions.get_rep_status(being.master._faction) == "hostile":
				being.master.hostile = true


# Wrapper function to update any faction data
func update_faction_data(faction: FACTIONS, property: String, value: Variant) -> void:
	var faction_name: String = Global.enum_to_snakecase(faction, FACTIONS)
	if faction_exists(faction):
		if property in Data.game_data["factions_data"][faction]:
			Data.game_data["factions_data"][faction][property] = value
		else:
			Data.throw_error(self, "Property " + property + " not found in faction " + faction_name)
	else:
		Data.throw_error(self, "Faction " + faction_name + " not found!")


func change_rep(faction: FACTIONS, rep_change: int) -> void:
	if faction_exists(faction):
		var old_rep_status: String = get_rep_status(faction)
		var new_rep: int = Data.game_data["factions_data"][faction]["rep"] + rep_change
		update_faction_data(faction, "rep", new_rep)
		var new_rep_status: String = get_rep_status(faction)
		if old_rep_status != new_rep_status:
			print("Your reputation with %s changed from %s to %s!" % [get_faction_name(faction),old_rep_status, new_rep_status])
	else:
		var faction_name: String = Global.enum_to_snakecase(faction, FACTIONS)
		Data.throw_error(self, "Faction " + faction_name + " not found!")


func log_decision(faction: FACTIONS, decision: String, rep_change: int) -> void:
	if faction_exists(faction):
		change_rep(faction, rep_change)

		# Get current decisions
		var decisions: Array = Data.game_data["factions_data"][faction]["decisions"]

		# Check if decision already exists
		var found: bool = false
		for entry: Array in decisions:
			if entry[0] == decision:
				entry[1] += rep_change  # Update reputation impact
				entry[2] += 1  # Increment count
				found = true
				break

		# If decision not found, add a new entry
		if not found:
			decisions.append([decision, rep_change, 1])

		# Update decisions using the wrapper
		update_faction_data(faction, "decisions", decisions)
	else:
		Data.throw_error(self, "Faction " + str(faction) + " not found!")


func print_overview() -> void:
	var output: String = ""

	# Find the longest faction name for proper formatting
	var longest_name_length: int = 0
	for faction_enum: FACTIONS in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		longest_name_length = max(longest_name_length, faction_name.length())

	# Add some padding
	longest_name_length += 2

	# Create the header with dynamic width
	var header: String = "| %-*s | %-10s | %-5s |" % [longest_name_length, "FACTION", "STATUS", "REP"]
	var divider: String = "-".repeat(header.length())

	output += divider + "\n"
	output += header + "\n"
	output += divider + "\n"

	# Process each faction with consistent formatting
	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var rep: int = get_rep_num(faction_enum)
		var status: String = get_rep_status(faction_enum)

		output += "| %-*s | %-10s | %5d |" % [longest_name_length, faction_name, status, rep] + "\n"
		output += divider + "\n\n"

	# Add decisions section with better formatting
	output += "FACTION DECISIONS:\n"
	output += divider + "\n"

	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var decisions: Array = Data.game_data["factions_data"][faction_enum]["decisions"]

		if decisions.size() > 0:
			output += faction_name + ":\n"

			# Sort decisions by impact (absolute value of rep change)
			# Expanded sorting logic instead of one-liner
			var sorted_decisions: Array = decisions.duplicate()

			# Custom sorting function to sort by absolute value of reputation change
			for i: int in range(sorted_decisions.size()):
				for j: int in range(i + 1, sorted_decisions.size()):
					var impact_i: int = abs(sorted_decisions[i][1])
					var impact_j: int = abs(sorted_decisions[j][1])

					# If impact_j is greater than impact_i, swap the elements
					if impact_j > impact_i:
						var temp: Array = sorted_decisions[i]
						sorted_decisions[i] = sorted_decisions[j]
						sorted_decisions[j] = temp

			# Show all decisions for this faction
			for entry: Array in sorted_decisions:
				var decision: String = entry[0]
				var rep_change: int = entry[1]
				var times: int = entry[2]

				var _sign: String = "+" if rep_change > 0 else ""
				output += "\tx%d %s (%s%d)\n" % [times, decision, _sign, rep_change]

			output += "\n"

	print(output)


func get_rep_status(faction: FACTIONS) -> String:
	if faction_exists(faction):
		var rep: int = Data.game_data["factions_data"][faction]["rep"]
		if rep < 0:
			return "hostile"
		elif rep < 25:
			return "unfriendly"
		elif rep < 50:
			return "neutral"
		elif rep < 75:
			return "friendly"
		else:
			return "allied"
	else:
		Debug.throw_error(self, "get_rep_status", "Faction %s not found!" % [faction])
		return "Faction not found!"


func is_faction_hostile(_faction: FACTIONS) -> bool:
	return get_rep_status(_faction) == "hostile"


func faction_exists(faction: FACTIONS) -> bool:
	return faction in FACTIONS.values()


func get_faction_name(faction: FACTIONS) -> String:
	return Global.enum_to_camelcase(faction, FACTIONS)


const death_rep_loss: int = -100
func process_member_kill(_character: Characters.CHARACTERS, rep_loss: int = death_rep_loss) -> void: # logs death and applies hostility
	var faction: FACTIONS = Dialogue.get_character_faction(_character)
	Factions.log_decision(faction, "killed %s." % [Characters.get_character_name(_character)], rep_loss)
	if Factions.is_faction_hostile(faction):
		var allies: Array = get_loaded_members(faction)
		for ally: Node2D in allies:
			ally.master.set_hostile(true)


func get_loaded_members(faction: FACTIONS) -> Array[Node]:
	return get_tree().get_nodes_in_group(get_faction_name(faction))


func get_rep_num(faction: FACTIONS) -> int:
	if faction_exists(faction):
		return Data.game_data["factions_data"][faction]["rep"]
	return 0


func reset_faction(faction: FACTIONS) -> void:
	if faction_exists(faction):
		update_faction_data(faction, "rep", 50.0)
		update_faction_data(faction, "decisions", [])
	else:
		var faction_name: String = Global.enum_to_snakecase(faction, FACTIONS)
		Data.throw_error(self, "Faction " + faction_name + " not found!")


func print_faction_status(faction: FACTIONS) -> void:
	if faction_exists(faction):
		var faction_name: String = FACTIONS.keys()[faction]
		var rep: int = Data.game_data["factions_data"][faction]["rep"]
		var status: String = get_rep_status(faction)
		var header: String = "| %-25s | %-10s (%3d) |" % [faction_name, status, rep]
		var divider: String = "-" .repeat(header.length())
		print(divider)
		print(header)
		print(divider)
		for entry: Array in Data.game_data["factions_data"][faction]["decisions"]:
			print("x" + str(entry[2]) + " " + entry[0] + " (" + str(entry[1]) + ")")
		print(divider)
	else:
		Data.throw_error(self, "Faction int " + str(faction) + " not found!")
