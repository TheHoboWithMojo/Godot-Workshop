class_name ActiveWaypoint extends Marker2D
# pos + home level + quest ref
@export var show_marker: bool = true
@export var debugging: bool = false
var home_level_info: Vector4
var home_level_pos: Vector2
var home_level_enum: Levels.LEVELS
var quest_enum_ref: Quests.QUESTS


func _ready() -> void:
	Global.level_manager.new_level_loaded.connect(_on_new_level_loaded)


func set_active_waypoint(waypoint_name: String) -> void:
	home_level_info = Data.game_data[Data.PROPERTIES.WAYPOINTS_DATA][waypoint_name]
	home_level_pos = Vector2(home_level_info.x, home_level_info.y)
	@warning_ignore("int_as_enum_without_cast")
	home_level_enum = int(home_level_info.w)
	@warning_ignore("int_as_enum_without_cast")
	quest_enum_ref = int(home_level_info.z)
	Debug.debug("Waypoint '%s' with pos '%s' of home_level '%s' and quest '%s' was set to active" % [waypoint_name, home_level_pos, Levels.get_level_name(home_level_enum), Quests.get_quest_name(quest_enum_ref)], self, "set_active_waypoint")
	_try_navigate_home(await Levels.get_current_level_node())


func _on_new_level_loaded(new_level: Level) -> void:
	_try_navigate_home(new_level)


func _try_navigate_home(level: Level) -> void:
	if quest_enum_ref and Quests.is_quest_completed(quest_enum_ref):
		Debug.debug("Current waypoints's quest has been completed, hiding waypoint", self, "_try_navigate_home")
		set_visible(false)
		return
	if await Global.quest_manager.get_current_quest_enum() != quest_enum_ref:
		Debug.debug("Current quest is not the current waypoint's linked quest, hiding waypoint", self, "_try_navigate_home")
		set_visible(false)
		return
	var new_level_enum: Levels.LEVELS = level.get_level_enum()
	if new_level_enum == home_level_enum:
		Debug.debug("Current level is the current waypoint's home level, deleting duplicates", self, "_try_navigate_home")
		set_global_position(home_level_pos)
		for _duplicate: Node in get_children():
			_duplicate.queue_free()
		add_logo()
		return
	Debug.debug("Current level is not the current waypoint's home level, calculating ways back", self, "_try_navigate_home")
	var steps_toward_home_level: Array[Levels.LEVELS] = Levels.get_next_steps(new_level_enum, home_level_enum)
	if not steps_toward_home_level.size() > 0:
		return
	var positions_to_move_to: Array[Vector2] = []
	var portals: Array[Portal] = level.get_portals()
	for step: Levels.LEVELS in steps_toward_home_level:
		for portal: Portal in portals:
			if portal.get_send_to_level_enum() == step:
				positions_to_move_to.append(portal.get_spawn_point_position())
	if not positions_to_move_to.size() > 0:
		return
	set_global_position(positions_to_move_to[0])
	positions_to_move_to.pop_front()
	for _position: Vector2 in positions_to_move_to:
		var _duplicate: Marker2D = duplicate()
		add_child(_duplicate)
		_duplicate.set_global_position(_position)


func add_logo() -> void:
	var sprite: Sprite2D = Sprite2D.new()
	add_child(sprite)
	sprite.set_visible(show_marker)
	sprite.set_texture(load("res://scenes/level_builders/waypoint/waypoint.tres"))
