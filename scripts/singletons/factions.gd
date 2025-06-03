extends Node

signal status_changed
signal rep_changed
signal member_died

enum FACTIONS {
	UNASSIGNED,
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
	FACTIONS.NEW_CALIFORNIA_REPUBLIC: { "rep": 50, "decisions": [] },
	FACTIONS.GOODSPRINGS: { "rep": 50, "decisions": [] },
	FACTIONS.CAESERS_LEGION: { "rep": 50, "decisions": [] },
	FACTIONS.BROTHERHOOD_OF_STEEL: { "rep": 50, "decisions": [] },
	FACTIONS.FOLLOWERS_OF_THE_APOCALYPSE: { "rep": 50, "decisions": [] },
	FACTIONS.GREAT_KHANS: { "rep": 50, "decisions": [] },
	FACTIONS.GUN_RUNNERS: { "rep": 50, "decisions": [] },
	FACTIONS.BOOMERS: { "rep": 50, "decisions": [] },
	FACTIONS.ENCLAVE_REMNANTS: { "rep": 50, "decisions": [] },
	FACTIONS.WHITE_GLOVE_SOCIETY: { "rep": 50, "decisions": [] },
	FACTIONS.OMERTAS: { "rep": 50, "decisions": [] },
	FACTIONS.CHAIRMEN: { "rep": 50, "decisions": [] },
	FACTIONS.KINGS: { "rep": 50, "decisions": [] },
	FACTIONS.POWDER_GANGERS: { "rep": 50, "decisions": [] },
	FACTIONS.FIENDS: { "rep": 50, "decisions": [] },
	FACTIONS.VAN_GRAFFS: { "rep": 50, "decisions": [] },
	FACTIONS.CRIMSON_CARAVAN: { "rep": 50, "decisions": [] },
	FACTIONS.JACOBSTOWN: { "rep": 50, "decisions": [] },
	FACTIONS.WESTSIDE_COOPERATIVE: { "rep": 50, "decisions": [] },
	FACTIONS.BROTHERHOOD_OUTCASTS: { "rep": 50, "decisions": [] }
}

func _ready() -> void:
	member_died.connect(_on_member_died)


func _on_member_died(member: Characters.CHARACTERS) -> void:
	_process_member_killed(member)


const death_rep_loss: int = -100
func _process_member_killed(_character: Characters.CHARACTERS, rep_loss: int = death_rep_loss) -> void:
	var faction: FACTIONS = Dialogue.get_character_faction(_character)
	Factions.log_decision(faction, "killed %s." % [Characters.get_character_name(_character)], rep_loss)
	if Factions.is_faction_hostile(faction):
		var allies: Array = get_loaded_members(faction)
		for ally: Node2D in allies:
			ally.set_hostile(true)


func update_faction_data(faction: FACTIONS, property: String, value: Variant) -> bool:
	if Debug.throw_warning_if(not property in Data.game_data["factions_data"][faction], "Property " + property + " not found in faction " + get_faction_name(faction), self):
		return false
	Data.game_data["factions_data"][faction][property] = value
	return true


func _change_rep(faction: FACTIONS, rep_change: int) -> bool:
	var old_rep_status: String = get_rep_status(faction)
	var new_rep: int = get_rep_num(faction) + rep_change
	if update_faction_data(faction, "rep", new_rep):
		var new_rep_status: String = get_rep_status(faction)
		if old_rep_status != new_rep_status:
			status_changed.emit()
		rep_changed.emit()
		return true
	return false


func log_decision(faction: FACTIONS, decision: String, rep_change: int) -> void:
	_change_rep(faction, rep_change)
	var decisions: Array = Data.game_data["factions_data"][faction]["decisions"]
	var found: bool = false
	for entry: Array in decisions:
		if entry[0] == decision:
			entry[1] += rep_change
			entry[2] += 1
			found = true
			break

	if not found:
		decisions.append([decision, rep_change, 1])

	update_faction_data(faction, "decisions", decisions)


func get_rep_status(faction: FACTIONS) -> String:
	var rep: int = Data.game_data["factions_data"][faction]["rep"]
	if rep < 0:
		return "hostile"
	if rep < 25:
		return "unfriendly"
	if rep < 50:
		return "neutral"
	if rep < 75:
		return "friendly"
	return "allied"


func is_faction_hostile(_faction: FACTIONS) -> bool:
	return get_rep_status(_faction) == "hostile"


func get_faction_name(faction: FACTIONS) -> String:
	return Global.enum_to_camelcase(faction, FACTIONS)


func get_loaded_members(faction: FACTIONS) -> Array[Node]:
	return get_tree().get_nodes_in_group(get_faction_name(faction))


func get_rep_num(faction: FACTIONS) -> int:
	return Data.game_data["factions_data"][faction]["rep"]


func reset_faction(faction: FACTIONS) -> void:
	update_faction_data(faction, "rep", 50.0)
	update_faction_data(faction, "decisions", [])


# bulky fancy print function
func print_overview() -> void:
	var output: String = ""
	var longest_name_length: int = 0
	for faction_enum: FACTIONS in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		longest_name_length = max(longest_name_length, faction_name.length())
	longest_name_length += 2

	var header: String = "| %-*s | %-10s | %-5s |" % [longest_name_length, "FACTION", "STATUS", "REP"]
	var divider: String = "-".repeat(header.length())
	output += divider + "\n"
	output += header + "\n"
	output += divider + "\n"

	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var rep: int = get_rep_num(faction_enum)
		var status: String = get_rep_status(faction_enum)
		output += "| %-*s | %-10s | %5d |" % [longest_name_length, faction_name, status, rep] + "\n"
		output += divider + "\n\n"

	output += "FACTION DECISIONS:\n"
	output += divider + "\n"

	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var decisions: Array = Data.game_data["factions_data"][faction_enum]["decisions"]
		if decisions.size() > 0:
			output += faction_name + ":\n"
			var sorted_decisions: Array = decisions.duplicate()
			for i: int in range(sorted_decisions.size()):
				for j: int in range(i + 1, sorted_decisions.size()):
					var impact_i: int = abs(sorted_decisions[i][1])
					var impact_j: int = abs(sorted_decisions[j][1])
					if impact_j > impact_i:
						var temp: Array = sorted_decisions[i]
						sorted_decisions[i] = sorted_decisions[j]
						sorted_decisions[j] = temp
			for entry: Array in sorted_decisions:
				var decision: String = entry[0]
				var rep_change: int = entry[1]
				var times: int = entry[2]
				var _sign: String = "+" if rep_change > 0 else ""
				output += "\tx%d %s (%s%d)\n" % [times, decision, _sign, rep_change]
			output += "\n"

	print(output)
