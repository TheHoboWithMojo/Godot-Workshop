class_name NavpointManager
extends ChildManager


func _ready() -> void:
	for navpoint: Navpoint in get_children():
		Levels.levels_dict[navpoint.get_home_level_enum()][Levels.PROPERTIES.NAVPOINTS][navpoint.name] = Vector2.ZERO
		Levels.levels_dict[navpoint.get_home_level_enum()][Levels.PROPERTIES.NAVPOINTS][navpoint.name] = [navpoint.global_position]


func get_navpoints() -> Array[Navpoint]:
	var waypoints: Array[Navpoint]
	for node: Navpoint in get_children():
		waypoints.append(node)
	return waypoints
