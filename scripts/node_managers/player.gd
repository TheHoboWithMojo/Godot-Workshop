extends CharacterBody2D
@export var active: bool = true
@export var collision_on: bool = true

@export var base_speed: float = 10000.0
@export var base_health: float = 100.0
@export var base_attack_speed: float = 20.0

@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var projectile: PackedScene
@export var health_bar: TextureProgressBar
@export var direction_tracker: Marker2D
@onready var can_shoot: bool = true

signal player_damaged

func _ready():
	await Global.active_and_ready(self, active)
	
	if not collision_on:
		collider.queue_free()

	# Initialize Game Data with these stats (use if save_data in game manager is false)
	if Global.game_manager.use_save_data == false:
		Global.player_change_stat("health = %s" % [base_health])
		Global.player_change_stat("speed = %s" % [base_speed])
		Global.player_change_stat("attack_speed = %s" % [base_attack_speed])
	
	health_bar.min_value = 0.0
	health_bar.max_value = base_health
		
	player_damaged.connect(_on_damage)

@onready var speed: float
@onready var direction_x: float
@onready var direction_y: float
@onready var mouse_pos
@onready var character_position
@onready var normal: Vector2
@onready var orientation_angle: float

func _physics_process(delta: float) -> void:
	normal = velocity.normalized()
	
	speed = _get_current_speed()
	
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
	character_position = position
	orientation_angle = (mouse_pos - character_position).angle()
	
	_flip_sprite(sprite, orientation_angle)
	_run_or_idle(velocity)

	move_and_slide()

func _process(_delta: float) -> void:
	var health: float = Global.player_get_stat("health")
	_shoot(orientation_angle)
	
	# State Checks
	if Global.frames % 10 == 0:
		_check_for_death(health)
	
	health_bar.set_value(health)
	
	if Global.frames % 120 == 0:
		check_for_achievements()

@onready var _just_shot: bool = false
func _shoot(angle): # spawns a projectile at a given angle
	if can_shoot:
		if Input.is_action_just_pressed("shoot") and not _just_shot:
			_just_shot = true
			var new_projectile = projectile.instantiate() as Area2D
			get_parent().add_child(new_projectile)  # Add projectile to the scene
			_flip_sprite(new_projectile.sprite, angle)
			new_projectile.position = global_position  # Spawn at player's position
			var direction = (get_global_mouse_position() - global_position).normalized()
			new_projectile.set_velocity(direction)  # Set projectile velocity
			await Global.delay(self, 1/(Global.player_get_stat("attack_speed")*Global.player_get_stat("attack_speed_mult")))
			_just_shot = false

func check_for_achievements(): #UPDATE SO EVERY PERK HAS A REQ LIST IN DICT
	if Global.player_get_stat("enemies_killed") > 5:
		Global.player_add_perk("dead eye")

func _flip_sprite(_sprite: AnimatedSprite2D, _orientation_angle: float):
	_sprite.flip_h = not (-PI/2 <= _orientation_angle and _orientation_angle <= PI/2)
	
func _run_or_idle(_velocity: Vector2):
	if _velocity.length() > 0:
		sprite.play("run")
	else:
		sprite.play("idle")

func _get_current_speed() -> float:
	speed = Global.player_get_stat("speed")
	
	speed = speed * Global.speed_mult * Global.player_get_stat("speed_mult")
	
	return speed
	
func _get_direction(x_or_y: String) -> float:
	if x_or_y.to_lower() == "x":
		var direction := Input.get_axis("move_left", "move_right")
		return direction
	elif x_or_y.to_lower() == "y":
		var direction := Input.get_axis("move_up", "move_down")
		return direction
	else:
		Debug.throw_error(self, "_get_direction", "x or y only", x_or_y)
		return 0.0

func _check_for_death(health: float):
	if health <= 0:
		_die()

@onready var _process_death: bool = true
func _die():
	if _process_death:
		_process_death = false
		set_process(false)  # Stop processing inputs
		set_physics_process(false)  # Stop physics updates (prevents movement)
		velocity = Vector2.ZERO  # Prevent movement from overriding animation
		sprite.play("die")  # Play death animation
		print("you died!")
		await sprite.animation_finished
		Data.is_data_loaded = false # DATA IS A SINGLETON SO ITS BOOLS DONT UPDATE ON CALLED RELOAD
		get_tree().reload_current_scene()  # Reload scene after animation

# Signals
@onready var _damagable: bool = true
func _on_damage(damage: int):
	if _damagable:
		_damagable = false
		Global.damage_player(damage)
		await Global.delay(self, 1.0) # IFRAMES
		_damagable = true
