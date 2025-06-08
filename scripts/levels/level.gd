@icon("res://assets/Icons/16x16/world.png")
class_name Level extends Node2D
@export var debugging: bool = false
@export var level: Levels.LEVELS
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var default_npcs: Array[NPC]
@export var waypoint_manager: WaypointManager
@export var navpoint_manager: NavpointManager
@export var interactables: Array[Interactable]
@export var portals: Array[Portal]
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

func _ready() -> void:
	assert(level, Debug.define_error("All members of the level class must have a level association", self))
	self.set_name(Levels.get_level_name(level)) # enforce naming conventions


func get_level_enum() -> Levels.LEVELS:
	return level


func get_interactables() -> Array[Interactable]:
	return interactables


func get_portals() -> Array[Portal]:
	return portals


func get_portals_overview() -> void:
	var dict: Dictionary = {}
	for portal: Portal in portals:
		dict[portal.name] = "Vector2" + str(portal.global_position)
	print("\nPortal Overview For Level %s:" % [name])
	Debug.pretty_print_dict(dict)


func get_npcs() -> Array[NPC]:
	return default_npcs


func get_portal_to_level(_level: Levels.LEVELS) -> Portal:
	var level_name: String = Levels.get_level_name(_level)
	var _portal: Array[Portal] = portals.filter(func(portal: Portal) -> bool: return portal.get_send_to_level_enum() == _level)
	match(_portal.size()):
		0:
			push_error(Debug.define_error("No portals to level %s was found" % [level_name], self))
			return null
		1:
			Debug.debug("Returning portal to level %s" % [level_name], self, "get_portal_to_level")
			return _portal[0]
		_:
			push_error(Debug.define_error("More than one portal to level %s was found, returning the first" % [level_name], self))
			return _portal[0]


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
		push_warning(Debug.define_error("Level has no waypoint manager to call for its waypoints", self))
		return []
	var waypoints: Array[Waypoint] = waypoint_manager.get_waypoints()
	if not waypoints:
		push_warning(Debug.define_error("Level has not/does not yet have waypoints under its waypoint manager", self))
		return []
	Debug.debug("Returning waypoints %s" % [waypoints], self, "get_navpoints")
	return waypoints



func get_navpoints_overview() -> void:
	print("\nNavpoint Overview For Level %s:" % [name])
	navpoint_manager.get_child_overview()
