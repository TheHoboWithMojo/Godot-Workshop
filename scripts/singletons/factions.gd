extends Node
func _process(_delta: float) -> void:
	if Global.frames % 60 == 0:
		for being: Node2D in get_tree().get_nodes_in_group("beings"):
			if being.master._faction != "unaffiliated":
				if Factions.get_rep_status(being.master._faction) == "hostile":
					being.master.hostile = true

# Wrapper function to update any faction data
func update_faction_data(faction: String, property: String, value: Variant) -> void:
	if Data.game_data["factions"].has(faction):
		if property in Data.game_data["factions"][faction]:
			Data.game_data["factions"][faction][property] = value
		else:
			Data.throw_error(self, "Property " + property + " not found in faction " + faction)
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")

func change_rep(faction: String, rep_change: int) -> void:
	if Data.game_data["factions"].has(faction):
		var new_rep: int = Data.game_data["factions"][faction]["rep"] + rep_change
		update_faction_data(faction, "rep", new_rep)
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")

func log_decision(faction: String, decision: String, rep_change: int) -> void:
	if Data.game_data["factions"].has(faction):
		# Update reputation
		change_rep(faction, rep_change)
		
		# Get current decisions
		var decisions: Array = Data.game_data["factions"][faction]["decisions"]
		
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
		Data.throw_error(self, "Faction " + faction + " not found!")
		
func get_rep_status(faction: String) -> String:
	if Data.game_data["factions"].has(faction):
		var rep: int = Data.game_data["factions"][faction]["rep"]
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
		Debug.throw_error(self, "get_rep_status", "Faction " + faction + " not found!")
		return "Faction not found!"
		
func faction_exists(faction: String) -> bool:
	if faction in Dicts.factions.keys():
		return true
	else:
		return false
		
func get_rep_num(faction: String) -> int:
	if Data.game_data["factions"].has(faction):
		return Data.game_data["factions"][faction]["rep"]
	return 0

func reset_faction(faction: String) -> void:
	if Data.game_data["factions"].has(faction):
		update_faction_data(faction, "rep", 50.0)
		update_faction_data(faction, "decisions", [])
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")
		
func print_faction_status(faction: String) -> void:
	if Data.game_data["factions"].has(faction):
		var rep: int = Data.game_data["factions"][faction]["rep"]
		var status: String = get_rep_status(faction)
		var header: String = "| %-25s | %-10s (%3d) |" % [faction, status, rep]
		var divider: String = "-" .repeat(header.length())
		print(divider)
		print(header)
		print(divider)
		for entry: Array in Data.game_data["factions"][faction]["decisions"]:
			print("x" + str(entry[2]) + " " + entry[0] + " (" + str(entry[1]) + ")")
		print(divider)
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")
