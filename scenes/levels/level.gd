@icon("res://assets/Icons/16x16/world.png")
class_name Level extends Node2D
@export var debugging: bool = false
@export var level_enum: Levels.LEVELS
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var waypoint_manager: WaypointManager
@export var navpoint_manager: NavpointManager
@export var portal_manager: PortalManager
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

func _ready() -> void:
	if level_enum == Levels.LEVELS.UNASSIGNED:
		level_enum = Levels.get_level_enum_from_scene_path(scene_file_path)
		if level_enum:
			push_error(Debug.define_error("LEVEL ENUM IS EITHER BROKEN OR UNASSIGNED TO THIS LEVEL, AUTO-RECOVERY SUCCESSFUL", self))
		else:
			push_error(Debug.define_error("LEVEL ENUM IS EITHER BROKEN OR UNASSIGNED TO THIS LEVEL, AUTO-RECOVERY UNSUCCESSFUL. TERMINATING RUNTIME.", self))
	assert(level_enum, Debug.define_error("All members of the level class must have a level_enum association", self))
	self.set_name(Levels.get_level_name(level_enum)) # enforce naming conventions


func get_level_enum() -> Levels.LEVELS:
	return level_enum


func get_portal_to_level(_level_enum: Levels.LEVELS) -> Portal:
	if not portal_manager:
		push_error(Debug.define_error("level does not have a portal manager to retrieve portals from", self))
		return null
	return portal_manager.get_portal_to(_level_enum)


func get_portals() -> Array[Portal]:
	if not portal_manager:
		push_error(Debug.define_error("level does not have a portal manager to retrieve portals from", self))
		return []
	return portal_manager.get_portals()


func get_waypoints_overview() -> void:
	print("\nWaypoint Overview For Level %s:" % [name])
	waypoint_manager.get_child_overview()


func get_navpoints() -> Array[Navpoint]:
	if not navpoint_manager:
		push_error(Debug.define_error("Level has no navpoint manager to call for its waypoints", self))
		return []
	var navpoints: Array[Navpoint] = navpoint_manager.get_navpoints()
	if not navpoints:
		push_error(Debug.define_error("Level has no navpoints under its navpoints manager", self))
		return []
	Debug.debug("Returning navpoints %s" % [navpoints], self, "get_navpoints")
	return navpoints


func get_waypoints() -> Array[Waypoint]:
	if not waypoint_manager:
		Debug.debug("Level has no waypoint manager to call for its waypoints", self, "get_waypoints")
		return []
	var waypoints: Array[Waypoint] = waypoint_manager.get_waypoints()
	if not waypoints:
		Debug.debug("Level has not/does not yet have waypoints under its waypoint manager", self, "get_waypoints")
		return []
	Debug.debug("Returning waypoints %s" % [waypoints], self, "get_navpoints")
	return waypoints


func get_navpoints_overview() -> void:
	print("\nNavpoint Overview For Level %s:" % [name])
	navpoint_manager.get_child_overview()
