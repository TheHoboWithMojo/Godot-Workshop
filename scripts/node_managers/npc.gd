class_name NPC
extends CharacterBody2D
@export_group("Optional Components")
@export var dialog_manager: DialogComponent
@export var timeline: Dialogue.TIMELINES
@export var health_manager: HealthComponent
@export var max_health: int = 300
@export var navigation_manager: NavigationComponent
@export var speed: int = 100
@export var character_manager: CharacterComponent
@export var character: Characters.CHARACTERS

@export_group("Nodes")
@export var collider: Collider

@export_group("Config")
@export var active: bool = true
@export var collision_on: bool = true
@export var debugging: bool

@onready var name_tag: RichTextLabel = $Texture/NameTag

@onready var hostile: bool = false # placeholders for future attack manager or something of the sort

signal moved_level

func set_hostile(value: bool) -> void:
	hostile = value


func set_paused(value: bool) -> void:
	if navigation_manager:
		navigation_manager.set_physics_process(value)


func get_character_enum() -> Characters.CHARACTERS:
	return character


func await_name_changed() -> void:
	if Characters.get_character_name(character) != name and character_manager:
		await renamed


func _ready() -> void:
	if not active:
		queue_free()
	if collider:
		collider.set_disabled(!collision_on)
	if dialog_manager and timeline != Dialogue.TIMELINES.UNASSIGNED:
		dialog_manager.set_timeline(timeline)
	if health_manager:
		health_manager.set_max_health(max_health)
		health_manager.set_health(max_health)
	if character_manager:
		character_manager.character = character


@onready var last_position: Vector2 = Vector2.ZERO
func _process(_delta: float) -> void:
	if last_position != global_position:
		Characters.set_character_last_position(character, global_position)
	last_position = global_position


var moving_to_level: Levels.LEVELS = Levels.LEVELS.UNASSIGNED
func move_to_new_level(level: Levels.LEVELS) -> void:
	Debug.enforce(level != Levels.LEVELS.UNASSIGNED, "Cannot move to an unassigned level", self)
	Debug.debug("preparing to move to level '%s'" % [Levels.get_level_name(level)], self, "move_to_new_level")

	moving_to_level = level

	var old_level: Level = await Levels.get_current_level()
	var old_level_enum: Levels.LEVELS = old_level.get_level_enum()
	var old_level_name: String = old_level.name
	var target: Vector2 = old_level.get_portal_to_level(level).get_spawn_point_position()

	navigation_manager.set_target(target)

	await _navigation_finished_or_level_changed(old_level)

	var new_level: Level = await Levels.get_current_level()
	if Debug.throw_warning_if(new_level.get_level_enum() != level, "'%s' is not the target level '%s'" % [new_level.name, old_level_name], self):
		return

	await _handle_unfinished_navigation()

	# Get the spawn position from the portal of the new level
	var spawn_position: Vector2 = new_level.get_portal_to_level(old_level_enum).get_spawn_point_position()
	navigation_manager.set_target(spawn_position)

	# Update the reload data before spawning
	Characters.set_character_last_position(character, spawn_position)
	Characters.set_character_last_level(character, new_level.get_level_enum())

	# Get the player's collision details
	var player_collider: Collider = Global.player_bubble.find_child("Collider")

	Debug.debug_if(Global.get_collider_global_rect(player_collider).has_point(spawn_position), "waiting for the player to move before spawning in level '%s'" % [new_level.name], self, "move_to_new_level")

	#Wait for the player to leave the spawn area
	while Global.get_collider_global_rect(player_collider).has_point(spawn_position):
		await get_tree().process_frame

	# Spawn the npc there and restore its functionality
	Global.npc_manager.load_npc(self, spawn_position)

	# Reset moving state and emit the moved_level signal
	moving_to_level = Levels.LEVELS.UNASSIGNED
	moved_level.emit()


func _navigation_finished_or_level_changed(old_level: Level) -> void:
	# Wait for either the navigation to finish or the level to change
	while (await Levels.get_current_level() == old_level) and (not navigation_manager.is_navigation_finished()):
		await get_tree().process_frame

	# Disable the NPC until the new_level is loaded
	await Global.npc_manager.set_npc_enabled(self, false)

	# Wait for a new level to load if needed
	if navigation_manager.is_navigation_finished() and (await Levels.get_current_level() == old_level):
		await Global.level_manager.new_level_loaded

# If navigation isn't finished, wait and force navigation completion
func _handle_unfinished_navigation() -> void:
	if Debug.debug_if(navigation_manager.is_navigation_finished(), "navigation to level '%s' was unfinished, simulating navigation." % [await Levels.get_current_level()], self, "_handle_unfinished_navigation"):
		await Global.delay(self, 2.0)
		navigation_manager.set_target(global_position)
