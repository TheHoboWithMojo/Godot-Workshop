# DEPRECATED CLASS
class_name Beings
extends Node2D

# Name and stats
var _nomen: String = ""
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

signal navigation_target_changed

# ===== Initialization =====
func _init(self_node: Node) -> void:
	_slave = self_node
	if _slave == null:
		push_warning(Debug.define_error("Could not initiate being", self))
		return

	_slave.add_to_group("beings")
	Debug.debug("[Being] Constructor called by %s" % [_slave.name], _slave, "_init")

	_init_vars()
	_init_nodes()


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


# ===== Public API =====

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

# --- Character Check ---

# --- Hostile ---
func is_hostile() -> bool:
	return _hostile


func set_hostile(value: bool) -> bool:
	return _set_hostile(value)

# --- Timeline ---

# --- Collision ---
func set_collision(value: bool) -> bool:
	return _set_collision(value)


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
	_slave.set_physics_process(!value)
	return true


func _set_collision(value: bool) -> bool:
	if not _alive:
		return false
	if not _collider:
		push_warning(Debug.define_error("%s does not have a collider" % [_nomen], _slave))
		return false
	_collider.set_disabled(!value)
	return true


func _print_missing_components() -> void:
	print("[Being] Warning: Missing essential components:")
	for component: String in _missing_components:
		print("  - %s" % component)
