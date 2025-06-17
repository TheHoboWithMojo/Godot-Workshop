extends Node

func _ready() -> void:
	await Global.ready_to_start()


func add_navpoint(navpoint: Navpoint) -> void:
	var nomen: String = navpoint.name
	if not nomen in Data.game_data[Data.PROPERTIES.NAVPOINTS_DATA]:
		Data.game_data[Data.PROPERTIES.NAVPOINTS_DATA][nomen] = Vector4(navpoint.global_position.x, navpoint.global_position.y, float(navpoint.get_related_quest_enums()[0]), float(navpoint.get_home_level_enum()))
		print("added new navpoint %s" % [navpoint.name])


func get_quest_navpoints(quest: Quests.QUESTS) -> Dictionary[String, Vector3]:
	var return_dict: Dictionary[String, Vector3]
	for navpoint_name: String in Data.game_data[Data.PROPERTIES.NAVPOINTS_DATA]:
		var data_storage: Vector4 = Data.game_data[Data.PROPERTIES.NAVPOINTS_DATA][navpoint_name]
		if int(data_storage.z) == quest:
			return_dict[navpoint_name] = Vector3(data_storage.x, data_storage.y, data_storage.w)
	return return_dict


func add_waypoint(waypoint: Waypoint) -> void:
	var nomen: String = waypoint.name
	if not nomen in Data.game_data[Data.PROPERTIES.WAYPOINTS_DATA]:
		Data.game_data[Data.PROPERTIES.WAYPOINTS_DATA][nomen] = Vector4(waypoint.global_position.x, waypoint.global_position.y, float(waypoint.get_quest_enum()), float(waypoint.get_home_level_enum()))
		print("added new waypoint %s" % [waypoint.name])


func get_quest_waypoints(quest: Quests.QUESTS) -> Dictionary[String, Vector3]:
	var return_dict: Dictionary[String, Vector3]
	for waypoint_name: String in Data.game_data[Data.PROPERTIES.WAYPOINTS_DATA]:
		var data_storage: Vector4 = Data.game_data[Data.PROPERTIES.WAYPOINTS_DATA][waypoint_name]
		if int(data_storage.z) == quest:
			return_dict[waypoint_name] = Vector3(data_storage.x, data_storage.y, data_storage.w)
	return return_dict
