# =========================================================================
# GAME MANAGER
# Handles essential game operations (loading, saving, essential signals, tracking frames)
# =========================================================================
extends Node2D

# =========================================================================
# CONFIGURATION
# =========================================================================
@export var track_frames: bool = true
@export var use_save_data: bool = false
@export var active: bool = true
@export var spawn_enemies: bool = true

# =========================================================================
# CONSTANTS
# =========================================================================
@export var MOB_CAP: int = 10
@export var SECONDS_PER_SPAWN: float = 2.0
@export var SPAWN_RADIUS: float = 1000
@export var ENTITY_LOADING_RADIUS: float = 500

# =========================================================================
# SCENES AND NODES
# =========================================================================
@export var Rogue: PackedScene
@export var Knight: PackedScene
@export var default_level: PackedScene

# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var start_ready: bool = false # Updated by ready_to_start signal
@onready var total_mobs: int
@onready var current_level: Node
@onready var enemy_spawnpoints: Array[Vector2]
@onready var checkpoints: Dictionary[String, Vector2]
@onready var current_tile_map: TileMapLayer
@onready var spawnable_enemies: Array[PackedScene]

# =========================================================================
# SIGNALS
# =========================================================================
signal ready_to_start # Nodes read this to know when to begin processing
signal mob_died # Handles mob death
signal level_changed # Procks when new area is entered

# =========================================================================
# CORE LIFECYCLE METHODS
# =========================================================================
func _ready() -> void:
	if active:
		update_global_references()
		load_data()
		boot_dialogic()
		connect_signals()
		if current_level == null:
			current_level = default_level.instantiate()
			add_child(current_level)
			_update_level_data()
		ready_up()
	else:
		queue_free()
	
func _process(_delta: float) -> void:
	if track_frames:
		count_frames()
	
	if total_mobs:
		disable_unseen_enemies() # Stops processing enemies outside of view
	
	if spawn_enemies and total_mobs < MOB_CAP:
		spawn(spawnable_enemies)

# =========================================================================
# READY FUNCTIONS
# =========================================================================
func update_global_references():
	Global.game_reloaded.emit()
	
func load_data():
	if not use_save_data:
		Data.clear_data()
		if Data.is_data_cleared != true:
			await Data.data_cleared
	
	Data.load_game_data() # Load _current data into the game
	if Data.is_data_loaded != true:
		await Data.data_loaded
	
func boot_dialogic():
	Dialogic.start("res://dialogic/timelines/boot.dtl") # Start a blank timeline to load dialogic assets
	preload("res://dialogic/styles/default.tres") # Load generic dialogic style
	
func connect_signals():
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)
	mob_died.connect(_on_mob_death)
	level_changed.connect(_on_level_changed)
	print("Game Manager Signals Connected!")
	
func ready_up():
	start_ready = true
	ready_to_start.emit()
# =========================================================================
# PROCESS FUNCTIONS
# =========================================================================
func count_frames():
	Global.frames += 1
	if Global.frames >= 100:
		Global.frames = 0

func disable_unseen_enemies():
	var enemies: Array = get_current_enemies()
	var camera = Global.player_camera
	
	# Get the viewport rectangle in global coordinates
	var camera_view = Rect2(camera.get_screen_center_position() - 0.5 * camera.get_viewport_rect().size, camera.get_viewport_rect().size)
	
	# expand the rect to account for different sprite sizes
	var margin = 100
	camera_view = camera_view.grow(margin)
	
	for enemy in enemies:
		# Check if enemy is in camera view
		var _is_visible = camera_view.has_point(enemy.global_position)
		
		# Enable/disable based on visibility
		enemy.set_process(_is_visible)
		enemy.set_physics_process(_is_visible)
		enemy.visible = _is_visible

func spawn(enemy_scene_array: Array[PackedScene]) -> void:
	spawn_enemies = false
	
	# Check if we have spawnable positions
	if enemy_spawnpoints.size() == 0:
		await Global.delay(self, SECONDS_PER_SPAWN)
		spawn_enemies = true
		return
	
	# Find valid spawn positions within the radius
	var valid_positions = []
	var player_pos = Global.player.global_position
	
	# Filter positions within the spawn radius
	for pos in enemy_spawnpoints:
		var distance = pos.distance_to(player_pos)
		if distance <= SPAWN_RADIUS:
			valid_positions.append(pos)
	
	# If no valid positions found, wait and try again later
	if valid_positions.size() == 0:
		print("No valid spawn positions within radius!")
		await Global.delay(self, SECONDS_PER_SPAWN)
		spawn_enemies = true
		return
	
	# Choose a random valid position
	var spawn_position = valid_positions[randi() % valid_positions.size()]
	
	# Spawn enemies at the chosen position
	for enemy in enemy_scene_array:
		var _enemy: Node = enemy.instantiate() as CharacterBody2D
		_enemy.global_position = spawn_position
		Global.game_manager.add_child(_enemy)
		total_mobs += 1
	
	await Global.delay(self, SECONDS_PER_SPAWN)
	spawn_enemies = true

# =========================================================================
# ENEMY MANAGEMENT
# =========================================================================
func get_current_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")
	
func clear_enemies():
	if total_mobs > 0:
		for enemy in get_current_enemies():
			enemy.queue_free()

func _on_mob_death():
	if total_mobs > 0:
		total_mobs -= 1
	Global.player_change_stat("enemies_killed + 1")
# =========================================================================
# SIGNAL HANDLERS
# =========================================================================
func _on_dialogue_start() -> void:
	Global.speed_mult = 0.0

func _on_dialogue_end() -> void:
	Global.speed_mult = 1.0
	
func _on_level_changed(old_level: Node, new_level: PackedScene):
	spawn_enemies = false
	clear_enemies()
	current_level = new_level.instantiate()
	add_child(current_level)
	_update_level_data()
	old_level.queue_free()
	spawn_enemies = true
# =========================================================================
# HELPER FUNCTIONS
# =========================================================================
func _update_level_data():
	current_tile_map = current_level.tiles
	spawnable_enemies = current_level.enemies
	enemy_spawnpoints = current_level.enemy_spawnpoints
	checkpoints = current_level.checkpoints_dict
