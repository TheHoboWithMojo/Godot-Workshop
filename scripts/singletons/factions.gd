extends Node

signal status_changed(faction: Factions.FACTIONS, old_status: STATUSES, new_status: STATUSES)
signal rep_changed(faction: Factions.FACTIONS, new_rep: int)
signal member_died(member: Characters.CHARACTERS, factions: Factions.FACTIONS)

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


enum PROPERTIES {REP, DECISIONS}

var factions_dict: Dictionary = {
	FACTIONS.NEW_CALIFORNIA_REPUBLIC: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.GOODSPRINGS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.CAESERS_LEGION: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.BROTHERHOOD_OF_STEEL: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.FOLLOWERS_OF_THE_APOCALYPSE: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.GREAT_KHANS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.GUN_RUNNERS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.BOOMERS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.ENCLAVE_REMNANTS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.WHITE_GLOVE_SOCIETY: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.OMERTAS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.CHAIRMEN: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.KINGS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.POWDER_GANGERS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.FIENDS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.VAN_GRAFFS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.CRIMSON_CARAVAN: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.JACOBSTOWN: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.WESTSIDE_COOPERATIVE: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] },
	FACTIONS.BROTHERHOOD_OUTCASTS: { PROPERTIES.REP: 50, PROPERTIES.DECISIONS: [] }
}

enum STATUSES {HOSTILE, UNFRIENDLY, NEUTRAL, LIKED, IDOLIZED}

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


func update_faction_data(faction: FACTIONS, property: PROPERTIES, value: Variant) -> void:
	Data.game_data["factions_dict"][faction][property] = value


func _change_rep(faction: FACTIONS, rep_change: int) -> void:
	var old_rep_status: STATUSES = get_rep_status(faction)
	var new_rep: int = get_rep_num(faction) + rep_change
	update_faction_data(faction, PROPERTIES.REP, new_rep)
	var new_rep_status: STATUSES = get_rep_status(faction)
	Global.if_do(old_rep_status != new_rep_status, [{emit_signal: [status_changed.get_name(), faction, old_rep_status, new_rep_status]}, {emit_signal: [rep_changed.get_name(), new_rep]}])


func log_decision(faction: FACTIONS, decision: String, rep_change: int) -> void:
	_change_rep(faction, rep_change)
	var decisions: Array = Data.game_data["factions_dict"][faction][PROPERTIES.DECISIONS]
	var found: bool = false
	for entry: Array in decisions:
		if entry[0] == decision:
			entry[1] += rep_change
			entry[2] += 1
			found = true
			break

	if not found:
		decisions.append([decision, rep_change, 1])

	update_faction_data(faction, PROPERTIES.DECISIONS, decisions)


func get_rep_status(faction: FACTIONS) -> STATUSES:
	var rep: int = Data.game_data["factions_dict"][faction][PROPERTIES.REP]
	if rep < 0:
		return STATUSES.HOSTILE
	if rep < 25:
		return STATUSES.UNFRIENDLY
	if rep < 50:
		return STATUSES.NEUTRAL
	if rep < 75:
		return STATUSES.LIKED
	return STATUSES.IDOLIZED


func set_faction_status(faction: FACTIONS, status: STATUSES) -> void:
	if faction == FACTIONS.UNASSIGNED:
		push_error(Debug.define_error("Tried to assign an unassigned factions status to '%s'" % [Global.enum_to_title(status, STATUSES)], self))
		return
	match(status):
		STATUSES.HOSTILE:
			set_faction_rep(faction, 0)
		STATUSES.UNFRIENDLY:
			set_faction_rep(faction, 25)
		STATUSES.NEUTRAL:
			set_faction_rep(faction, 50)
		STATUSES.LIKED:
			set_faction_rep(faction, 75)
		STATUSES.IDOLIZED:
			set_faction_rep(faction, 100)


func set_faction_rep(faction: FACTIONS, rep: int) -> void:
	if rep < 0:
		push_warning(Debug.define_error("Cannot set rep of '%s' to negative value '%s', defaulting to 0" % [get_faction_name(faction), rep], self))
	if faction == FACTIONS.UNASSIGNED:
		push_error(Debug.define_error("Tried to set unassigned faction rep to '%s'" % [rep], self))
	factions_dict[faction][PROPERTIES.REP] = rep


func is_faction_hostile(_faction: FACTIONS) -> bool:
	return get_rep_status(_faction) == STATUSES.HOSTILE


func get_faction_name(faction: FACTIONS) -> String:
	return Global.enum_to_camelcase(faction, FACTIONS)


func get_loaded_members(faction: FACTIONS) -> Array[Node]:
	return get_tree().get_nodes_in_group(get_faction_name(faction))


func get_rep_num(faction: FACTIONS) -> int:
	return Data.game_data["factions_dict"][faction][PROPERTIES.REP]


func reset_faction(faction: FACTIONS) -> void:
	update_faction_data(faction, PROPERTIES.REP, 50.0)
	update_faction_data(faction, PROPERTIES.DECISIONS, [])


# bulky fancy print function
func print_overview() -> void:
	var output: String = ""
	var longest_name_length: int = 0
	for faction_enum: FACTIONS in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		longest_name_length = max(longest_name_length, faction_name.length())
	longest_name_length += 2

	var header: String = "| %-*s | %-10s | %-5s |" % [longest_name_length, "FACTION", "STATUS", PROPERTIES.REP]
	var divider: String = "-".repeat(header.length())
	output += divider + "\n"
	output += header + "\n"
	output += divider + "\n"

	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var rep: int = get_rep_num(faction_enum)
		var status: String = Global.enum_to_title(get_rep_status(faction_enum), STATUSES)
		output += "| %-*s | %-10s | %5d |" % [longest_name_length, faction_name, status, rep] + "\n"
		output += divider + "\n\n"

	output += "FACTION DECISIONS:\n"
	output += divider + "\n"

	for faction_enum: int in FACTIONS.values():
		var faction_name: String = get_faction_name(faction_enum)
		var decisions: Array = Data.game_data["factions_dict"][faction_enum][PROPERTIES.DECISIONS]
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
