extends Node

enum QUESTS {UNASSIGNED, AINT_THAT_A_KICK_IN_THE_HEAD}

var quests: Dictionary = {
	QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD: {
		"complete": false,
		"characters": [Characters.CHARACTERS.DOC_MITCHELL],
		"timelines": [Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS],
		"related_levels": [Levels.LEVELS.DOC_MITCHELLS_HOUSE],
		"waypoints": [], # appended by waypoint scenes, will be hardcoded later
	}
}


func get_quest_name(quest: QUESTS) -> String:
	return Global.enum_to_title(quest, QUESTS)


func get_quest_characters(quest: QUESTS) -> Array[Characters.CHARACTERS]:
	return quests[quest]["characters"]


func get_quest_timelines(quest: QUESTS) -> Array[Dialogue.TIMELINES]:
	return quests[quest]["timelines"]


func get_quest_levels(quest: QUESTS) -> Array[Levels.LEVELS]:
	return quests[quest]["related_levels"]


func get_quest_waypoints(quest: QUESTS) -> Array: # bc godot doesnt support nested dictionaries i cant return a Waypoint safely
	return quests[quest]["waypoints"]


func add_quest_waypoint(waypoint: Waypoint, quest: QUESTS) -> void:
	if waypoint not in quests[quest]["waypoints"]:
		quests[quest]["waypoints"].append(waypoint)


func is_quest_complete(quest: QUESTS) -> bool:
	return quests[quest]["completed"]
