@icon("res://assets/Icons/16x16/entity_move.png")
extends Node
class_name LevelManager
#var game_data: Dictionary = {} # stores ALL GAME DATA
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@export var debugging: bool = false
@onready var current_level: Level
@onready var enemy_spawnpoints: Array[Vector2]
@onready var checkpoints: Dictionary[String, Vector2]
@onready var current_tile_map: TileMapLayer
@onready var spawnable_enemies: Array[PackedScene]
@onready var _level_loading: bool = false
# =========================================================================
# SIGNALS
# =========================================================================
signal new_level_loaded(level: Level)
signal about_to_change_level(level: Levels.LEVELS)
# =========================================================================
# PUBLIC FUNCTIONS
# =========================================================================

func is_level_loading() -> bool:
	return _level_loading


func get_spawnable_enemies() -> Array[PackedScene]:
	await get_current_level_node()
	return spawnable_enemies


func get_enemy_spawnpoints() -> Array[Vector2]:
	await get_current_level_node()
	return enemy_spawnpoints


func get_current_level_node() -> Node:
	if is_level_loading() or not current_level:
		await new_level_loaded
	return current_level


func get_current_level_enum() -> Levels.LEVELS:
	if is_level_loading():
		await new_level_loaded
	return current_level.get_level_enum()


func get_current_tile_map() -> TileMapLayer:
	await get_current_level_node()
	return current_tile_map


func set_current_level(level: Levels.LEVELS) -> void: # bypass level switch
	if not is_level_loading():
		about_to_change_level.emit(level)
		_level_loading = true
		current_level = load(Levels.get_level_path(level)).instantiate()
		_update_level_data()
		add_child(current_level)
		if not current_level.is_node_ready(): # wait for the level and all is children to be fully initialized
			await get_tree().process_frame
		_level_loading = false
		new_level_loaded.emit(current_level)
		Debug.debug("New Level %s loaded" % [current_level.name], self, "set_current_level")


func change_level(old_level: Level, new_level_path: String) -> void:
	if _level_loading:
		return
	Global.enter_menu()
	_level_loading = true
	var old_level_enum: Levels.LEVELS = old_level.get_level_enum()
	var new_level: Level = load(new_level_path).instantiate()
	about_to_change_level.emit(new_level.get_level_enum())
	current_level = new_level
	add_child.call_deferred(current_level)
	_update_level_data()
	var spawn_position: Vector2 = current_level.get_portal_to_level(old_level_enum).get_spawn_point_position()
	Global.player.global_position = spawn_position
	Global.player_camera.global_position = spawn_position
	Global.player_camera.reset_smoothing()
	old_level.queue_free()
	if not current_level.is_node_ready(): # wait for the level and all is children to be fully initialized
		await get_tree().process_frame
	current_level.set_visible(true)
	_level_loading = false
	new_level_loaded.emit(current_level)
	Global.exit_menu()
	Debug.debug("New Level %s loaded" % [current_level.name], self, "_change_level")
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
