class_name Being
extends Node2D

# Name and stats
var _nomen: String = "Unnamed"
var _faction: String = ""
var _health: float = 0.0
var _speed: float = 0.0
var _damage: float = 0.0

# Bools
var _alive: bool = true # Alive is not required by caller
var _hostile: bool = false
var _debugging: bool = false
var is_touching_player: bool = false
var _vincible: bool = true

# Nodes
var _sprite: AnimatedSprite2D = null
var _collider: CollisionShape2D = null
var _area: Area2D = null
var _animator: AnimationPlayer = null
var _caller: Node
var _health_bar: TextureProgressBar = null
# Missing nodes
var _missing_components: Dictionary = {}

# Functions for each node type (for debug printing)
const SPRITE_FUNCTIONS = {
	"show_damage_effect": "Display visual effects when taking damage",
	"show_healing_effect": "Display visual effects when healing",
	"set_sprite_visible": "Show or hide the being's sprite",
	"flip_sprite": "Flip the sprite horizontally"
}

const COLLIDER_FUNCTIONS = {
	"move_to": "Move the being to a specific position",
	"detect_collisions": "Check for collisions with other objects",
	"set_collision_enabled": "Enable or disable collision detection"
}

const AREA_FUNCTIONS = {
	"setup_interaction_area": "Configure the interaction area",
	"set_area_monitoring": "Enable or disable area monitoring",
	"get_overlapping_bodies": "Get list of bodies overlapping with this being"
}

const ANIMATOR_FUNCTIONS = {
	"play_animation": "Play a specific animation",
	"stop_animation": "Stop the current animation",
	"is_playing_animation": "Check if an animation is currently playing",
	"get_current_animation": "Get the name of the current animation"
}

# Setter getter for health
var health: float:
	get:
		return _health
	set(value):
		if _debugging:
			print("[Being] Setting Health: %s" % value)
		if value <= 0 and _alive:
			_health = 0
			#print("[Being] " + _caller.name + " - " + _nomen + " died!")
			_alive = false
		elif value > 0:
			_health = value

var speed: float:
	get:
		return _speed
	set(value):
		if _debugging:
			print("[Being] Setting Speed: %s" % value)
		if value <= 0 and _speed:
			_speed = 0
		elif value > 0:
			_speed = value


var damage: float:
	get:
		return _damage
	set(value):
		if _debugging:
			print("[Being] Setting Damage: %s" % value)
		if value <= 0 and _damage:
			_damage = 0
		elif value > 0:
			_damage = value

# Use a dictionary for optional parameters
func _init(params: Dictionary = {}):
	# First set debugging properties
	_debugging = params.get("debugging", false)
	_caller = params.get("caller", "")
	
	if _debugging:
		print("[Being] Constructor called by ", _caller.name)
	
	# Set non node values
	_nomen = params.get("nomen", "unnamed")
	_faction = params.get("faction", "unaffiliated")
	if _faction and _faction != "unaffiliated" and _faction not in Factions.factions_template.keys():
		Debug.throw_error(self, "_init", "Faction %s does not exist" % [_faction])
		_faction = "unaffiliated"
	else:
		_caller.add_to_group(_faction)
		
	_hostile = params.get("hostile", false)
	_vincible = params.get("vincible", true)
	health = params.get("base_health", 0.0) # If no health in entity, assume its non living
	speed = params.get("base_speed", 0.0)
	damage = params.get("base_damage", 0.0)
	
	# Store node components and track missing ones
	_sprite = params.get("sprite")
	if not _sprite:
		_missing_components["sprite"] = SPRITE_FUNCTIONS
		
	_collider = params.get("collider")
	if not _collider:
		_missing_components["collider"] = COLLIDER_FUNCTIONS
		
	_area = params.get("area")
	if not _area:
		_missing_components["area"] = AREA_FUNCTIONS
		
	_animator = params.get("animator")
	if not _animator:
		_missing_components["animator"] = ANIMATOR_FUNCTIONS
	
	_health_bar = params.get("health_bar")
	if not _health_bar:
		_missing_components["health_bar"] = ANIMATOR_FUNCTIONS
	else:
		_health_bar.min_value = 0.0
		_health_bar.max_value = health
		_health_bar.set_value(health)
	if _debugging:
		print("[Being] Initialized: Name = %s, Health = %s Speed = %s" % [_nomen, _health, _speed])
	
	if _caller:
		_caller.add_to_group("beings")
	_print_missing_components()
	
func _print_missing_components() -> void:
	if _missing_components.size() > 0:
		if _debugging:
			print("[Being] Warning: Missing components:")
			for component in _missing_components:
				print("  - %s component missing. Unavailable functions:" % component)
				for func_name in _missing_components[component]:
					print("    • %s: %s" % [func_name, _missing_components[component][func_name]])

func _has_component(component: String) -> bool:
	if component in _missing_components:
		return false
	return true

# ===== Core Functions (No Component Requirements) =====

func take_damage(amount: float) -> void:
	if _vincible:
		var new_health = health - amount
		if new_health < 0:
			new_health = 0
		health = new_health

func heal(amount: float) -> void:
	health += amount

var _died: bool = false # Used for die function

func die(exp_gain: int = 0) -> void:
	if _died == false:
		_died = true # Stops from piling calls
		
		speed = 0
		
		_health_bar.set_value(0.0)
		
		play_animation("die")
		
		if _faction != "unaffiliated":
			Factions.log_decision(_faction, "killed a member.", -100)
		
		if _animator and _animator.is_playing():
			await _animator.animation_finished
		
		elif _sprite and _sprite.is_playing():
			await _sprite.animation_finished
		
		if exp_gain:
			Global.player_add_exp(exp_gain)
			
		Global.game_manager.mob_died.emit()
		_caller.queue_free()
	
func revive(revive_health: float = 100.0) -> void:
	_alive = true
	health = revive_health

func is_alive() -> bool:
	return _alive

func is_hostile() -> bool:
	return _hostile

func set_vincible(Bool: bool):
	_vincible = Bool

func set_hostile(value: bool) -> void:
	_hostile = value

# ===== Sprite Component Functions =====

func show_damage_effect() -> bool:
	if not _has_component("sprite"):
		return false
	# Visual damage effect code
	return true

func show_healing_effect() -> bool:
	if not _has_component("sprite"):
		return false
	# Visual healing effect code
	return true

func set_sprite_visible(_visible: bool) -> bool:
	if not _has_component("sprite"):
		return false
	_sprite.visible = _visible
	return true

func flip_sprite(flip_h: bool) -> bool:
	if not _has_component("sprite"):
		return false
	_sprite.flip_h = flip_h
	return true

# ===== Collision Component Functions =====
func move_to(_position: Vector2) -> bool:
	if not _has_component("collider"):
		return false
	# Movement code here
	return true

func detect_collisions() -> bool:
	if not _has_component("collider"):
		return false
	# Collision detection code
	return true

func toggle_collision(enabled: bool) -> bool:
	if not _has_component("collider"):
		return false
	_collider.disabled = !enabled
	return true
# ===== Area Component Functions =====
func toggle_monitoring(enabled: bool) -> bool:
	if not _has_component("area"):
		return false
	_area.monitoring = enabled
	_area.monitorable = enabled
	return true

func get_overlapping_bodies() -> Array:
	if not _has_component("area"):
		return []
	return _area.get_overlapping_bodies()
# ===== Animation Player Component Functions =====
func play_animation(anim_name: String) -> bool:
	if not _has_component("animator") and not _has_component("sprite"):
		return false
	
	# Check AnimationPlayer first
	if _animator and _animator.has_animation(anim_name):
		_animator.play(anim_name)
		return true
	
	# Check AnimatedSprite2D
	if _sprite and anim_name in _sprite.sprite_frames.get_animation_names():
		_sprite.play(anim_name)
		return true
	
	return false

func stop_animation() -> bool:
	if not _has_component("animator") and not _has_component("sprite"):
		return false
	
	var stopped = false
	
	if _animator and _animator.is_playing():
		_animator.stop()
		stopped = true
	
	if _sprite and _sprite.is_playing():
		_sprite.stop()
		stopped = true
	
	return stopped

func is_playing_animation() -> bool:
	if not _has_component("animator") and not _has_component("sprite"):
		return false
	
	if _animator and _animator.is_playing():
		return true
	
	if _sprite and _sprite.is_playing():
		return true
	
	return false
	
func get_current_animation() -> String:
	if not _has_component("animator"):
		return ""
	return _animator.current_animation
# ===== Static Functions =====
static func create_being(self_node: Node) -> Being:
	var params = {} # Keep track of what variables and nodes the caller has
	
	var caller: Node = self_node # Save caller path for direct manipulation
	params["caller"] = caller
	
	# Add available components to params
	var sprite = self_node.get("sprite")
	if sprite:
		params["sprite"] = sprite
		
	var collider = self_node.get("collider")
	if collider:
		params["collider"] = collider
		
	var area = self_node.get("area")
	if area:
		params["area"] = area
		
	var animator = self_node.get("animator")
	if animator:
		params["animator"] = animator
	
	var health_bar = self_node.get("health_bar")
	if health_bar:
		params["health_bar"] = health_bar
	
	var base_health = self_node.get("base_health")
	if base_health != null:
		params["base_health"] = base_health
		
	var base_speed = self_node.get("base_speed")
	if base_speed != null:
		params["base_speed"] = base_speed
		
	var base_damage = self_node.get("base_damage")
	if base_damage != null:
		params["base_speed"] = base_speed
		
	var nomen = self_node.get("nomen")
	if nomen != null and nomen != "":
		params["nomen"] = nomen
		
	var hostile = self_node.get("hostile")
	if hostile != null:
		params["hostile"] = hostile
		
	var debugging = self_node.get("debugging")
	if debugging != null:
		params["debugging"] = debugging
		
	var faction = self_node.get("faction")
	if faction != null and faction != "":
		params["faction"] = faction
	
	var vincible = self_node.get("vincible")
	if vincible != null:
		params["vincible"] = vincible
		
	return Being.new(params)
	
static func print_reqs() -> void:
	print("# Optional export variables for Being:")
	print("@export var base_health: float = ")
	print("@export var base_health: float = ")
	print("@export var nomen: String = ")
	print("@export var hostile: bool = ")
	print("@export var sprite: AnimatedSprite2D")
	print("@export var collider: CollisionShape2D")
	print("@export var area: Area2D")
	print("@export var animator: AnimationPlayer")
