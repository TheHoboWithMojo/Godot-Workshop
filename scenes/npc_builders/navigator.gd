extends NavigationAgent2D
class_name NavigationComponent
@export var debugging_enabled: bool = false
@export var parent: Node
@export var speed: int = 100
@onready var parent_name: String = parent.name
var navigation_target: Vector2 = Vector2.ZERO
var seeking_enabled: bool = true
signal target_changed


func _ready() -> void:
	assert(parent)
	await parent.ready
	target_reached.connect(_on_target_reached)
	velocity_computed.connect(_on_velocity_computed)


func seek() -> void:
	target_position = navigation_target
	if is_navigation_finished():
		parent.velocity = Vector2.ZERO
		return
	set_velocity(parent.global_position.direction_to(get_next_path_position()) * speed * Global.speed_mult)
	parent.set_velocity(velocity)


var displacement: float = 0.0 # how much to nudge the target based on direction input
var setting_target: bool = false
func set_target(target: Variant = navigation_target, up_down_left_right: String = "") -> void:
	if typeof(target) == typeof(navigation_target) and target == navigation_target:
		return
	setting_target = true
	seeking_enabled = false
	if target is Vector2:
		if target == Vector2.ZERO:
			target = Vector2(0.0001, 0.0001)
		navigation_target = target
	elif target is Node2D:
		navigation_target = target.global_position
	else:
		Debug.throw_error(parent, "set_target", "can only target a vector2 or node2d")
	match(up_down_left_right):
		"left":
			navigation_target -= (1.2 * Vector2(displacement, 0))
		"right":
			navigation_target += (1.2 * Vector2(displacement, 0))
		"above":
			navigation_target -= (1.2 * Vector2(0, displacement))
		"below":
			navigation_target += (1.2 * Vector2(displacement, 0))
	seeking_enabled = true
	setting_target = false
	target_changed.emit()
	if debugging_enabled:
		print("[Being] ", parent_name, "'s target has been changed to: ", navigation_target)


func set_seeking_enabled(value: bool) -> void:
	if setting_target:
		await target_changed
	seeking_enabled = value


func _physics_process(_delta: float) -> void:
	if seeking_enabled and navigation_target != Vector2.ZERO:
		seek()
	parent.move_and_slide()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	parent.set_velocity(safe_velocity)


func _on_target_reached() -> void:
	pass # Replace with function body.
