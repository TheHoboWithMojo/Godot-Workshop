extends CharacterBody2D

@onready var camera: Camera2D = $"Sim Camera"

var speed: float = 300.0
var camera_limit: float = 200.0  # Max distance the camera can move from the player in pixels

func _physics_process(_delta: float) -> void:
	# Get the Y direction
	var direction_y := Input.get_axis("move_up", "move_down")
	
	# Handle Y movement
	if direction_y:
		velocity.y = direction_y * speed
	else:
		velocity.y = move_toward(velocity.y, 0, speed)
	
	# Get the X direction	
	var direction_x := Input.get_axis("move_left", "move_right")
	
	# Handle X movement
	if direction_x:
		velocity.x = direction_x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	# Move object based on velocity
	move_and_slide()

func _process(_delta: float) -> void:
	# Check if the "center_camera" action is pressed
	if Input.is_action_just_pressed("center_camera"):
		camera.position = Vector2.ZERO  # Reset camera position relative to player
	
	# **Only clamp if out of bounds**
	var max_offset = camera_limit
	
	if abs(camera.position.x) > max_offset:
		camera.position.x = sign(camera.position.x) * max_offset  # Snap to the max boundary
	
	if abs(camera.position.y) > max_offset:
		camera.position.y = sign(camera.position.y) * max_offset  # Snap to the max boundary
