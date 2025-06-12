@icon("res://assets/Icons/16x16/script_lightning_edit.png")
class_name QuestManager extends Node
@onready var back_in_the_saddle: BackInTheSaddle = $BackInTheSaddle
@onready var aint_that_a_kick_in_the_head: AintThatAKickInTheHead = $AintThatAKickInTheHead


func _ready() -> void:
	for child: Node in get_children():
		if "linked_quest" in child:
			child.set_name(Quests.get_quest_name(child.linked_quest))

signal new_quest_assigned

var current_quest: Quest


func get_quest_node(quest: Quests.QUESTS) -> Quest:
	return find_child(Quests.get_quest_name(quest))


func get_current_quest_node() -> Quest:
	if not current_quest:
		await new_quest_assigned
	return current_quest


func get_current_quest_enum() -> Quests.QUESTS:
	return current_quest.get_quest_enum() if current_quest else Quests.QUESTS.UNASSIGNED


func set_current_quest(quest: Quest, override: bool = false) -> bool:
	if not override and current_quest: # safety logic
		pass
	current_quest = quest
	new_quest_assigned.emit()
	return true
