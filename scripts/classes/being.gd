class_name Being
extends Node2D

# Name and stats
var _nomen: String = ""
var _faction: int = -1
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
var _sprite: AnimatedSprite2D = null
var _collider: CollisionShape2D = null
var _area: Area2D = null
var _animator: AnimationPlayer = null
var _slave: Node
var _health_bar: TextureProgressBar = null
var _audio: AudioStreamPlayer2D = null

# Missing nodes
var _missing_components: Dictionary = {}

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

const ANIMATOR_FUNCTIONS: Dictionary[String, String] = {
	"play_animation": "Play a specific animation",
	"stop_animation": "Stop the current animation",
	"is_playing_animation": "Check if an animation is currently playing",
	"get_current_animation": "Get the name of the current animation"
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
func _init(params: Dictionary = {}) -> void:
	
	_debugging = params.get("debugging", false)
	
	_slave = params.get("slave", null)
	
	if _slave == null:
		Debug.throw_error(self, "init", "Could not initiate being")
		return
	
	_nomen = params.get("nomen", "")
	
	if _nomen and Dialogue.character_exists(_nomen):
		is_character = true
		if not Data.game_data["characters"][_nomen]["alive"]:
			_slave.queue_free()
			return
	
	_slave.add_to_group("beings")
		
	if _debugging:
		print("[Being] Constructor called by ", _slave.name)
	
	_faction = params.get("faction", -1)
	if Factions.faction_exists(_faction):
		_slave.add_to_group(Factions.get_faction(_faction))
		
	# Store node components and track missing ones
	_sprite = params.get("sprite", null)
	if _sprite == null:
		_missing_components["sprite"] = SPRITE_FUNCTIONS
		
	_collider = params.get("collider", null)
	if _collider == null:
		_missing_components["collider"] = COLLIDER_FUNCTIONS
		
	_area = params.get("area", null)
	if _area == null:
		_missing_components["area"] = AREA_FUNCTIONS
		
	_animator = params.get("animator", null)
	if _animator == null:
		_missing_components["animator"] = ANIMATOR_FUNCTIONS
		
	_audio = params.get("audio", null)
	if _audio == null:
		_missing_components["audio"] = ANIMATOR_FUNCTIONS
	
	health = params.get("base_health", 0.0) # If no health in entity, assume its non living
	
	_health_bar = params.get("health_bar", null)
	if _health_bar == null:
		_missing_components["health_bar"] = ANIMATOR_FUNCTIONS
	else:
		_health_bar.min_value = 0.0
		_health_bar.max_value = health
		_health_bar.set_value(health)
		
	vincible = params.get("vincible", true)
	hostile = params.get("hostile", false)
	speed = params.get("base_speed", 0.0)
	damage = params.get("base_damage", 0.0)
	_exp_on_kill = params.get("exp_on_kill", 0.0)
	
	_print_missing_components()

# ===== Component Management =====

func _print_missing_components() -> void:
	if _missing_components.size() > 0:
		if _debugging:
			print("[Being] Warning: Missing components:")
			for component: Variant in _missing_components:
				print("  - %s component missing. Unavailable functions:" % component)
				for func_name: String in _missing_components[component]:
					print("    • %s: %s" % [func_name, _missing_components[component][func_name]])

# ===== Health Management =====

func take_damage(amount: float) -> void:
	if vincible:
		hostile = true
		health -= amount

func heal(amount: float) -> void:
	health += amount

func approach_player(delta: float, perception: float, repulsion_strength: float) -> void:
	if _alive:
		var vector_to_player: Vector2 =  Global.get_vector_to_player(_slave)
		var direction: Vector2 = vector_to_player.normalized()
		
		if vector_to_player.length() < perception:
			_slave.velocity = direction * _speed * delta * Global.speed_mult
			if _slave.velocity.length() > 0:
				play_animation("run")
			else:
				play_animation("idle")
			if direction.x < 0:
				flip_sprite(true)
			else:
				flip_sprite(false)
			if Global.is_touching_player(_slave) and Global.get_vector_to_player(_slave).length() < 10:
				var repulsion_vector: Vector2 = -direction * repulsion_strength * delta
				_slave.velocity += repulsion_vector
		else:
			_slave.velocity = Vector2.ZERO
			play_animation("idle")

func die() -> void:
	_slave.velocity = Vector2.ZERO
	_slave.set_physics_process(false)
	_slave.set_process(false)
	
	if _alive == true:
		_alive = false # Stops from piling calls
		
		if is_character:
			Data.game_data["characters"][_nomen]["alive"] = false
		
		speed = 0
		
		if _audio != null:
			_audio.play()
			
		play_animation("die")
		
		if Factions.faction_exists(_faction):
			Factions.log_decision(_faction, "killed a member.", -100)
			if Factions.get_rep_status(_faction) == "hostile":
				var allies: Array = get_tree().get_nodes_in_group(Factions.get_faction(_faction))
				for ally: Node2D in allies:
					ally.master.set_hostile(true)
		
		if _animator != null and _animator.is_playing():
			await _animator.animation_finished
		
		elif _sprite != null and _sprite.is_playing():
			await _sprite.animation_finished
		
		Global.game_manager.mob_died.emit()
		Player.log_kill(_exp_on_kill)
		_slave.queue_free()

func revive(revive_health: float = 100.0) -> void:
	_alive = true
	health = revive_health

func is_alive() -> bool:
	return _alive

func is_hostile() -> bool:
	return _hostile

# ===== Sprite Component Functions =====

func show_damage_effect() -> bool:
	if _sprite == null:
		return false
	# Visual damage effect code
	return true

func show_healing_effect() -> bool:
	if _sprite == null:
		return false
	# Visual healing effect code
	return true

func set_sprite_visible(_visible: bool) -> bool:
	if _sprite == null:
		return false
	_sprite.visible = _visible
	return true

func flip_sprite(flip_h: bool) -> bool:
	if _sprite == null:
		return false
	_sprite.flip_h = flip_h
	return true

# ===== Collider Component Functions =====

func move_to(_position: Vector2) -> bool:
	if _collider == null:
		return false
	# Movement code here
	return true

func detect_collisions() -> bool:
	if _collider == null:
		return false
	# Collision detection code
	return true

func toggle_collision(enabled: bool) -> bool:
	if _collider == null:
		return false
	_collider.disabled = !enabled
	return true

# ===== Area Component Functions =====

func toggle_monitoring(enabled: bool) -> bool:
	if _area == null:
		return false
	_area.monitoring = enabled
	_area.monitorable = enabled
	return true

func get_overlapping_bodies() -> Array:
	if _area == null:
		return []
	return _area.get_overlapping_bodies()

# ===== Animation Player Component Functions =====

func play_animation(anim_name: String) -> bool:
	if _animator == null and _sprite == null:
		return false
	
	# Check AnimationPlayer first
	if _animator != null and _animator.has_animation(anim_name):
		_animator.play(anim_name)
		return true
	
	# Check AnimatedSprite2D
	if _sprite != null and anim_name in _sprite.sprite_frames.get_animation_names():
		_sprite.play(anim_name)
		return true
	
	return false

func stop_animation() -> bool:
	if _animator == null and _sprite == null:
		return false
	
	var stopped: bool = false
	
	if _animator != null and _animator.is_playing():
		_animator.stop()
		stopped = true
	
	if _sprite != null and _sprite.is_playing():
		_sprite.stop()
		stopped = true
	
	return stopped

func is_playing_animation() -> bool:
	if _animator == null and _sprite == null:
		return false
	
	if _animator != null and _animator.is_playing():
		return true
	
	if _sprite != null and _sprite.is_playing():
		return true
	
	return false

func get_current_animation() -> String:
	if _animator == null:
		return ""
	return _animator.current_animation

# ===== Static Functions =====

static func create_being(self_node: Node) -> Being:
	var params: Dictionary = {} # Keep track of what variables and nodes the slave has
	
	var slave: Node = self_node # Save slave path for direct manipulation
	params["slave"] = slave
	
	# Add available components to params
	var sprite: AnimatedSprite2D = self_node.get("sprite")
	if sprite:
		params["sprite"] = sprite
		
	var collider: CollisionShape2D = self_node.get("collider")
	if collider:
		params["collider"] = collider
		
	var area: Area2D = self_node.get("area")
	if area:
		params["area"] = area
		
	var animator: AnimationPlayer = self_node.get("animator")
	if animator:
		params["animator"] = animator
	
	var health_bar: TextureProgressBar = self_node.get("health_bar")
	if health_bar:
		params["health_bar"] = health_bar
		
	var audio: AudioStreamPlayer2D= self_node.get("audio")
	if audio:
		params["audio"] = audio
	
	@warning_ignore("untyped_declaration")
	var base_health = self_node.get("base_health")
	if base_health != null:
		params["base_health"] = base_health
		
	@warning_ignore("untyped_declaration")
	var base_speed = self_node.get("base_speed")
	if base_speed != null:
		params["base_speed"] = base_speed
		
	@warning_ignore("untyped_declaration")
	var base_damage = self_node.get("base_damage")
	if base_damage != null:
		params["base_damage"] = base_damage
		
	@warning_ignore("untyped_declaration")
	var exp_on_kill = self_node.get("exp_on_kill")
	if exp_on_kill != null:
		params["exp_on_kill"] = exp_on_kill
		
	@warning_ignore("untyped_declaration")
	var nomen = self_node.get("nomen")
	if nomen != null:
		params["nomen"] = nomen
		
	@warning_ignore("untyped_declaration")
	var hostile_ = self_node.get("hostile")
	if hostile_ != null:
		params["hostile"] = hostile_
		
	@warning_ignore("untyped_declaration")
	var debugging = self_node.get("debugging")
	if debugging != null:
		params["debugging"] = debugging
		
	@warning_ignore("untyped_declaration")
	var faction = self_node.get("faction")
	if faction != null:
		if Factions.faction_exists(faction):
			params["faction"] = faction
	
	@warning_ignore("untyped_declaration")
	var vincible_ = self_node.get("vincible")
	if vincible_ != null:
		params["vincible"] = vincible_
		
	return Being.new(params)
