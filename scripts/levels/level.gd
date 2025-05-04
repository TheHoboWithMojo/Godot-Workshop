extends Node2D
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@export var npcs: Array[CharacterBody2D]
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

# IN FILE REFERENCES SECTION #
@export var checkpoints: Array[Marker2D]
@export var npcs_dict: Dictionary[String, CharacterBody2D]
@onready var enemies_dict: Dictionary[String, PackedScene] = {}

func _ready() -> void:
	init_dicts()

func init_dicts() -> void:
	for enemy: PackedScene in enemies:
		var enemy_name: String = Global.get_rawname(enemy)
		enemies_dict[enemy_name] = enemy
	
	for npc: CharacterBody2D in npcs:
		var npc_name: String = Global.get_rawname(npc)
		npcs_dict[npc_name] = npc
	
	for checkpoint: Marker2D in checkpoints:
		var checkpoint_name: String = Global.get_rawname(checkpoint)
		checkpoints_dict[checkpoint_name] = checkpoint.position
