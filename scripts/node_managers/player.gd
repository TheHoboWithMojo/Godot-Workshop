extends CharacterBody2D
@export_group("Control")
@export var active: bool = true
@export var collision_on: bool = true

@export_group("Base Stats")
@export var base_speed: float = 10000.0
@export var base_health: float = 100.0
@export var base_attack_speed: float = 20.0

@export_group("Nodes")
@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var projectile: PackedScene
@export var health_bar: TextureProgressBar
@export var direction_tracker: Marker2D

func _ready() -> void:
	await Global.active_and_ready(self, active)
	
	if not collision_on:
		collider.queue_free()

	# Initialize Game Data with these stats (use if save_data in game manager is false)
	if Global.game_manager.use_save_data == false:
		Player.change_stat("health = %s" % [base_health])
		Player.change_stat("speed = %s" % [base_speed])
		Player.change_stat("attack_speed = %s" % [base_attack_speed])
	
	health_bar.min_value = 0.0
	health_bar.max_value = base_health

@onready var speed: float
@onready var direction_x: float
@onready var direction_y: float
@onready var mouse_pos: Vector2
@onready var character_position: Vector2
@onready var normal: Vector2
@onready var orientation_angle: float

func _physics_process(delta: float) -> void:
	normal = velocity.normalized()
	
	speed = Player.get_speed()
	
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
	var health: float = Player.get_health()
	shoot(orientation_angle)
	
	# State Checks
	if Global.frames % 10 == 0:
		_check_for_death(health)
	
	health_bar.set_value(health)
	
	if Global.frames % 120 == 0:
		check_for_achievements()


@onready var can_shoot: bool = true # Turns off during dialogue
@onready var _just_shot: bool = false
func shoot(angle: float) -> void: # spawns a projectile at a given angle
	if projectile != null:
		if can_shoot:
			if Input.is_action_just_pressed("shoot") and not _just_shot:
				_just_shot = true
				var new_projectile: Area2D = projectile.instantiate() as Area2D
				get_parent().add_child(new_projectile)  # Add projectile to the scene
				_flip_sprite(new_projectile.sprite, angle)
				new_projectile.position = global_position  # Spawn at player's position
				var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
				new_projectile.set_velocity(direction)  # Set projectile velocity
				await Global.delay(self, 1/(Player.get_stat("attack_speed")*Player.get_stat("attack_speed_mult")))
				_just_shot = false

func check_for_achievements() -> void: #UPDATE SO EVERY PERK HAS A REQ LIST IN DICT
	if Player.get_stat("enemies_killed") > 5:
		Player.add_perk("dead eye")

func _flip_sprite(_sprite: AnimatedSprite2D, _orientation_angle: float) -> void:
	_sprite.flip_h = not (-PI/2 <= _orientation_angle and _orientation_angle <= PI/2)
	
func _run_or_idle(_velocity: Vector2) -> void:
	if _velocity.length() > 0:
		sprite.play("run")
	else:
		sprite.play("idle")
	
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

func _check_for_death(health: float) -> void:
	if health <= 0:
		die()

@onready var _process_death: bool = true
func die() -> void:
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
