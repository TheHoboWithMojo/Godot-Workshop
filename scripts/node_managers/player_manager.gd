extends CharacterBody2D
@export var collision_on: bool = true
@export var active: bool = true

@export var camera_distance_limit: float = 100000
@export var base_speed: float = 3000.0
@export var base_health: float = 100.0

@export var collision: CollisionShape2D

func _ready():
	if active:
		if not collision_on:
			collision.queue_free()
		
		if not Data.is_data_loaded:
			await Data.data_loaded # Wait for game data to load
		
		# Initialize Game Data with these stats (use if save_data in game manager is false)
		if get_parent().save_data == false:
			Global.player_change_stat("health = %s" % [base_health], true)
			Global.player_change_stat("speed = %s" % [base_speed], true)
			
	else:
		self.queue_free() # Delete self if not active

func _physics_process(delta: float) -> void:
	
	var speed = _get_current_speed()
	
	var direction_x = _get_direction("x")
	
	var direction_y = _get_direction("y")
	
	if direction_x:
		velocity.x = direction_x * speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if direction_y:
		velocity.y = direction_y * speed * delta
	else:
		velocity.y = move_toward(velocity.y, 0, speed)
	
	move_and_slide()

func _process(_delta: float) -> void:
	# Key Press Functions
	_center_camera()
	
	# Automatic Functions
	_auto_bind_camera()
	
	# State Checks
	_check_for_death()

func _get_current_speed() -> float:
	var speed: float = Global.player_get_stat("speed")
	
	speed = speed * Global.speed_mult
	
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

func _center_camera():
		if Input.is_action_just_pressed("center_camera"):
			Global.player_camera.position = Vector2.ZERO  # Reset camera position relative to player

func _auto_bind_camera(): # Ensures the camera doesnt go too far from the player
	var max_offset = camera_distance_limit
	if abs(Global.player_camera.position.x) > max_offset:
		Global.player_camera.position.x = sign(Global.player_camera.position.x) * max_offset  # Snap to the max boundary
	
	if abs(Global.player_camera.position.y) > max_offset:
		Global.player_camera.position.y = sign(Global.player_camera.position.y) * max_offset  # Snap to the max boundary

func _check_for_death():
	var health = Global.player_get_stat("health")
	if health <= 0:
		self.visible = false
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()
