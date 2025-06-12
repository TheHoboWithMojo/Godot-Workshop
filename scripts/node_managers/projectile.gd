class_name Projectile extends Area2D

@export var speed: float = 500.0
@export var sprite: AnimatedSprite2D
@export var damage: int = 10
@export var audio: AudioStreamPlayer2D
@export var collider: CollisionShape2D

@onready var velocity: Vector2 = Vector2.ZERO
@onready var entered: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body in get_tree().get_nodes_in_group("damagable"):
		var health_component: HealthComponent = body.health_component if "health_component" in body else body.find_child("HealthComponent")
		if not health_component:
			push_error(Debug.define_error("Body is in group 'damagable' but does not reference a health component", body))
		else:
			health_component.take_damage(damage)
		entered = true
		destroy()
	elif not body == Global.player:
		destroy()

func _on_area_entered(area: Area2D) -> void:
	if area in get_tree().get_nodes_in_group("damagable"):
		var health_component: HealthComponent = area.health_component if "health_component" in area else area.find_child("HealthComponent")
		if not health_component:
			push_error(Debug.define_error("Body is in group 'damagable' but does not reference a health component", area))
		else:
			health_component.take_damage(damage)
		entered = true
		destroy()
	elif not area == Global.player_bubble:
		destroy()

func _on_body_exited(_body: Node2D) -> void:
	if not entered:
		await Global.delay(self, 3.0) # wait three seconds and self destruct if it doesnt hit anything
		destroy()

func destroy() -> void:
	velocity = Vector2.ZERO
	collider.call_deferred("set_disabled", true)
	if sprite:
		sprite.visible = false
	if audio.playing:
		await audio.finished
	queue_free()
