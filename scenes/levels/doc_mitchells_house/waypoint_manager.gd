extends ChildManager
class_name WaypointManager

func _ready() -> void:
	for waypoint: Node in get_children():
		Levels.levels[waypoint.related_level]["Waypoints"][waypoint.name] = Vector2.ZERO
		Levels.levels[waypoint.related_level]["Waypoints"][waypoint.name] = [waypoint.global_position]

func get_waypoints() -> Array[Waypoint]:
	var waypoints: Array[Waypoint]
	for node: Waypoint in get_children():
		waypoints.append(node)
	return waypoints
