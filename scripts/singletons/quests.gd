extends Node

enum QUESTS {ERROR, AINT_THAT_A_KICK_IN_THE_HEAD}

var quests: Dictionary = {
	QUESTS.AINT_THAT_A_KICK_IN_THE_HEAD: {
		"complete": false,
		"characters": [Characters.CHARACTERS.DOC_MITCHELL],
		"timelines": [Dialogue.TIMELINES.YOURE_AWAKE, Dialogue.TIMELINES.PICKTAGS],
		"related_levels": [Levels.LEVELS.DOC_MITCHELLS_HOUSE]
	}
}

func get_quest_name(quest: QUESTS) -> void:
	return Global.enum_to_title(quest, QUESTS)

func get_quest_characters(quest: QUESTS) -> Array[Characters.CHARACTERS]:
	return quests[quest]["characters"]

func get_quest_timelines(quest: QUESTS) -> Array[Dialogue.TIMELINES]:
	return quests[quest]["timelines"]

func get_quest_levels(quest: QUESTS) -> Array[Levels.LEVELS]:
	return quests[quest]["related_levels"]

func is_quest_complete(quest: QUESTS) -> bool:
	return quests[quest]["completed"]
