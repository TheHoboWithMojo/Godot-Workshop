extends Node

enum LEVELS {UNASSIGNED, DOC_MITCHELLS_HOUSE, GOODSPRINGS}

var levels: Dictionary[LEVELS, String] = {
	LEVELS.DOC_MITCHELLS_HOUSE: "res://scenes/levels/doc_mitchells_house/doc_mitchells_house.tscn",
	LEVELS.GOODSPRINGS: "res://scenes/levels/goodsprings/goodsprings.tscn",
}

func get_level_path(level: LEVELS) -> String:
	return levels[level]

func get_level_name(level: LEVELS) -> String:
	return Global.enum_to_camelcase(level, LEVELS)

func get_current_level() -> Level:
	return Global.level_manager.get_current_level()


func print_level_navpoints(level: LEVELS) -> bool: # loads the files created by vector places
	var level_name: String = get_level_name(level)
	var access_path: String = get_level_path(level).replace(".tscn", "_navpoints.txt")
	if not FileAccess.file_exists(access_path):
		Debug.throw_error(self, "print_level_navpoints", "The level %s does not have an associated navpoint file at %s" % [level_name, access_path])
		return false
	var navpoint_dict: Dictionary = Data.load_json_file(access_path)
	for navpoint_name: String in navpoint_dict:
		navpoint_dict[navpoint_name] = "Vector2" + navpoint_dict[navpoint_name]
	print("\nNavpoint Summary For Level: %s" % [level_name])
	Debug.pretty_print_dict(navpoint_dict)
	print("\n")
	return true
