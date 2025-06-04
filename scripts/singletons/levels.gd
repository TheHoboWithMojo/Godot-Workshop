extends Node

enum LEVELS {UNASSIGNED, DOC_MITCHELLS_HOUSE, GOODSPRINGS, PROSPECTORS_SALOON}

var levels: Dictionary[LEVELS, Dictionary] = {
	LEVELS.DOC_MITCHELLS_HOUSE: {
		"Path": "res://scenes/levels/doc_mitchells_house/doc_mitchells_house.tscn",
		"Waypoints": {},
		"Navpoints": {},
	},
	LEVELS.GOODSPRINGS: {
		"Path": "res://scenes/levels/goodsprings/goodsprings.tscn",
		"Waypoints": {},
		"Navpoints": {},
	},
		LEVELS.PROSPECTORS_SALOON: {
		"Path": "res://scenes/levels/prospectors_saloon/prospectors_saloon.tscn",
		"Waypoints": {},
		"Navpoints": {},
	},
}


func get_level_path(level: LEVELS) -> String:
	return levels[level]["Path"]

func get_level_name(level: LEVELS) -> String:
	return Global.enum_to_camelcase(level, LEVELS)

func get_current_level_node() -> Level:
	return await Global.level_manager.get_current_level_node()


func get_current_level_enum() -> Levels.LEVELS:
	return await Global.level_manager.get_current_level_enum()


func print_vector_tool_level_navpoints(level: LEVELS) -> bool: # loads the files created by vector placing tool
	var level_name: String = get_level_name(level)
	var access_path: String = get_level_path(level).replace(".tscn", "_navpoints.txt")
	if Debug.throw_warning_if(!FileAccess.file_exists(access_path), "The level %s does not have an associated navpoint file at %s" % [level_name, access_path], self):
		return false
	var navpoint_dict: Dictionary = Data.load_json_file(access_path)
	for navpoint_name: String in navpoint_dict:
		navpoint_dict[navpoint_name] = "Vector2" + navpoint_dict[navpoint_name]
	print("\nNavpoint Summary For Level: %s" % [level_name])
	Debug.pretty_print_dict(navpoint_dict)
	print("\n")
	return true


func print_onready_level_navpoints(level: LEVELS) -> void: # uses the level class navpoint and waypoint nodse
	print("\nNavpoint Summary For Level: %s" % [get_level_name(level)])
	Debug.pretty_print_dict(levels[level]["Navpoints"])


func print_onready_level_waypoints(level: LEVELS) -> void:
	print("\nWaypoint Summary For Level: %s" % [get_level_name(level)])
	Debug.pretty_print_dict(levels[level]["Navpoints"])
