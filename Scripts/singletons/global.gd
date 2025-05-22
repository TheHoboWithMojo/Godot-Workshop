# Stores constant references, global variables, and essential functions
extends Node2D

# Constants
const FLOAT_LIMIT: float = 2147483647.0
const PLAYER_PATH: String = "/root/GameManager/Player"
const PLAYER_CAMERA_PATH: String = "/root/GameManager/Player/Camera"
const PLAYER_BUBBLE_PATH: String = "/root/GameManager/Player/Bubble"
const GAME_MANAGER_PATH: String = "/root/GameManager"
const QUEST_DISPLAYER_PATH: String = "/root/GameManager/UI/QuestDisplayer"
const QUEST_MANAGER_PATH: String = "/root/GameManager/QuestManager"
const WAYPOINT_MANAGER_PATH: String = "/root/GameManager/WaypointManager"
const LEVEL_MANAGER_PATH: String = "/root/GameManager/LevelManager"
const MOB_MANAGER_PATH: String = "/root/GameManager/MobManager"

# Signals
signal game_reloaded # Receives this signal when game_manager's ready runs

# Global Variables
@onready var frames: int = 0
@onready var speed_mult: float = 1.0
@onready var player: CharacterBody2D = get_node(PLAYER_PATH)
@onready var player_camera: Camera2D = get_node(PLAYER_CAMERA_PATH)
@onready var player_bubble: Area2D = get_node(PLAYER_BUBBLE_PATH)
@onready var game_manager: Node2D = get_node(GAME_MANAGER_PATH)
@onready var quest_displayer: Control = get_node(QUEST_DISPLAYER_PATH)
@onready var waypoint_manager: Node = get_node(WAYPOINT_MANAGER_PATH)
@onready var level_manager: Node = get_node(LEVEL_MANAGER_PATH)
@onready var quest_manager: Node = get_node(QUEST_MANAGER_PATH)
@onready var mob_manager: Node = get_node(MOB_MANAGER_PATH)
@onready var player_touching_node: Variant = null
@onready var mouse_touching_node: Variant = null
@onready var delta: float = 0.0
@onready var can_fast_travel: bool = true
@onready var in_menu: bool = false


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


func enter_menu() -> void:
	#print("menu entered")
	set_paused(true)
	in_menu = true


func exit_menu() -> void:
	#print("menu exited")
	set_paused(false)
	in_menu = false


@onready var total_mobs: int
func set_paused(value: bool) -> void:
	if player and game_manager:
		set_fast_travel_enabled(!value)
		player.set_physics_process(!value)
		player.can_shoot = !value

		for being: Node2D in get_beings():
			being.master.set_vincible(!value)
			being.master.set_paused(value)
	if not value:
		speed_mult = 1.0
		mob_manager.total_mobs = total_mobs # Restores actual mob count
		return
	speed_mult = 0.0
	total_mobs = game_manager.total_mobs # Store actual mob count
	mob_manager.total_mobs = mob_manager.MOB_CAP # Sets mob count to max to stop spawning


func is_in_menu() -> bool:
	return in_menu


func is_touching_player(node: Node) -> bool:
	return node == player_touching_node


func is_touching_mouse(node: Node) -> bool:
	return node == mouse_touching_node


func get_beings() -> Array[Node]:
	return get_tree().get_nodes_in_group("beings")


func string_to_enum_value(string: String, enum_reference: Variant) -> int:
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
	match typeof(scene_or_node_or_path):
		TYPE_OBJECT:
			if scene_or_node_or_path is Node:
				return scene_or_node_or_path.name
			elif scene_or_node_or_path is PackedScene or scene_or_node_or_path is Resource:
				return scene_or_node_or_path.resource_path.get_file().get_basename()
		TYPE_STRING:
			return scene_or_node_or_path.get_file().get_basename()

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
	if not active: # Check is node is active and if the player exists
		self_node.queue_free()
		return

	if not player:
		await game_reloaded # if theres no player wait for references to update

	if not game_manager.is_ready_to_start:
		await game_manager.ready_to_start


func string_to_vector2(input: String) -> Vector2:
	var trimmed: String = input.strip_edges(true, true).trim_prefix("(").trim_suffix(")")
	var parts: PackedStringArray = trimmed.split(",")
	if parts.size() == 2:
		var x: float = parts[0].to_float()
		var y: float = parts[1].to_float()
		return Vector2(x, y)
	return Vector2.ZERO  # fallback if string is malformed


func delay(self_node: Node, seconds: float) -> void:
	await self_node.get_tree().create_timer(seconds).timeout


func get_vector_to_player(self_node: Node2D) -> Vector2:
	if not player:
		Debug.throw_error(self, "get_vector_to_player", "Player path has changed")
		return Vector2.ZERO
	return player.global_position - self_node.global_position


func get_vector_to_player_camera(self_node: Node2D) -> Vector2:
	if not player_camera:
		Debug.throw_error(self, "get_vector_to_player_camera", "Player camera path has changed")
		return Vector2.ZERO
	return player_camera.global_position - self_node.global_position


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

# SIGNALS
func _on_game_reloaded() -> void: # SIGNAL, Reset assignments if scene is reset
	player = get_node(PLAYER_PATH)
	player_camera = get_node(PLAYER_CAMERA_PATH)
	game_manager = get_node(GAME_MANAGER_PATH)
	quest_displayer = get_node(QUEST_DISPLAYER_PATH)
	waypoint_manager = get_node(WAYPOINT_MANAGER_PATH)
	level_manager = get_node(LEVEL_MANAGER_PATH)
	quest_manager = get_node(QUEST_MANAGER_PATH)
	mob_manager = get_node(MOB_MANAGER_PATH)
	print("Global references reloaded!")
