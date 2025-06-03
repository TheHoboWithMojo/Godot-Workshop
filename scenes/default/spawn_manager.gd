@icon("res://assets/Icons/16x16/skull_delete.png")
extends Node
class_name MobManager
# =========================================================================
# CONFIGURATION
# =========================================================================
@export_group("Spawning")
@export var spawn_enemies: bool = true
#@onready var _spawn_enemies: bool = spawn_enemies
@export_range(1, 10) var enemies_per_spawn: int = 2
@export var MOB_CAP: int = 10
@export var SECONDS_PER_SPAWN: float = 10.0
@export var SPAWN_RADIUS: float = 1000
@export var ENTITY_LOADING_RADIUS: float = 100
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var total_mobs: int = 0
@onready var level_manager: Node = $"../LevelManager"
@onready var enemy_spawnpoints: Array[Vector2]
@onready var spawnable_enemies: Array[PackedScene]
# =========================================================================
# SIGNALS
# =========================================================================
signal mob_died
# =========================================================================
# CORE LIFECYCLE METHODS
# =========================================================================
func _ready() -> void:
	mob_died.connect(_on_mob_death)
	await Global.active_and_ready(self)
	level_manager.new_level_loaded.connect(_on_new_level_loaded)


func _process(_delta: float) -> void:
	if spawn_enemies and total_mobs < MOB_CAP:
		pass
		#spawn()
	if total_mobs:
		disable_unseen_enemies() # Stops processing enemies outside of view


func _on_new_level_loaded() -> void:
	spawnable_enemies = level_manager.get_spawnable_enemies()
	enemy_spawnpoints = level_manager.get_enemy_spawnpoints()


func set_spawn_enemies(value: bool) -> void:
	spawn_enemies = value
# =========================================================================
# SPAWNING FUNCTION
# =========================================================================
#func spawn() -> void:
	#if spawn_enemies:
		#if spawnable_enemies.size() != 0:
			#if not _spawn_enemies or total_mobs >= MOB_CAP:
				#return  # Early exit if spawning is disabled or the cap is already reached
			#_spawn_enemies = false  # Lock spawning immediately
			## Calculate how many enemies we can spawn without exceeding the cap
			#var available_slots: int = MOB_CAP - total_mobs
			#var spawn_count: int = min(enemies_per_spawn, available_slots)
			## Early return if no room for new mobs
			#if spawn_count <= 0:
				#await Global.delay(self, SECONDS_PER_SPAWN)
				#_spawn_enemies = true
				#return
			## Check if we have spawnable positions
			#if enemy_spawnpoints.is_empty():
				#await Global.delay(self, SECONDS_PER_SPAWN)
				#_spawn_enemies = true
				#return
			## Find valid spawn positions within the radius
			#var valid_positions: Array[Vector2] = []
			#var player_pos: Vector2 = Global.player.global_position
			## Filter positions within the spawn radius
			#for pos: Vector2 in enemy_spawnpoints:
				#if pos.distance_to(player_pos) <= SPAWN_RADIUS:
					#valid_positions.append(pos)
			## If no valid positions found, wait and try again later
			#if valid_positions.is_empty():
				##print("No valid spawn positions within radius!")
				#await Global.delay(self, SECONDS_PER_SPAWN)
				#_spawn_enemies = true
				#return
			## Spawn the calculated number of enemies
			#for i: int in range(spawn_count):
				#var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
				#var spawn_position: Vector2 = valid_positions[randi() % valid_positions.size()] # Rand pos
				#var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
				#query.position = spawn_position
				#if not space_state.intersect_point(query, 1): # Only spawn if there will it will not overlap another body
					#var random: int = randi_range(0, spawnable_enemies.size() - 1)
					#var _enemy: Node = spawnable_enemies[random].instantiate() as CharacterBody2D # Rand enemy
					#_enemy.global_position = spawn_position
					#Global.game_manager.add_child(_enemy)
					#total_mobs += 1
			#await Global.delay(self, SECONDS_PER_SPAWN)
			#_spawn_enemies = true

# =========================================================================
# ENEMY MANAGEMENT
# =========================================================================
func disable_unseen_enemies() -> void:
	var enemies: Array = get_current_enemies()
	var camera: Camera2D = Global.player_camera
	# Get the viewport rectangle in global coordinates
	var camera_view: Rect2 = Rect2(camera.get_screen_center_position() - 0.5 * camera.get_viewport_rect().size, camera.get_viewport_rect().size)
	# expand the rect to account for different sprite sizes
	var margin: float = ENTITY_LOADING_RADIUS
	camera_view = camera_view.grow(margin)
	for enemy: Node2D in enemies:
		# Check if enemy is in camera view
		var _is_visible: bool = camera_view.has_point(enemy.global_position)
		# Enable/disable based on visibility
		enemy.set_process(_is_visible)
		enemy.set_physics_process(_is_visible)
		enemy.visible = _is_visible

func get_current_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")

func clear_enemies() -> void:
	if total_mobs > 0:
		for enemy: Node2D in get_current_enemies():
			enemy.queue_free()

func _on_mob_death() -> void:
	if total_mobs > 0:
		total_mobs -= 1
