class_name Being
extends Node2D

# Name and stats
var _nomen: String = ""
var _faction: Factions.FACTIONS
var _character: Characters.CHARACTERS
var _health: float = 0.0
var _speed: float = 0.0
var _damage: float = 0.0
var _exp_on_kill: int = 0

# Booleans
var _alive: bool = true
var _hostile: bool = false
var _debugging: bool = false
var is_character: bool = false # in the characters dict?
var _vincible: bool = true
var _paused: bool = false

# Nodes
var _slave: Node # node this class controls
var _sprite: Sprite2D = null
var _collider: CollisionShape2D = null
var _ibubble: Area2D = null
var _health_bar: TextureProgressBar = null
var _audio: AudioStreamPlayer2D = null
var _navigator: NavigationAgent2D = NavigationAgent2D.new()
var _navigation_target: Vector2 = Vector2.ZERO
var _timeline: Dialogue.TIMELINES = Dialogue.TIMELINES.ERROR
var _missing_components: Array[String] # tracks missing nodes

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


# ===== Initialization =====
# Use a dictionary for optional parameters
func _init(self_node: Node) -> void:
	_slave = self_node
	if _slave == null:
		Debug.throw_error(self, "init", "Could not initiate being")
		return

	_slave.add_to_group("beings")
	_debugging = self_node.get("debugging")
	if _debugging:
		print("[Being] Constructor called by ", _slave.name)

	_init_character()

	_init_vars()

	_init_nodes()

	if _debugging and _missing_components.size() > 0:
		_print_missing_components()


func _init_character() -> void:
	if "character" in _slave:
		if _slave.character is Characters.CHARACTERS:
			if not Characters.is_character_alive(_slave.character):
				_slave.queue_free()
				return
			_character = _slave.character
			is_character = true
			_nomen = Characters.get_character_name(_character)
			_faction = Characters.get_character_faction(_character)
			_slave.add_to_group(Factions.get_faction_name(_faction))
			_slave.add_to_group("interactable")
			_slave.add_to_group("npc")


func _init_vars() -> void:
	if _slave.get("vincible"):
		_vincible = _slave.get("vincible")

	if _slave.get("hostile"):
		_hostile = _slave.get("hostile")

	if _slave.get("base_speed"):
		speed = _slave.get("base_speed")

	if _slave.get("base_damage"):
		damage = _slave.get("base_damage")

	if _slave.get("exp_on_kill"):
		_exp_on_kill = _slave.get("exp_on_kill")

	_timeline = _slave.get("timeline")
	if not _timeline:
		_missing_components.append("timeline")
	else:
		Dialogue.preload_timeline(_timeline)


func _init_nodes() -> void:
	_sprite = _slave.get("sprite")
	if _sprite == null:
		_missing_components.append("sprite")

	_collider = _slave.get("collider")
	if _collider == null:
		_missing_components.append("collider")
	elif _slave.get("collision_on") != null:
		set_collision(_slave.collision_on)

	_ibubble = _slave.get("ibubble")
	if _ibubble == null:
		_missing_components.append("ibubble")
	else:
		_create_navigator()

	_audio = _slave.get("audio")
	if _audio == null:
		_missing_components.append("audio")

	_health_bar = _slave.get("health_bar")
	if _health_bar == null:
		_missing_components.append("health_bar")
	else:
		_health_bar.min_value = 0.0
		_health_bar.max_value = _health
		_health_bar.set_value(_health)
		_health_bar.set_visible(_hostile)


func _create_navigator() -> void:
	_slave.add_child(_navigator)
	if _debugging:
		_navigator.set_debug_enabled(true)
		print("[Being] agents avoidance layers: ", _navigator.get_avoidance_layers())
		print("[Being] agents navigation map: ", _navigator.get_navigation_map())

	_navigator.set_avoidance_enabled(true)
	_navigator.set_path_desired_distance(20.0) # these both are set to default, tinker as needed
	_navigator.set_target_desired_distance(10.0)
	_navigator.set_path_postprocessing(NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL) # PATH_POSTPROCESSING_EDGECENTERED
	_navigator.velocity_computed.connect(_on_navigator_velocity_computed)
	_navigator.target_reached.connect(_on_navigator_target_reached)
	_navigator.set_radius(Global.get_collider(_ibubble).shape.radius)
	_navigation_target = _slave.global_position
	displacement = Global.get_collider(_ibubble).shape.radius


# ===== Component Management =====
func _print_missing_components() -> void:
	print("[Being] Warning: Missing essential components:")
	for component: String in _missing_components:
		print("  - %s" % component)


# ===== Health Management =====
func take_damage(amount: float) -> void:
	if _vincible:
		_hostile = true
		health -= amount
		if _health_bar:
			_health_bar.set_visible(true)


func heal(amount: float) -> void:
	health += amount


func set_paused(value: bool) -> void:
	_paused = value
	set_vincible(!value)
	_slave.set_physics_process(!value)


func is_paused() -> bool:
	return _paused

func set_vincible(value: bool) -> void:
	_vincible = value


func is_vincible() -> bool:
	return _vincible


func die() -> void:
	_slave.velocity = Vector2.ZERO
	_slave.set_physics_process(false)
	_slave.set_process(false)

	if _alive == true:
		_alive = false # Stops from piling calls

		if _character:
			Dialogue.set_alive(_character, false)

		speed = 0

		_health_bar.set_value(0)

		if _audio != null:
			_audio.play()

		if _faction:
			Factions.process_member_kill(_character)

		Global.mob_manager.mob_died.emit()
		Player.log_kill(_exp_on_kill)
		await Global.delay(self, 1.0)
		_slave.queue_free()


func is_alive() -> bool:
	return _alive


func is_hostile() -> bool:
	return _hostile


func set_hostile(value: bool) -> void:
	_hostile = value
	if _health_bar:
		_health_bar.set_visible(value)
	if _hostile:
		_slave.add_to_group("enemies")
	else:
		_slave.remove_from_group("enemies")


func set_timeline(timeline: Dialogue.TIMELINES) -> void:
	_timeline = timeline
	_slave.timeline = _timeline


func set_collision(value: bool) -> void:
	if _collider:
		_collider.set_disabled(!value)


func _on_navigator_velocity_computed(safe_velocity: Vector2) -> void:
	_slave.velocity = safe_velocity


func _on_navigator_target_reached() -> void:
	pass


func seeking_complete() -> void:
	if _navigator:
		await _navigator.navigation_finished
	else:
		Debug.throw_error(_slave, "seeking_complete", "The being %s does not have a navigator" % [_nomen])


# PROCESS FUNCTIONS
var displacement: float = 0.0 # set in init
func seek(target: Variant = _navigation_target, up_down_left_right: String = "") -> void:
	if typeof(target) != typeof(_navigation_target) or target != _navigation_target: # ALWAYS accept a target change
		if target is Vector2:
			_navigation_target = target
		elif target is Node2D:
			_navigation_target = target.global_position
		match(up_down_left_right): # shift will only occur on change of target
			"left":
				_navigation_target -= (1.2 * Vector2(displacement, 0))
			"right":
				_navigation_target += (1.2 * Vector2(displacement, 0))
			"above":
				_navigation_target -= (1.2 * Vector2(0, displacement))
			"below":
				_navigation_target += (1.2 * Vector2(displacement, 0))
		if _debugging:
			print(_nomen, "'s target has been changed. Now seeking: ", _navigation_target)
	if _alive and not _paused:
		_navigator.target_position = _navigation_target
		if _navigator.is_navigation_finished():
			_slave.velocity = Vector2.ZERO
			return
		_navigator.set_velocity(_slave.global_position.direction_to(_navigator.get_next_path_position()) * 50 * Global.speed_mult)
		_slave.set_velocity(_navigator.velocity)
