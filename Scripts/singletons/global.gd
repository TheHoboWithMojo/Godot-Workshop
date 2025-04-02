# Stores constant references, global variables, and essential functions
extends Node2D

# Constants
const FLOAT_LIMIT: float = 2147483647.0
const PLAYER_PATH: String = "/root/Game/Player"
const PLAYER_CAMERA_PATH: String = "/root/Game/Player/PlayerCamera"
const GAME_MANAGER_PATH: String = "/root/Game"

# Signals
signal game_reloaded # Receives this signal when game_manager's ready runs

# Global Variables
@onready var frames: int = 0
@onready var speed_mult: float = 1.0
@onready var player: CharacterBody2D = get_node(PLAYER_PATH)
@onready var player_camera: Camera2D = get_node(PLAYER_CAMERA_PATH)
@onready var player_touching_node: Area2D = null
@onready var cursor_touching_node: Area2D = null
@onready var game_manager: Node2D = get_node(GAME_MANAGER_PATH)

# Stat Constraints
var stat_constraints: Dictionary = {
	"speed": {
		"speed_mult": {"min": 1.0, "max": 5.0},
		"speed_base": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"health": {
		"health": {"min": 0.0, "max": FLOAT_LIMIT},
		"health_regen": {"min": 0.0, "max": FLOAT_LIMIT}
	},
	"crit": {
		"crit_chance": {"min": 0.0, "max": 1.0},
		"crit_mult": {"min": 0.0, "max": FLOAT_LIMIT}
	}
}

# =============================================
# PUBLIC FUNCTIONS
# =============================================
func _ready() -> void:
	game_reloaded.connect(_on_game_reloaded)

func _on_game_reloaded() -> void: # SIGNAL, Reset assignments if scene is reset
	player = get_node(PLAYER_PATH)
	player_camera = get_node(PLAYER_CAMERA_PATH)
	game_manager = get_node(GAME_MANAGER_PATH)
	print("Global references reloaded!")

func swap_scenes(self_node: Node, new_scene: PackedScene) -> void:
	self_node.queue_free()
	get_tree().get_parent().add_child(new_scene.instantiate())
	
func get_interactable_nodes() -> Array[Node]:
	return get_tree().get_nodes_in_group("interactable")
	
func get_rawname(scene_or_node_or_path: Variant) -> String:
	if scene_or_node_or_path is Node:
		return scene_or_node_or_path.name
	elif scene_or_node_or_path is PackedScene:
		return scene_or_node_or_path.resource_path.get_file().get_basename()
	elif scene_or_node_or_path is String:
		return scene_or_node_or_path.get_file().get_basename()
	else:
		Debug.throw_error(self, "get_name", "Input does not have a filepath property", scene_or_node_or_path)
		return ""

func get_tiles_with_property(tilemap: TileMapLayer, property_name: String) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	# Get rectangle with used tiles
	var used_rect: Rect2 = tilemap.get_used_rect()
	
	# Scan through all tiles in the used rect
	for x: int in range(used_rect.position.x, used_rect.end.x):
		for y: int in range(used_rect.position.y, used_rect.end.y):
			var tile_pos: Vector2 = Vector2i(x, y)
			var tile_data: TileData = tilemap.get_cell_tile_data(tile_pos)
			
			# Check if the tile has the specified property
			if tile_data and tile_data.get_custom_data(property_name):
				# Convert tile position to world position
				var world_pos: Vector2 = tilemap.map_to_local(tile_pos)
				world_pos = tilemap.to_global(world_pos)
				positions.append(world_pos)
	
	return positions
	
# ESSENTIAL, UBIQUITOUS FUNCTION, CHECKS IF NODE IS SET TO ACTIVE AND WAITS FOR DATA TO BE LOADED
func active_and_ready(self_node: Node, active: bool = true) -> void:
	if active: # Check is node is active and if the player exists
		if not Global.player:
			await Global.game_reloaded # if theres no player wait for references to update
			
		if not Global.game_manager.is_ready_to_start:
			await Global.game_manager.ready_to_start
	else:
		self_node.queue_free()

func delay(self_node: Node, seconds: float) -> void:
	await self_node.get_tree().create_timer(seconds).timeout

func get_vector_to_player(self_node: Node2D) -> Vector2:
	if player:
		return player.global_position - self_node.global_position
	else:
		Debug.throw_error(self, "get_vector_to_player", "Player path has changed")
		return Vector2.ZERO
		
func get_vector_to_player_camera(self_node: Node2D) -> Vector2:
	if player_camera:
		return player_camera.global_position - self_node.global_position
	else:
		Debug.throw_error(self, "get_vector_to_player_camera", "Player camera path has changed")
		return Vector2.ZERO
				
# =============================================
# PRIVATE HELPER FUNCTIONS
# =============================================

# Parses a buff string, i.e. "stat", "operator", value and directly modifies the game data dict
# Can be generalized to all beings NOT JUST PLAYER

func _is_valid_buff_string(string: String) -> bool:
	var buffs: Array = _split_buff_string(string)
	for buff: Array in buffs:
		if buff.size() != 3:
			Debug.throw_error(self, "_is_valid_buff_string", "Buff does not contain the required word amount (3)", buff)
			return false
		
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: String = buff[2]
		if not _is_valid_stat(stat) or not _is_valid_operator(operator) or not value.is_valid_float():
			Debug.throw_error(self, "_is_valid_buff_string", "Invalid buff format", buff)
			return false
	
	return true

func _is_valid_stat(stat: String) -> bool:
	for stat_category: Dictionary in Data.game_data["stats"].values():
		if stat in stat_category:
			return true
	return false

func _is_valid_operator(_char: String) -> bool:
	return _char in ["*", "-", "+", "/", "="]

func _split_buff_string(buff_string: String) -> Array:
	var buffs: Array = []
	for buff: String in buff_string.split(";", false):
		var split_buff: Array = buff.strip_edges().split(" ", false)
		if split_buff.size() == 3:
			buffs.append(Array(split_buff))
	return buffs

func _parse_buff_string(buff_string: String) -> Array:
	if _is_valid_buff_string(buff_string):
		var buffs: Array = _split_buff_string(buff_string)
		for buff: Array in buffs:
			buff[2] = buff[2].to_float()
		return buffs
	return []

func _print_stat_change(stat: String, original_stat_value: float, new_stat_value: float) -> void:
	var change: float = new_stat_value - original_stat_value
	print("Stat changed: %s from %.2f to %.2f (change: %s%.2f)" % [
		stat, original_stat_value, new_stat_value, "+" if change >= 0 else "", change
	])

func _get_stat_category(stat: String) -> String:
	if Global.game_manager.active:
		for stat_category: String in Data.game_data["stats"].keys():
			if stat in Data.game_data["stats"][stat_category]:
				return stat_category
		return ""
	return ""

func _get_stat_constraints(stat_category: String, stat: String) -> Dictionary:
	var category_constraints: Dictionary = stat_constraints.get(stat_category, {})
	return category_constraints.get(stat, { "min": 0.0, "max": FLOAT_LIMIT })

func _get_updated_stat(stat_category: String, stat: String, operator: String, value: float) -> float:
	if player:
		var current_value: float = Data.game_data["stats"][stat_category][stat]
		match operator:
			"*": current_value *= value
			"-": current_value -= value
			"+": current_value += value
			"=": current_value = value
			"/": 
				if value != 0:
					current_value /= value
				else:
					Debug.throw_error(self, "_get_updated_stat", "Cannot divide by 0")
		var constraints: Dictionary = _get_stat_constraints(stat_category, stat)
		var constrained_value: float = clamp(current_value, constraints["min"], constraints["max"])
		Data.game_data["stats"][stat_category][stat] = constrained_value
		
		return constrained_value
	return 0.0

func _is_toggle_buff_active(buff_dict: Dictionary) -> bool:
	return buff_dict.get("has") == "true"

func _update_toggle_buff(buff_name: String, buff_data: Dictionary) -> bool:
	if not buff_data.has(buff_name):
		return false
		
	var buff: Dictionary = buff_data[buff_name]
	
	if _is_toggle_buff_active(buff):
		return false
	
	buff["has"] = "true"
	Player.player_change_stat(buff.get("buffs", ""))
	return true
