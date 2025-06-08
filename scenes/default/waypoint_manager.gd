@icon("res://assets/Icons/16x16/crosshair.png")
class_name GlobalWaypointManager
extends ChildManager
@export var debugging: bool = false

func _ready() -> void:
	assert(enforced_class == ENFORCABLE_CLASSES.WAYPOINT)
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)


func set_active_all_waypoints(value: bool, custom_array: Array[Waypoint] = []) -> void:
	print("setting all active to ", value)
	if not custom_array:
		for waypoint: Waypoint in get_children():
			waypoint.set_active(value)
	for waypoint: Waypoint in custom_array:
			waypoint.set_active(value)


#var current_waypoints: Array[Waypoint]
#func set_current_waypoints(waypoints: Array[Waypoint]) -> void:
	#current_waypoints.clear()
	#current_waypoints = waypoints
#
#
#func get_current_waypoints() -> Array[Waypoint]:
	#return current_waypoints


func _on_new_level_loaded(level: Level) -> void:
	var pot_new_waypoints: Array[Waypoint] = level.get_waypoints()
	_process_new_waypoints(pot_new_waypoints)
	_place_waypoints_at_paths_to_home_level(level)

func _process_new_waypoints(waypoints: Array[Waypoint]) -> void:
	if not get_children():
		for waypoint: Waypoint in waypoints:
			waypoint.reparent.call_deferred(self)
		Debug.debug_if(waypoints != [], "Added new waypoints %s" % [waypoints], self, "_process_new_waypoints")
		return
	for waypoint: Waypoint in waypoints:
		for stored_waypoint: Waypoint in get_children():
			if waypoint.name == stored_waypoint.name and waypoint.get_home_level() == stored_waypoint.get_home_level():
				waypoint.duplicated = true
				if waypoint.get_parent() != self:
					waypoint.remove_from_group("waypoints")
					waypoint.queue_free()
					continue
			waypoint.reparent.call_deferred(self)
			Debug.debug("Added new waypoints %s" % [waypoint.name], self, "_process_new_waypoints")


# method to place copies of a waypoint at every door that leads back to its home level
func _place_waypoints_at_paths_to_home_level(level: Level) -> void:
	var new_level_enum: Levels.LEVELS = level.get_level_enum()
	var current_quest: Quest = await Global.quest_manager.get_current_quest_node()
	for navpoint: Waypoint in get_children():

		var show_navpoint: bool = navpoint in await current_quest.get_active_waypoints()
		Debug.debug_if(show_navpoint, "%s should be set to visible" % [navpoint.name], self, "_place_waypoints_at_paths_to_home_level")
		var home_level: Levels.LEVELS = navpoint.get_home_level()

		if new_level_enum == home_level:
			var duplicates: Array[Waypoint] = navpoint.get_duplicates()
			Debug.debug_if(duplicates != [], "home level reached, deleting duplicates", navpoint, "_place_waypoints_at_paths_to_home_level")
			for copy: Waypoint in duplicates:
				copy.queue_free()
			navpoint.global_position = navpoint.spawn_position
			await get_tree().process_frame
		else:
			# otherwise, find paths toward the home level and mark every way to get there
			var steps_toward_home_level: Array[Levels.LEVELS] = Levels.get_next_steps(new_level_enum, home_level)

			if steps_toward_home_level.size() > 0:
				Debug.debug("new level different than home level, calculating paths back", navpoint, "_place_waypoints_at_paths_to_home_level")
				var positions_to_move_to: Array[Vector2] = []
				var portals: Array[Portal] = level.get_portals()
				for step: Levels.LEVELS in steps_toward_home_level:
					for portal: Portal in portals:
						if portal.get_send_to_level_enum() == step:
							positions_to_move_to.append(portal.get_spawn_point_position())

				if positions_to_move_to.size() > 0:
					Debug.debug("Path positions successfully calculated, moving position", navpoint, "_place_waypoints_at_paths_to_home_level")
					# First position goes to this waypoint
					navpoint.global_position = positions_to_move_to[0]
					positions_to_move_to.pop_front()

					# Duplicate for remaining positions
					for _position: Vector2 in positions_to_move_to:
						var copy: Waypoint = navpoint.create_duplicate()
						copy.global_position = _position
						copy.set_active(show_navpoint)
		navpoint.set_active(show_navpoint)
