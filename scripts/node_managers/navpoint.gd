extends Marker2D
class_name Navpoint

@export var related_quests: Array[Quests.QUESTS] = []
@export var related_level: Levels.LEVELS = Levels.LEVELS.UNASSIGNED

func _ready() -> void:
	assert(related_level != Levels.LEVELS.UNASSIGNED, Debug.define_error("Each navpoint must be reference a level enum", self))
	if related_quests != []:
		assert(related_quests.all(func(quest: Quests.QUESTS) -> bool: return quest != Quests.QUESTS.UNASSIGNED), Debug.define_error("Each quest related to a navpoint must not be unassigned", self))
	else:
		push_warning(Debug.define_error("Does not have an related quest assigned", self))
	add_to_group("navpoints")
