extends Node

enum LEVELS {DOC_MITCHELLS_HOUSE}

var levels: Dictionary[LEVELS, String] = {
	LEVELS.DOC_MITCHELLS_HOUSE: "res://scenes/levels/doc_mitchell's_house/doc_mitchell's_house.tscn"
}

func get_level_path(level: LEVELS) -> String:
	return levels[level]

func get_current_level() -> Node2D:
	return Global.game_manager.current_level
