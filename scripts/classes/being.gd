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
var _vincible: bool = true
var _paused: bool = false

# Nodes
var _slave: Node
var _sprite: Sprite2D = null
var _collider: CollisionShape2D = null
var _touch_detector: Area2D = null
var _health_bar: TextureProgressBar = null
var _audio: AudioStreamPlayer2D = null
var _navigator: NavigationAgent2D = NavigationAgent2D.new()
var _navigation_target: Vector2 = Vector2.ZERO
var _timeline: Dialogue.TIMELINES = Dialogue.TIMELINES.UNASSIGNED
var _missing_components: Array[String] = []

# ===== Initialization =====
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
		_set_speed(_slave.get("base_speed"))

	if _slave.get("base_damage"):
		_set_damage(_slave.get("base_damage"))

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

	_touch_detector = _slave.get("touch_detector")
	if _touch_detector == null:
		_missing_components.append("touch_detector")
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
	_navigator.set_path_desired_distance(20.0)
	_navigator.set_target_desired_distance(10.0)


# ===== Public API =====
# --- Navigation ---
func seeking_complete() -> bool:
	if not _navigator:
		Debug.throw_error(_slave, "seeking_complete", "The being %s does not have a navigator" % [_nomen])
		return false
	await _navigator.navigation_finished
	return true

var displacement: float = 0.0
func seek(target: Variant = _navigation_target, up_down_left_right: String = "") -> void:
	if typeof(target) != typeof(_navigation_target) or target != _navigation_target:
		if target is Vector2:
			_navigation_target = target
		elif target is Node2D:
			_navigation_target = target.global_position
		match(up_down_left_right):
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
		_navigator.set_velocity(_slave.global_position.direction_to(_navigator.get_next_path_position()) * _speed * Global.speed_mult)
		_slave.set_velocity(_navigator.velocity)

# --- Health ---
func set_health(value: float) -> bool:
	return await _set_health(value)


func get_health() -> float:
	return _health


func take_damage(amount: float) -> bool:
	return await _set_health(_health - amount)


func heal(amount: float) -> bool:
	return await _set_health(_health + amount)

# --- Alive ---
func set_alive(value: bool) -> bool:
	return await _set_alive(value)


func is_alive() -> bool:
	return _alive

# --- Speed ---
func set_speed(value: float) -> bool:
	return _set_speed(value)


func get_speed() -> float:
	return _speed

# --- Damage ---
func set_damage(value: float) -> bool:
	return _set_damage(value)


func get_damage() -> float:
	return _damage

# --- Paused ---
func set_paused(value: bool) -> bool:
	return _set_paused(value)


func is_paused() -> bool:
	return _paused

# --- Vincibility ---
func set_vincible(value: bool) -> void:
	return _set_vincible(value)


func is_vincible() -> bool:
	return _vincible

# --- Character Check ---
func is_character() -> bool:
	return _character != Characters.CHARACTERS.UNASSIGNED

# --- Hostile ---
func is_hostile() -> bool:
	return _hostile


func set_hostile(value: bool) -> bool:
	return _set_hostile(value)

# --- Timeline ---
func set_timeline(timeline: Dialogue.TIMELINES) -> bool:
	return _set_timeline(timeline)

# --- Collision ---
func set_collision(value: bool) -> bool:
	return _set_collision(value)

# ===== Private Functions =====
func _set_health(value: float) -> bool:
	if _health_bar == null:
		Debug.throw_error(_slave, "_set_health", "%s requires a health bar in order to change its health" % [_nomen])
		return false
	if not _vincible:
		Debug.throw_error(_slave, "take_damage", "%s is currently invincible and cannot take damage" % [_nomen])
		return false
	if value <= 0 and _alive:
		_health = 0
		_health_bar.set_value(0.0)
		return await _set_alive(false)
	_health = value
	_health_bar.set_value(_health)
	return true


func _set_alive(value: bool) -> bool:
	if value and not _alive:
		_alive = true # its revived
		__process_revival() # process revival
		return true

	if not value and _alive:
		if not _health_bar:
			Debug.throw_error(_slave, "_die", "%s must have a health bar in order to die" % [_nomen])
			return false
		_alive = false # its killed
		await __process_death() # process killing
		return true

	return false

var __processing_revival: bool = false
func __process_revival() -> void: # __ means only the parent function should call it
	if not __processing_revival:
		__processing_revival = true
	__processing_revival = false
	pass

var __processing_death: bool = false
func __process_death() -> void:
	if not __processing_death:
		__processing_death = true
		_health = 0
		_health_bar.set_value(0)
		_speed = 0
		_slave.velocity = Vector2.ZERO
		_slave.set_physics_process(false)
		_slave.set_process(false)
		if _character:
			Dialogue.set_alive(_character, false)
		if _audio != null:
			_audio.play()
		if _faction:
			Factions.member_died.emit(_character)
		Global.mob_manager.mob_died.emit()
		Player.log_kill(_exp_on_kill)
		await Global.delay(self, 1.0)
		_slave.queue_free()
		__processing_revival = false


func _set_speed(value: float) -> bool:
	if not _alive:
		return false
	if value <= 0:
		_speed = 0
		return true
	_speed = value
	return true


func _set_damage(value: float) -> bool:
	if not _alive:
		return false
	if value <= 0:
		_damage = 0
		return true
	_damage = value
	return true


func _set_hostile(value: bool) -> bool:
	if value == _hostile:
		return false
	_hostile = value
	if _health_bar:
		_health_bar.set_visible(_hostile)
	if _hostile:
		_slave.add_to_group("enemies")
	else:
		_slave.remove_from_group("enemies")
	return true


func _set_paused(value: bool) -> bool:
	if not _alive:
		return false
	_paused = value
	set_vincible(!value)
	_slave.set_physics_process(!value)
	return true


func _set_vincible(value: bool) -> bool:
	if not _alive:
		return false
	_vincible = value
	return true


func _set_timeline(timeline: Dialogue.TIMELINES) -> bool:
	if not _alive:
		return false
	if not "timeline" in _slave:
		Debug.throw_error(
			_slave,
			"set_timeline",
			"%s does not have a timeline variable in which to store the timeline '%s'" % [_nomen, Dialogue.get_timeline_name(timeline)]
		)
		return false
	_timeline = timeline
	_slave.timeline = _timeline
	return true


func _set_collision(value: bool) -> bool:
	if not _alive:
		return false
	if not _collider:
		Debug.throw_error(_slave, "set_collision", "%s does not have a collider" % [_nomen])
		return false
	_collider.set_disabled(!value)
	return true


func _print_missing_components() -> void:
	print("[Being] Warning: Missing essential components:")
	for component: String in _missing_components:
		print("  - %s" % component)


func _on_navigator_velocity_computed(safe_velocity: Vector2) -> void:
	_slave.velocity = safe_velocity


func _on_navigator_target_reached() -> void:
	pass
