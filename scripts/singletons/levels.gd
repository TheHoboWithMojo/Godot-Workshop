extends Node

enum LEVELS { UNASSIGNED, DOC_MITCHELLS_HOUSE, GOODSPRINGS, PROSPECTORS_SALOON }

var levels: Dictionary = {
	LEVELS.DOC_MITCHELLS_HOUSE: {
		"path": "res://scenes/levels/doc_mitchells_house/doc_mitchells_house.tscn",
		"waypoints": {},
		"navpoints": {},
		"connected_to": [LEVELS.GOODSPRINGS]
	},
	LEVELS.GOODSPRINGS: {
		"path": "res://scenes/levels/goodsprings/goodsprings.tscn",
		"waypoints": {},
		"navpoints": {},
		"connected_to": [LEVELS.DOC_MITCHELLS_HOUSE, LEVELS.PROSPECTORS_SALOON]
	},
	LEVELS.PROSPECTORS_SALOON: {
		"path": "res://scenes/levels/prospectors_saloon/prospectors_saloon.tscn",
		"waypoints": {},
		"navpoints": {},
		"connected_to": [LEVELS.GOODSPRINGS]
	},
}

func _ready() -> void:
	_precompute_paths() # Then precompute/cache all paths

func get_level_path(level: LEVELS) -> String:
	return levels[level]["path"]

func get_level_name(level: LEVELS) -> String:
	return Global.enum_to_camelcase(level, LEVELS)

func get_current_level_node() -> Level:
	return await Global.level_manager.get_current_level_node()

func get_current_level_enum() -> LEVELS:
	return await Global.level_manager.get_current_level_enum()

func print_vector_tool_level_navpoints(level: LEVELS) -> bool:
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

func print_onready_level_navpoints(level: LEVELS) -> void:
	print("\nNavpoint Summary For Level: %s" % [get_level_name(level)])
	Debug.pretty_print_dict(levels[level]["navpoints"])

func print_onready_level_waypoints(level: LEVELS) -> void:
	print("\nWaypoint Summary For Level: %s" % [get_level_name(level)])
	Debug.pretty_print_dict(levels[level]["navpoints"])

# -----------------------------
# PATHFINDING FUNCTIONS
# -----------------------------

var path_cache: Dictionary = {}

# computes all paths, theri inverses, and the shortest paths for easy reference
func _precompute_paths() -> void:
	path_cache.clear()

	var all_levels: Array = levels.keys()
	for start_level: LEVELS in all_levels:
		for end_level: LEVELS in all_levels:
			if start_level != end_level:
				var all_paths: Array[Array] = [] # Array of LEVELS paths
				_find_all_paths(start_level, end_level, [], {}, all_paths)
				if all_paths.size() > 0:
					path_cache[["all", start_level, end_level]] = all_paths

					var reversed_paths: Array[Array] = []
					for path: Array[LEVELS] in all_paths:
						var rev_path: Array[LEVELS] = path.duplicate()
						rev_path.reverse()
						reversed_paths.append(rev_path)
					path_cache[["all", end_level, start_level]] = reversed_paths

					all_paths.sort_custom(func(a: Array[LEVELS], b: Array[LEVELS]) -> bool:
						return a.size() < b.size()
					)
					path_cache[["short", start_level, end_level]] = all_paths[0]

					var shortest_rev: Array[LEVELS] = all_paths[0].duplicate()
					shortest_rev.reverse()
					path_cache[["short", end_level, start_level]] = shortest_rev

func get_all_paths(starting_level: LEVELS, desired_level: LEVELS) -> Array:
	var key: Array = ["all", starting_level, desired_level]
	if path_cache.has(key):
		return path_cache[key].map(func(p: Array) -> Array:
			return p.slice(1) # Return path without start_level
		)
	return []

func get_shortest_path(starting_level: LEVELS, desired_level: LEVELS) -> Array[LEVELS]:
	var key: Array = ["short", starting_level, desired_level]
	if path_cache.has(key):
		return path_cache[key].slice(1) # Remove start_level
	return []

func get_next_steps(starting_level: LEVELS, desired_level: LEVELS) -> Array[LEVELS]:
	var all_paths: Array = get_all_paths(starting_level, desired_level)
	var next_steps: Array[LEVELS] = []
	for path: Array[LEVELS] in all_paths:
		if path.size() > 0:
			var next_level: LEVELS = path[0]
			if next_level not in next_steps:
				next_steps.append(next_level)
	return next_steps

func _find_all_paths(current: LEVELS, target: LEVELS, path: Array[LEVELS], visited: Dictionary, all_paths: Array) -> void:
	if current in visited:
		return
	visited[current] = true
	path.append(current)
	if current == target:
		all_paths.append(path.duplicate())
	else:
		for next_level: LEVELS in levels[current]["connected_to"]:
			_find_all_paths(next_level, target, path, visited.duplicate(), all_paths)
	path.pop_back()
