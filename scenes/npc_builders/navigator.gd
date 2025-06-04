extends NavigationAgent2D
class_name NavigationComponent
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@export var parent: Node
@export var speed: int = 100
@onready var parent_name: String = parent.name
@onready var parent_character: CharacterComponent = parent.get_character() if parent is NPC else null
var navigation_target: Vector2 = Vector2.ZERO
var seeking_enabled: bool = true
signal target_changed
signal moved_level


func _ready() -> void:
	Debug.enforce(parent != null, "A navigation agent must reference a parent", self)
	await parent.ready
	target_reached.connect(_on_target_reached)
	velocity_computed.connect(_on_velocity_computed)
	if parent_character:
		await parent.await_name_changed()
		parent_name = parent.name
	if inherit_debugging:
		debugging = parent.debugging


@onready var last_position: Vector2 = Vector2.ZERO
func _process(_delta: float) -> void:
	if last_position != parent.global_position:
		#Debug.debug("Position changed to %s" % [str(parent.parent.global_position)], self, "_process")
		if parent_character:
			Characters.set_character_last_position(parent_character.get_character_enum(), parent.global_position)
	last_position = parent.global_position


func seek() -> void:
	target_position = navigation_target
	if is_navigation_finished() or target_position == Vector2.ZERO:
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
		Debug.throw_warning("Can only target a vector2 or node2d", parent)
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
	Debug.debug("target has been changed to %s." % [navigation_target], parent, "set_target")


func set_seeking_enabled(value: bool) -> void:
	if setting_target:
		await target_changed
	seeking_enabled = value


func _physics_process(_delta: float) -> void:
	if seeking_enabled:
		seek()
	parent.move_and_slide()


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	parent.set_velocity(safe_velocity)


func _on_target_reached() -> void:
	pass # Replace with function body.


var moving_to_level: Levels.LEVELS = Levels.LEVELS.UNASSIGNED

func move_to_new_level(level: Levels.LEVELS) -> void:

	Debug.enforce(level != Levels.LEVELS.UNASSIGNED, "Cannot move to an unassigned level", self)

	Debug.debug("[NPC] '%s' preparing to move to level '%s'" % [name, Levels.get_level_name(level)], parent, "move_to_new_level")



	moving_to_level = level



	var old_level: Level = await Levels.get_current_level_node()

	var old_level_enum: Levels.LEVELS = old_level.get_level_enum()

	var target: Vector2 = old_level.get_portal_to_level(level).get_spawn_point_position()



	set_target(target)



	# Wait for either the navigation to finish or the level to change

	while (await Levels.get_current_level_node() == old_level) and (not is_navigation_finished()):

		await get_tree().process_frame



	# Disable the NPC until the new_level is loaded

	await Global.npc_manager.set_npc_enabled(parent, false)



	if is_navigation_finished() and (await Levels.get_current_level() == old_level):

		await Global.level_manager.new_level_loaded


	var new_level: Level = await Levels.get_current_level_node()


	# If the new level is not the one we're moving to, abort

	if Debug.debug_if(new_level.get_level_enum() != level, "[NPC] '%s' new level '%s' is not the target level '%s'" % [name, new_level.name, Levels.get_level_name(level)], parent, "move_to_new_level"):
		# recursive function with a timer that goes until the correct level loads OR moves the npc to the level in the background idk how yet
		return


	# If navigation isn't finished, wait and force navigation completion

	if not is_navigation_finished():

		Debug.debug("[NPC] '%s' navigation to level '%s' was unfinished, simulating navigation." % [name, Levels.get_level_name(level)], parent, "move_to_new_level")

		await Global.delay(self, 2.0)

		set_target(parent.global_position)


	# Get the spawn position from the portal of the new level

	var spawn_position: Vector2 = new_level.get_portal_to_level(old_level_enum).get_spawn_point_position()

	Debug.debug("New level spawnpoint location calculated, targeting it now", parent, "move_to_new_level")

	set_target(spawn_position)


	# Update the reload data before spawning

	Characters.set_character_last_position(parent.character, spawn_position)

	Characters.set_character_last_level(parent.character, new_level.get_level_enum())


	# Get the player's collision details

	var player_collider: Collider = Global.player_bubble.find_child("Collider")


	# Wait for the player to leave the spawn area

	Debug.debug_if(Global.get_collider_global_rect(player_collider).has_point(spawn_position), "waiting for the player to move before spawning in level '%s'" % [new_level.name], self, "move_to_new_level")



	while Global.get_collider_global_rect(player_collider).has_point(spawn_position):

		await get_tree().process_frame


	# Spawn the npc there and restore its functionality

	Global.npc_manager.load_npc(parent, spawn_position)


	# Reset moving state and emit the moved_level signal

	moving_to_level = Levels.LEVELS.UNASSIGNED

	moved_level.emit()
