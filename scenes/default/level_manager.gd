@icon("res://assets/Icons/16x16/entity_move.png")
extends Node
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var current_level: Level
@onready var enemy_spawnpoints: Array[Vector2]
@onready var checkpoints: Dictionary[String, Vector2]
@onready var current_tile_map: TileMapLayer
@onready var spawnable_enemies: Array[PackedScene]
@onready var _level_loaded: bool = false
# =========================================================================
# SIGNALS
# =========================================================================
signal level_loaded
# =========================================================================
# PUBLIC FUNCTIONS
# =========================================================================
func _ready() -> void:
	if not Data.is_data_loaded:
		await Data.data_loaded

func is_level_loaded() -> bool:
	return _level_loaded


func get_spawnable_enemies() -> Array[PackedScene]:
	if not is_level_loaded():
		Debug.throw_error(self, "get_spawnable_enemies", "Level is still loading...")
		return []
	return spawnable_enemies


func get_enemy_spawnpoints() -> Array[Vector2]:
	if not is_level_loaded():
		Debug.throw_error(self, "get_enemy_spawnpoints", "Level is still loading...")
		return []
	return enemy_spawnpoints


func get_current_level() -> Node:
	if not is_level_loaded():
		Debug.throw_error(self, "get_current_level", "Level is still loading...")
		return null
	return current_level


func get_current_tile_map() -> TileMapLayer:
	if not is_level_loaded():
		Debug.throw_error(self, "get_spawnable_enemies", "Level is still loading...")
		return null
	return current_tile_map


func set_current_level(node: Node2D) -> void: # bypass level switch
	if not is_level_loaded():
		current_level = node
		_update_level_data()
		add_child(current_level)
		_level_loaded = true
		level_loaded.emit()


@onready var changing_level: bool = false
func change_level(old_level: Node, new_level_path: String) -> void:
	if changing_level:
		return
	changing_level = true
	_level_loaded = false
	current_level = load(new_level_path).instantiate()
	add_child(current_level)
	_update_level_data()
	var new_spawn_position: Vector2 = current_level.find_child("PortalTo" + old_level.name).spawn_point.global_position
	Global.player.global_position = new_spawn_position
	Global.player_camera.global_position = new_spawn_position
	Global.player_camera.reset_smoothing()
	old_level.queue_free()
	_level_loaded = true
	level_loaded.emit()
	changing_level = false
# =========================================================================
# SIGNAL HANDLERS
# =========================================================================
# =========================================================================
# HELPER FUNCTIONS
# =========================================================================
func _update_level_data() -> void:
	if "tiles" in current_level:
		current_tile_map = current_level.tiles
	if "enemies" in current_level:
		spawnable_enemies = current_level.enemies
	if "spawnpoints" in current_level:
		enemy_spawnpoints = current_level.enemy_spawnpoints
	if "checkpoints" in current_level:
		checkpoints = current_level.checkpoints_dict
	Data.game_data.reload_data.last_level = current_level.scene_file_path
