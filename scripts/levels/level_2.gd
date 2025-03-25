extends Node2D
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "enemy_spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

# IN FILE REFERENCES SECTION #
@export var checkpoints: Array[Marker2D]
@export var linked_levels: Array[PackedScene] = []
@onready var door1_player_in_range: bool = false
@onready var door2_player_in_range: bool = false
@onready var linked_levels_dict: Dictionary[String, PackedScene] = {}
@onready var enemies_dict: Dictionary[String, PackedScene] = {}

@onready var is_level_loaded = false

func _ready() -> void:
	init()
		
func init():
	for level in linked_levels:
		var level_name = Global.get_rawname(level)
		linked_levels_dict[level_name] = level
	
	for enemy in enemies:
		var enemy_name = Global.get_rawname(enemy)
		enemies_dict[enemy_name] = enemy
	
	for checkpoint in checkpoints:
		var checkpoint_name = Global.get_rawname(checkpoint)
		checkpoints_dict[checkpoint_name] = checkpoint.position
