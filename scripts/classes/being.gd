class_name Being
extends Node2D

# Name and stats
var _nomen: String = ""
var _faction: Factions.FACTIONS
var _character: Dialogue.CHARACTERS
var _health: float = 0.0
var _speed: float = 0.0
var _damage: float = 0.0
var _exp_on_kill: int = 0

# Booleans
var _alive: bool = true
var _hostile: bool = false
var _debugging: bool = false
var is_character: bool = false # in the characters dict?
var vincible: bool = true

# Nodes
var _slave: Node
var _sprite: Sprite2D = null
var _collider: CollisionShape2D = null
var ibubble: Area2D = null
var _health_bar: TextureProgressBar = null
var _audio: AudioStreamPlayer2D = null
var _navigator: NavigationAgent2D = NavigationAgent2D.new()
var _navigation_target: Vector2 = Vector2.ZERO

# Missing nodes
var _missing_components: Array[String]

# Functions for each node type (for debug printing)
const SPRITE_FUNCTIONS: Dictionary[String, String] = {
	"show_damage_effect": "Display visual effects when taking damage",
	"show_healing_effect": "Display visual effects when healing",
	"set_sprite_visible": "Show or hide the being's sprite",
	"flip_sprite": "Flip the sprite horizontally"
}

const COLLIDER_FUNCTIONS: Dictionary[String, String] = {
	"move_to": "Move the being to a specific position",
	"detect_collisions": "Check for collisions with other objects",
	"set_collision_enabled": "Enable or disable collision detection"
}

const AREA_FUNCTIONS: Dictionary[String, String] = {
	"setup_interaction_area": "Configure the interaction area",
	"set_area_monitoring": "Enable or disable area monitoring",
	"get_overlapping_bodies": "Get list of bodies overlapping with this being"
}

# ===== Properties =====

# Setter getter for health
var health: float:
	get:
		return _health
	set(value):
		if _debugging:
			print("[Being] %s Setting Health: %s" % [_nomen, value])
		if value <= 0 and _alive:
			_health = 0
			die()
		elif value > 0:
			_health = value
		if _health_bar != null:
			_health_bar.set_value(_health)

var speed: float:
	get:
		return _speed
	set(value):
		if _debugging:
			print("[Being] %s Setting Speed: %s" % [_nomen, value])
		if value <= 0 and _speed:
			_speed = 0
		elif value > 0:
			_speed = value

var damage: float:
	get:
		return _damage
	set(value):
		if _debugging:
			print("[Being] %s Setting Damage: %s" % [_nomen, value])
		if value <= 0 and _damage:
			_damage = 0
		elif value > 0:
			_damage = value
		
var hostile: bool:
	get:
		return _hostile
	set(value):
		if _debugging:
			print("[Being] %s Setting Hostile: %s" % [_nomen, value])
			
		if value == true:
			_hostile = true
			_slave.add_to_group("enemies")
		else:
			_hostile = false
			_slave.remove_from_group("enemies")
				
		if _health_bar != null:
			_health_bar.set_visible(hostile)
			
# ===== Initialization =====

# Use a dictionary for optional parameters
func _init(self_node: Node) -> void:
	_debugging = self_node.get("debugging")
	_slave = self_node

	if _slave == null:
		Debug.throw_error(self, "init", "Could not initiate being")
		return

	if "character" in _slave:
		_character = _slave.character
		is_character = true
		_nomen = Dialogue.characters[_character]["name"]
		_faction = Dialogue.characters[_character]["faction"]
		_slave.add_to_group(Factions.get_faction(_faction))
		if not Data.game_data["characters"][str(_character)]["alive"]:
			_slave.queue_free()
			return

	_slave.add_to_group("beings")

	if _debugging:
		print("[Being] Constructor called by ", _slave.name)

	_sprite = _slave.get("sprite")
	if _sprite == null:
		_missing_components.append("sprite")
		
	_collider = _slave.get("collider")
	if _collider == null:
		_missing_components.append("collider")

	ibubble = _slave.get("ibubble")
	if ibubble == null:
		_missing_components.append("ibubble")
	else:
		_slave.add_child(_navigator)
		if _debugging:
			_navigator.set_debug_enabled(true)
			print("agents avoidance layers: ", _navigator.get_avoidance_layers())
			print("agents navigation map: ", _navigator.get_navigation_map())
			
		_navigator.set_avoidance_enabled(true)
		_navigator.set_path_desired_distance(5.0)
		_navigator.set_target_desired_distance(5.0)
		#_navigator.set_path_postprocessing(1) # PATH_POSTPROCESSING_EDGECENTERED
		_navigator.velocity_computed.connect(_on_navigator_velocity_computed)
		_navigator.set_radius(Global.get_collider(ibubble).shape.radius)
		_navigation_target = _slave.global_position
		displacement = Global.get_collider(ibubble).shape.radius

	_audio = _slave.get("audio")
	if _audio == null:
		_missing_components.append("audio")

	_health_bar = _slave.get("health_bar")
	if _health_bar == null:
		_missing_components.append("health_bar")
	else:
		_health_bar.min_value = 0.0

	if _slave.get("vincible"):
		vincible = _slave.get("vincible")

	if _slave.get("hostile"):
		hostile = _slave.get("hostile")

	if _slave.get("base_speed"):
		speed = _slave.get("base_speed")

	if _slave.get("base_damage"):
		damage = _slave.get("base_damage")

	if _slave.get("exp_on_kill"):
		_exp_on_kill = _slave.get("exp_on_kill")

	_print_missing_components()

# ===== Component Management =====
func _print_missing_components() -> void:
	if _debugging and _missing_components.size() > 0:
		print("[Being] Warning: Missing essential components:")
		for component: String in _missing_components:
			print("  - %s component is missing." % component)
			
# ===== Health Management =====

func take_damage(amount: float) -> void:
	if vincible:
		hostile = true
		health -= amount

func heal(amount: float) -> void:
	health += amount
		
func _on_navigator_velocity_computed(safe_velocity: Vector2) -> void:
	_slave.velocity = safe_velocity

@onready var displacement: float = 0.0 # set in init
@onready var shifted: bool = false
func seek(target: Variant = _navigation_target, up_down_left_right: String = "") -> void:
	if _alive:
		if target is Vector2:
			_navigation_target = target
		elif target is Node:
			_navigation_target = target.global_position
		if not shifted:
			match(up_down_left_right): # shift the position WILL ONLY RUN ONCE ON NON PROCESS CALL
				"left":
					_navigation_target -= (1.2 * Vector2(displacement, 0))
					shifted = true
				"right":
					_navigation_target += (1.2 * Vector2(displacement, 0))
					shifted = true
				"up":
					_navigation_target += (1.2 * Vector2(0, displacement))
					shifted = true
				"down":
					_navigation_target -= (1.2 * Vector2(displacement, 0))
					shifted = true
		_navigator.target_position = _navigation_target
		if _navigator.is_navigation_finished():
			_slave.velocity = Vector2.ZERO
			shifted = false
			return
				
		_navigator.set_velocity(_slave.global_position.direction_to(_navigator.get_next_path_position()) * 50)

func die() -> void:
	_slave.velocity = Vector2.ZERO
	_slave.set_physics_process(false)
	_slave.set_process(false)
	
	if _alive == true:
		_alive = false # Stops from piling calls
		
		if is_character:
			Data.game_data["characters"][str(_character)]["alive"] = false
		
		speed = 0
		
		_health_bar.set_value(0)
		
		if _audio != null:
			_audio.play()
		
		if Factions.faction_exists(_faction):
			Factions.log_decision(_faction, "killed a member.", -100)
			if Factions.get_rep_status(_faction) == "hostile":
				var allies: Array = _slave.get_tree().get_nodes_in_group(Factions.get_faction(_faction))
				for ally: Node2D in allies:
					ally.master.set_hostile(true)
		
		Global.game_manager.mob_died.emit()
		Player.log_kill(_exp_on_kill)
		await Global.delay(_slave, 1.0)
		_slave.queue_free()

func is_alive() -> bool:
	return _alive

func is_hostile() -> bool:
	return _hostile
	
func set_hostile(toggle: bool) -> void:
	_hostile = toggle

# ===== Sprite Component Functions =====
func toggle_visible(_visible: bool) -> bool:
	if _sprite != null:
		_sprite.visible = _visible
		return true
	return false

func flip_sprite(flip_h: bool) -> bool:
	if _sprite == null:
		return false
	_sprite.flip_h = flip_h
	return true

# ===== Collider Component Functions =====
func toggle_collision(enabled: bool) -> bool:
	if _collider != null:
		_collider.disabled = !enabled
		return true
	return false
# ===== Area Component Functions =====
func toggle_monitoring(enabled: bool) -> bool:
	if ibubble != null:
		ibubble.monitoring = enabled
		ibubble.monitorable = enabled
		return true
	return false

func get_overlapping_bodies() -> Array:
	if ibubble != null:
		return ibubble.get_overlapping_bodies()
	return []
