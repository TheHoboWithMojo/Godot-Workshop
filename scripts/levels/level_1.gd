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

signal player_entered_area

func _ready() -> void:
	init_dicts()
	player_entered_area.connect(_on_player_entered_portal)
	
func _on_player_entered_portal(portal: Area2D) -> void: # open the portal if the player and cursor touch the portal
	while Global.is_touching_player(portal):
		if Global.is_touching_mouse(portal):
			if Input.is_action_just_pressed("interact"):
				Global.game_manager.level_changed.emit(self, linked_levels_dict[portal])
				break
		await get_tree().process_frame

func init_dicts() -> void:
	for enemy: PackedScene in enemies:
		var enemy_name: String = Global.get_rawname(enemy)
		enemies_dict[enemy_name] = enemy
	
	for checkpoint: Marker2D in checkpoints:
		var checkpoint_name: String = Global.get_rawname(checkpoint)
		checkpoints_dict[checkpoint_name] = checkpoint.position
		
	for portal: Area2D in linked_levels_dict:
		portal.add_to_group("interactable")
