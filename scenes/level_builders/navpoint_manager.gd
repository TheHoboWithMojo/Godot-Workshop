class_name NavpointManager
extends ChildManager

func _ready() -> void:
	for navpoint: Node in get_children():
		Levels.levels[navpoint.related_level][Levels.PROPERTIES.NAVPOINTS][navpoint.name] = Vector2.ZERO
		Levels.levels[navpoint.related_level][Levels.PROPERTIES.NAVPOINTS][navpoint.name] = [navpoint.global_position]


func get_navpoints() -> Array[Navpoint]:
	var waypoints: Array[Navpoint]
	for node: Navpoint in get_children():
		waypoints.append(node)
	return waypoints
