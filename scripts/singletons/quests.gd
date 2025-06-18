extends Node

enum QUESTS {UNASSIGNED, AINT_THAT_A_KICK_IN_THE_HEAD, BACK_IN_THE_SADDLE}
enum PROPERTIES {FINISHED, CHARACTERS, TIMELINES, RELATED_LEVELS, OBJECTIVES}

var quests_dict: Dictionary[QUESTS, Dictionary] = {
	QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.DOC_MITCHELL],
		PROPERTIES.TIMELINES: [Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS],
		PROPERTIES.RELATED_LEVELS: [Levels.LEVELS.DOC_MITCHELLS_HOUSE],
		PROPERTIES.OBJECTIVES: {},
		},
	QUESTS.BACK_IN_THE_SADDLE: {
		PROPERTIES.FINISHED: false,
		PROPERTIES.CHARACTERS: [Characters.CHARACTERS.SUNNY_SMILES],
		PROPERTIES.TIMELINES: [Dialogue.TIMELINES.SUNNY_GREETING],
		PROPERTIES.RELATED_LEVELS: [Levels.LEVELS.GOODSPRINGS, Levels.LEVELS.PROSPECTORS_SALOON],
		PROPERTIES.OBJECTIVES: {},
	},
}


func print_quests_data() -> void:
	var pretty_dict: Dictionary[String, Dictionary]
	for quest: QUESTS in Data.game_data[Data.PROPERTIES.QUESTS]:
		var quest_name: String = Global.enum_to_snakecase(quest, QUESTS)
		pretty_dict[quest_name] = {}
		for property: int in PROPERTIES.size():
			var category_name: String = Global.enum_to_snakecase(property, PROPERTIES)
			var property_value: Variant
			match(property):
				PROPERTIES.CHARACTERS:
					property_value = Data.game_data[Data.PROPERTIES.QUESTS][quest][property].map(func(character: Characters.CHARACTERS) -> String: return Characters.get_character_name(character))
				PROPERTIES.RELATED_LEVELS:
					property_value = Data.game_data[Data.PROPERTIES.QUESTS][quest][property].map(func(level: Levels.LEVELS) -> String: return Levels.get_level_name(level))
				PROPERTIES.TIMELINES:
					property_value = Data.game_data[Data.PROPERTIES.QUESTS][quest][property].map(func(timeline: Dialogue.TIMELINES) -> String: return Dialogue.get_timeline_name(timeline))
				_:
					property_value = Data.game_data[Data.PROPERTIES.QUESTS][quest][property]
					if not property_value is bool and not property_value:
						property_value = "empty"
			pretty_dict[quest_name][category_name] = property_value
	Debug.pretty_print(pretty_dict)


func get_quest_name(quest: QUESTS) -> String:
	return Global.enum_to_title(quest, QUESTS)


func get_quest_characters(quest: QUESTS) -> Array[Characters.CHARACTERS]:
	return quests_dict[quest][PROPERTIES.CHARACTERS]


func is_objective_finished(quest: QUESTS, objective_name: String) -> bool:
	return Data.game_data[Data.PROPERTIES.QUESTS][quest][PROPERTIES.OBJECTIVES][objective_name]


func is_objective_stored(quest: QUESTS, objective_name: String) -> bool:
	return objective_name in Data.game_data[Data.PROPERTIES.QUESTS][quest][PROPERTIES.OBJECTIVES]


func get_quest_timelines(quest: QUESTS) -> Array[Dialogue.TIMELINES]:
	return quests_dict[quest][PROPERTIES.TIMELINES]


func get_quest_levels(quest: QUESTS) -> Array[Levels.LEVELS]:
	return quests_dict[quest][PROPERTIES.RELATED_LEVELS]


func get_quest_waypoints(quest_enum: QUESTS) -> Array[Waypoint]:
	var waypoint_array: Array[Waypoint]
	for waypoint: Waypoint in get_tree().get_nodes_in_group("waypoints"):
		if not waypoint.get_quest_enum() == quest_enum:
			continue
		waypoint_array.append(waypoint)
	if not waypoint_array:
		push_warning("No waypoints found for quest %s, ensure quest enum refs are not broken" % [get_quest_name(quest_enum)], self)
	return waypoint_array


func get_quest_navpoints(quest_enum: QUESTS) -> Array[Navpoint]:
	var navpoint_array: Array[Navpoint]
	for navpoint: Navpoint in get_tree().get_nodes_in_group("navpoints"):
		if not quest_enum in navpoint.get_related_quest_enums():
			continue
		navpoint_array.append(navpoint)
	if not navpoint_array:
		push_warning("No navpoints found for quest %s, ensure quest enum refs are not broken" % [get_quest_name(quest_enum)], self)
	return navpoint_array


func set_quest_finished(quest: QUESTS, value: bool) -> void:
	if quest == QUESTS.UNASSIGNED:
		push_error(Debug.define_error("Tried to set an unassigned quest's completions to %s" % [value], self))
		return
	Data.game_data[Data.PROPERTIES.QUESTS][quest][PROPERTIES.FINISHED] = value


func is_quest_finished(quest: QUESTS) -> bool:
	if quest == QUESTS.UNASSIGNED:
		push_error(Debug.define_error("Tried to get the completion status of an unassigned timeline", self))
		return false
	return Data.game_data[Data.PROPERTIES.QUESTS][quest][PROPERTIES.FINISHED]
