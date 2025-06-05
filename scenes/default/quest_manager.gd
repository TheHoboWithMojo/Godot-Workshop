@icon("res://assets/Icons/16x16/script_lightning_edit.png")
extends Node
class_name QuestManager

#func _ready() -> void:
	#Global.level_manager.new_level_loaded.connect(_on_new_leveL_loaded)


#func _on_new_level_loaded()

func store_child(node: Node) -> void:
	node.reparent.call_deferred(self)
	var current_level: Level = await Levels.get_current_level_node()
	if node not in current_level.get_interactables():
		node.set_physics_process(false)
