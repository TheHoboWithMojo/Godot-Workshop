@icon("res://assets/Icons/16x16/world.png")
extends Node2D
class_name Level
@export var level: Levels.LEVELS
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var npcs: Array[NPC]
@export var waypoints: ChildManager
@export var interactables: Array[Interactable]
@export var navpoints: ChildManager
@export var portals: Array[Interactable]
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

func _ready() -> void:
	assert(level, "All members of the level class must have a level association")
	self.set_name(Levels.get_level_name(level)) # enforce naming conventions
	if navpoints:
		await navpoints.ready
		Levels.levels[level]["Waypoints"] = navpoints.children_dict
	if waypoints:
		await waypoints.ready
		Levels.levels[level]["Navpoints"] = navpoints.children_dict


func get_level() -> Levels.LEVELS:
	return level


func get_interactables() -> Array[Interactable]:
	return interactables


func get_portals() -> Array[Interactable]:
	return portals


func get_npcs() -> Array[NPC]:
	return npcs


func get_waypoints_overview() -> void:
	print("\nWaypoint Overview For Level %s" % [name])
	waypoints.get_child_overview()


func get_navpoints_overview() -> void:
	print("\nNavpoint Overview For Level %s" % [name])
	navpoints.get_child_overview()
