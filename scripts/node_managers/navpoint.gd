extends Marker2D
class_name Navpoint

@export var related_quests: Array[Quests.QUESTS]

func _ready() -> void:
	if related_quests:
		for quest: Quests.QUESTS in related_quests:
			assert(quest != Quests.QUESTS.UNASSIGNED)
			Quests.add_quest_navpoint(self, quest)
