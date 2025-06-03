@icon("res://assets/Icons/16x16/world.png")
extends Node2D
class_name Level
@export var level: Levels.LEVELS
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var npcs: Array[NPC]
@export var waypoint_manager: ChildManager
@onready var waypoints: Array[Waypoint]
@export var navpoint_manager: ChildManager
@onready var navpoints: Array[Navpoint]
@export var interactables: Array[Interactable]
@export var portals: Array[Portal]
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

func _ready() -> void:
	Debug.enforce(level, "All members of the level class must have a level association", self)
	self.set_name(Levels.get_level_name(level)) # enforce naming conventions
	if navpoint_manager:
		await navpoint_manager.ready
		Levels.levels[level]["Waypoints"] = navpoint_manager.children_dict
		waypoints = waypoint_manager.get_children(false).filter(func(c: Node) -> bool: return c is Waypoint)
	if waypoint_manager:
		await waypoint_manager.ready
		Levels.levels[level]["Navpoints"] = navpoint_manager.children_dict
		navpoints = navpoint_manager.get_children(false).filter(func(c: Node) -> bool: return c is Navpoint)



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
	return npcs


func get_portal_to_level(_level: Levels.LEVELS) -> Portal:
	for portal: Portal in portals:
		if portal.send_to_level_path == Levels.get_level_path(_level):
			return portal
	return null


func get_waypoints_overview() -> void:
	print("\nWaypoint Overview For Level %s:" % [name])
	waypoint_manager.get_child_overview()


func get_navpoints() -> Array[Navpoint]:
	return navpoints


func get_waypoints() -> Array[Waypoint]:
	return waypoints


func get_navpoints_overview() -> void:
	print("\nNavpoint Overview For Level %s:" % [name])
	navpoint_manager.get_child_overview()
