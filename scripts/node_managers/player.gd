extends CharacterBody2D
# EXPORTS
@export_group("Control")
@export var active: bool = true
@export var collision_on: bool = true

@export_group("Default Stats")
@export var default_speed: float = 10000.0
@export var default_health: float = 100.0
@export var attack_speed: float = 2.0

@export_group("Nodes")
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var projectiles: Array[PackedScene]
@export var health_bar: TextureProgressBar
@export var direction_tracker: Marker2D
@export var nametag: RichTextLabel

func _ready() -> void:
	await Global.active_and_ready(self, active)
	if not collision_on:
		collider.queue_free()
	
	if Global.game_manager.use_save_data:
		load_saved_stats()
		
	health_bar.set_visible(false)

@onready var speed: float = default_speed
@onready var health: float = default_health
@onready var max_health: float = default_health
@onready var speed_mult: float = 1.0
@onready var attack_speed_mult: float = 1.0

func load_saved_stats() -> void:
	# load commonly used stats and one time use stats to reduce calls to Player singleton
	speed = Player.get_stat("speed")
	health = Player.get_stat("health")
	max_health = Player.get_stat("max_health")
	speed_mult = Player.get_stat("speed_mult")
	attack_speed_mult = Player.get_stat("attack_speed_mult")
	health_bar.min_value = 0.0
	health_bar.max_value = max_health
	
# physics variables
@onready var normal: Vector2
@onready var orientation_angle: float
@onready var current_projectile: PackedScene
@onready var direction_x: float
@onready var direction_y: float
@onready var mouse_pos: Vector2
func _physics_process(delta: float) -> void:
	if not dying:
		normal = velocity.normalized()
		
		speed *= speed_mult*Global.speed_mult
		
		direction_x = _get_direction("x")
		
		direction_y = _get_direction("y")

		# Smooth movement
		if direction_x:
			velocity.x = direction_x * speed * delta
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

		if direction_y:
			velocity.y = direction_y * speed * delta
		else:
			velocity.y = move_toward(velocity.y, 0, speed)

		# Animation handling
		mouse_pos = get_global_mouse_position()
		#character_position = position
		orientation_angle = (mouse_pos - position).angle()
		
		_flip_sprite(sprite, orientation_angle)
		#_run_or_idle(velocity)

		move_and_slide()

@onready var dying: bool = false
func _process(_delta: float) -> void:
	if not dying:
		if health <= 0:
			die()
			return  # Exit early to prevent other processing
			
		else:
			shoot(orientation_angle)
			health_bar.set_value(health)
			
			if Global.frames % 120 == 0:
				check_for_achievements()
				
			if projectiles:
				process_scroll()

func process_scroll() -> void:
	var size: int = projectiles.size()
	var current_pos: int = projectiles.find(current_projectile)
	if Input.is_action_just_pressed("cycle_up"):
		if current_pos == size - 1: # if we're at the end, go to the beginning
			current_projectile = projectiles[0]
		else:
			current_projectile = projectiles[(projectiles.find(current_projectile) + 1)]
	if Input.is_action_just_pressed("cycle_down"):
		if current_pos == 0: # if we're at the beginning of the array, move to the last part of the array
			current_projectile = projectiles[size - 1]
		else:
			current_projectile = projectiles[(projectiles.find(current_projectile) - 1)]

@onready var can_shoot: bool = true # Turns off during dialogue
@onready var _just_shot: bool = false
func shoot(angle: float) -> void: # spawns a projectile at a given angle
	if current_projectile != null:
		if can_shoot:
			if Input.is_action_just_pressed("shoot") and not _just_shot:
				_just_shot = true
				var new_projectile: Area2D = current_projectile.instantiate() as Area2D
				get_parent().add_child(new_projectile)  # Add projectile to the scene
				_flip_sprite(new_projectile.sprite, angle)
				new_projectile.position = global_position  # Spawn at player's position
				var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
				new_projectile.velocity = direction*new_projectile.speed # Set projectile velocity
				await Global.delay(self, 1/(attack_speed*attack_speed_mult))
				_just_shot = false

func check_for_achievements() -> void: #UPDATE SO EVERY PERK HAS A REQ LIST IN DICT
	if Player.get_stat("enemies_killed") > 5:
		Player.add_perk("asshole")

func _flip_sprite(_sprite: Variant, _orientation_angle: float) -> void:
	if sprite:
		_sprite.flip_h = (-PI/2 <= _orientation_angle and _orientation_angle <= PI/2)
	
func _get_direction(x_or_y: String) -> float:
	if x_or_y.to_lower() == "x":
		var direction: float = Input.get_axis("move_left", "move_right")
		return direction
	elif x_or_y.to_lower() == "y":
		var direction: float = Input.get_axis("move_up", "move_down")
		return direction
	else:
		Debug.throw_error(self, "_get_direction", "x or y only", x_or_y)
		return 0.0

func die() -> void:
	if not dying:
		dying = true
		set_process(false)  # Stop processing inputs
		set_physics_process(false)  # Stop physics updates (prevents movement)
		speed = 0
		Global.speed_mult = 0.0 # Stop all enemy movement
		health_bar.set_value(0)
		await Global.delay(self, 1.0)
		Data.is_data_loaded = false # DATA IS A SINGLETON SO ITS BOOLS DONT UPDATE ON CALLED RELOAD
		get_tree().reload_current_scene()  # Reload scene after animation
