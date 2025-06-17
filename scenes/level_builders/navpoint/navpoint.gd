extends Marker2D
class_name Navpoint

@export var related_quest_enums: Array[Quests.QUESTS] = []
@export var home_level_enum: Levels.LEVELS = Levels.LEVELS.UNASSIGNED

func _ready() -> void:
	assert(home_level_enum != Levels.LEVELS.UNASSIGNED, Debug.define_error("is a navpoint and accordingly must reference a level enum", self))
	if related_quest_enums != []:
		assert(related_quest_enums.all(func(quest: Quests.QUESTS) -> bool: return quest != Quests.QUESTS.UNASSIGNED), Debug.define_error("Each quest related to a navpoint must not be unassigned", self))
	else:
		push_warning(Debug.define_error("Does not have an related quest assigned", self))
	Markers.add_navpoint(self)
	add_to_group("navpoints")


func get_related_quest_enums() -> Array[Quests.QUESTS]:
	return related_quest_enums


func get_home_level_enum() -> Levels.LEVELS:
	return home_level_enum
