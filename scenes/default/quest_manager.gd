@icon("res://assets/Icons/16x16/script_lightning_edit.png")
class_name QuestManager extends Node

signal new_quest_assigned

var current_quest: QuestMaker


func get_quest_node(quest: Quests.QUESTS) -> QuestMaker:
	return find_child(Quests.get_quest_name(quest))


func get_current_quest_node() -> QuestMaker:
	if not current_quest:
		await new_quest_assigned
	return current_quest


func get_current_quest_enum() -> Quests.QUESTS:
	return current_quest.get_quest_enum() if current_quest else Quests.QUESTS.UNASSIGNED


func set_current_quest(quest: QuestMaker, override: bool = false) -> bool:
	if not override and current_quest: # safety logic
		pass
	current_quest = quest
	new_quest_assigned.emit()
	return true
