class_name Projectile extends Area2D

@export var speed: float = 500.0
@export var sprite: AnimatedSprite2D
@export var damage: int = 10
@export var audio: AudioStreamPlayer2D
@export var collider: CollisionShape2D

@onready var velocity: Vector2 = Vector2.ZERO
@onready var entered: bool = false
@onready var player_bubble: Area2D = Global.player_bubble
@onready var player: CharacterBody2D = Global.player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		return
	if body in get_tree().get_nodes_in_group("damagable"):
		var health_component: HealthComponent = body.health_component if "health_component" in body else body.find_child("HealthComponent")
		if not health_component:
			push_error(Debug.define_error("Body is in group 'damagable' but does not reference a health component", body))
		else:
			health_component.take_damage(damage)
		entered = true
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
