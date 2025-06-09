extends Node

enum QUESTS {UNASSIGNED, AINT_THAT_A_KICK_IN_THE_HEAD, BACK_IN_THE_SADDLE}

var quests: Dictionary = {
	QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD: {
		"complete": false,
		"characters": [Characters.CHARACTERS.DOC_MITCHELL],
		"timelines": [Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS],
		"related_levels": [Levels.LEVELS.DOC_MITCHELLS_HOUSE]
		},
	QUESTS.BACK_IN_THE_SADDLE: {
		"complete": false,
		"characters": [Characters.CHARACTERS.SUNNY_SMILES],
		"timelines": [Dialogue.TIMELINES.SUNNY_GREETING],
		"related_levels": [Levels.LEVELS.GOODSPRINGS, Levels.LEVELS.PROSPECTORS_SALOON],
	},
}


func get_quest_name(quest: QUESTS) -> String:
	return Global.enum_to_title(quest, QUESTS)


func get_quest_characters(quest: QUESTS) -> Array[Characters.CHARACTERS]:
	return quests[quest]["characters"]


func get_quest_timelines(quest: QUESTS) -> Array[Dialogue.TIMELINES]:
	return quests[quest]["timelines"]


func get_quest_levels(quest: QUESTS) -> Array[Levels.LEVELS]:
	return quests[quest]["related_levels"]


func get_quest_waypoints(quest_enum: QUESTS) -> Array[Waypoint]:
	var waypoint_array: Array[Waypoint]
	for waypoint: Waypoint in get_tree().get_nodes_in_group("waypoints"):
		if waypoint.get_quest_enum() == quest_enum:
			waypoint_array.append(waypoint)
	if waypoint_array.size() == 0:
		push_warning("No waypoints found for quest %s, ensure quest enum refs are not broken" % [get_quest_name(quest_enum)], self)
	return waypoint_array


func get_quest_navpoints(quest_enum: QUESTS) -> Array[Navpoint]:
	var navpoint_array: Array[Navpoint]
	for navpoint: Navpoint in get_tree().get_nodes_in_group("navpoints"):
		if quest_enum in navpoint.get_related_quest_enums():
			navpoint_array.append(navpoint)
	if navpoint_array.size() == 0:
		push_warning("No navpoints found for quest %s, ensure quest enum refs are not broken" % [get_quest_name(quest_enum)], self)
	return navpoint_array


func is_quest_complete(quest: QUESTS) -> bool:
	return quests[quest]["completed"]
