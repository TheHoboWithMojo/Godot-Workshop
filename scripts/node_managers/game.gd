# =========================================================================
# GAME MANAGER
# Handles essential game operations (loading, saving, essential signals, tracking frames)
# =========================================================================
extends Node2D
# =========================================================================
# CONFIGURATION
# =========================================================================
@export_group("Config")
@export var active: bool = true
@export var track_frames: bool = true
@export var use_save_data: bool = true
@export var autosaving: bool = true
# =========================================================================
# CONSTANTS
# =========================================================================
@export_group("Spawning")
@export var spawn_enemies: bool = true
@onready var _spawn_enemies: bool = spawn_enemies
@export_range(1, 10) var enemies_per_spawn: int = 2
@export var MOB_CAP: int = 10
@export var SECONDS_PER_SPAWN: float = 10.0
@export var SPAWN_RADIUS: float = 1000
@export var ENTITY_LOADING_RADIUS: float = 500
# =========================================================================
# RUNTIME VARIABLES
# =========================================================================
@onready var is_ready_to_start: bool = false # Updated by ready_to_start signal
@onready var total_mobs: int
@onready var current_level: Node
@onready var enemy_spawnpoints: Array[Vector2]
@onready var checkpoints: Dictionary[String, Vector2]
@onready var current_tile_map: TileMapLayer
@onready var spawnable_enemies: Array[PackedScene]
@onready var is_level_loaded: bool

# =========================================================================
# SIGNALS
# =========================================================================
signal ready_to_start # Nodes read this to know when to begin processing
signal mob_died # Handles mob death
signal level_changed # Procks when new level is entered
signal level_loaded
# =========================================================================
# CORE LIFECYCLE METHODS
# =========================================================================
func _ready() -> void:
	if active:
		update_global_references()
		boot_dialogic()
		connect_signals()
		load_data()
		add_child(current_level)
		update_level_data()
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
	
	if use_save_data and autosaving:
		autosave()
# =========================================================================
# READY FUNCTIONS
# =========================================================================
func update_global_references() -> void:
	Global.game_reloaded.emit()
	
func load_data() -> void:
	if not use_save_data:
		Data.clear_data()
		if Data.is_data_cleared != true:
			await Data.data_cleared
	Data.load_game_data() # Load _current data into the game
	if not Data.is_data_loaded:
		await Data.data_loaded
	
func boot_dialogic() -> void:
	Dialogic.start("res://dialogic/timelines/boot.dtl") # Start a blank timeline to load dialogic assets
	preload("res://dialogic/styles/tryme.tres") # Load generic dialogic style
	
func connect_signals() -> void:
	mob_died.connect(_on_mob_death)
	level_changed.connect(_on_level_changed)
	print("Game Manager Signals Connected!")
	
func ready_up() -> void:
	# Wait for ALL SIGNALS BEFORE STARTING
	if not is_level_loaded:
		await level_loaded
	is_ready_to_start = true
	ready_to_start.emit()
# =========================================================================
# PROCESS FUNCTIONS
# =========================================================================
func count_frames() -> void:
	Global.frames += 1
	if Global.frames >= 100:
		Global.frames = 0

func disable_unseen_enemies() -> void:
	var enemies: Array = get_current_enemies()
	var camera: Camera2D = Global.player_camera
	
	# Get the viewport rectangle in global coordinates
	var camera_view: Rect2 = Rect2(camera.get_screen_center_position() - 0.5 * camera.get_viewport_rect().size, camera.get_viewport_rect().size)
	
	# expand the rect to account for different sprite sizes
	var margin: int = 100
	camera_view = camera_view.grow(margin)
	
	for enemy: Node2D in enemies:
		# Check if enemy is in camera view
		var _is_visible: bool = camera_view.has_point(enemy.global_position)
		
		# Enable/disable based on visibility
		enemy.set_process(_is_visible)
		enemy.set_physics_process(_is_visible)
		enemy.visible = _is_visible

func spawn(enemy_scene_array: Array[PackedScene]) -> void:
	if spawn_enemies:
		if spawnable_enemies.size() != 0:
			if not _spawn_enemies or total_mobs >= MOB_CAP:
				return  # Early exit if spawning is disabled or the cap is already reached
			
			_spawn_enemies = false  # Lock spawning immediately
			
			# Calculate how many enemies we can spawn without exceeding the cap
			var available_slots: int = MOB_CAP - total_mobs
			var spawn_count: int = min(enemies_per_spawn, available_slots)
			
			# Early return if no room for new mobs
			if spawn_count <= 0:
				await Global.delay(self, SECONDS_PER_SPAWN)
				_spawn_enemies = true
				return
			
			# Check if we have spawnable positions
			if enemy_spawnpoints.is_empty():
				await Global.delay(self, SECONDS_PER_SPAWN)
				_spawn_enemies = true
				return
			
			# Find valid spawn positions within the radius
			var valid_positions: Array[Vector2] = []
			var player_pos: Vector2 = Global.player.global_position
			
			# Filter positions within the spawn radius
			for pos: Vector2 in enemy_spawnpoints:
				if pos.distance_to(player_pos) <= SPAWN_RADIUS:
					valid_positions.append(pos)
			
			# If no valid positions found, wait and try again later
			if valid_positions.is_empty():
				#print("No valid spawn positions within radius!")
				await Global.delay(self, SECONDS_PER_SPAWN)
				_spawn_enemies = true
				return
			
			# Spawn the calculated number of enemies
			for i: int in range(spawn_count):
				var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
				var spawn_position: Vector2 = valid_positions[randi() % valid_positions.size()] # Rand pos
				var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
				query.position = spawn_position
				
				if not space_state.intersect_point(query, 1): # Only spawn if there will it will not overlap another body
					var random: int = randi_range(0, enemy_scene_array.size() - 1)
					var _enemy: Node = enemy_scene_array[random].instantiate() as CharacterBody2D # Rand enemy
					_enemy.global_position = spawn_position
					Global.game_manager.add_child(_enemy)
					total_mobs += 1
			
			await Global.delay(self, SECONDS_PER_SPAWN)
			_spawn_enemies = true

var _currently_autosaving: bool = false
func autosave() -> void:
	if autosaving:
		if not _currently_autosaving:
			_currently_autosaving = true
			await Global.delay(self, 10)
			Global.speed_mult = 0.0
			Data.save_data_changes()
			Global.speed_mult = 1.0
# =========================================================================
# ENEMY MANAGEMENT
# =========================================================================
func get_current_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemies")
	
func clear_enemies() -> void:
	if total_mobs > 0:
		for enemy: Node2D in get_current_enemies():
			enemy.queue_free()

func _on_mob_death() -> void:
	if total_mobs > 0:
		total_mobs -= 1
# =========================================================================
# SIGNAL HANDLERS
# =========================================================================
func _on_level_changed(old_level: Node, new_level_path: String) -> void:
	_spawn_enemies = false
	clear_enemies()
	current_level = load(new_level_path).instantiate()
	add_child(current_level)
	update_level_data()
	
	var old_level_number: String = Global.get_rawname(old_level)[Global.get_rawname(old_level).length()-1] # get the old level number
	var new_spawn_position: Vector2 = current_level.find_child("PortalToLevel%s" % [old_level_number]).find_child("SpawnPoint").global_position
	Global.player.global_position = new_spawn_position
	Global.player_camera.global_position = new_spawn_position
	Global.player_camera.reset_smoothing()
	
	old_level.queue_free()
	
	if spawn_enemies:
		_spawn_enemies = true
# =========================================================================
# HELPER FUNCTIONS
# =========================================================================
func update_level_data() -> void:
	current_tile_map = current_level.tiles
	spawnable_enemies = current_level.enemies
	enemy_spawnpoints = current_level.enemy_spawnpoints
	checkpoints = current_level.checkpoints_dict
	Data.game_data.reload_data.last_level = current_level.scene_file_path
	is_level_loaded = true
	level_loaded.emit()
