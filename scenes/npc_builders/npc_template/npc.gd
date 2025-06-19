class_name NPC extends CharacterBody2D
@export var default_spawn_position: Vector2
@export var event_manager: EventPlayer
@export var health_manager: HealthComponent
@export var navigation_manager: NavigationComponent
@export var character_manager: CharacterComponent
@export var collider: Collider
@export var debugging: bool
@export var quests_to_notify_on_death: Array[Quests.QUESTS]
@onready var touch_detector: TouchDetector = $TouchDetector
var hostile: bool = false # placeholders for future attack manager or something of the sort
var encountered: bool = false

signal target_changed(new_target: Vector2)
signal moved_level(level: Levels.LEVELS)
signal navigation_finished(self_node: Node)
signal dialogue_started(self_node: Node)
signal dialogue_ended(self_node: Node)


func place_at(vector: Vector2) -> void:
	set_target(vector)
	set_global_position.call_deferred(vector)


func set_hostile(value: bool) -> void:
	Debug.debug("Setting hostile to %s" % [value], self, "set_hostile")
	hostile = value


func has_been_encountered() -> bool:
	Debug.debug("Returning encountered status %s" % [encountered], self, "has_been_encountered")
	return encountered


func set_encountered(value: bool) -> void:
	Debug.debug("Setting encountered to %s" % [value], self, "set_encountered")
	encountered = value


func set_paused(value: bool) -> bool:
	if not navigation_manager:
		push_error(Debug.define_error("Cannot call pause on an npc that does not have a navigation component", self))
		return false
	navigation_manager.set_physics_process(value)
	return true


func await_name_changed() -> bool:
	if not character_manager:
		push_error(Debug.define_error("This npc does not have a character component and as such their name will never change", self))
		return false
	if Characters.get_character_name(character_manager.get_character_enum()) != name:
		Debug.debug("Returning dialog component %s" % [event_manager], self, "get_dialog_component")
		await renamed
	return true


func set_target(target: Variant, up_down_left_right: String = "") -> bool:
	if not navigation_manager:
		push_error(Debug.define_error("Cannot call the seek function on a npc without a navigation component", self))
		return false
	navigation_manager.set_target(target, false, up_down_left_right)
	return true


func get_character_enum() -> Characters.CHARACTERS:
	if not character_manager:
		push_error(Debug.define_error("Cannot get the character enum of an npc without a character component", self))
		return Characters.CHARACTERS.UNASSIGNED
	return character_manager.get_character_enum()


func set_timeline_enum(timeline: Dialogue.TIMELINES) -> bool:
	if not event_manager:
		push_error(Debug.define_error("Cannot set the timeline of a npc without an EventManager", self))
		return false
	event_manager.set_timeline_enum(timeline)
	return true


func get_navigation_component() -> NavigationComponent:
	Debug.debug("Returning navigation component %s" % [navigation_manager], self, "get_navigation_component")
	return navigation_manager


func get_character_component() -> CharacterComponent:
	Debug.debug("Returning character component %s" % [character_manager], self, "get_character_component")
	return character_manager


func get_health_component() -> HealthComponent:
	Debug.debug("Returning health component %s" % [health_manager], self, "get_health_component")
	return health_manager


func is_navigation_finished() -> bool:
	if navigation_manager:
		return navigation_manager.is_navigation_finished()
	push_error(Debug.define_error("Does not have a navigation component to call is_navigation_finished on", self))
	return false


func wait_for_nav_finished() -> void:
	if not navigation_manager:
		push_error(Debug.define_error("Does not have a navigation component to call is_navigation_finished on", self))
		return
	if not is_navigation_finished():
		await navigation_manager.navigation_finished


func get_event_player() -> EventPlayer:
	Debug.debug("Returning dialog component %s" % [event_manager], self, "get_dialog_component")
	return event_manager


func set_collision_enabled(value: bool) -> bool:
	if not collider:
		push_error(Debug.define_error("Does not have a collider to alter", self))
		return false
	collider.set_disabled(!value)
	Debug.debug("Setting collision to %s" % [value], self, "set_collision_enabled")
	return true


func set_alive(value: bool) -> bool:
	if not health_manager:
		push_error(Debug.define_error("Does not have a health component to alter", self))
		return false
	return await health_manager.set_alive(value)


func set_enabled(value: bool) -> void:
	set_visible(false)
	set_physics_process(false)
	set_process(false)
	collider.set_disabled.call_deferred(true)
	touch_detector.set_monitoring(false)
	if value:
		await get_tree().process_frame
		touch_detector.set_monitoring(true)
		collider.set_disabled(false)
		set_physics_process(true)
		set_process(true)
		set_visible(true)


func get_default_level() -> Levels.LEVELS:
	if not character_manager:
		push_error("Only npc with a character component have a default level", self, "get_default_level")
		return Levels.LEVELS.UNASSIGNED
	return Characters.get_character_default_level(character_manager.get_character_enum())


func get_faction_enum() -> Factions.FACTIONS:
	return Characters.get_character_faction(character_manager.get_character_enum()) if character_manager else Factions.FACTIONS.UNASSIGNED


func get_default_spawn_position() -> Vector2:
	return default_spawn_position


func move_to_new_level(level: Levels.LEVELS) -> void:
	if not navigation_manager:
		push_error("Only npc with a character component have a default level", self, "get_default_level")
		return
	navigation_manager.move_to_new_level(level)


func _ready() -> void:
	#assert(default_spawn_position, "All npcs must have a default spawn point") # THIS WILL BE HARDCODED LATER IN GLOBAL CHARACTERS DICT
	_wrap_active_component_signals()


func _wrap_active_component_signals() -> void:
	if event_manager:
		event_manager.event_started.connect(_on_dialog_started)
		event_manager.event_ended.connect(_on_dialog_ended)

	if navigation_manager:
		navigation_manager.target_changed.connect(_on_target_changed)
		navigation_manager.moved_level.connect(_on_moved_level)
		navigation_manager.navigation_finished.connect(_on_navigation_finished)

	if health_manager:
		health_manager.died.connect(_on_died)


func _on_dialog_started() -> void:
	dialogue_started.emit()


func _on_dialog_ended() -> void:
	dialogue_ended.emit()


func _on_target_changed(new_target: Vector2) -> void:
	target_changed.emit(new_target)


func _on_moved_level(new_level: Levels.LEVELS) -> void:
	moved_level.emit(new_level)


func _on_died() -> void:
	Characters.character_died.emit(character_manager.get_character_enum())


func _on_navigation_finished() -> void:
	navigation_finished.emit(self)
