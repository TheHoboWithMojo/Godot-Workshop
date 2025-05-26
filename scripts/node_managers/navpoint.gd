extends Marker2D
class_name Navpoint

@export var related_quests: Array[Quests.QUESTS]

func _ready() -> void:
	add_to_group("navpoints")
	if related_quests:
		for quest: Quests.QUESTS in related_quests:
			assert(quest != Quests.QUESTS.UNASSIGNED)
