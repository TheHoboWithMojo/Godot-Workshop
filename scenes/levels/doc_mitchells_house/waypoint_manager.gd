extends ChildManager
class_name WaypointManager

var waypoints_unloaded: bool = false
func _ready() -> void:
	for waypoint: Waypoint in get_children():
		if waypoint == null:
			waypoints_unloaded = true
			return
		Levels.levels_dict[waypoint.get_home_level_enum()][Levels.PROPERTIES.WAYPOINTS][waypoint.name] = Vector2.ZERO
		Levels.levels_dict[waypoint.get_home_level_enum()][Levels.PROPERTIES.WAYPOINTS][waypoint.name] = [waypoint.global_position]

func get_waypoints() -> Array[Waypoint]:
	var waypoints: Array[Waypoint]
	if not waypoints_unloaded:
		for waypoint: Waypoint in get_children():
			waypoints.append(waypoint)
	return waypoints
