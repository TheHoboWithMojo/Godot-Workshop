extends Node2D
class_name Level
@export var level: Levels.LEVELS
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var npcs: Array[CharacterBody2D]
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

func _ready() -> void:
	if level:
		self.set_name(Levels.get_level_name(level)) # enforce naming conventions
	else:
		Debug.throw_error(self, "_ready", "Parent of Level node MUST be connected to the level singleton")
		
func get_level() -> Levels.LEVELS:
	return level
