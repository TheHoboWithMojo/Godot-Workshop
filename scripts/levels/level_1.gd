extends Node2D
# READ BY GAME MANAGER SECTION #
@export var tiles: TileMapLayer
@export var enemies: Array[PackedScene] = []
@onready var enemy_spawnpoints: Array[Vector2] = Global.get_tiles_with_property(tiles, "enemy_spawnable")
@onready var checkpoints_dict: Dictionary[String, Vector2] = {}

# IN FILE REFERENCES SECTION #
@export var checkpoints: Array[Marker2D]
@export var linked_levels_dict: Dictionary[Area2D, PackedScene]
@export var steve: CharacterBody2D
@onready var enemies_dict: Dictionary[String, PackedScene] = {}

func _ready() -> void:
	init_dicts()
	
func init_dicts():
	for enemy in enemies:
		var enemy_name = Global.get_rawname(enemy)
		enemies_dict[enemy_name] = enemy
	
	for checkpoint in checkpoints:
		var checkpoint_name = Global.get_rawname(checkpoint)
		checkpoints_dict[checkpoint_name] = checkpoint.position
		
	for portal in linked_levels_dict:
		portal.add_to_group("interactable")
		
func _process(_delta: float) -> void:
	if Global.player_touching_node:
		if Global.player_touching_node in linked_levels_dict.keys():
				open_portal(Global.player_touching_node)
		
func open_portal(portal: Area2D):
	if Input.is_action_just_pressed("interact"):
		Global.game_manager.level_changed.emit(self, linked_levels_dict[portal])
