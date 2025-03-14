extends CharacterBody2D

var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	# get the y direction
	var direction_y := Input.get_axis("move_up", "move_down")
	
	# handle y movement
	if direction_y:
		velocity.y = direction_y * speed
	else:
		velocity.y = move_toward(velocity.y, 0, speed)
	
	# get the x direction	
	var direction_x := Input.get_axis("move_left", "move_right")
	
	# handle x movement
	if direction_x:
		velocity.x = direction_x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	# move object based on velocity
	move_and_slide()
