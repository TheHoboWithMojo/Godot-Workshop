extends Node

enum LEVELS {DESERT, BOBSHOUSE}

var levels: Dictionary[LEVELS, String] = {
	LEVELS.DESERT: "res://scenes/levels/desert.tscn",
	LEVELS.BOBSHOUSE: "res://scenes/levels/bobs_house.tscn"
	}
	
func get_level_path(level: LEVELS) -> String:
	return levels[level]
