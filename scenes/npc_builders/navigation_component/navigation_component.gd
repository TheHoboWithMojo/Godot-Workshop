
class_name NavigationComponent extends NavigationAgent2D
@export var debugging: bool = false
@export var inherit_debugging: bool = false
@export var parent: Node
@export var self_parented: bool = false
@export var speed: int = 100
@onready var parent_character: CharacterComponent = parent.get_character_component() if parent is NPC else null
@onready var player_collider: CollisionShape2D = Global.player_bubble.find_child("Collider")
var navigation_target: Vector2 = Vector2.ZERO
var seeking_enabled: bool = true

signal target_changed(target: Vector2)
signal moved_level(level: Level)


func _ready() -> void:
	set_name("NavigationComponent")
	if self_parented:
		parent = self
		Debug.debug("In self_parent mode", parent, "_ready")
	assert(parent != null, Debug.define_error("A navigation agent must reference a parent", self))
	debugging = Debug.get_configed_debugging(parent, debugging, inherit_debugging)
	target_reached.connect(_on_target_reached)
	velocity_computed.connect(_on_velocity_computed)


@onready var last_position: Vector2 = Vector2.ZERO
func _process(_delta: float) -> void:
	if last_position != parent.global_position:
		#Debug.debug("Position changed to %s" % [str(parent.global_position)], parent, "_process", self)
		pass
		if parent_character:
			Characters.set_character_last_position(parent_character.get_character_enum(), parent.global_position)
			var npc: NPC = parent
			Global.npc_manager.npc_dict[npc][Global.npc_manager.PROPERTIES.LAST_POSITION] = parent.global_position
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
func set_target(target: Variant = navigation_target, move_level_call: bool = false, up_down_left_right: String = "") -> void:
	if not move_level_call and moving_to_level:
		await moved_level
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
		push_error(Debug.define_error("Can only target a vector2 or node2d, instead was given '%s' of type '%s'" % [target, typeof(target)], parent))
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
	target_changed.emit(navigation_target)
	Debug.debug("target has been changed to %s." % [navigation_target], parent, "set_target", self)


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
	assert(level != Levels.LEVELS.UNASSIGNED, Debug.define_error("Cannot move to an unassigned level", parent))
	Debug.debug("[NPC] '%s' preparing to move to level '%s'" % [name, Levels.get_level_name(level)], parent, "move_to_new_level", self)
	moving_to_level = level


	var old_level: Level = await Levels.get_current_level_node()

	var old_level_enum: Levels.LEVELS = old_level.get_level_enum()

	var target: Vector2 = old_level.get_portal_to_level(level).get_spawn_point_position()

	set_target(target, true)


	# Wait for either the navigation to finish or the level to change

	while (await Levels.get_current_level_enum() == old_level_enum) and (not is_navigation_finished()):
		await get_tree().process_frame

	# Disable the NPC until the new_level is loaded

	if parent.has_method("set_enabled"):
		await parent.set_enabled(false)


	if is_navigation_finished() and (await Levels.get_current_level_enum() == old_level_enum):
		await Global.level_manager.new_level_loaded


	var new_level: Level = await Levels.get_current_level_node()
	var new_level_enum: Levels.LEVELS = new_level.get_level_enum()


	# If the new level is not the one we're moving to, abort

	if Debug.debug_if(new_level_enum != level, "[NPC] '%s' new level '%s' is not the target level '%s'" % [name, new_level.name, Levels.get_level_name(level)], parent, "move_to_new_level"):
		# recursive function with a timer that goes until the correct level loads OR moves the npc to the level in the background idk how yet
		return


	# If navigation isn't finished, wait and force navigation completion

	if not is_navigation_finished():

		Debug.debug("[NPC] '%s' navigation to level '%s' was unfinished, simulating navigation." % [name, new_level.name], parent, "move_to_new_level", self)

		await Global.delay(self, 2.0)

		set_target(parent.global_position, true)

	seeking_enabled = false

	# Get the spawn position from the portal of the new level
	var spawn_position: Vector2 = new_level.get_portal_to_level(old_level_enum).get_spawn_point_position()

	Debug.debug("New level spawnpoint location calculated, targeting it now", parent, "move_to_new_level", self)

	# Update the reload data before spawning
	if parent is NPC:
		var npc: NPC = parent
		Characters.set_character_last_position(parent.get_character_enum(), spawn_position)
		Global.npc_manager.npc_dict[npc][Global.npc_manager.PROPERTIES.LAST_POSITION] = spawn_position
		Characters.set_character_last_level(parent.get_character_enum(), new_level_enum)
		Global.npc_manager.npc_dict[npc][Global.npc_manager.PROPERTIES.LAST_LEVEL] = new_level_enum


	# Wait for the player to leave the spawn area

	Debug.debug_if(Global.get_collider_global_rect(player_collider).has_point(spawn_position), "waiting for the player to move before spawning in level '%s'" % [new_level.name], self, "move_to_new_level")



	while Global.get_collider_global_rect(player_collider).has_point(spawn_position):

		await get_tree().process_frame


	# Spawn the npc there and restore its functionality

	Global.npc_manager.load_npc(parent, spawn_position)

	seeking_enabled = true

	# Reset moving state and emit the moved_level signal

	moving_to_level = Levels.LEVELS.UNASSIGNED

	moved_level.emit(new_level)
