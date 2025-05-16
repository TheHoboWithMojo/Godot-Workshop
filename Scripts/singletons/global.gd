# Stores constant references, global variables, and essential functions
extends Node2D

# Constants
const FLOAT_LIMIT: float = 2147483647.0
const PLAYER_PATH: String = "/root/Game/Player"
const PLAYER_CAMERA_PATH: String = "/root/Game/Player/Camera"
const GAME_MANAGER_PATH: String = "/root/Game"
const QUEST_BOX_PATH: String = "/root/Game/Player/QuestBox"

# Signals
signal game_reloaded # Receives this signal when game_manager's ready runs

# Global Variables
@onready var frames: int = 0
@onready var speed_mult: float = 1.0
@onready var player: CharacterBody2D = get_node(PLAYER_PATH)
@onready var player_camera: Camera2D = get_node(PLAYER_CAMERA_PATH)
@onready var game_manager: Node2D = get_node(GAME_MANAGER_PATH)
@onready var quest_box: Control = get_node(QUEST_BOX_PATH)
@onready var player_touching_node: Variant = null
@onready var mouse_touching_node: Variant = null
@onready var delta: float = 0.0
@onready var can_fast_travel: bool = true


func _ready() -> void:
	game_reloaded.connect(_on_game_reloaded)


func _process(_delta: float) -> void:
	delta = _delta


# =============================================
# PUBLIC FUNCTIONS
# =============================================
func set_fast_travel_enabled(value: bool) -> void:
	can_fast_travel = value


func is_fast_travel_enabled() -> bool:
	return can_fast_travel


func is_touching_player(node: Node) -> bool:
	return node == Global.player_touching_node


func is_touching_mouse(node: Node) -> bool:
	return node == Global.mouse_touching_node


func _on_game_reloaded() -> void: # SIGNAL, Reset assignments if scene is reset
	player = get_node(PLAYER_PATH)
	player_camera = get_node(PLAYER_CAMERA_PATH)
	game_manager = get_node(GAME_MANAGER_PATH)
	quest_box = get_node(QUEST_BOX_PATH)
	print("Global references reloaded!")


func get_beings() -> Array[Node]:
	return get_tree().get_nodes_in_group("beings")


func string_to_enum(string: String, enum_reference: Variant) -> int:
	string = string.to_snake_case().to_upper()
	return enum_reference[string]


func enum_to_snakecase(index: int, enum_reference: Variant) -> String:
	return enum_reference.keys()[index].to_lower()


func enum_to_camelcase(index: int, enum_reference: Variant) -> String:
	var title: String = ""
	var words: PackedStringArray = enum_to_snakecase(index, enum_reference).split("_")
	for word: String in words:
		title += word.capitalize()
	return title.strip_edges()


func enum_to_title(index: int, enum_reference: Variant) -> String:
	var title: String = ""
	var words: PackedStringArray = enum_to_snakecase(index, enum_reference).split("_")
	for word: String in words:
		title += word.capitalize() + " "
	return title.strip_edges()


func swap_scenes(self_node: Node, new_scene: PackedScene) -> void:
	self_node.queue_free()
	get_tree().get_parent().add_child(new_scene.instantiate())


func get_rawname(scene_or_node_or_path: Variant) -> String:
	if scene_or_node_or_path is Node:
		return scene_or_node_or_path.name
	elif scene_or_node_or_path is PackedScene:
		return scene_or_node_or_path.resource_path.get_file().get_basename()
	elif scene_or_node_or_path is String:
		return scene_or_node_or_path.get_file().get_basename()
	elif scene_or_node_or_path is Resource:
		return scene_or_node_or_path.resource_path.get_file().get_basename()
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
			if tile_data and tile_data.has_custom_data(property_name):
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


func get_collider(node: Node2D) -> CollisionShape2D:
	match(node.get_class()):
		"CollisionShape2D":
			return node
		"Sprite2D":
			return node.get_node("Body/Collider")
		"AnimatedSprite2D":
			return node.get_node("Body/Collider")
		"Area2D":
			return node.get_node("Collider")
		"Node2D":
			return node.get_node("Collider")
		"Node":
			return node.get_node("Collider")
		"StaticBody2D":
			return node.get_node("Collider")
	return null
