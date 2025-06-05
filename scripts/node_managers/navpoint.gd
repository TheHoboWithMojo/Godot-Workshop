extends Marker2D
class_name Navpoint

@export var related_quests: Array[Quests.QUESTS]
@export var related_level: Levels.LEVELS

func _ready() -> void:
	assert(related_level != Levels.LEVELS.UNASSIGNED, Debug.define_error("Each navpoint must be reference a level enum", self))
	add_to_group("navpoints")
	if related_quests:
		for quest: Quests.QUESTS in related_quests:
			assert(quest != Quests.QUESTS.UNASSIGNED, Debug.define_error("Each quest related to a navpoint must not be unassigned", self))
