@icon("res://assets/Icons/16x16/heart.png")
class_name HealthComponent extends Node
# --- Exported Variables ---
@export var inherit_debugging: bool = false
@export var debugging: bool = false
@export var parent: Node
@export var process_death_internally: bool = true
@export var regen_rate: int = 0
@export var vincible: bool = true
@export var exp_per_kill: int = 10
@export var health_bar: HealthBar = null
@export var max_health: int = 100
# --- Internal State ---
var alive: bool = true
var health: int = 100
# --- Signals ---
signal died()

func _ready() -> void:
	set_name("HealthComponent")
	if parent == self:
		Debug.debug("In self_parent mode", parent, "_ready")
	assert(parent != null, Debug.define_error("HealthComponent of inferred parent %s does not explicity reference a parent" % [get_parent()], self))
	if vincible:
		parent.add_to_group("damagable")
	debugging = parent.debugging if inherit_debugging else debugging
	if health_bar:
		health_bar.set_value(max_health)
		health_bar.set_visible(false)
	if parent is NPC and parent.get_character_component():
		await parent.await_name_changed()

# --- Health Interface ---
func set_health(value: int) -> bool:
	return await _set_health(value)


func set_max_health(value: int) -> void:
	max_health = value if value > 0 else max_health


func get_health() -> int:
	return health


func take_damage(amount: int) -> bool:
	return await _set_health(health - amount)


func heal(amount: int) -> bool:
	return await _set_health(health + amount)


# --- Alive Interface ---
func set_alive(value: bool) -> bool:
	return await _set_alive(value)


func is_alive() -> bool:
	return alive


# --- Vincibility Interface ---
func set_vincible(value: bool) -> void:
	_set_vincible(value)


func is_vincible() -> bool:
	return vincible

# --- Internal Health Logic ---
func _set_health(value: int) -> bool:
	if value <= 0 and alive:
		health = 0
		if health_bar:
			health_bar.set_value(0.0)
		return await _set_alive(false)
	elif value > max_health:
		health = max_health
		return true
	health = value
	if health_bar:
		health_bar.set_value(health)
	return true

# --- Internal Alive Logic ---
func _set_alive(value: bool) -> bool:
	if value and not alive:
		alive = true
		__process_revival()
		return true

	if not value and alive:
		#if not health_bar:
			#push_error(Debug.define_error("%s must have a health bar in order to die" % [parent.name], parent))
			#return false
		alive = false
		await __process_death()
		return true

	return false

# --- Vincibility Logic ---
func _set_vincible(value: bool) -> bool:
	if not alive:
		return false
	vincible = value
	return true

# --- Death and Revival ---
var __processing_revival: bool = false
func __process_revival() -> void:
	if __processing_revival:
		return
	__processing_revival = true
	# Add revival behavior here
	__processing_revival = false


var __processing_death: bool = false
func __process_death() -> void:
	if not process_death_internally:
		died.emit()
		return
	if __processing_death:
		return
	__processing_death = true

	health = 0
	if health_bar:
		health_bar.set_value(0)

	if "velocity" in parent:
		parent.velocity = Vector2.ZERO
	parent.set_physics_process(false)
	parent.set_process(false)

	Global.mob_manager.mob_died.emit()
	Player.log_kill(exp_per_kill)

	await Global.delay(self, 0.1)
	died.emit()
	parent.queue_free()

	__processing_revival = false
