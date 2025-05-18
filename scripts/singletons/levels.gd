extends Node

enum LEVELS {NA, DOC_MITCHELLS_HOUSE, GOODSPRINGS}

var levels: Dictionary[LEVELS, String] = {
	LEVELS.DOC_MITCHELLS_HOUSE: "res://scenes/levels/doc_mitchell's_house/doc_mitchell's_house.tscn",
	LEVELS.GOODSPRINGS: "res://scenes/levels/goodsprings/goodsprings.tscn",
}

func get_level_path(level: LEVELS) -> String:
	return levels[level]

func get_level_name(level: LEVELS) -> String:
	return Global.enum_to_camelcase(level, LEVELS)

func get_current_level() -> Level:
	return Global.game_manager.current_level
