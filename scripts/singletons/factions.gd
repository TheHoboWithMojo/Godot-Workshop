extends Node
func _process(_delta: float) -> void:
	if Data.is_data_loaded:
		if Global.frames % 60 == 0:
			for being: Node2D in get_tree().get_nodes_in_group("beings"):
				if being.master._faction in Factions.factions.values():
					if Factions.get_rep_status(being.master._faction) == "hostile":
						being.master.hostile = true

# Wrapper function to update any faction data
func update_faction_data(faction: int, property: String, value: Variant) -> void:
	var faction_name: String = Global.enum_to_camelcase(faction, factions)
	if faction_exists(faction):
		if property in Data.game_data["factions_data"][faction]:
			Data.game_data["factions_data"][faction][property] = value
		else:
			Data.throw_error(self, "Property " + property + " not found in faction " + faction_name)
	else:
		Data.throw_error(self, "Faction " + faction_name + " not found!")

func change_rep(faction: int, rep_change: int) -> void:
	if faction_exists(faction):
		var new_rep: int = Data.game_data["factions_data"][faction]["rep"] + rep_change
		update_faction_data(faction, "rep", new_rep)
	else:
		var faction_name: String = Global.enum_to_camelcase(faction, factions)
		Data.throw_error(self, "Faction " + faction_name + " not found!")

func log_decision(faction: int, decision: String, rep_change: int) -> void:
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
		
		print(decision)
		# Update decisions using the wrapper
		update_faction_data(faction, "decisions", decisions)
	else:
		Data.throw_error(self, "Faction " + str(faction) + " not found!")
		
func get_rep_status(faction: int) -> String:
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
		
func faction_exists(faction: int) -> bool:
	return faction in factions.values()
		
func get_rep_num(faction: int) -> int:
	if faction_exists(faction):
		return Data.game_data["factions_data"][faction]["rep"]
	return 0

func reset_faction(faction: int) -> void:
	if faction_exists(faction):
		update_faction_data(faction, "rep", 50.0)
		update_faction_data(faction, "decisions", [])
	else:
		var faction_name: String = Global.enum_to_camelcase(faction, factions)
		Data.throw_error(self, "Faction " + faction_name + " not found!")
		
func print_faction_status(faction: int) -> void:
	if faction_exists(faction):
		var faction_name: String = factions.keys()[faction]
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
		
enum factions {
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
	BROTHERHOOD_OUTCASTS
}
